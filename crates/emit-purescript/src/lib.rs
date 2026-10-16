//! Deterministic PureScript provider-binding emitter.
//!
//! Every nested input block gets its own builder named after its full path, so a provider
//! with deep unrolled schemas renders to very large modules (AWS: 312 MB in all). Modules are
//! therefore rendered straight into their output sink, and each builder's names are computed
//! once and extended for its children rather than rebuilt from the path at every use.

use std::fmt::{self, Write as _};
use std::path::{Path, PathBuf};

use inframe_binding_model::emit::{self, FileJob, Output};
use inframe_binding_model::{
    BindingField, BindingItem, BindingPackage, BindingType, path_count, push_capitalized,
};
use serde::Serialize;
use thiserror::Error;

pub use inframe_binding_model::emit::GeneratedPackage;

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

/// Renders the whole package in memory.
pub fn render_package(
    package: &BindingPackage,
    module_root: &str,
    schema_sha256: &str,
) -> Result<GeneratedPackage, EmitError> {
    let files = package_files(package, module_root, schema_sha256)?;
    Ok(GeneratedPackage::render(&files))
}

/// Renders the package straight into `output`, every module streamed to its file and the
/// modules spread over all cores. The files are those of [`render_package`], byte for byte.
pub fn write_package(
    package: &BindingPackage,
    module_root: &str,
    schema_sha256: &str,
    output: &Path,
) -> Result<(), EmitError> {
    let files = package_files(package, module_root, schema_sha256)?;
    emit::write_files(files, output)?;
    Ok(())
}

