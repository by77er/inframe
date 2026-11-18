//! The document `inframe serve` hands the browser: every stack of the project as nodes that
//! know where the source declared them, and the associations between them.
//!
//! The model is derived from what a stack's entry point printed and nothing else: Graph IR
//! for the nodes and their references, the origins beside it for the source hierarchy, and
//! the stack's local state for what has been applied. State is reduced to presence here;
//! attribute values in a state file, sensitive ones among them, never reach the browser.

use std::collections::{BTreeMap, BTreeSet};

use inframe_graph_ir::{
    Address, Expr, GraphDocument, Lifecycle, REMOTE_STATE_DATA_SOURCE, TemplatePart,
};
use serde_json::Value;

use crate::inspect::{format_expr, format_json};
use crate::project::Origins;
pub use inframe_view::model::{
    Argument, BuildStatus, Edge, EdgeKind, Model, Node, NodeKind, Origin, ProjectInfo, StackModel,
    StateModel,
};

/// The rows shown for one node; a node configured past this is cut off and says so.
const MAX_ARGUMENT_ROWS: usize = 160;
/// The characters shown of one value; multi-kilobyte literals are cut off here.
const MAX_VALUE_LENGTH: usize = 320;

/// What the server knows about one stack: its configuration, the result of its last build,
/// and what its state holds.
#[derive(Debug, Clone)]
pub struct StackSnapshot {
    pub name: String,
    pub frontend: &'static str,
    pub backend: String,
    pub gated: bool,
    pub status: BuildStatus,
    pub error: Option<String>,
    pub built: Option<Built>,
    pub state: StateSnapshot,
}

/// The last successful build of a stack.
#[derive(Debug, Clone)]
pub struct Built {
    pub graph: GraphDocument,
    pub origins: Option<Origins>,
    pub finished_ms: u64,
    pub took_ms: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StateSnapshot {
    /// The stack's state is not read, for the reason given (a remote backend, for one).
    Untracked(String),
    /// A local backend with no state file yet: nothing has been applied.
    Empty,
    Tracked(AppliedState),
}

/// What a state file says exists, by graph address and output name.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct AppliedState {
    pub serial: u64,
    pub updated_ms: u64,
    /// Addresses (`type.name`, `data.type.name`) with at least one instance.
    pub addresses: BTreeSet<String>,
    pub outputs: BTreeSet<String>,
}

impl AppliedState {
    /// Read presence out of a state file (format 4). Resources inside `OpenTofu` modules are
    /// skipped: a graph has none, so they could only be reported as unmanaged.
    pub fn parse(bytes: &[u8], updated_ms: u64) -> Result<Self, serde_json::Error> {
        let document: Value = serde_json::from_slice(bytes)?;
        let mut state = Self {
            serial: document.get("serial").and_then(Value::as_u64).unwrap_or(0),
            updated_ms,
            ..Self::default()
        };
        for resource in document
            .get("resources")
            .and_then(Value::as_array)
            .into_iter()
            .flatten()
        {
            let field = |name: &str| resource.get(name).and_then(Value::as_str);
            let (Some(kind), Some(name)) = (field("type"), field("name")) else {
                continue;
            };
            let instances = resource
                .get("instances")
                .and_then(Value::as_array)
                .map_or(0, Vec::len);
            if field("module").is_some() || instances == 0 {
                continue;
            }
            state.addresses.insert(match field("mode") {
                Some("data") => format!("data.{kind}.{name}"),
                _ => format!("{kind}.{name}"),
            });
        }
        if let Some(outputs) = document.get("outputs").and_then(Value::as_object) {
            state.outputs.extend(outputs.keys().cloned());
        }
        Ok(state)
    }
}

/// Assemble the document from every stack's snapshot. Cross-stack edges need all of them: a
/// stack reference points at the outputs of another stack's last good build.
pub fn build(version: u64, project: &ProjectInfo, stacks: &[StackSnapshot]) -> Model {
    let outputs_by_stack: BTreeMap<&str, BTreeSet<&str>> = stacks
        .iter()
        .filter_map(|stack| {
            let built = stack.built.as_ref()?;
            Some((
                stack.name.as_str(),
                built.graph.outputs.keys().map(String::as_str).collect(),
            ))
        })
        .collect();
    Model {
        version,
        project: project.clone(),
        stacks: stacks
            .iter()
            .map(|stack| stack_model(stack, &outputs_by_stack))
            .collect(),
    }
}

