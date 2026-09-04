//! Pure Graph IR lowering plus the effectful `OpenTofu` process boundary.

use std::collections::BTreeMap;
use std::ffi::OsString;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};

use inframe_graph_ir::{Expr, GraphDocument, TemplatePart};
use serde_json::{Map, Value, json};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum LowerError {
    #[error(transparent)]
    InvalidGraph(#[from] inframe_graph_ir::ValidationError),
    #[error("unsafe raw expression is empty")]
    EmptyRawExpression,
}

/// Lower a validated Graph IR document to `OpenTofu`'s JSON configuration syntax.
#[allow(clippy::too_many_lines)]
pub fn lower(graph: &GraphDocument) -> Result<Value, LowerError> {
    graph.validate()?;
    let mut document = Map::new();

    let mut terraform = Map::new();
    if !graph.required_providers.is_empty() {
        let mut required = Map::new();
        for (name, requirement) in &graph.required_providers {
            required.insert(
                name.clone(),
                json!({
                    "source": requirement.source,
                    "version": requirement.version,
                }),
            );
        }
        terraform.insert("required_providers".into(), Value::Object(required));
    }
    if !terraform.is_empty() {
        document.insert("terraform".into(), Value::Object(terraform));
    }

    let secret_names = graph.secret_environment_names();
    if !secret_names.is_empty() {
        let variables = secret_names
            .iter()
            .map(|name| {
                (
                    secret_variable_name(name),
                    json!({
                        "type": "string",
                        "sensitive": true,
                        "nullable": false,
                    }),
                )
            })
            .collect();
        document.insert("variable".into(), Value::Object(variables));
    }

    if !graph.provider_configs.is_empty() {
        let mut providers: BTreeMap<String, Vec<Value>> = BTreeMap::new();
        for config in &graph.provider_configs {
            let mut body = lower_arguments(&config.arguments)?;
            if let Some(alias) = &config.alias {
                body.insert("alias".into(), Value::String(alias.clone()));
            }
            providers
                .entry(config.provider.clone())
                .or_default()
                .push(Value::Object(body));
        }
        let providers = providers
            .into_iter()
            .map(|(name, configs)| (name, Value::Array(configs)))
            .collect();
        document.insert("provider".into(), Value::Object(providers));
    }

    if !graph.resources.is_empty() {
        let mut resource_types: BTreeMap<String, BTreeMap<String, Value>> = BTreeMap::new();
        for resource in &graph.resources {
            let mut body = lower_arguments(&resource.arguments)?;
            if !resource.depends_on.is_empty() {
                body.insert(
                    "depends_on".into(),
                    Value::Array(
                        resource
                            .depends_on
                            .iter()
                            .map(ToString::to_string)
                            .map(Value::String)
                            .collect(),
                    ),
                );
            }
            if let Some(provider) = &resource.provider {
                body.insert("provider".into(), Value::String(provider.clone()));
            }
            if let Some(lifecycle) = &resource.lifecycle {
                let mut value = serde_json::to_value(lifecycle).expect("lifecycle serializes");
                if let Value::Object(object) = &mut value {
                    if let Some(Value::Array(addresses)) = object.get_mut("replace_triggered_by") {
                        for address in addresses {
                            // The Graph IR serializer already represents addresses as strings.
                            debug_assert!(address.is_string());
                        }
                    }
                }
                body.insert("lifecycle".into(), value);
            }
            resource_types
                .entry(resource.resource_type.clone())
                .or_default()
                .insert(resource.name.clone(), Value::Object(body));
        }
        document.insert("resource".into(), nested_object(resource_types));
    }

    if !graph.data_sources.is_empty() {
        let mut data_types: BTreeMap<String, BTreeMap<String, Value>> = BTreeMap::new();
        for data_source in &graph.data_sources {
            let mut body = lower_arguments(&data_source.arguments)?;
            if !data_source.depends_on.is_empty() {
                body.insert(
                    "depends_on".into(),
                    Value::Array(
                        data_source
                            .depends_on
                            .iter()
                            .map(ToString::to_string)
                            .map(Value::String)
                            .collect(),
                    ),
                );
            }
            if let Some(provider) = &data_source.provider {
                body.insert("provider".into(), Value::String(provider.clone()));
            }
            data_types
                .entry(data_source.data_source_type.clone())
                .or_default()
                .insert(data_source.name.clone(), Value::Object(body));
        }
        document.insert("data".into(), nested_object(data_types));
    }

    if !graph.outputs.is_empty() {
        let mut outputs = Map::new();
        for (name, output) in &graph.outputs {
            let mut body = Map::new();
            body.insert("value".into(), lower_expr(&output.value)?);
            if output.sensitive {
                body.insert("sensitive".into(), Value::Bool(true));
            }
            if let Some(description) = &output.description {
                body.insert("description".into(), Value::String(description.clone()));
            }
            outputs.insert(name.clone(), Value::Object(body));
        }
        document.insert("output".into(), Value::Object(outputs));
    }

    if !graph.moves.is_empty() {
        document.insert(
            "moved".into(),
            Value::Array(
                graph
                    .moves
                    .iter()
                    .map(|movement| {
                        json!({
                            "from": movement.from.to_string(),
                            "to": movement.to.to_string(),
                        })
                    })
                    .collect(),
            ),
        );
    }

    let mut value = Value::Object(document);
    sort_json(&mut value);
    Ok(value)
}

pub fn to_pretty_json(graph: &GraphDocument) -> Result<String, LowerError> {
    let mut output = serde_json::to_string_pretty(&lower(graph)?).expect("JSON value serializes");
    output.push('\n');
    Ok(output)
}

fn nested_object(input: BTreeMap<String, BTreeMap<String, Value>>) -> Value {
    Value::Object(
        input
            .into_iter()
            .map(|(kind, values)| (kind, Value::Object(values.into_iter().collect())))
            .collect(),
    )
}

fn lower_arguments(arguments: &BTreeMap<String, Expr>) -> Result<Map<String, Value>, LowerError> {
    arguments
        .iter()
        .map(|(name, expression)| Ok((name.clone(), lower_expr(expression)?)))
        .collect()
}

pub fn lower_expr(expression: &Expr) -> Result<Value, LowerError> {
    match expression {
        Expr::Literal {
            value: Value::String(value),
        } => Ok(Value::String(escape_template(value))),
        Expr::Literal { value } => Ok(value.clone()),
        Expr::Array { items } => Ok(Value::Array(
            items.iter().map(lower_expr).collect::<Result<_, _>>()?,
        )),
        Expr::Object { fields } => Ok(Value::Object(
            fields
                .iter()
                .map(|(key, value)| Ok((key.clone(), lower_expr(value)?)))
                .collect::<Result<_, LowerError>>()?,
        )),
        Expr::Template { parts } => {
            let mut template = String::new();
            for part in parts {
                match part {
                    TemplatePart::Literal { value } => template.push_str(&escape_template(value)),
                    TemplatePart::Interpolation { expression } => {
                        template.push_str("${");
                        template.push_str(&render_expression(expression)?);
                        template.push('}');
                    }
                }
            }
            Ok(Value::String(template))
        }
        _ => Ok(Value::String(format!(
            "${{{}}}",
            render_expression(expression)?
        ))),
    }
}

fn render_expression(expression: &Expr) -> Result<String, LowerError> {
    match expression {
        Expr::Literal { value } => Ok(render_literal(value)),
        Expr::ResourceAttr { address, path } | Expr::DataSourceAttr { address, path } => {
            let mut output = address.to_string();
            for step in path {
                output.push('.');
                output.push_str(step);
            }
            Ok(output)
        }
        Expr::Array { items } => Ok(format!("[{}]", render_list(items.iter())?.join(", "))),
        Expr::Object { fields } => {
            let values = fields
                .iter()
                .map(|(key, value)| Ok(format!("{} = {}", quote(key), render_expression(value)?)))
                .collect::<Result<Vec<_>, LowerError>>()?;
            Ok(format!("{{ {} }}", values.join(", ")))
        }
        Expr::Index { collection, key } => Ok(format!(
            "{}[{}]",
            render_expression(collection)?,
            render_expression(key)?
        )),
        Expr::Conditional {
            condition,
            when_true,
            when_false,
        } => Ok(format!(
            "{} ? {} : {}",
            render_expression(condition)?,
            render_expression(when_true)?,
            render_expression(when_false)?
        )),
        Expr::Function { name, args } => {
            Ok(format!("{name}({})", render_list(args.iter())?.join(", ")))
        }
        Expr::Template { parts } => {
            let mut template = String::new();
            for part in parts {
                match part {
                    TemplatePart::Literal { value } => template.push_str(&escape_template(value)),
                    TemplatePart::Interpolation { expression } => {
                        template.push_str("${");
                        template.push_str(&render_expression(expression)?);
                        template.push('}');
                    }
                }
            }
            Ok(quote(&template))
        }
        Expr::SecretEnv { name } => Ok(format!("var.{}", secret_variable_name(name))),
        Expr::UnsafeRaw { expression } => {
            if expression.trim().is_empty() {
                Err(LowerError::EmptyRawExpression)
            } else {
                Ok(expression.clone())
            }
        }
    }
}

#[must_use]
pub fn secret_variable_name(environment_name: &str) -> String {
    format!("inframe_secret_{environment_name}")
}

fn render_list<'a>(items: impl Iterator<Item = &'a Expr>) -> Result<Vec<String>, LowerError> {
    items.map(render_expression).collect()
}