fn package_files<'a>(
    package: &'a BindingPackage,
    module_root: &'a str,
    schema_sha256: &str,
) -> Result<Vec<FileJob<'a>>, EmitError> {
    if !valid_module_root(module_root) {
        return Err(EmitError::InvalidModuleRoot(module_root.to_owned()));
    }
    let mut files = Vec::with_capacity(package.resources.len() + package.data_sources.len() + 4);
    files.push(FileJob::new(
        module_path(&format!("{module_root}.Provider")),
        path_count(&package.provider.fields),
        move |out| render_provider(out, package, module_root),
    ));
    for (items, kind, data_source) in [
        (&package.resources, "Resource", false),
        (&package.data_sources, "Data", true),
    ] {
        for item in items {
            let module = format!("{module_root}.{kind}.{}", item.public_name);
            files.push(FileJob::new(
                module_path(&module),
                path_count(&item.fields),
                move |out| {
                    render_item(
                        out,
                        item,
                        &module,
                        module_root,
                        &package.provider,
                        data_source,
                    );
                },
            ));
        }
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
    files.push(FileJob::text("provider-manifest.json", manifest));
    files.push(FileJob::text(
        "README.md",
        format!(
            "# {module_root}\n\nGenerated PureScript bindings for `{}` `{}`. Do not edit by hand.\n",
            package.provider.source, package.provider.version
        ),
    ));
    files.push(FileJob::text(
        "spago.yaml",
        format!(
            "package:\n  name: generated-{}\n  dependencies:\n    - argonaut-core\n    - foreign-object\n    - prelude\n    - inframe-graph-core\n    - tuples\n",
            package.provider.public_name.to_ascii_lowercase()
        ),
    ));
    Ok(files)
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

fn render_provider(out: &mut Output<'_>, package: &BindingPackage, module_root: &str) {
    let fields = &package.provider.fields;
    let builders = collect_nested_builders(fields);
    let marker = provider_marker(module_root);
    let mut exports = Exports::new(out, &format!("{module_root}.Provider"));
    for export in [
        marker.as_str(),
        "Args",
        "Required",
        "args",
        "configure",
        "configureAs",
    ] {
        exports.add(export);
    }
    extend_nested_exports(&mut exports, &builders);
    for field in fields.iter().filter(|field| field.optional) {
        exports.add(safe_field_name(field));
    }
    exports.finish();
    if uses_nested_mapping(fields) {
        out.push_str("import Prelude (map)\n\n");
    }
    if requires_json_import(fields) {
        out.push_str("import Data.Argonaut.Core (Json)\n");
    }
    out.push_str("import Data.Maybe (Maybe(..))\n");
    if has_required_fields(fields, &builders) {
        out.push_str("import Data.Tuple (Tuple(..))\n");
    }
    if uses_map_expressions(fields) {
        out.push_str("import Foreign.Object as Object\n");
    }
    render_builder_import(out, "addProvider", fields, &builders);
    render_core_import(out, None, fields, &builders);
    out.push('\n');
    let _ = write!(out, "data {marker}\n\n");
    render_nested_builders(out, &builders);
    render_args(out, fields);
    for field in fields.iter().filter(|field| field.optional) {
        render_setter(out, field);
    }
    let _ = writeln!(out, "configure :: Args -> Infra (Provider {marker})");
    let local_name = provider_local_name_from_source(&package.provider.source);
    let version = format!("= {}", package.provider.version);
    let _ = write!(
        out,
        "configure (Args values) = addProvider \"{local_name}\" \"{}\" \"{version}\" Nothing values\n\n",
        package.provider.source
    );
    let _ = writeln!(
        out,
        "configureAs :: String -> Args -> Infra (Provider {marker})"
    );
    let _ = writeln!(
        out,
        "configureAs alias (Args values) = addProvider \"{local_name}\" \"{}\" \"{version}\" (Just alias) values",
        package.provider.source
    );
}

#[allow(clippy::too_many_lines)]
fn render_item(
    out: &mut Output<'_>,
    item: &BindingItem,
    module: &str,
    module_root: &str,
    provider: &inframe_binding_model::BindingProvider,
    data_source: bool,
) {
    let fields = &item.fields;
    let builders = collect_nested_builders(fields);
    let operation = if data_source { "read" } else { "create" };
    let operation_with = if data_source {
        "readWith"
    } else {
        "createWith"
    };
    let handle_name = safe_type_name(item.public_name.clone());
    let node = format!(
        "{}{}",
        item.public_name,
        if data_source {
            "DataSource"
        } else {
            "Resource"
        }
    );
    let mut exports = Exports::new(out, module);
    for export in [
        "Args",
        "Required",
        handle_name.as_str(),
        node.as_str(),
        "args",
        operation,
        operation_with,
    ] {
        exports.add(export);
    }
    extend_nested_exports(&mut exports, &builders);
    for field in fields.iter().filter(|field| field.optional) {
        exports.add(safe_field_name(field));
    }
    exports.finish();
    out.push_str("import Prelude (bind");
    if uses_nested_mapping(fields) {
        out.push_str(", map");
    }
    out.push_str(", pure)\n\n");
    if requires_json_import(fields) {
        out.push_str("import Data.Argonaut.Core (Json)\n");
    }
    if has_required_fields(fields, &builders) {
        out.push_str("import Data.Tuple (Tuple(..))\n");
    }
    if uses_map_expressions(fields) {
        out.push_str("import Foreign.Object as Object\n");
    }
    render_builder_import(
        out,
        if data_source {
            "addDataSource"
        } else {
            "addResource"
        },
        fields,
        &builders,
    );
    render_core_import(out, Some(data_source), fields, &builders);
    let _ = writeln!(
        out,
        "import {module_root}.Provider ({})",
        provider_marker(module_root)
    );
    out.push('\n');
    let _ = write!(out, "data {node}\n\n");
    render_nested_builders(out, &builders);
    render_args(out, fields);
    for field in fields.iter().filter(|field| field.optional) {
        render_setter(out, field);
    }
    let handle_fields: Vec<_> = item.outputs().collect();
    render_record_documentation(
        out,
        &format!("A symbolic handle to `{}`.", item.provider_type),
        &handle_fields,
    );
    let _ = write!(out, "type {handle_name} =\n  {{ ");
    out.push_str(if data_source {
        "dataSource :: DataSource "
    } else {
        "resource :: Resource "
    });
    out.push_str(&node);
    for field in &handle_fields {
        let _ = write!(out, "\n  , {} :: Expr ", safe_field_name(field));
        render_type_argument(out, &field.r#type);
    }
    out.push_str("\n  }\n\n");
    let options_type = if data_source {
        "DataSourceOptions"
    } else {
        "ResourceOptions"
    };
    let default_options = if data_source {
        "dataSourceOptions"
    } else {
        "resourceOptions"
    };
    let marker = provider_marker(module_root);
    let _ = write!(
        out,
        "{operation} :: String -> Args -> Infra {handle_name}\n\
         {operation} logicalName values = {operation_with} logicalName values {default_options}\n\n\
         {operation_with} :: String -> Args -> {options_type} {marker} -> Infra {handle_name}\n"
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
        out,
        "{operation_with} logicalName (Args values) options = do\n  _ <- requireProvider \"{}\" \"{}\" \"= {}\"\n  handle <- {add} options \"{}\" logicalName values\n  pure\n    {{ {handle_key}: handle",
        provider_local_name_from_source(&provider.source),
        provider.source,
        provider.version,
        item.provider_type
    );
    for field in &handle_fields {
        let _ = write!(
            out,
            "\n    , {}: {attr} handle [ \"{}\" ]",
            safe_field_name(field),
            field.provider_name
        );
    }
    out.push_str("\n    }\n");
}

/// The module header with its export list, written as the list is built.
struct Exports<'o, 'w> {
    out: &'o mut Output<'w>,
    first: bool,
}

impl<'o, 'w> Exports<'o, 'w> {
    fn new(out: &'o mut Output<'w>, module: &str) -> Self {
        let _ = write!(out, "module {module}\n  ( ");
        Self { out, first: true }
    }

    fn add(&mut self, export: impl fmt::Display) {
        if !std::mem::take(&mut self.first) {
            self.out.push_str("\n  , ");
        }
        let _ = write!(self.out, "{export}");
    }

    fn finish(self) {
        self.out.push_str("\n  ) where\n\n");
    }
}

fn render_doc_comment(out: &mut Output<'_>, description: &str) {
    for line in description.trim().lines() {
        if line.trim().is_empty() {
            out.push_str("-- |\n");
        } else {
            let _ = writeln!(out, "-- | {}", line.trim_end());
        }
    }
}

/// The summary, then every documented field below `fields` by path. The paths are listed
/// separately from the summary only when there are any, so they are collected first.
fn render_record_documentation(out: &mut Output<'_>, summary: &str, fields: &[&BindingField]) {
    render_doc_comment(out, summary);
    let mut entries = String::new();
    let mut path = String::new();
    for field in fields {
        collect_field_documentation(&mut entries, &mut path, field);
    }
    if !entries.is_empty() {
        out.push_str("-- |\n");
        out.push_str(&entries);
    }
}

/// Appends the documentation entries of `field` and its nested fields, `path` holding the
/// dotted path of the field's parent (and restored before returning).
fn collect_field_documentation(entries: &mut String, path: &mut String, field: &BindingField) {
    let parent_length = path.len();
    if !path.is_empty() {
        path.push('.');
    }
    let _ = write!(path, "{}", safe_field_name(field));
    if let Some(description) = field
        .description
        .as_deref()
        .map(str::trim)
        .filter(|description| !description.is_empty())
    {
        let mut lines = description.lines();
        let first = lines.next().unwrap_or_default().trim_end();
        let _ = writeln!(entries, "-- | - `{path}`: {first}");
        for line in lines {
            if line.trim().is_empty() {
                entries.push_str("-- |\n");
            } else {
                let _ = writeln!(entries, "-- |   {}", line.trim_end());
            }
        }
    }
    if let Some(container) = nested_container(&field.r#type) {
        for child in container.fields() {
            collect_field_documentation(entries, path, child);
        }
    }
    path.truncate(parent_length);
}

/// The names generated for a nested input block, derived from its path: the type
/// `NodePoolTaint`, and the prefix `nodePoolTaint` of its constructor, setters, and node.
#[derive(Debug, Clone)]
struct BuilderNames {
    /// Whether this is the empty path of the top-level record.
    root: bool,
    /// The path's segments capitalized and joined, before [`safe_type_name`].
    joined: String,
    type_name: String,
    prefix: String,
}

impl BuilderNames {
    fn root() -> Self {
        Self {
            root: true,
            joined: String::new(),
            type_name: String::new(),
            prefix: String::new(),
        }
    }

    fn child(&self, segment: &str) -> Self {
        let mut joined = String::with_capacity(self.joined.len() + segment.len());
        joined.push_str(&self.joined);
        push_capitalized(&mut joined, segment);
        let mut prefix = String::with_capacity(self.prefix.len() + segment.len());
        if self.root {
            prefix.push_str(segment);
        } else {
            prefix.push_str(&self.prefix);
            push_capitalized(&mut prefix, segment);
        }
        Self {
            root: false,
            type_name: safe_type_name(joined.clone()),
            joined,
            prefix,
        }
    }
}

#[derive(Debug)]
struct NestedBuilder<'a> {
    names: BuilderNames,
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

/// Every nested input block below `fields`, parents before their children.
fn collect_nested_builders(fields: &[BindingField]) -> Vec<NestedBuilder<'_>> {
    fn visit<'a>(
        field: &'a BindingField,
        parent: &BuilderNames,
        builders: &mut Vec<NestedBuilder<'a>>,
    ) {
        if !field.required && !field.optional {
            return;
        }
        let Some(container) = nested_container(&field.r#type) else {
            return;
        };
        let names = parent.child(&field.public_name);
        builders.push(NestedBuilder {
            names: names.clone(),
            fields: container.fields(),
        });
        for child in container.fields() {
            visit(child, &names, builders);
        }
    }

    let mut builders = Vec::new();
    let root = BuilderNames::root();
    for field in fields {
        visit(field, &root, &mut builders);
    }
    builders
}