fn stack_model(
    stack: &StackSnapshot,
    outputs_by_stack: &BTreeMap<&str, BTreeSet<&str>>,
) -> StackModel {
    let applied = match &stack.state {
        StateSnapshot::Tracked(state) => Some(state.clone()),
        StateSnapshot::Empty => Some(AppliedState::default()),
        StateSnapshot::Untracked(_) => None,
    };
    let state = match &stack.state {
        StateSnapshot::Untracked(reason) => StateModel {
            tracked: false,
            reason: Some(reason.clone()),
            serial: None,
            updated_ms: None,
        },
        StateSnapshot::Empty => StateModel {
            tracked: true,
            reason: Some("nothing has been applied yet".to_owned()),
            serial: None,
            updated_ms: None,
        },
        StateSnapshot::Tracked(state) => StateModel {
            tracked: true,
            reason: None,
            serial: Some(state.serial),
            updated_ms: Some(state.updated_ms),
        },
    };
    let mut builder = StackBuilder {
        stack: &stack.name,
        origins: stack
            .built
            .as_ref()
            .and_then(|built| built.origins.as_ref()),
        applied: applied.as_ref(),
        nodes: Vec::new(),
        edges: BTreeMap::new(),
    };
    let mut unmanaged = Vec::new();
    if let Some(built) = &stack.built {
        builder.add_graph(&built.graph, outputs_by_stack);
        if let Some(applied) = &applied {
            let declared: BTreeSet<String> = built
                .graph
                .resources
                .iter()
                .map(|resource| resource.address().to_string())
                .collect();
            unmanaged = applied
                .addresses
                .iter()
                .filter(|address| !address.starts_with("data.") && !declared.contains(*address))
                .cloned()
                .collect();
        }
    }
    let ids: BTreeSet<&str> = builder.nodes.iter().map(|node| node.id.as_str()).collect();
    let edges = builder
        .edges
        .iter()
        .filter(|((from, to, kind), _)| {
            // A stack edge ends in another stack, whose outputs were checked when it was added.
            ids.contains(from.as_str()) && (*kind == EdgeKind::Stack || ids.contains(to.as_str()))
        })
        .map(|((from, to, kind), via)| Edge {
            from: from.clone(),
            to: to.clone(),
            kind: *kind,
            via: via.iter().cloned().collect(),
        })
        .collect();
    StackModel {
        name: stack.name.clone(),
        frontend: stack.frontend.to_owned(),
        backend: stack.backend.clone(),
        gated: stack.gated,
        status: stack.status,
        error: stack.error.clone(),
        built_at_ms: stack.built.as_ref().map(|built| built.finished_ms),
        build_ms: stack.built.as_ref().map(|built| built.took_ms),
        has_origins: builder.origins.is_some_and(|origins| !origins.is_empty()),
        state,
        nodes: builder.nodes,
        edges,
        unmanaged,
    }
}

struct StackBuilder<'a> {
    stack: &'a str,
    origins: Option<&'a Origins>,
    applied: Option<&'a AppliedState>,
    nodes: Vec<Node>,
    /// Keyed by `(from, to, kind)` so that several arguments reading one node are one edge.
    edges: BTreeMap<(String, String, EdgeKind), BTreeSet<String>>,
}