fn render_literal(value: &Value) -> String {
    match value {
        Value::String(value) => quote(&escape_template(value)),
        _ => serde_json::to_string(value).expect("JSON value serializes"),
    }
}

fn quote(value: &str) -> String {
    serde_json::to_string(value).expect("string serializes")
}

fn escape_template(value: &str) -> String {
    value.replace("${", "$${").replace("%{", "%%{")
}

fn sort_json(value: &mut Value) {
    match value {
        Value::Object(object) => {
            let old = std::mem::take(object);
            let mut entries: Vec<_> = old.into_iter().collect();
            entries.sort_by(|left, right| left.0.cmp(&right.0));
            for (key, mut value) in entries {
                sort_json(&mut value);
                object.insert(key, value);
            }
        }
        Value::Array(items) => {
            for item in items {
                sort_json(item);
            }
        }
        _ => {}
    }
}

#[derive(Debug, Clone)]
pub struct Workspace {
    root: PathBuf,
}

impl Workspace {
    pub fn new(base: impl AsRef<Path>, stack: &str) -> Result<Self, WorkspaceError> {
        if !valid_stack_name(stack) {
            return Err(WorkspaceError::InvalidStackName(stack.to_owned()));
        }
        Ok(Self {
            root: base.as_ref().join("stacks").join(stack),
        })
    }