fn extend_nested_exports(exports: &mut Exports<'_, '_>, builders: &[NestedBuilder<'_>]) {
    for builder in builders {
        let names = &builder.names;
        exports.add(&names.type_name);
        exports.add(format_args!("{}Required", names.type_name));
        exports.add(format_args!("{}Args", names.prefix));
        for field in builder.fields.iter().filter(|field| field.optional) {
            exports.add(NestedSetterName(names, field));
        }
    }
}

fn has_required_fields(fields: &[BindingField], builders: &[NestedBuilder<'_>]) -> bool {
    fields.iter().any(|field| field.required)
        || builders
            .iter()
            .any(|builder| builder.fields.iter().any(|field| field.required))
}

/// Whether any nested input block (at any depth) satisfies `matches`.
fn any_nested_input(fields: &[BindingField], matches: fn(NestedContainer<'_>) -> bool) -> bool {
    fields.iter().any(|field| {
        if !field.required && !field.optional {
            return false;
        }
        let Some(container) = nested_container(&field.r#type) else {
            return false;
        };
        matches(container) || any_nested_input(container.fields(), matches)
    })
}

fn uses_nested_mapping(fields: &[BindingField]) -> bool {
    any_nested_input(fields, |container| {
        matches!(
            container,
            NestedContainer::Array(_) | NestedContainer::Map(_)
        )
    })
}

fn uses_array_expressions(fields: &[BindingField]) -> bool {
    any_nested_input(fields, |container| {
        matches!(container, NestedContainer::Array(_))
    })
}

fn uses_map_expressions(fields: &[BindingField]) -> bool {
    any_nested_input(fields, |container| {
        matches!(container, NestedContainer::Map(_))
    })
}

fn has_optional_nested_fields(builders: &[NestedBuilder<'_>]) -> bool {
    builders
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

    fields.iter().any(|field| type_uses_json(&field.r#type))
}

fn render_builder_import(
    out: &mut Output<'_>,
    operation: &str,
    fields: &[BindingField],
    builders: &[NestedBuilder<'_>],
) {
    let mut public_imports = vec!["Infra"];
    let mut internal_imports = vec![operation, "InputObject", "inputObject"];
    if operation == "addResource" {
        internal_imports.push("requireProvider");
        public_imports.push("ResourceOptions");
        public_imports.push("resourceOptions");
    } else if operation == "addDataSource" {
        internal_imports.push("requireProvider");
        public_imports.push("DataSourceOptions");
        public_imports.push("dataSourceOptions");
    }
    if fields.iter().any(|field| field.optional) || has_optional_nested_fields(builders) {
        internal_imports.push("insertInputField");
    }
    if !builders.is_empty() {
        internal_imports.push("inputObjectNode");
    }
    let _ = write!(
        out,
        "import Inframe.Builder ({})\nimport Inframe.Internal.Builder ({})\n",
        public_imports.join(", "),
        internal_imports.join(", ")
    );
}

fn provider_local_name_from_source(source: &str) -> &str {
    source.rsplit('/').next().unwrap_or(source)
}

fn render_core_import(
    out: &mut Output<'_>,
    item_kind: Option<bool>,
    fields: &[BindingField],
    builders: &[NestedBuilder<'_>],
) {
    let mut public_imports = vec!["Input"];
    let mut internal_imports = vec!["inputNode"];
    if item_kind.is_none() {
        public_imports.insert(0, "Provider");
    }
    if item_kind.is_some() {
        public_imports.insert(0, "Expr");
    }
    if !builders.is_empty() {
        internal_imports.push("ExprNode");
        if uses_array_expressions(fields) {
            internal_imports.push("arrayExprNode");
        }
        if uses_map_expressions(fields) {
            internal_imports.push("objectExprNode");
        }
    }
    if let Some(data_source) = item_kind {
        public_imports.push(if data_source {
            "DataSource"
        } else {
            "Resource"
        });
        internal_imports.push(if data_source {
            "dataSourceAttr"
        } else {
            "resourceAttr"
        });
    }
    let _ = write!(
        out,
        "import Inframe.Core ({})\nimport Inframe.Internal.Core ({})\n",
        public_imports.join(", "),
        internal_imports.join(", ")
    );
}

fn provider_marker(module_root: &str) -> String {
    format!(
        "{}Provider",
        module_root.rsplit('.').next().unwrap_or(module_root)
    )
}

fn render_nested_builders(out: &mut Output<'_>, builders: &[NestedBuilder<'_>]) {
    for builder in builders {
        render_nested_builder(out, builder);
    }
}

fn render_nested_builder(out: &mut Output<'_>, builder: &NestedBuilder<'_>) {
    let names = &builder.names;
    let type_name = &names.type_name;
    let prefix = &names.prefix;
    let required: Vec<_> = builder
        .fields
        .iter()
        .filter(|field| field.required)
        .collect();
    let _ = write!(out, "newtype {type_name} = {type_name} InputObject\n\n");
    render_record_documentation(
        out,
        &format!("Required fields for `{type_name}`."),
        &required,
    );
    let _ = write!(out, "type {type_name}Required =\n  {{");
    render_required_fields(out, &required, names);
    let _ = write!(
        out,
        "\n  }}\n\n{prefix}Args :: {type_name}Required -> {type_name}\n"
    );
    let argument = if required.is_empty() { "_" } else { "required" };
    let _ = write!(
        out,
        "{prefix}Args {argument} = {type_name} (inputObject\n  ["
    );
    render_required_values(out, &required, names);
    out.push_str("\n  ])\n\n");
    for field in builder.fields.iter().filter(|field| field.optional) {
        render_nested_setter(out, builder, field);
    }
    let _ = write!(
        out,
        "{prefix}Node :: {type_name} -> ExprNode\n\
         {prefix}Node ({type_name} values) = inputObjectNode values\n\n"
    );
}

fn render_args(out: &mut Output<'_>, fields: &[BindingField]) {
    let required: Vec<_> = fields.iter().filter(|field| field.required).collect();
    render_record_documentation(out, "Required arguments.", &required);
    out.push_str("type Required =\n  {");
    let root = BuilderNames::root();
    render_required_fields(out, &required, &root);
    out.push_str("\n  }\n\nnewtype Args = Args InputObject\n\n");
    let required_argument = if required.is_empty() { "_" } else { "required" };
    let _ = write!(
        out,
        "args :: Required -> Args\nargs {required_argument} = Args (inputObject\n  ["
    );
    render_required_values(out, &required, &root);
    out.push_str("\n  ])\n\n");
}

fn render_required_fields(out: &mut Output<'_>, required: &[&BindingField], parent: &BuilderNames) {
    for (index, field) in required.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n  , " };
        let _ = write!(out, "{separator}{} :: ", safe_field_name(field));
        render_input_type(out, field, parent);
    }
}

fn render_required_values(out: &mut Output<'_>, required: &[&BindingField], parent: &BuilderNames) {
    for (index, field) in required.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n  , " };
        let _ = write!(out, "{separator}Tuple \"{}\" (", field.provider_name);
        render_input_node(
            out,
            format_args!("required.{}", safe_field_name(field)),
            field,
            parent,
        );
        out.push(')');
    }
}

fn render_setter(out: &mut Output<'_>, field: &BindingField) {
    let name = safe_field_name(field);
    if let Some(description) = field.description.as_deref() {
        render_doc_comment(out, description);
    }
    let root = BuilderNames::root();
    let _ = write!(out, "{name} :: ");
    render_input_type(out, field, &root);
    let _ = write!(
        out,
        " -> Args -> Args\n\
         {name} value (Args values) = Args (insertInputField \"{}\" (",
        field.provider_name
    );
    render_input_node(out, "value", field, &root);
    out.push_str(") values)\n\n");
}

fn render_nested_setter(out: &mut Output<'_>, builder: &NestedBuilder<'_>, field: &BindingField) {
    let name = NestedSetterName(&builder.names, field);
    let type_name = &builder.names.type_name;
    if let Some(description) = field.description.as_deref() {
        render_doc_comment(out, description);
    }
    let _ = write!(out, "{name} :: ");
    render_input_type(out, field, &builder.names);
    let _ = write!(
        out,
        " -> {type_name} -> {type_name}\n\
         {name} value ({type_name} values) = {type_name} (insertInputField \"{}\" (",
        field.provider_name
    );
    render_input_node(out, "value", field, &builder.names);
    out.push_str(") values)\n\n");
}

/// The type of an input `field` of the block named by `parent`.
fn render_input_type(out: &mut Output<'_>, field: &BindingField, parent: &BuilderNames) {
    let Some(container) = nested_container(&field.r#type) else {
        out.push_str("Input ");
        render_type_argument(out, &field.r#type);
        return;
    };
    let child = parent.child(&field.public_name);
    match container {
        NestedContainer::Single(_) => out.push_str(&child.type_name),
        NestedContainer::Array(_) => {
            let _ = write!(out, "Array {}", child.type_name);
        }
        NestedContainer::Map(_) => {
            let _ = write!(out, "Object.Object {}", child.type_name);
        }
    }
}

/// The `ExprNode` for `value`, an input `field` of the block named by `parent`.
fn render_input_node(
    out: &mut Output<'_>,
    value: impl fmt::Display,
    field: &BindingField,
    parent: &BuilderNames,
) {
    let Some(container) = nested_container(&field.r#type) else {
        let _ = write!(out, "inputNode {value}");
        return;
    };
    let child = parent.child(&field.public_name);
    let node = &child.prefix;
    let _ = match container {
        NestedContainer::Single(_) => write!(out, "{node}Node {value}"),
        NestedContainer::Array(_) => write!(out, "arrayExprNode (map {node}Node {value})"),
        NestedContainer::Map(_) => write!(out, "objectExprNode (map {node}Node {value})"),
    };
}

/// The setter of an optional `field` in the block named by the builder names.
struct NestedSetterName<'a>(&'a BuilderNames, &'a BindingField);

impl fmt::Display for NestedSetterName<'_> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0.prefix)?;
        let mut characters = self.1.public_name.chars();
        if let Some(first) = characters.next() {
            formatter.write_char(first.to_ascii_uppercase())?;
            formatter.write_str(characters.as_str())?;
        }
        Ok(())
    }
}

/// A field's PureScript name: its public name, with `_` appended when that is a keyword.
struct SafeFieldName<'a>(&'a BindingField);

impl fmt::Display for SafeFieldName<'_> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0.public_name)?;
        if self.0.target_reserved {
            formatter.write_str("_")?;
        }
        Ok(())
    }
}

fn safe_field_name(field: &BindingField) -> SafeFieldName<'_> {
    SafeFieldName(field)
}