impl StackBuilder<'_> {
    fn id(&self, key: &str) -> String {
        format!("{}/{key}", self.stack)
    }

    fn origin(&self, key: &str) -> Option<Origin> {
        self.origins?
            .get(key)
            .filter(|origin| !origin.module.is_empty())
            .cloned()
    }

    fn edge(&mut self, from: &str, to: String, kind: EdgeKind, via: Option<String>) {
        if from == to {
            return;
        }
        self.edges
            .entry((from.to_owned(), to, kind))
            .or_default()
            .extend(via);
    }

    fn add_graph(
        &mut self,
        graph: &GraphDocument,
        outputs_by_stack: &BTreeMap<&str, BTreeSet<&str>>,
    ) {
        let configured: BTreeSet<String> = graph
            .provider_configs
            .iter()
            .map(|config| provider_address(&config.provider, config.alias.as_deref()))
            .collect();

        for config in &graph.provider_configs {
            let address = provider_address(&config.provider, config.alias.as_deref());
            let key = format!("provider.{address}");
            let id = self.id(&key);
            let (arguments, hidden_arguments, weight) = self.arguments(&id, &config.arguments);
            self.nodes.push(Node {
                origin: self.origin(&key),
                id,
                kind: NodeKind::Provider,
                address: key,
                type_name: graph.required_providers.get(&config.provider).map_or_else(
                    || config.provider.clone(),
                    |required| required.source.clone(),
                ),
                name: address,
                provider: Some(config.provider.clone()),
                arguments,
                hidden_arguments,
                flags: graph
                    .required_providers
                    .get(&config.provider)
                    .map(|required| required.version.clone())
                    .into_iter()
                    .collect(),
                weight,
                applied: None,
            });
        }

        self.add_resources(graph, &configured);
        self.add_data_sources(graph, &configured);
        self.add_outputs(graph);
        self.stack_edges(graph, outputs_by_stack);
    }

    fn add_resources(&mut self, graph: &GraphDocument, configured: &BTreeSet<String>) {
        for resource in &graph.resources {
            let address = resource.address().to_string();
            let id = self.id(&address);
            let (arguments, hidden_arguments, weight) = self.arguments(&id, &resource.arguments);
            self.explicit_edges(&id, &resource.depends_on, EdgeKind::DependsOn);
            if let Some(lifecycle) = &resource.lifecycle {
                self.explicit_edges(
                    &id,
                    &lifecycle.replace_triggered_by,
                    EdgeKind::ReplaceTrigger,
                );
            }
            let provider = provider_of(&resource.resource_type, resource.provider.as_deref());
            self.provider_edge(&id, &provider, resource.provider.as_deref(), configured);
            self.nodes.push(Node {
                origin: self.origin(&address),
                applied: self
                    .applied
                    .map(|applied| applied.addresses.contains(&address)),
                id,
                kind: NodeKind::Resource,
                address,
                type_name: resource.resource_type.clone(),
                name: resource.name.clone(),
                provider: Some(provider),
                arguments,
                hidden_arguments,
                flags: resource
                    .lifecycle
                    .as_ref()
                    .map(lifecycle_flags)
                    .unwrap_or_default(),
                weight,
            });
        }
    }

    fn add_data_sources(&mut self, graph: &GraphDocument, configured: &BTreeSet<String>) {
        for data_source in &graph.data_sources {
            let address = data_source.address().to_string();
            let id = self.id(&address);
            let (arguments, hidden_arguments, weight) = self.arguments(&id, &data_source.arguments);
            self.explicit_edges(&id, &data_source.depends_on, EdgeKind::DependsOn);
            let provider = provider_of(
                &data_source.data_source_type,
                data_source.provider.as_deref(),
            );
            self.provider_edge(&id, &provider, data_source.provider.as_deref(), configured);
            self.nodes.push(Node {
                origin: self.origin(&address),
                applied: self
                    .applied
                    .map(|applied| applied.addresses.contains(&address)),
                id,
                kind: NodeKind::Data,
                address,
                type_name: data_source.data_source_type.clone(),
                name: data_source.name.clone(),
                provider: Some(provider),
                arguments,
                hidden_arguments,
                flags: Vec::new(),
                weight,
            });
        }

        for reference in &graph.stack_references {
            let address = reference.address().to_string();
            let id = self.id(&address);
            self.nodes.push(Node {
                origin: self.origin(&address),
                applied: None,
                id,
                kind: NodeKind::StackReference,
                address,
                type_name: REMOTE_STATE_DATA_SOURCE.to_owned(),
                name: reference.stack.clone(),
                provider: None,
                arguments: Vec::new(),
                hidden_arguments: 0,
                flags: Vec::new(),
                weight: 2,
            });
        }
    }

    fn add_outputs(&mut self, graph: &GraphDocument) {
        for (name, output) in &graph.outputs {
            let key = format!("output.{name}");
            let id = self.id(&key);
            let mut rows = Rows::default();
            flatten_expr("value", &output.value, &mut rows);
            let (arguments, hidden_arguments, weight) = self.rows(&id, rows);
            let mut flags = Vec::new();
            if output.sensitive {
                flags.push("sensitive".to_owned());
            }
            self.nodes.push(Node {
                origin: self.origin(&key),
                applied: self.applied.map(|applied| applied.outputs.contains(name)),
                id,
                kind: NodeKind::Output,
                address: key,
                type_name: String::new(),
                name: name.clone(),
                provider: None,
                arguments,
                hidden_arguments,
                flags,
                weight,
            });
        }
    }

    /// Each stack reference points at the outputs it is read for, in the stack that
    /// declares them.
    fn stack_edges(
        &mut self,
        graph: &GraphDocument,
        outputs_by_stack: &BTreeMap<&str, BTreeSet<&str>>,
    ) {
        let mut read = Vec::new();
        let mut visit = |expression: &Expr| {
            collect_references(expression, &mut |address, path| {
                if let Address::DataSource {
                    data_source_type,
                    name,
                } = address
                {
                    if data_source_type == REMOTE_STATE_DATA_SOURCE {
                        if let [outputs, output, ..] = path {
                            if outputs == "outputs" {
                                read.push((name.clone(), output.clone()));
                            }
                        }
                    }
                }
            });
        };
        for expression in graph
            .resources
            .iter()
            .flat_map(|resource| resource.arguments.values())
            .chain(
                graph
                    .data_sources
                    .iter()
                    .flat_map(|data_source| data_source.arguments.values()),
            )
            .chain(
                graph
                    .provider_configs
                    .iter()
                    .flat_map(|config| config.arguments.values()),
            )
            .chain(graph.outputs.values().map(|output| &output.value))
        {
            visit(expression);
        }
        for (stack, output) in read {
            let declared = graph
                .stack_references
                .iter()
                .any(|reference| reference.stack == stack);
            let exported = outputs_by_stack
                .get(stack.as_str())
                .is_some_and(|outputs| outputs.contains(output.as_str()));
            if declared && exported {
                let from = self.id(&format!("data.{REMOTE_STATE_DATA_SOURCE}.{stack}"));
                self.edge(
                    &from,
                    format!("{stack}/output.{output}"),
                    EdgeKind::Stack,
                    Some(output),
                );
            }
        }
    }

    fn explicit_edges(&mut self, from: &str, targets: &[Address], kind: EdgeKind) {
        for target in targets {
            let to = self.id(&target.to_string());
            self.edge(from, to, kind, None);
        }
    }

    /// The provider configuration a node is created through: the one it selects, or the
    /// default configuration of its provider when the stack configures one.
    fn provider_edge(
        &mut self,
        from: &str,
        provider: &str,
        selected: Option<&str>,
        configured: &BTreeSet<String>,
    ) {
        let address = selected.unwrap_or(provider);
        if configured.contains(address) {
            let to = self.id(&format!("provider.{address}"));
            self.edge(from, to, EdgeKind::Provider, None);
        }
    }

    fn arguments(
        &mut self,
        id: &str,
        arguments: &BTreeMap<String, Expr>,
    ) -> (Vec<Argument>, usize, usize) {
        let mut rows = Rows::default();
        for (name, expression) in arguments {
            flatten_expr(name, expression, &mut rows);
        }
        self.rows(id, rows)
    }

    /// Turn flattened rows into arguments and reference edges; returns the arguments, how
    /// many were left out, and the node's weight.
    fn rows(&mut self, id: &str, rows: Rows) -> (Vec<Argument>, usize, usize) {
        let weight = 1 + rows.0.len();
        let hidden = rows.0.len().saturating_sub(MAX_ARGUMENT_ROWS);
        let mut arguments = Vec::new();
        for (index, row) in rows.0.into_iter().enumerate() {
            let mut references = Vec::new();
            for (address, path) in row.references {
                let to = self.id(&address.to_string());
                let via = if path.is_empty() {
                    row.name.clone()
                } else {
                    format!("{} → {}", row.name, path.join("."))
                };
                self.edge(id, to.clone(), EdgeKind::Reference, Some(via));
                if !references.contains(&to) {
                    references.push(to);
                }
            }
            if index < MAX_ARGUMENT_ROWS {
                arguments.push(Argument {
                    name: row.name,
                    value: truncate(row.value),
                    references,
                });
            }
        }
        (arguments, hidden, weight)
    }
}