    #[must_use]
    pub fn root(&self) -> &Path {
        &self.root
    }

    pub fn write_graph(&self, graph: &GraphDocument) -> Result<PathBuf, WorkspaceError> {
        let rendered = to_pretty_json(graph).map_err(WorkspaceError::Lower)?;
        self.write_atomic("main.tofu.json", &rendered)
    }

    pub fn write_backend(
        &self,
        kind: &str,
        config: &Map<String, Value>,
    ) -> Result<PathBuf, WorkspaceError> {
        if !valid_backend_kind(kind) {
            return Err(WorkspaceError::InvalidBackendKind(kind.to_owned()));
        }
        let value = json!({
            "terraform": {
                "backend": {
                    (kind): config,
                },
            },
        });
        let mut rendered = serde_json::to_string_pretty(&value).expect("backend JSON serializes");
        rendered.push('\n');
        self.write_atomic("backend.tofu.json", &rendered)
    }

    fn write_atomic(&self, name: &str, contents: &str) -> Result<PathBuf, WorkspaceError> {
        fs::create_dir_all(&self.root)?;
        let path = self.root.join(name);
        let temporary = tempfile::NamedTempFile::new_in(&self.root)?;
        fs::write(temporary.path(), contents)?;
        temporary.persist(&path).map_err(|error| error.error)?;
        Ok(path)
    }
}

