use std::collections::{BTreeMap, BTreeSet};
use std::fmt::Write as _;

use inframe_graph_ir::{
    Address, DataSourceSpec, Dependency, Expr, GraphDocument, Lifecycle, OutputSpec,
    ProviderConfig, ResourceSpec, TemplatePart, ValidationError,
};
use serde_json::Value;

#[derive(Debug)]
struct TreeNode {
    label: String,
    children: Vec<Self>,
}

impl TreeNode {
    fn leaf(label: impl Into<String>) -> Self {
        Self {
            label: label.into(),
            children: Vec::new(),
        }
    }

    fn branch(label: impl Into<String>, children: Vec<Self>) -> Self {
        Self {
            label: label.into(),
            children,
        }
    }
}

pub fn render(graph: &GraphDocument) -> Result<String, ValidationError> {
    let dependencies = graph.dependencies()?;
    let mut output = format!("Graph IR {}\n\n", graph.format_version);

    render_section(&mut output, "Providers", &provider_nodes(graph));
    render_section(&mut output, "Resources", &resource_nodes(graph));
    render_section(&mut output, "Data sources", &data_source_nodes(graph));
    render_section(&mut output, "Outputs", &output_nodes(graph));
    render_section(&mut output, "Moves", &move_nodes(graph));
    render_section(
        &mut output,
        "Dependencies",
        &dependency_nodes(&dependencies),
    );

    let _ = writeln!(
        output,
        "Summary: {} {}, {} {}, {} data {}, {} {}, {} {}",
        graph.required_providers.len(),
        plural(graph.required_providers.len(), "provider", "providers"),
        graph.resources.len(),
        plural(graph.resources.len(), "resource", "resources"),
        graph.data_sources.len(),
        plural(graph.data_sources.len(), "source", "sources"),
        graph.outputs.len(),
        plural(graph.outputs.len(), "output", "outputs"),
        dependencies.len(),
        plural(dependencies.len(), "dependency", "dependencies"),
    );
    Ok(output)
}

fn provider_nodes(graph: &GraphDocument) -> Vec<TreeNode> {
    let mut nodes = Vec::new();
    for (local_name, requirement) in &graph.required_providers {
        let mut configurations: Vec<_> = graph
            .provider_configs
            .iter()
            .filter(|configuration| configuration.provider == *local_name)
            .collect();
        configurations.sort_by_key(|configuration| provider_address(configuration));
        let children = if configurations.is_empty() {
            vec![TreeNode::leaf("default configuration: implicit")]
        } else {
            configurations
                .into_iter()
                .map(provider_configuration_node)
                .collect()
        };
        nodes.push(TreeNode::branch(
            format!(
                "{local_name}: {} {}",
                requirement.source, requirement.version
            ),
            children,
        ));
    }

    let declared: BTreeSet<_> = graph.required_providers.keys().collect();
    let mut undeclared: Vec<_> = graph
        .provider_configs
        .iter()
        .filter(|configuration| !declared.contains(&configuration.provider))
        .collect();
    undeclared.sort_by_key(|configuration| provider_address(configuration));
    nodes.extend(undeclared.into_iter().map(|configuration| {
        TreeNode::branch(
            format!("{}: no explicit requirement", configuration.provider),
            vec![provider_configuration_node(configuration)],
        )
    }));
    nodes
}

fn provider_configuration_node(configuration: &ProviderConfig) -> TreeNode {
    let name = configuration.alias.as_ref().map_or_else(
        || "default configuration".to_owned(),
        |alias| format!("configuration alias: {alias}"),
    );
    TreeNode::branch(name, argument_nodes(&configuration.arguments))
}

fn provider_address(configuration: &ProviderConfig) -> String {
    configuration.alias.as_ref().map_or_else(
        || configuration.provider.clone(),
        |alias| format!("{}.{alias}", configuration.provider),
    )
}

fn resource_nodes(graph: &GraphDocument) -> Vec<TreeNode> {
    let mut resources: Vec<_> = graph.resources.iter().collect();
    resources.sort_by_key(|resource| resource.address().to_string());
    resources.into_iter().map(resource_node).collect()
}