struct Row {
    name: String,
    value: String,
    references: Vec<(Address, Vec<String>)>,
}

#[derive(Default)]
struct Rows(Vec<Row>);

/// Flatten an expression into one row per leaf. Objects and lists of objects descend, both
/// symbolic ones and literal JSON; everything else is one value printed as `graph inspect`
/// prints it, which never resolves a secret.
fn flatten_expr(name: &str, expression: &Expr, rows: &mut Rows) {
    match expression {
        Expr::Object { fields } if !fields.is_empty() => {
            for (field, value) in fields {
                flatten_expr(&format!("{name}.{field}"), value, rows);
            }
        }
        Expr::Array { items } if !items.is_empty() && items.iter().all(is_structured) => {
            for (index, item) in items.iter().enumerate() {
                flatten_expr(&format!("{name}[{index}]"), item, rows);
            }
        }
        Expr::Literal { value } if is_structured_json(value) => flatten_json(name, value, rows),
        _ => {
            let mut references = Vec::new();
            collect_references(expression, &mut |address, path| {
                references.push((address.clone(), path.to_vec()));
            });
            rows.0.push(Row {
                name: name.to_owned(),
                value: format_expr(expression),
                references,
            });
        }
    }
}

fn is_structured(expression: &Expr) -> bool {
    match expression {
        Expr::Object { fields } => !fields.is_empty(),
        Expr::Literal { value } => is_structured_json(value),
        _ => false,
    }
}