fn valid_stack_name(value: &str) -> bool {
    !value.is_empty()
        && value != "."
        && value != ".."
        && value
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || matches!(character, '-' | '_'))
}

fn valid_backend_kind(value: &str) -> bool {
    let mut characters = value.chars();
    matches!(characters.next(), Some(first) if first == '_' || first.is_ascii_alphabetic())
        && characters.all(|character| character == '_' || character.is_ascii_alphanumeric())
}

#[derive(Debug, Error)]
pub enum WorkspaceError {
    #[error("invalid stack name `{0}`")]
    InvalidStackName(String),
    #[error("invalid OpenTofu backend kind `{0}`")]
    InvalidBackendKind(String),
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error(transparent)]
    Lower(LowerError),
}

#[derive(Debug, Clone)]
pub struct OpenTofu {
    binary: PathBuf,
}

impl Default for OpenTofu {
    fn default() -> Self {
        Self::new("tofu")
    }
}

impl OpenTofu {
    pub fn new(binary: impl Into<PathBuf>) -> Self {
        Self {
            binary: binary.into(),
        }
    }

    pub fn run(
        &self,
        workspace: &Workspace,
        command: &str,
        args: &[OsString],
    ) -> Result<ExitStatus, ProcessError> {
        self.run_with_env(workspace, command, args, &BTreeMap::new())
    }

    pub fn run_with_env(
        &self,
        workspace: &Workspace,
        command: &str,
        args: &[OsString],
        environment: &BTreeMap<OsString, OsString>,
    ) -> Result<ExitStatus, ProcessError> {
        let mut process = Command::new(&self.binary);
        process
            .arg(command)
            .args(args)
            .current_dir(workspace.root())
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit());
        process.envs(environment);
        let status = process.status().map_err(|source| ProcessError::Spawn {
            binary: self.binary.clone(),
            source,
        })?;
        if status.success() {
            Ok(status)
        } else {
            Err(ProcessError::Exit {
                command: command.to_owned(),
                status,
            })
        }
    }

    pub fn output_json(
        &self,
        workspace: &Workspace,
        command: &str,
        args: &[OsString],
    ) -> Result<Value, ProcessError> {
        let output = Command::new(&self.binary)
            .arg(command)
            .arg("-json")
            .args(args)
            .current_dir(workspace.root())
            .output()
            .map_err(|source| ProcessError::Spawn {
                binary: self.binary.clone(),
                source,
            })?;
        if !output.status.success() {
            return Err(ProcessError::Exit {
                command: command.to_owned(),
                status: output.status,
            });
        }
        serde_json::from_slice(&output.stdout).map_err(ProcessError::Json)
    }
}

#[derive(Debug, Error)]
pub enum ProcessError {
    #[error("failed to start OpenTofu binary at {binary}")]
    Spawn {
        binary: PathBuf,
        #[source]
        source: std::io::Error,
    },
    #[error("`tofu {command}` exited with {status}")]
    Exit { command: String, status: ExitStatus },
    #[error("OpenTofu returned invalid JSON")]
    Json(#[source] serde_json::Error),
}

#[cfg(test)]
mod tests {
    use std::collections::BTreeMap;

    use inframe_graph_ir::{
        Address, DataSourceSpec, OutputSpec, ProviderRequirement, ResourceSpec,
    };
    use tempfile::tempdir;

    use super::*;