fn resource_node(resource: &ResourceSpec) -> TreeNode {
    let mut children = argument_nodes(&resource.arguments);
    if let Some(provider) = &resource.provider {
        children.push(TreeNode::leaf(format!("provider: {provider}")));
    }
    if !resource.depends_on.is_empty() {
        children.push(TreeNode::leaf(format!(
            "depends_on: {}",
            format_addresses(&resource.depends_on)
        )));
    }
    if let Some(lifecycle) = &resource.lifecycle {
        children.push(lifecycle_node(lifecycle));
    }
    TreeNode::branch(resource.address().to_string(), children)
}

fn data_source_nodes(graph: &GraphDocument) -> Vec<TreeNode> {
    let mut data_sources: Vec<_> = graph.data_sources.iter().collect();
    data_sources.sort_by_key(|data_source| data_source.address().to_string());
    data_sources.into_iter().map(data_source_node).collect()
}

fn data_source_node(data_source: &DataSourceSpec) -> TreeNode {
    let mut children = argument_nodes(&data_source.arguments);
    if let Some(provider) = &data_source.provider {
        children.push(TreeNode::leaf(format!("provider: {provider}")));
    }
    if !data_source.depends_on.is_empty() {
        children.push(TreeNode::leaf(format!(
            "depends_on: {}",
            format_addresses(&data_source.depends_on)
        )));
    }
    TreeNode::branch(data_source.address().to_string(), children)
}

fn lifecycle_node(lifecycle: &Lifecycle) -> TreeNode {
    let mut children = Vec::new();
    if lifecycle.create_before_destroy {
        children.push(TreeNode::leaf("create_before_destroy: true"));
    }
    if lifecycle.prevent_destroy {
        children.push(TreeNode::leaf("prevent_destroy: true"));
    }
    if !lifecycle.ignore_changes.is_empty() {
        let value = Value::Array(
            lifecycle
                .ignore_changes
                .iter()
                .cloned()
                .map(Value::String)
                .collect(),
        );
        children.push(TreeNode::leaf(format!(
            "ignore_changes: {}",
            format_json(&value)
        )));
    }
    if !lifecycle.replace_triggered_by.is_empty() {
        children.push(TreeNode::leaf(format!(
            "replace_triggered_by: {}",
            format_addresses(&lifecycle.replace_triggered_by)
        )));
    }
    TreeNode::branch("lifecycle", children)
}

fn output_nodes(graph: &GraphDocument) -> Vec<TreeNode> {
    graph
        .outputs
        .iter()
        .map(|(name, output)| output_node(name, output))
        .collect()
}

fn output_node(name: &str, output: &OutputSpec) -> TreeNode {
    let sensitivity = if output.sensitive { " (sensitive)" } else { "" };
    let mut children = Vec::new();
    if let Some(description) = &output.description {
        children.push(TreeNode::leaf(format!(
            "description: {}",
            format_json(&Value::String(description.clone()))
        )));
    }
    let label = format!("{name}: {}{sensitivity}", format_expr(&output.value));
    if children.is_empty() {
        TreeNode::leaf(label)
    } else {
        TreeNode::branch(label, children)
    }
}

fn move_nodes(graph: &GraphDocument) -> Vec<TreeNode> {
    let mut moves: Vec<_> = graph.moves.iter().collect();
    moves.sort_by_key(|movement| (movement.from.to_string(), movement.to.to_string()));
    moves
        .into_iter()
        .map(|movement| TreeNode::leaf(format!("{} -> {}", movement.from, movement.to)))
        .collect()
}

fn dependency_nodes(dependencies: &BTreeSet<Dependency>) -> Vec<TreeNode> {
    dependencies
        .iter()
        .map(|dependency| {
            let kind = if dependency.explicit {
                "explicit"
            } else {
                "inferred"
            };
            TreeNode::leaf(format!("{} -> {} ({kind})", dependency.from, dependency.to))
        })
        .collect()
}

