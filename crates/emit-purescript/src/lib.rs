//! Deterministic PureScript provider-binding emitter.

use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::fs;
use std::path::{Path, PathBuf};

use serde::Serialize;
use thiserror::Error;
use tofu_dag_binding_model::{BindingField, BindingItem, BindingPackage, BindingType};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GeneratedPackage {
    pub files: BTreeMap<PathBuf, String>,
}

impl GeneratedPackage {
    pub fn write_to(&self, output: &Path) -> Result<(), EmitError> {
        for (relative_path, contents) in &self.files {
            let path = output.join(relative_path);
            if let Some(parent) = path.parent() {
                fs::create_dir_all(parent)?;
            }
            fs::write(path, contents)?;
        }
        Ok(())
    }
}

#[derive(Debug, Serialize)]
struct Manifest<'a> {
    provider_source: &'a str,
    provider_version: &'a str,
    schema_sha256: &'a str,
    generator_version: &'a str,
    binding_model_version: &'static str,
    graph_ir_version: &'static str,
}

#[derive(Debug, Error)]
pub enum EmitError {
    #[error("invalid PureScript module root `{0}`")]
    InvalidModuleRoot(String),
    #[error("failed to write generated package")]
    Io(#[from] std::io::Error),
    #[error("failed to render provider manifest")]
    Json(#[from] serde_json::Error),
}

pub fn render_package(
    package: &BindingPackage,
    module_root: &str,
    schema_sha256: &str,
) -> Result<GeneratedPackage, EmitError> {
    if !valid_module_root(module_root) {
        return Err(EmitError::InvalidModuleRoot(module_root.to_owned()));
    }
    let mut files = BTreeMap::new();
    files.insert(
        module_path(&format!("{module_root}.Provider")),
        render_provider(package, module_root),
    );
    for resource in &package.resources {
        let module = format!("{module_root}.Resource.{}", resource.public_name);
        files.insert(module_path(&module), render_item(resource, &module, false));
    }
    for data_source in &package.data_sources {
        let module = format!("{module_root}.Data.{}", data_source.public_name);
        files.insert(
            module_path(&module),
            render_item(data_source, &module, true),
        );
    }
    let manifest = Manifest {
        provider_source: &package.provider.source,
        provider_version: &package.provider.version,
        schema_sha256,
        generator_version: env!("CARGO_PKG_VERSION"),
        binding_model_version: "1.0",
        graph_ir_version: "1.0",
    };
    let mut manifest = serde_json::to_string_pretty(&manifest)?;
    manifest.push('\n');
    files.insert(PathBuf::from("provider-manifest.json"), manifest);
    files.insert(
        PathBuf::from("README.md"),
        format!(
            "# {module_root}\n\nGenerated PureScript bindings for `{}` `{}`. Do not edit by hand.\n",
            package.provider.source, package.provider.version
        ),
    );
    files.insert(
        PathBuf::from("spago.yaml"),
        format!(
            "package:\n  name: generated-{}\n  dependencies:\n    - argonaut-core\n    - foreign-object\n    - prelude\n    - tofu-dag-graph-core\n    - tuples\n",
            package.provider.public_name.to_ascii_lowercase()
        ),
    );
    Ok(GeneratedPackage { files })
}

fn valid_module_root(value: &str) -> bool {
    !value.is_empty()
        && value.split('.').all(|segment| {
            segment
                .chars()
                .next()
                .is_some_and(|first| first.is_ascii_uppercase())
                && segment
                    .chars()
                    .all(|character| character.is_ascii_alphanumeric())
        })
}

fn module_path(module: &str) -> PathBuf {
    PathBuf::from("src").join(module.replace('.', "/") + ".purs")
}

fn render_provider(package: &BindingPackage, module_root: &str) -> String {
    let fields = &package.provider.fields;
    let builders = collect_nested_builders(fields);
    let setters: Vec<_> = fields.iter().filter(|field| field.optional).collect();
    let mut exports = vec![
        "Args".to_owned(),
        "Required".to_owned(),
        "args".to_owned(),
        "configure".to_owned(),
        "configureAs".to_owned(),
    ];
    extend_nested_exports(&mut exports, &builders);
    exports.extend(setters.iter().map(|field| safe_field_name(field)));
    let mut output = module_header(&format!("{module_root}.Provider"), &exports);
    output.push_str("import Prelude (Unit");
    if uses_nested_mapping(fields) {
        output.push_str(", map");
    }
    output.push_str(")\n\n");
    if requires_json_import(fields) {
        output.push_str("import Data.Argonaut.Core (Json)\n");
    }
    output.push_str("import Data.Maybe (Maybe(..))\n");
    if has_required_fields(fields, &builders) {
        output.push_str("import Data.Tuple (Tuple(..))\n");
    }
    if uses_map_expressions(fields) {
        output.push_str("import Foreign.Object as Object\n");
    }
    output.push_str(&render_builder_import("addProvider", fields));
    output.push_str(&render_core_import(None, fields));
    output.push('\n');
    output.push_str(&render_nested_builders(&builders));
    output.push_str(&render_args(fields));
    for field in setters {
        output.push_str(&render_setter(field, &[]));
    }
    output.push_str("configure :: Args -> Infra Unit\n");
    let _ = write!(
        output,
        "configure (Args values) = addProvider \"{}\" Nothing values\n\n",
        package
            .provider
            .source
            .rsplit('/')
            .next()
            .unwrap_or(&package.provider.source)
    );
    output.push_str("configureAs :: String -> Args -> Infra Unit\n");
    let _ = writeln!(
        output,
        "configureAs alias (Args values) = addProvider \"{}\" (Just alias) values",
        package
            .provider
            .source
            .rsplit('/')
            .next()
            .unwrap_or(&package.provider.source)
    );
    output
}

#[allow(clippy::too_many_lines)]
fn render_item(item: &BindingItem, module: &str, data_source: bool) -> String {
    let builders = collect_nested_builders(&item.fields);
    let setters: Vec<_> = item.fields.iter().filter(|field| field.optional).collect();
    let operation = if data_source { "read" } else { "create" };
    let handle_name = safe_type_name(&item.public_name);
    let node = format!(
        "{}{}",
        item.public_name,
        if data_source {
            "DataSource"
        } else {
            "Resource"
        }
    );
    let mut exports = vec![
        "Args".to_owned(),
        "Required".to_owned(),
        handle_name.clone(),
        node.clone(),
        "args".to_owned(),
        operation.to_owned(),
    ];
    extend_nested_exports(&mut exports, &builders);
    exports.extend(setters.iter().map(|field| safe_field_name(field)));
    let mut output = module_header(module, &exports);
    output.push_str("import Prelude (bind");
    if uses_nested_mapping(&item.fields) {
        output.push_str(", map");
    }
    output.push_str(", pure)\n\n");
    if requires_json_import(&item.fields) {
        output.push_str("import Data.Argonaut.Core (Json)\n");
    }
    if has_required_fields(&item.fields, &builders) {
        output.push_str("import Data.Tuple (Tuple(..))\n");
    }
    if uses_map_expressions(&item.fields) {
        output.push_str("import Foreign.Object as Object\n");
    }
    output.push_str(&render_builder_import(
        if data_source {
            "addDataSource"
        } else {
            "addResource"
        },
        &item.fields,
    ));
    output.push_str(&render_core_import(Some(data_source), &item.fields));
    output.push('\n');
    let _ = write!(output, "data {node}\n\n");
    output.push_str(&render_nested_builders(&builders));
    output.push_str(&render_args(&item.fields));
    for field in setters {
        output.push_str(&render_setter(field, &[]));
    }
    let handle_fields: Vec<_> = item.outputs().collect();
    let _ = write!(output, "type {handle_name} =\n  {{ ");
    output.push_str(if data_source {
        "dataSource :: DataSource "
    } else {
        "resource :: Resource "
    });
    output.push_str(&node);
    for field in &handle_fields {
        let _ = write!(
            output,
            "\n  , {} :: Expr {}",
            safe_field_name(field),
            render_type_argument(&field.r#type)
        );
    }
    output.push_str("\n  }\n\n");
    let _ = writeln!(
        output,
        "{operation} :: String -> Args -> Infra {handle_name}"
    );
    let add = if data_source {
        "addDataSource"
    } else {
        "addResource"
    };
    let handle_key = if data_source {
        "dataSource"
    } else {
        "resource"
    };
    let attr = if data_source {
        "dataSourceAttr"
    } else {
        "resourceAttr"
    };
    let _ = write!(
        output,
        "{operation} logicalName (Args values) = do\n  handle <- {add} \"{}\" logicalName values\n  pure\n    {{ {handle_key}: handle",
        item.provider_type
    );
    for field in &handle_fields {
        let _ = write!(
            output,
            "\n    , {}: {attr} handle [ \"{}\" ]",
            safe_field_name(field),
            field.provider_name
        );
    }
    output.push_str("\n    }\n");
    output
}

fn module_header(module: &str, exports: &[String]) -> String {
    let mut output = format!("module {module}\n  ( {}", exports[0]);
    for export in &exports[1..] {
        let _ = write!(output, "\n  , {export}");
    }
    output.push_str("\n  ) where\n\n");
    output
}

#[derive(Debug)]
struct NestedBuilder<'a> {
    path: Vec<String>,
    fields: &'a [BindingField],
}

#[derive(Debug, Clone, Copy)]
enum NestedContainer<'a> {
    Single(&'a [BindingField]),
    Array(&'a [BindingField]),
    Map(&'a [BindingField]),
}

impl<'a> NestedContainer<'a> {
    fn fields(self) -> &'a [BindingField] {
        match self {
            Self::Single(fields) | Self::Array(fields) | Self::Map(fields) => fields,
        }
    }
}

fn nested_container(r#type: &BindingType) -> Option<NestedContainer<'_>> {
    match r#type {
        BindingType::Object(fields) => Some(NestedContainer::Single(fields)),
        BindingType::List(item) | BindingType::Set(item) => match item.as_ref() {
            BindingType::Object(fields) => Some(NestedContainer::Array(fields)),
            _ => None,
        },
        BindingType::Map(item) => match item.as_ref() {
            BindingType::Object(fields) => Some(NestedContainer::Map(fields)),
            _ => None,
        },
        BindingType::String
        | BindingType::Bool
        | BindingType::Number
        | BindingType::Tuple(_)
        | BindingType::Dynamic => None,
    }
}

fn collect_nested_builders(fields: &[BindingField]) -> Vec<NestedBuilder<'_>> {
    fn visit<'a>(
        field: &'a BindingField,
        parent_path: &[String],
        builders: &mut Vec<NestedBuilder<'a>>,
    ) {
        if !field.required && !field.optional {
            return;
        }
        let Some(container) = nested_container(&field.r#type) else {
            return;
        };
        let mut path = parent_path.to_vec();
        path.push(field.public_name.clone());
        builders.push(NestedBuilder {
            path: path.clone(),
            fields: container.fields(),
        });
        for child in container.fields() {
            visit(child, &path, builders);
        }
    }