    fn graph() -> GraphDocument {
        let tag_address = Address::parse("digitalocean_tag.app").unwrap();
        GraphDocument {
            required_providers: BTreeMap::from([(
                "digitalocean".into(),
                ProviderRequirement {
                    source: "digitalocean/digitalocean".into(),
                    version: "= 2.100.0".into(),
                },
            )]),
            resources: vec![ResourceSpec {
                resource_type: "digitalocean_tag".into(),
                name: "app".into(),
                arguments: BTreeMap::from([("name".into(), Expr::literal("app"))]),
                depends_on: Vec::new(),
                provider: None,
                lifecycle: None,
            }],
            data_sources: vec![DataSourceSpec {
                data_source_type: "digitalocean_tag".into(),
                name: "read".into(),
                arguments: BTreeMap::from([(
                    "name".into(),
                    Expr::ResourceAttr {
                        address: tag_address,
                        path: vec!["name".into()],
                    },
                )]),
                depends_on: Vec::new(),
                provider: None,
            }],
            outputs: BTreeMap::from([(
                "tag_name".into(),
                OutputSpec {
                    value: Expr::DataSourceAttr {
                        address: Address::parse("data.digitalocean_tag.read").unwrap(),
                        path: vec!["name".into()],
                    },
                    sensitive: false,
                    description: None,
                },
            )]),
            ..GraphDocument::default()
        }
    }

    #[test]
    fn lowers_resource_reference() {
        let value = lower(&graph()).unwrap();
        assert_eq!(
            value["data"]["digitalocean_tag"]["read"]["name"],
            "${digitalocean_tag.app.name}"
        );
        assert_eq!(
            value["output"]["tag_name"]["value"],
            "${data.digitalocean_tag.read.name}"
        );
    }

    #[test]
    fn writes_an_atomic_workspace_file() {
        let directory = tempdir().unwrap();
        let workspace = Workspace::new(directory.path(), "dev").unwrap();
        let path = workspace.write_graph(&graph()).unwrap();
        assert!(path.ends_with("stacks/dev/main.tofu.json"));
        assert!(fs::read_to_string(path).unwrap().ends_with('\n'));
    }

    #[test]
    fn rejects_unsafe_stack_names() {
        assert!(matches!(
            Workspace::new("build", "../prod"),
            Err(WorkspaceError::InvalidStackName(_))
        ));
    }

    #[test]
    fn escapes_template_markers_in_literal_strings() {
        assert_eq!(
            lower_expr(&Expr::literal("literal ${not_a_reference} %{also_literal}")).unwrap(),
            "literal $${not_a_reference} %%{also_literal}"
        );
    }

    #[test]
    fn lowers_secrets_to_sensitive_variables_without_the_value() {
        let mut graph = graph();
        graph.resources[0].arguments.insert(
            "token".into(),
            Expr::SecretEnv {
                name: "DIGITALOCEAN_TOKEN".into(),
            },
        );
        let value = lower(&graph).unwrap();
        assert_eq!(
            value["resource"]["digitalocean_tag"]["app"]["token"],
            "${var.inframe_secret_DIGITALOCEAN_TOKEN}"
        );
        assert_eq!(
            value["variable"]["inframe_secret_DIGITALOCEAN_TOKEN"]["sensitive"],
            true
        );
        assert!(!value.to_string().contains("actual-secret-value"));
    }

    #[test]
    fn writes_backend_configuration_separately() {
        let directory = tempdir().unwrap();
        let workspace = Workspace::new(directory.path(), "dev").unwrap();
        let path = workspace
            .write_backend(
                "http",
                &Map::from_iter([(
                    "address".to_owned(),
                    Value::String("https://state.example.test/dev".to_owned()),
                )]),
            )
            .unwrap();
        let value: Value = serde_json::from_slice(&fs::read(path).unwrap()).unwrap();
        assert_eq!(
            value["terraform"]["backend"]["http"]["address"],
            "https://state.example.test/dev"
        );
    }
}