fn argument_nodes(arguments: &BTreeMap<String, Expr>) -> Vec<TreeNode> {
    let width = arguments.keys().map(String::len).max().unwrap_or(0);
    arguments
        .iter()
        .map(|(name, expression)| named_expression_node(name, expression, width))
        .collect()
}

fn named_expression_node(name: &str, expression: &Expr, width: usize) -> TreeNode {
    if let Some(children) = expression_children(expression) {
        TreeNode::branch(format!("{name}:"), children)
    } else {
        let padding = " ".repeat(width - name.len());
        TreeNode::leaf(format!("{name}:{padding} {}", format_expr(expression)))
    }
}

fn expression_children(expression: &Expr) -> Option<Vec<TreeNode>> {
    match expression {
        Expr::Array { items }
            if !items.is_empty()
                && items.iter().any(|item| expression_children(item).is_some()) =>
        {
            Some(
                items
                    .iter()
                    .enumerate()
                    .map(|(index, item)| expression_item_node(index, item))
                    .collect(),
            )
        }
        Expr::Object { fields } if !fields.is_empty() => Some(argument_nodes(fields)),
        Expr::Literal {
            value: Value::Array(items),
        } if !items.is_empty() && items.iter().any(is_structured_json) => Some(
            items
                .iter()
                .enumerate()
                .map(|(index, item)| json_item_node(index, item))
                .collect(),
        ),
        Expr::Literal {
            value: Value::Object(fields),
        } if !fields.is_empty() => Some(json_argument_nodes(fields)),
        _ => None,
    }
}

fn expression_item_node(index: usize, expression: &Expr) -> TreeNode {
    expression_children(expression).map_or_else(
        || TreeNode::leaf(format!("[{index}]: {}", format_expr(expression))),
        |children| TreeNode::branch(format!("[{index}]"), children),
    )
}

fn json_argument_nodes(fields: &serde_json::Map<String, Value>) -> Vec<TreeNode> {
    let mut fields: Vec<_> = fields.iter().collect();
    fields.sort_by_key(|(name, _)| *name);
    let width = fields.iter().map(|(name, _)| name.len()).max().unwrap_or(0);
    fields
        .into_iter()
        .map(|(name, value)| {
            if is_structured_json(value) {
                TreeNode::branch(format!("{name}:"), json_children(value))
            } else {
                let padding = " ".repeat(width - name.len());
                TreeNode::leaf(format!("{name}:{padding} {}", format_json(value)))
            }
        })
        .collect()
}

fn json_item_node(index: usize, value: &Value) -> TreeNode {
    if is_structured_json(value) {
        TreeNode::branch(format!("[{index}]"), json_children(value))
    } else {
        TreeNode::leaf(format!("[{index}]: {}", format_json(value)))
    }
}

fn json_children(value: &Value) -> Vec<TreeNode> {
    match value {
        Value::Array(items) => items
            .iter()
            .enumerate()
            .map(|(index, item)| json_item_node(index, item))
            .collect(),
        Value::Object(fields) => json_argument_nodes(fields),
        _ => Vec::new(),
    }
}

fn is_structured_json(value: &Value) -> bool {
    matches!(value, Value::Array(items) if !items.is_empty())
        || matches!(value, Value::Object(fields) if !fields.is_empty())
}