    let mut builders = Vec::new();
    for field in fields {
        visit(field, &[], &mut builders);
    }
    builders
}

fn extend_nested_exports(exports: &mut Vec<String>, builders: &[NestedBuilder<'_>]) {
    for builder in builders {
        let type_name = builder_type_name(&builder.path);
        exports.push(type_name.clone());
        exports.push(format!("{type_name}Required"));
        exports.push(format!("{}Args", builder_prefix(&builder.path)));
        exports.extend(
            builder
                .fields
                .iter()
                .filter(|field| field.optional)
                .map(|field| nested_setter_name(&builder.path, field)),
        );
    }
}

fn has_required_fields(fields: &[BindingField], builders: &[NestedBuilder<'_>]) -> bool {
    fields.iter().any(|field| field.required)
        || builders
            .iter()
            .any(|builder| builder.fields.iter().any(|field| field.required))
}

fn uses_nested_mapping(fields: &[BindingField]) -> bool {
    fields.iter().any(|field| {
        if !field.required && !field.optional {
            return false;
        }
        let Some(container) = nested_container(&field.r#type) else {
            return false;
        };
        matches!(
            container,
            NestedContainer::Array(_) | NestedContainer::Map(_)
        ) || uses_nested_mapping(container.fields())
    })
}

fn uses_array_expressions(fields: &[BindingField]) -> bool {
    fields.iter().any(|field| {
        if !field.required && !field.optional {
            return false;
        }
        let Some(container) = nested_container(&field.r#type) else {
            return false;
        };
        matches!(container, NestedContainer::Array(_)) || uses_array_expressions(container.fields())
    })
}

fn uses_map_expressions(fields: &[BindingField]) -> bool {
    fields.iter().any(|field| {
        if !field.required && !field.optional {
            return false;
        }
        let Some(container) = nested_container(&field.r#type) else {
            return false;
        };
        matches!(container, NestedContainer::Map(_)) || uses_map_expressions(container.fields())
    })
}

fn has_optional_nested_fields(fields: &[BindingField]) -> bool {
    collect_nested_builders(fields)
        .iter()
        .any(|builder| builder.fields.iter().any(|field| field.optional))
}

fn requires_json_import(fields: &[BindingField]) -> bool {
    fn type_uses_json(r#type: &BindingType) -> bool {
        match r#type {
            BindingType::Map(_) | BindingType::Tuple(_) | BindingType::Dynamic => true,
            BindingType::List(item) | BindingType::Set(item) => type_uses_json(item),
            BindingType::Object(fields) => fields.iter().any(|field| type_uses_json(&field.r#type)),
            BindingType::String | BindingType::Bool | BindingType::Number => false,
        }
    }

    !collect_nested_builders(fields).is_empty()
        || fields.iter().any(|field| type_uses_json(&field.r#type))
}

fn render_builder_import(operation: &str, fields: &[BindingField]) -> String {
    let mut imports = vec!["Infra", operation, "InputObject", "inputObject"];
    if fields.iter().any(|field| field.optional) || has_optional_nested_fields(fields) {
        imports.push("insertInputField");
    }
    if !collect_nested_builders(fields).is_empty() {
        imports.push("inputObjectJson");
    }
    format!("import TofuDag.Builder ({})\n", imports.join(", "))
}

fn render_core_import(item_kind: Option<bool>, fields: &[BindingField]) -> String {
    let mut imports = vec!["Input", "inputJson"];
    if item_kind.is_some() {
        imports.insert(0, "Expr");
    }
    if collect_nested_builders(fields).is_empty() {
        // No nested expression constructors are needed.
    } else {
        if uses_array_expressions(fields) {
            imports.push("arrayExprJson");
        }
        if uses_map_expressions(fields) {
            imports.push("objectExprJson");
        }
    }
    if let Some(data_source) = item_kind {
        imports.push(if data_source {
            "DataSource"
        } else {
            "Resource"
        });
        imports.push(if data_source {
            "dataSourceAttr"
        } else {
            "resourceAttr"
        });
    }
    format!("import TofuDag.Core ({})\n", imports.join(", "))
}

fn render_nested_builders(builders: &[NestedBuilder<'_>]) -> String {
    let mut output = String::new();
    for builder in builders {
        output.push_str(&render_nested_builder(builder));
    }
    output
}

fn render_nested_builder(builder: &NestedBuilder<'_>) -> String {
    let type_name = builder_type_name(&builder.path);
    let required_name = format!("{type_name}Required");
    let constructor_name = format!("{}Args", builder_prefix(&builder.path));
    let required: Vec<_> = builder
        .fields
        .iter()
        .filter(|field| field.required)
        .collect();
    let mut output = format!(
        "newtype {type_name} = {type_name} InputObject\n\n\
         type {required_name} =\n  {{"
    );
    render_required_fields(&mut output, &required, &builder.path);
    let _ = write!(
        output,
        "\n  }}\n\n{constructor_name} :: {required_name} -> {type_name}\n"
    );
    let argument = if required.is_empty() { "_" } else { "required" };
    let _ = write!(
        output,
        "{constructor_name} {argument} = {type_name} (inputObject\n  ["
    );
    render_required_values(&mut output, &required, &builder.path);
    output.push_str("\n  ])\n\n");
    for field in builder.fields.iter().filter(|field| field.optional) {
        output.push_str(&render_nested_setter(builder, field));
    }
    let json_name = format!("{}Json", builder_prefix(&builder.path));
    let _ = write!(
        output,
        "{json_name} :: {type_name} -> Json\n\
         {json_name} ({type_name} values) = inputObjectJson values\n\n"
    );
    output
}

fn render_args(fields: &[BindingField]) -> String {
    let required: Vec<_> = fields.iter().filter(|field| field.required).collect();
    let mut output = String::from("type Required =\n  {");
    render_required_fields(&mut output, &required, &[]);
    output.push_str("\n  }\n\nnewtype Args = Args InputObject\n\n");
    let required_argument = if required.is_empty() { "_" } else { "required" };
    let _ = write!(
        output,
        "args :: Required -> Args\nargs {required_argument} = Args (inputObject\n  ["
    );
    render_required_values(&mut output, &required, &[]);
    output.push_str("\n  ])\n\n");
    output
}

fn render_required_fields(output: &mut String, required: &[&BindingField], parent_path: &[String]) {
    for (index, field) in required.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n  , " };
        let path = child_path(parent_path, field);
        let _ = write!(
            output,
            "{separator}{} :: {}",
            safe_field_name(field),
            render_input_type(&field.r#type, &path)
        );
    }
}

fn render_required_values(output: &mut String, required: &[&BindingField], parent_path: &[String]) {
    for (index, field) in required.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n  , " };
        let field_name = safe_field_name(field);
        let value = format!("required.{field_name}");
        let path = child_path(parent_path, field);
        let encoded = render_input_json(&value, &field.r#type, &path);
        let _ = write!(
            output,
            "{separator}Tuple \"{}\" ({encoded})",
            field.provider_name
        );
    }
}

fn render_setter(field: &BindingField, parent_path: &[String]) -> String {
    let name = safe_field_name(field);
    let path = child_path(parent_path, field);
    let input_type = render_input_type(&field.r#type, &path);
    let encoded = render_input_json("value", &field.r#type, &path);
    format!(
        "{name} :: {input_type} -> Args -> Args\n\
         {name} value (Args values) = Args (insertInputField \"{}\" ({encoded}) values)\n\n",
        field.provider_name
    )
}

fn render_nested_setter(builder: &NestedBuilder<'_>, field: &BindingField) -> String {
    let name = nested_setter_name(&builder.path, field);
    let path = child_path(&builder.path, field);
    let input_type = render_input_type(&field.r#type, &path);
    let encoded = render_input_json("value", &field.r#type, &path);
    let type_name = builder_type_name(&builder.path);
    format!(
        "{name} :: {input_type} -> {type_name} -> {type_name}\n\
         {name} value ({type_name} values) = {type_name} (insertInputField \"{}\" ({encoded}) values)\n\n",
        field.provider_name
    )
}

fn render_input_type(r#type: &BindingType, path: &[String]) -> String {
    match nested_container(r#type) {
        Some(NestedContainer::Single(_)) => builder_type_name(path),
        Some(NestedContainer::Array(_)) => format!("Array {}", builder_type_name(path)),
        Some(NestedContainer::Map(_)) => {
            format!("Object.Object {}", builder_type_name(path))
        }
        None => format!("Input {}", render_type_argument(r#type)),
    }
}

fn render_input_json(value: &str, r#type: &BindingType, path: &[String]) -> String {
    let json_function = format!("{}Json", builder_prefix(path));
    match nested_container(r#type) {
        Some(NestedContainer::Single(_)) => format!("{json_function} {value}"),
        Some(NestedContainer::Array(_)) => {
            format!("arrayExprJson (map {json_function} {value})")
        }
        Some(NestedContainer::Map(_)) => {
            format!("objectExprJson (map {json_function} {value})")
        }
        None => format!("inputJson {value}"),
    }
}

fn child_path(parent_path: &[String], field: &BindingField) -> Vec<String> {
    let mut path = parent_path.to_vec();
    path.push(field.public_name.clone());
    path
}

fn nested_setter_name(path: &[String], field: &BindingField) -> String {
    format!(
        "{}{}",
        builder_prefix(path),
        upper_first(&field.public_name)
    )
}

fn builder_type_name(path: &[String]) -> String {
    safe_type_name(
        &path
            .iter()
            .map(|part| upper_first(part))
            .collect::<String>(),
    )
}

fn builder_prefix(path: &[String]) -> String {
    let Some((first, rest)) = path.split_first() else {
        return String::new();
    };
    let mut prefix = first.clone();
    for part in rest {
        prefix.push_str(&upper_first(part));
    }
    prefix
}

fn upper_first(value: &str) -> String {
    let mut characters = value.chars();
    characters
        .next()
        .map(|first| first.to_ascii_uppercase().to_string() + characters.as_str())
        .unwrap_or_default()
}

fn safe_field_name(field: &BindingField) -> String {
    if field.target_reserved {
        format!("{}_", field.public_name)
    } else {
        field.public_name.clone()
    }
}

fn safe_type_name(name: &str) -> String {
    if matches!(name, "Record" | "Row" | "Type") {
        format!("{name}Handle")
    } else {
        name.to_owned()
    }
}

fn render_type(r#type: &BindingType) -> String {
    match r#type {
        BindingType::String => "String".into(),
        BindingType::Bool => "Boolean".into(),
        BindingType::Number => "Number".into(),
        BindingType::List(item) | BindingType::Set(item) => {
            format!("Array {}", render_type_argument(item))
        }
        BindingType::Map(_) | BindingType::Tuple(_) | BindingType::Dynamic => "Json".into(),
        BindingType::Object(fields) => {
            let body = fields
                .iter()
                .map(|field| {
                    format!(
                        "{} :: {}",
                        safe_field_name(field),
                        render_type(&field.r#type)
                    )
                })
                .collect::<Vec<_>>()
                .join(", ");
            format!("{{ {body} }}")
        }
    }
}

fn render_type_argument(r#type: &BindingType) -> String {
    match r#type {
        BindingType::String
        | BindingType::Bool
        | BindingType::Number
        | BindingType::Map(_)
        | BindingType::Tuple(_)
        | BindingType::Dynamic => render_type(r#type),
        BindingType::List(_) | BindingType::Set(_) | BindingType::Object(_) => {
            format!("({})", render_type(r#type))
        }
    }
}

#[cfg(test)]
mod tests {
    use tofu_dag_binding_model::{BindingProvider, BindingType};

    use super::*;

    fn package() -> BindingPackage {
        let name = BindingField {
            provider_name: "name".into(),
            public_name: "name".into(),
            r#type: BindingType::String,
            required: true,
            optional: false,
            computed: false,
            sensitive: false,
            block: false,
            target_reserved: false,
            description: None,
        };
        let id = BindingField {
            provider_name: "id".into(),
            public_name: "id".into(),
            r#type: BindingType::String,
            required: false,
            optional: false,
            computed: true,
            sensitive: false,
            block: false,
            target_reserved: false,
            description: None,
        };
        let nested_field = |provider_name: &str,
                            public_name: &str,
                            r#type: BindingType,
                            required: bool,
                            optional: bool,
                            computed: bool| BindingField {
            provider_name: provider_name.into(),
            public_name: public_name.into(),
            r#type,
            required,
            optional,
            computed,
            sensitive: false,
            block: false,
            target_reserved: false,
            description: None,
        };
        let node_pool = nested_field(
            "node_pool",
            "nodePool",
            BindingType::List(Box::new(BindingType::Object(vec![
                nested_field("name", "name", BindingType::String, true, false, false),
                nested_field(
                    "auto_scale",
                    "autoScale",
                    BindingType::Bool,
                    false,
                    true,
                    false,
                ),
                nested_field(
                    "actual_node_count",
                    "actualNodeCount",
                    BindingType::Number,
                    false,
                    false,
                    true,
                ),
            ]))),
            true,
            false,
            false,
        );
        BindingPackage {
            provider: BindingProvider {
                source: "digitalocean/digitalocean".into(),
                version: "2.100.0".into(),
                public_name: "Digitalocean".into(),
                fields: Vec::new(),
            },
            resources: vec![BindingItem {
                provider_type: "digitalocean_tag".into(),
                public_name: "Tag".into(),
                fields: vec![id, name, node_pool],
            }],
            data_sources: Vec::new(),
        }
    }

    #[test]
    fn emits_a_typed_resource_constructor() {
        let generated = render_package(&package(), "DigitalOcean", "abc").unwrap();
        let source = &generated.files[Path::new("src/DigitalOcean/Resource/Tag.purs")];
        assert!(source.contains("create :: String -> Args -> Infra Tag"));
        assert!(source.contains("name :: Expr String"));
        assert!(source.contains("id: resourceAttr handle [ \"id\" ]"));
        assert!(source.contains("newtype NodePool = NodePool InputObject"));
        assert!(source.contains("type NodePoolRequired =\n  { name :: Input String"));
        assert!(source.contains("nodePoolAutoScale :: Input Boolean -> NodePool -> NodePool"));
        assert!(!source.contains("nodePoolActualNodeCount ::"));
        assert!(source.contains("nodePool :: Array NodePool"));
        assert!(
            source.contains(
                "Tuple \"node_pool\" (arrayExprJson (map nodePoolJson required.nodePool))"
            )
        );
    }

    #[test]
    fn output_is_deterministic() {
        let first = render_package(&package(), "DigitalOcean", "abc").unwrap();
        let second = render_package(&package(), "DigitalOcean", "abc").unwrap();
        assert_eq!(first, second);
    }
}