fn is_structured_json(value: &Value) -> bool {
    match value {
        Value::Object(fields) => !fields.is_empty(),
        Value::Array(items) => {
            !items.is_empty()
                && items
                    .iter()
                    .all(|item| matches!(item, Value::Object(fields) if !fields.is_empty()))
        }
        _ => false,
    }
}

fn flatten_json(name: &str, value: &Value, rows: &mut Rows) {
    match value {
        Value::Object(fields) if !fields.is_empty() => {
            let mut fields: Vec<_> = fields.iter().collect();
            fields.sort_by_key(|(field, _)| *field);
            for (field, value) in fields {
                flatten_json(&format!("{name}.{field}"), value, rows);
            }
        }
        Value::Array(_) if is_structured_json(value) => {
            for (index, item) in value.as_array().into_iter().flatten().enumerate() {
                flatten_json(&format!("{name}[{index}]"), item, rows);
            }
        }
        _ => rows.0.push(Row {
            name: name.to_owned(),
            value: format_json(value),
            references: Vec::new(),
        }),
    }
}

/// Every direct attribute reference in `expression`, in the order written.
fn collect_references(expression: &Expr, visit: &mut impl FnMut(&Address, &[String])) {
    match expression {
        Expr::ResourceAttr { address, path } | Expr::DataSourceAttr { address, path } => {
            visit(address, path);
        }
        Expr::Array { items } => {
            for item in items {
                collect_references(item, visit);
            }
        }
        Expr::Object { fields } => {
            for value in fields.values() {
                collect_references(value, visit);
            }
        }
        Expr::Index { collection, key } => {
            collect_references(collection, visit);
            collect_references(key, visit);
        }
        Expr::Attribute { of, .. } | Expr::Splat { of } => collect_references(of, visit),
        Expr::Conditional {
            condition,
            when_true,
            when_false,
        } => {
            collect_references(condition, visit);
            collect_references(when_true, visit);
            collect_references(when_false, visit);
        }
        Expr::Function { args, .. } => {
            for argument in args {
                collect_references(argument, visit);
            }
        }
        Expr::Template { parts } => {
            for part in parts {
                if let TemplatePart::Interpolation { expression } = part {
                    collect_references(expression, visit);
                }
            }
        }
        Expr::Literal { .. } | Expr::SecretEnv { .. } | Expr::UnsafeRaw { .. } => {}
    }
}

fn truncate(value: String) -> String {
    if value.chars().count() <= MAX_VALUE_LENGTH {
        return value;
    }
    let mut cut: String = value.chars().take(MAX_VALUE_LENGTH).collect();
    cut.push('…');
    cut
}

fn provider_address(provider: &str, alias: Option<&str>) -> String {
    alias.map_or_else(
        || provider.to_owned(),
        |alias| format!("{provider}.{alias}"),
    )
}

/// The local name of the provider a node belongs to: that of the configuration it selects,
/// else the prefix of its type, which is how `OpenTofu` infers it.
fn provider_of(type_name: &str, selected: Option<&str>) -> String {
    let name = selected.map_or_else(
        || type_name.split('_').next().unwrap_or(type_name),
        |selected| selected.split('.').next().unwrap_or(selected),
    );
    name.to_owned()
}