fn format_expr(expression: &Expr) -> String {
    match expression {
        Expr::Literal { value } => format_json(value),
        Expr::ResourceAttr { address, path } | Expr::DataSourceAttr { address, path } => {
            format_reference(address, path)
        }
        Expr::Array { items } => format!(
            "[{}]",
            items.iter().map(format_expr).collect::<Vec<_>>().join(", ")
        ),
        Expr::Object { fields } => format!(
            "{{{}}}",
            fields
                .iter()
                .map(|(name, value)| format!("{name}: {}", format_expr(value)))
                .collect::<Vec<_>>()
                .join(", ")
        ),
        Expr::Index { collection, key } => {
            format!("{}[{}]", format_expr(collection), format_expr(key))
        }
        Expr::Conditional {
            condition,
            when_true,
            when_false,
        } => format!(
            "if {} then {} else {}",
            format_expr(condition),
            format_expr(when_true),
            format_expr(when_false)
        ),
        Expr::Function { name, args } => format!(
            "{name}({})",
            args.iter().map(format_expr).collect::<Vec<_>>().join(", ")
        ),
        Expr::Template { parts } => format!(
            "template({})",
            parts
                .iter()
                .map(|part| match part {
                    TemplatePart::Literal { value } => format_json(&Value::String(value.clone())),
                    TemplatePart::Interpolation { expression } => {
                        format!("${{{}}}", format_expr(expression))
                    }
                })
                .collect::<Vec<_>>()
                .join(", ")
        ),
        Expr::SecretEnv { name } => {
            format!("secretEnv({})", format_json(&Value::String(name.clone())))
        }
        Expr::UnsafeRaw { expression } => format!(
            "unsafeRaw({})",
            format_json(&Value::String(expression.clone()))
        ),
    }
}

fn format_reference(address: &Address, path: &[String]) -> String {
    if path.is_empty() {
        address.to_string()
    } else {
        format!("{address}.{}", path.join("."))
    }
}

fn format_json(value: &Value) -> String {
    match value {
        Value::Null => "null".to_owned(),
        Value::Bool(value) => value.to_string(),
        Value::Number(value) => value.to_string(),
        Value::String(value) => serde_json::to_string(value).expect("strings always serialize"),
        Value::Array(items) => format!(
            "[{}]",
            items.iter().map(format_json).collect::<Vec<_>>().join(", ")
        ),
        Value::Object(fields) => {
            let mut fields: Vec<_> = fields.iter().collect();
            fields.sort_by_key(|(name, _)| *name);
            format!(
                "{{{}}}",
                fields
                    .into_iter()
                    .map(|(name, value)| format!(
                        "{}: {}",
                        serde_json::to_string(name).expect("object keys always serialize"),
                        format_json(value)
                    ))
                    .collect::<Vec<_>>()
                    .join(", ")
            )
        }
    }
}

fn format_addresses(addresses: &[Address]) -> String {
    format!(
        "[{}]",
        addresses
            .iter()
            .map(ToString::to_string)
            .collect::<Vec<_>>()
            .join(", ")
    )
}

fn render_section(output: &mut String, title: &str, nodes: &[TreeNode]) {
    if nodes.is_empty() {
        return;
    }
    let _ = writeln!(output, "{title}");
    render_nodes(output, nodes, "");
    output.push('\n');
}

fn render_nodes(output: &mut String, nodes: &[TreeNode], prefix: &str) {
    for (index, node) in nodes.iter().enumerate() {
        let last = index + 1 == nodes.len();
        let branch = if last { "└── " } else { "├── " };
        let _ = writeln!(output, "{prefix}{branch}{}", node.label);
        if !node.children.is_empty() {
            let child_prefix = format!("{prefix}{}", if last { "    " } else { "│   " });
            render_nodes(output, &node.children, &child_prefix);
        }
    }
}

fn plural<'a>(count: usize, singular: &'a str, plural: &'a str) -> &'a str {
    if count == 1 { singular } else { plural }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn expressions_stay_symbolic_and_secrets_stay_redacted() {
        let expression = Expr::Object {
            fields: [
                (
                    "endpoint".to_owned(),
                    Expr::ResourceAttr {
                        address: Address::parse("digitalocean_droplet.web").unwrap(),
                        path: vec!["ipv4_address".to_owned()],
                    },
                ),
                (
                    "token".to_owned(),
                    Expr::SecretEnv {
                        name: "DIGITALOCEAN_TOKEN".to_owned(),
                    },
                ),
            ]
            .into_iter()
            .collect(),
        };

        assert_eq!(
            format_expr(&expression),
            "{endpoint: digitalocean_droplet.web.ipv4_address, token: secretEnv(\"DIGITALOCEAN_TOKEN\")}"
        );
    }
}