fn safe_type_name(mut name: String) -> String {
    if matches!(name.as_str(), "Record" | "Row" | "Type") {
        name.push_str("Handle");
    }
    name
}

fn render_type(out: &mut Output<'_>, r#type: &BindingType) {
    match r#type {
        BindingType::String => out.push_str("String"),
        BindingType::Bool => out.push_str("Boolean"),
        BindingType::Number => out.push_str("Number"),
        BindingType::List(item) | BindingType::Set(item) => {
            out.push_str("Array ");
            render_type_argument(out, item);
        }
        BindingType::Map(_) | BindingType::Tuple(_) | BindingType::Dynamic => {
            out.push_str("Json");
        }
        BindingType::Object(fields) => {
            out.push_str("{ ");
            for (index, field) in fields.iter().enumerate() {
                if index > 0 {
                    out.push_str(", ");
                }
                let _ = write!(out, "{} :: ", safe_field_name(field));
                render_type(out, &field.r#type);
            }
            out.push_str(" }");
        }
    }
}

fn render_type_argument(out: &mut Output<'_>, r#type: &BindingType) {
    match r#type {
        BindingType::String
        | BindingType::Bool
        | BindingType::Number
        | BindingType::Map(_)
        | BindingType::Tuple(_)
        | BindingType::Dynamic => render_type(out, r#type),
        BindingType::List(_) | BindingType::Set(_) | BindingType::Object(_) => {
            out.push('(');
            render_type(out, r#type);
            out.push(')');
        }
    }
}

#[cfg(test)]
mod tests {
    use inframe_binding_model::{BindingProvider, BindingType};

    use super::*;

    fn object(fields: Vec<BindingField>) -> BindingType {
        BindingType::Object(fields.into())
    }

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
            description: Some("The tag name.\nMust be unique within the account.".into()),
            min_items: None,
            max_items: None,
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
            description: Some("The provider-assigned tag identifier.".into()),
            min_items: None,
            max_items: None,
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
            min_items: None,
            max_items: None,
        };
        let nested_name = nested_field("name", "name", BindingType::String, true, false, false);
        let mut auto_scale = nested_field(
            "auto_scale",
            "autoScale",
            BindingType::Bool,
            false,
            true,
            false,
        );
        auto_scale.description = Some("Whether automatic scaling is enabled.".into());
        let mut actual_node_count = nested_field(
            "actual_node_count",
            "actualNodeCount",
            BindingType::Number,
            false,
            false,
            true,
        );
        actual_node_count.description = Some("The current number of nodes.".into());
        let mut node_pool = nested_field(
            "node_pool",
            "nodePool",
            BindingType::List(Box::new(object(vec![
                nested_name,
                auto_scale,
                actual_node_count,
            ]))),
            true,
            false,
            false,
        );
        node_pool.block = true;
        BindingPackage {
            provider: BindingProvider {
                source: "digitalocean/digitalocean".into(),
                version: "2.100.0".into(),
                public_name: "Digitalocean".into(),
                fields: Vec::new().into(),
            },
            resources: vec![BindingItem {
                provider_type: "digitalocean_tag".into(),
                public_name: "Tag".into(),
                fields: vec![id, name, node_pool].into(),
            }],
            data_sources: Vec::new(),
        }
    }

    #[test]
    fn emits_a_typed_resource_constructor() {
        let generated = render_package(&package(), "DigitalOcean", "abc").unwrap();
        let provider = &generated.files[Path::new("src/DigitalOcean/Provider.purs")];
        assert!(provider.contains("data DigitalOceanProvider"));
        assert!(provider.contains("configure :: Args -> Infra (Provider DigitalOceanProvider)"));
        assert!(
            provider.contains(
                "addProvider \"digitalocean\" \"digitalocean/digitalocean\" \"= 2.100.0\""
            )
        );
        let source = &generated.files[Path::new("src/DigitalOcean/Resource/Tag.purs")];
        assert!(source.contains("import Inframe.Core (Expr, Input, Resource)"));
        assert!(source.contains("import Inframe.Internal.Core ("));
        assert!(source.contains("resourceAttr"));
        assert!(source.contains("create :: String -> Args -> Infra Tag"));
        assert!(source.contains(
            "requireProvider \"digitalocean\" \"digitalocean/digitalocean\" \"= 2.100.0\""
        ));
        assert!(source.contains(
            "createWith :: String -> Args -> ResourceOptions DigitalOceanProvider -> Infra Tag"
        ));
        assert!(source.contains("name :: Expr String"));
        assert!(source.contains("id: resourceAttr handle [ \"id\" ]"));
        assert!(source.contains("newtype NodePool = NodePool InputObject"));
        assert!(source.contains("type NodePoolRequired =\n  { name :: Input String"));
        assert!(source.contains("nodePoolAutoScale :: Input Boolean -> NodePool -> NodePool"));
        assert!(
            source.contains("-- | Whether automatic scaling is enabled.\nnodePoolAutoScale ::")
        );
        assert!(!source.contains("nodePoolActualNodeCount ::"));
        assert!(source.contains("nodePool :: Array NodePool"));
        assert!(source.contains("nodePool: resourceAttr handle [ \"node_pool\" ]"));
        assert!(source.contains("-- | - `name`: The tag name."));
        assert!(source.contains("-- |   Must be unique within the account."));
        assert!(source.contains("-- | - `id`: The provider-assigned tag identifier."));
        assert!(source.contains("-- | - `nodePool.actualNodeCount`: The current number of nodes."));
        assert!(
            source.contains(
                "Tuple \"node_pool\" (arrayExprNode (map nodePoolNode required.nodePool))"
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