fn lifecycle_flags(lifecycle: &Lifecycle) -> Vec<String> {
    let mut flags = Vec::new();
    if lifecycle.create_before_destroy {
        flags.push("create before destroy".to_owned());
    }
    if lifecycle.prevent_destroy {
        flags.push("prevent destroy".to_owned());
    }
    if !lifecycle.ignore_changes.is_empty() {
        flags.push(format!("ignores {}", lifecycle.ignore_changes.join(", ")));
    }
    flags
}

#[cfg(test)]
mod tests {
    use super::*;

    const PLATFORM: &str = r#"{
      "format_version": "1.0",
      "required_providers": {"digitalocean": {"source": "digitalocean/digitalocean", "version": "= 2.100.0"}},
      "provider_configs": [{"provider": "digitalocean", "arguments": {"token": {"kind": "secret_env", "name": "DIGITALOCEAN_TOKEN"}}}],
      "resources": [
        {"type": "digitalocean_vpc", "name": "platform", "arguments": {"name": {"kind": "literal", "value": "platform"}}, "depends_on": []},
        {"type": "digitalocean_database_cluster", "name": "postgres", "depends_on": [],
         "lifecycle": {"create_before_destroy": true},
         "arguments": {
           "private_network_uuid": {"kind": "resource_attr", "address": "digitalocean_vpc.platform", "path": ["id"]},
           "storage_autoscale": {"kind": "array", "items": [{"kind": "object", "fields": {
             "enabled": {"kind": "literal", "value": true},
             "threshold_percent": {"kind": "literal", "value": 80}}}]}}}
      ],
      "data_sources": [],
      "outputs": {"database_host": {"value": {"kind": "resource_attr", "address": "digitalocean_database_cluster.postgres", "path": ["host"]}}},
      "moves": []
    }"#;

    const CONSUMER: &str = r#"{
      "format_version": "1.0",
      "required_providers": {}, "provider_configs": [], "resources": [], "data_sources": [],
      "outputs": {"host": {"sensitive": true, "value": {"kind": "data_source_attr",
        "address": "data.terraform_remote_state.platform", "path": ["outputs", "database_host"]}}},
      "moves": [],
      "stack_references": [{"stack": "platform"}]
    }"#;

    fn snapshot(name: &str, graph: &str, state: StateSnapshot) -> StackSnapshot {
        let origins = Origins::from([(
            "digitalocean_database_cluster.postgres".to_owned(),
            Origin {
                module: "Infra.Platform".to_owned(),
                declaration: "createDatabases".to_owned(),
                line: 40,
            },
        )]);
        StackSnapshot {
            name: name.to_owned(),
            frontend: "Lean",
            backend: "local".to_owned(),
            gated: false,
            status: BuildStatus::Ready,
            error: None,
            built: Some(Built {
                graph: serde_json::from_str(graph).unwrap(),
                origins: Some(origins),
                finished_ms: 1,
                took_ms: 1,
            }),
            state,
        }
    }

    fn project() -> ProjectInfo {
        ProjectInfo {
            name: "demo".to_owned(),
            root: "/demo".to_owned(),
            error: None,
        }
    }

    fn edge<'a>(stack: &'a StackModel, from: &str, to: &str) -> &'a Edge {
        stack
            .edges
            .iter()
            .find(|edge| edge.from == from && edge.to == to)
            .unwrap_or_else(|| panic!("no edge {from} -> {to} in {:?}", stack.edges))
    }

    #[test]
    fn nodes_carry_origins_flattened_arguments_and_reference_edges() {
        let model = build(
            7,
            &project(),
            &[snapshot(
                "platform",
                PLATFORM,
                StateSnapshot::Untracked("s3".to_owned()),
            )],
        );
        let stack = &model.stacks[0];
        assert!(stack.has_origins);
        assert!(!stack.state.tracked);

        let database = stack
            .nodes
            .iter()
            .find(|node| node.address == "digitalocean_database_cluster.postgres")
            .unwrap();
        assert_eq!(
            database.id,
            "platform/digitalocean_database_cluster.postgres"
        );
        assert_eq!(
            database.origin.as_ref().unwrap().declaration,
            "createDatabases"
        );
        assert_eq!(database.provider.as_deref(), Some("digitalocean"));
        assert_eq!(database.flags, ["create before destroy"]);
        assert_eq!(database.applied, None);
        let names: Vec<_> = database
            .arguments
            .iter()
            .map(|row| row.name.as_str())
            .collect();
        assert_eq!(
            names,
            [
                "private_network_uuid",
                "storage_autoscale[0].enabled",
                "storage_autoscale[0].threshold_percent"
            ]
        );
        assert_eq!(database.weight, 4);
        assert_eq!(
            database.arguments[0].references,
            ["platform/digitalocean_vpc.platform"]
        );

        let reference = edge(
            stack,
            "platform/digitalocean_database_cluster.postgres",
            "platform/digitalocean_vpc.platform",
        );
        assert_eq!(reference.kind, EdgeKind::Reference);
        assert_eq!(reference.via, ["private_network_uuid → id"]);
        // The default provider configuration is an association of every node of its provider.
        let provider = edge(
            stack,
            "platform/digitalocean_vpc.platform",
            "platform/provider.digitalocean",
        );
        assert_eq!(provider.kind, EdgeKind::Provider);
        edge(
            stack,
            "platform/output.database_host",
            "platform/digitalocean_database_cluster.postgres",
        );
        // Secrets stay names.
        let token = &stack.nodes[0].arguments[0];
        assert_eq!(token.value, "secretEnv(\"DIGITALOCEAN_TOKEN\")");
    }

    #[test]
    fn stack_references_point_at_the_outputs_they_read() {
        let model = build(
            1,
            &project(),
            &[
                snapshot("consumer", CONSUMER, StateSnapshot::Empty),
                snapshot("platform", PLATFORM, StateSnapshot::Empty),
            ],
        );
        let consumer = &model.stacks[0];
        let reference = consumer
            .nodes
            .iter()
            .find(|node| node.kind == NodeKind::StackReference)
            .unwrap();
        assert_eq!(
            reference.id,
            "consumer/data.terraform_remote_state.platform"
        );
        edge(consumer, "consumer/output.host", &reference.id);
        let across = edge(consumer, &reference.id, "platform/output.database_host");
        assert_eq!(across.kind, EdgeKind::Stack);
        let output = consumer
            .nodes
            .iter()
            .find(|node| node.kind == NodeKind::Output)
            .unwrap();
        assert_eq!(output.flags, ["sensitive"]);
        assert_eq!(output.applied, Some(false));
    }

    #[test]
    fn state_is_reduced_to_presence() {
        let state = AppliedState::parse(
            br#"{"version": 4, "serial": 9,
                 "outputs": {"database_host": {"value": "db.internal", "type": "string"}},
                 "resources": [
                   {"mode": "managed", "type": "digitalocean_vpc", "name": "platform",
                    "instances": [{"attributes": {"id": "secret-looking-id"}}]},
                   {"mode": "managed", "type": "digitalocean_tag", "name": "retired", "instances": [{}]},
                   {"mode": "managed", "type": "digitalocean_tag", "name": "tainted", "instances": []},
                   {"mode": "data", "type": "digitalocean_region", "name": "here", "instances": [{}]}]}"#,
            42,
        )
        .unwrap();
        assert_eq!(state.serial, 9);
        assert!(state.addresses.contains("data.digitalocean_region.here"));
        assert!(!state.addresses.contains("digitalocean_tag.tainted"));

        let model = build(
            1,
            &project(),
            &[snapshot(
                "platform",
                PLATFORM,
                StateSnapshot::Tracked(state),
            )],
        );
        let stack = &model.stacks[0];
        let applied = |address: &str| {
            stack
                .nodes
                .iter()
                .find(|node| node.address == address)
                .unwrap()
                .applied
        };
        assert_eq!(applied("digitalocean_vpc.platform"), Some(true));
        assert_eq!(
            applied("digitalocean_database_cluster.postgres"),
            Some(false)
        );
        assert_eq!(applied("output.database_host"), Some(true));
        assert_eq!(stack.unmanaged, ["digitalocean_tag.retired"]);
        let rendered = serde_json::to_string(&model).unwrap();
        assert!(!rendered.contains("secret-looking-id"));
        assert!(!rendered.contains("db.internal"));
    }
}
