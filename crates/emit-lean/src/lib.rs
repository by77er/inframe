//! Deterministic Lean 4 provider-binding emitter.
//!
//! Renders a language-neutral [`BindingPackage`] into a Lake package whose modules mirror
//! the PureScript adapters: one module per resource and data source, a provider module,
//! required-argument structures, optional-argument setters, nested block builders, and
//! typed symbolic handles. Logical names are validated at compile time through the core
//! library's `Identifier` proofs.

use std::collections::{BTreeMap, HashMap};
use std::fmt::Write as _;
use std::fs;
use std::path::{Path, PathBuf};

use inframe_binding_model::{
    BindingField, BindingItem, BindingPackage, BindingProvider, BindingType,
};
use serde::Serialize;
use thiserror::Error;

/// The Lean toolchain pinned by generated packages and by the core library.
pub const LEAN_TOOLCHAIN: &str = "leanprover/lean4:v4.33.1";

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

/// How the generated Lake package locates the `inframe` core library.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CoreDependency {
    /// A relative path written verbatim into the lakefile.
    Path(String),
    /// A git requirement.
    Git {
        url: String,
        rev: String,
        sub_dir: Option<String>,
    },
}

#[derive(Debug, Serialize)]
struct Manifest<'a> {
    provider_source: &'a str,
    provider_version: &'a str,
    schema_sha256: &'a str,
    generator_version: &'a str,
    binding_model_version: &'static str,
    graph_ir_version: &'static str,
    lean_toolchain: &'static str,
}

#[derive(Debug, Error)]
pub enum EmitError {
    #[error("invalid Lean module root `{0}`")]
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
    core: &CoreDependency,
) -> Result<GeneratedPackage, EmitError> {
    if !valid_module_root(module_root) {
        return Err(EmitError::InvalidModuleRoot(module_root.to_owned()));
    }
    let mut files = BTreeMap::new();
    let mut modules = vec![format!("{module_root}.Provider")];
    files.insert(
        module_path(&format!("{module_root}.Provider")),
        render_provider(package, module_root),
    );
    for resource in &package.resources {
        let module = format!("{module_root}.Resource.{}", resource.public_name);
        files.insert(
            module_path(&module),
            render_item(resource, &module, module_root, &package.provider, false),
        );
        modules.push(module);
    }
    for data_source in &package.data_sources {
        let module = format!("{module_root}.Data.{}", data_source.public_name);
        files.insert(
            module_path(&module),
            render_item(data_source, &module, module_root, &package.provider, true),
        );
        modules.push(module);
    }
    let mut root = header_comment(&package.provider);
    for module in &modules {
        let _ = writeln!(root, "import {module}");
    }
    files.insert(module_path(module_root), root);
    let manifest = Manifest {
        provider_source: &package.provider.source,
        provider_version: &package.provider.version,
        schema_sha256,
        generator_version: env!("CARGO_PKG_VERSION"),
        binding_model_version: "1.0",
        graph_ir_version: "1.0",
        lean_toolchain: LEAN_TOOLCHAIN,
    };
    let mut manifest = serde_json::to_string_pretty(&manifest)?;
    manifest.push('\n');
    files.insert(PathBuf::from("provider-manifest.json"), manifest);
    files.insert(
        PathBuf::from("README.md"),
        format!(
            "# {module_root}\n\nGenerated Lean 4 bindings for `{}` `{}`. Do not edit by hand.\n",
            package.provider.source, package.provider.version
        ),
    );
    files.insert(
        PathBuf::from("lean-toolchain"),
        format!("{LEAN_TOOLCHAIN}\n"),
    );
    files.insert(
        PathBuf::from("lakefile.toml"),
        render_lakefile(package, module_root, core),
    );
    if let CoreDependency::Path(path) = core {
        files.insert(
            PathBuf::from("lake-manifest.json"),
            render_manifest(&package.provider, path),
        );
    }
    Ok(GeneratedPackage { files })
}

/// Lake's manifest for a package whose only dependency is a local checkout of the core
/// library. Git dependencies record a resolved commit, which only Lake can compute, so
/// those packages let `lake` create the manifest on first use.
fn render_manifest(provider: &BindingProvider, core_path: &str) -> String {
    let manifest = serde_json::json!({
        "version": "1.2.0",
        "packagesDir": ".lake/packages",
        "packages": [{
            "type": "path",
            "scope": "",
            "name": "inframe",
            "manifestFile": "lake-manifest.json",
            "inherited": false,
            "dir": core_path,
            "configFile": "lakefile.toml"
        }],
        "name": format!("«generated-{}»", provider.public_name.to_ascii_lowercase()),
        "lakeDir": ".lake",
        "fixedToolchain": false
    });
    let mut output = serde_json::to_string_pretty(&manifest).unwrap_or_default();
    output.push('\n');
    output
}

fn render_lakefile(package: &BindingPackage, module_root: &str, core: &CoreDependency) -> String {
    let mut output = format!(
        "name = \"generated-{}\"\nversion = \"{}\"\ndefaultTargets = [\"{module_root}\"]\n\n[[require]]\nname = \"inframe\"\n",
        package.provider.public_name.to_ascii_lowercase(),
        lake_version(&package.provider.version)
    );
    match core {
        CoreDependency::Path(path) => {
            let _ = writeln!(output, "path = \"{}\"", escape_toml(path));
        }
        CoreDependency::Git { url, rev, sub_dir } => {
            let _ = writeln!(output, "git = \"{}\"", escape_toml(url));
            let _ = writeln!(output, "rev = \"{}\"", escape_toml(rev));
            if let Some(sub_dir) = sub_dir {
                let _ = writeln!(output, "subDir = \"{}\"", escape_toml(sub_dir));
            }
        }
    }
    let _ = write!(
        output,
        "\n[[lean_lib]]\nname = \"{module_root}\"\nglobs = [\"{module_root}.*\"]\n"
    );
    output
}

/// Lake requires a semantic version; provider versions such as `2.100.0` already qualify,
/// anything else falls back to `0.0.0`.
fn lake_version(version: &str) -> &str {
    let mut parts = version.split('.');
    let numeric = |part: Option<&str>| {
        part.is_some_and(|part| !part.is_empty() && part.chars().all(|c| c.is_ascii_digit()))
    };
    if numeric(parts.next())
        && numeric(parts.next())
        && numeric(parts.next())
        && parts.next().is_none()
    {
        version
    } else {
        "0.0.0"
    }
}

fn escape_toml(value: &str) -> String {
    value.replace('\\', "\\\\").replace('"', "\\\"")
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
    PathBuf::from(module.replace('.', "/") + ".lean")
}

fn header_comment(provider: &BindingProvider) -> String {
    format!(
        "-- Generated by inframe from `{}` {}. Do not edit by hand.\n",
        provider.source, provider.version
    )
}

fn provider_marker(module_root: &str) -> String {
    format!(
        "{}Provider",
        module_root.rsplit('.').next().unwrap_or(module_root)
    )
}

fn provider_local_name_from_source(source: &str) -> &str {
    source.rsplit('/').next().unwrap_or(source)
}

fn render_provider(package: &BindingPackage, module_root: &str) -> String {
    let provider = &package.provider;
    let fields = &provider.fields;
    let marker = provider_marker(module_root);
    let mut output = header_comment(provider);
    let _ = write!(
        output,
        "import Inframe\n\nnamespace {module_root}.Provider\n\nopen Inframe\n\n"
    );
    let _ = write!(
        output,
        "/-- Phantom type tagging handles to configured `{}` providers. -/\ninductive {marker}\n\n",
        provider.source
    );
    let module = format!("{module_root}.Provider");
    let shapes = Shapes::collect(fields, &[&marker]);
    output.push_str(&render_shapes(&shapes, &module));
    output.push_str(&render_args(
        fields,
        &format!("the `{}` provider", provider.source),
        &module,
        &shapes,
    ));
    let local_name = provider_local_name_from_source(&provider.source);
    let version = format!("= {}", provider.version);
    let _ = write!(
        output,
        "/-- Configure the default `{local_name}` provider. -/\n\
         def configure (a : Args) : Infra (Inframe.Provider {marker}) :=\n  \
           addProvider (Identifier.mk \"{local_name}\") \"{}\" \"{version}\" none a.values\n\n\
         /-- Configure an aliased `{local_name}` provider. The alias is validated at compile time. -/\n\
         def configureAs (alias : String) (a : Args) (valid : validIdentifier alias = true := by decide) :\n    \
           Infra (Inframe.Provider {marker}) :=\n  \
           addProvider (Identifier.mk \"{local_name}\") \"{}\" \"{version}\" (some ⟨alias, valid⟩) a.values\n\n\
         end {module_root}.Provider\n",
        escape_string(&provider.source),
        escape_string(&provider.source)
    );
    output
}

#[allow(clippy::too_many_lines)]
fn render_item(
    item: &BindingItem,
    module: &str,
    module_root: &str,
    provider: &BindingProvider,
    data_source: bool,
) -> String {
    let marker = provider_marker(module_root);
    let node = format!(
        "{}{}",
        item.public_name,
        if data_source {
            "DataSource"
        } else {
            "Resource"
        }
    );
    let handle_name = safe_handle_name(&item.public_name, &node);
    let kind = if data_source {
        "data source"
    } else {
        "resource"
    };
    let mut output = header_comment(provider);
    let _ = write!(
        output,
        "import Inframe\nimport {module_root}.Provider\n\nnamespace {module}\n\nopen Inframe\n\n"
    );
    let _ = write!(
        output,
        "/-- Phantom type tagging handles to `{}` {kind}s. -/\ninductive {node}\n\n",
        item.provider_type
    );
    let shapes = Shapes::collect(&item.fields, &[&handle_name, &node]);
    output.push_str(&render_shapes(&shapes, module));
    output.push_str(&render_args(
        &item.fields,
        &format!("`{}`", item.provider_type),
        module,
        &shapes,
    ));
    let handle_fields: Vec<_> = item.outputs().collect();
    let handle_reserved: &[&str] = if data_source {
        &["dataSource"]
    } else {
        &["resource"]
    };
    output.push_str(&render_attributes(
        "Attributes",
        &[],
        &handle_fields,
        handle_reserved,
        &format!(
            "The attributes of `{}`, held in `f`, with non-required attributes wrapped in `o`: \
             `Attributes Input Resolved` is the symbolic handle, `Attributes Resolved Option` \
             the resolved state, `Attributes Option Resolved` a fully optional view.",
            item.provider_type
        ),
        &shapes,
    ));
    let _ = write!(
        output,
        "/-- A symbolic handle to `{}`. Every attribute is a symbolic input resolved by OpenTofu. -/\nstructure {handle_name} extends Attributes Input Resolved where\n",
        item.provider_type
    );
    if data_source {
        let _ = writeln!(output, "  dataSource : DataSource {node}\n");
    } else {
        let _ = writeln!(output, "  resource : Resource {node}\n");
    }
    let _ = write!(
        output,
        "/-- The resolved attributes of `{}`, decoded from `tofu show -json` with\n`ShowDocument.decode?`: required attributes are plain values, the rest `Option`. -/\nabbrev State := Attributes Resolved Option\n\n\
         /-- Every attribute optional. -/\nabbrev Partial := Attributes Option Resolved\n\n",
        item.provider_type
    );
    // Fully qualified: a nested block named `managed` or `dependable` would otherwise shadow
    // the core class inside this namespace.
    if data_source {
        let _ = write!(
            output,
            "instance : Inframe.Dependable {handle_name} := ⟨fun handle => handle.dataSource.address⟩\n\n"
        );
    } else {
        let _ = write!(
            output,
            "instance : Inframe.Dependable {handle_name} := ⟨fun handle => handle.resource.address⟩\n\
             instance : Inframe.Managed {handle_name} := ⟨fun handle => handle.resource.address⟩\n\n"
        );
    }
    let (operation, operation_with, options_type, default_options, add, attr, handle_key) =
        if data_source {
            (
                "read",
                "readWith",
                "DataSourceOptions",
                "dataSourceOptions",
                "addDataSource",
                "dataSourceAttr",
                "dataSource",
            )
        } else {
            (
                "create",
                "createWith",
                "ResourceOptions",
                "resourceOptions",
                "addResource",
                "resourceAttr",
                "resource",
            )
        };
    let local_name = provider_local_name_from_source(&provider.source);
    let _ = write!(
        output,
        "/-- Add `{}.<name>` to the graph with explicit options. The logical name is validated at\ncompile time. -/\n\
         def {operation_with} (name : String) (a : Args) (options : {options_type} {module_root}.Provider.{marker})\n    \
           (valid : validIdentifier name = true := by decide) : Infra {handle_name} := do\n  \
           requireProvider (Identifier.mk \"{local_name}\") \"{}\" \"= {}\"\n  \
           let handle ← {add} options (Identifier.mk \"{}\") ⟨name, valid⟩ a.values\n  \
           pure\n    {{ {handle_key} := handle",
        item.provider_type,
        escape_string(&provider.source),
        escape_string(&provider.version),
        item.provider_type
    );
    for field in &handle_fields {
        let _ = write!(
            output,
            "\n      {} := {attr} handle [\"{}\"]",
            safe_field_name(field, handle_reserved),
            escape_string(&field.provider_name)
        );
    }
    let _ = write!(
        output,
        " }}\n\n\
         /-- Add `{}.<name>` to the graph with default options. -/\n\
         def {operation} (name : String) (a : Args) (valid : validIdentifier name = true := by decide) :\n    \
           Infra {handle_name} :=\n  \
           {operation_with} name a {default_options} valid\n\n\
         end {module}\n",
        item.provider_type
    );
    output
}

fn render_args(
    fields: &[BindingField],
    subject: &str,
    module: &str,
    shapes: &Shapes<'_>,
) -> String {
    let required: Vec<_> = fields.iter().filter(|field| field.required).collect();
    let mut output =
        format!("/-- Required arguments for {subject}. -/\nstructure Required where\n");
    render_required_fields(&mut output, &required, &[], shapes);
    let _ = write!(
        output,
        "\n/-- Arguments for {subject}. Build with `args` and refine with `Args.*` setters, for example\n`args {{ .. }} |>.someField (lit value)`. -/\nabbrev Args := Block \"{module}.Args\"\n\n"
    );
    let argument = if required.is_empty() { "_" } else { "required" };
    let _ = write!(
        output,
        "def args ({argument} : Required) : Args :=\n  ⟨InputObject.ofList\n    ["
    );
    render_required_values(&mut output, &required, &[], shapes);
    output.push_str("]⟩\n\n");
    for field in fields.iter().filter(|field| field.optional) {
        output.push_str(&render_setter("Args", "a", field, &[], shapes));
    }
    output
}

fn render_required_fields(
    output: &mut String,
    required: &[&BindingField],
    parent_path: &[String],
    shapes: &Shapes<'_>,
) {
    for field in required {
        let path = child_path(parent_path, field);
        output.push_str(&indent_doc(&field_documentation(field), "  "));
        let _ = writeln!(
            output,
            "  {} : {}",
            safe_field_name(field, &[]),
            render_input_type(&field.r#type, &path, shapes)
        );
    }
}

fn render_required_values(
    output: &mut String,
    required: &[&BindingField],
    parent_path: &[String],
    shapes: &Shapes<'_>,
) {
    for (index, field) in required.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n    , " };
        let value = format!("required.{}", safe_field_name(field, &[]));
        let path = child_path(parent_path, field);
        let _ = write!(
            output,
            "{separator}(\"{}\", {})",
            escape_string(&field.provider_name),
            render_input_node(&value, &field.r#type, &path, shapes)
        );
    }
    if !required.is_empty() {
        output.push(' ');
    }
}

fn render_setter(
    type_name: &str,
    receiver: &str,
    field: &BindingField,
    parent_path: &[String],
    shapes: &Shapes<'_>,
) -> String {
    let name = safe_field_name(field, SETTER_RESERVED);
    let path = child_path(parent_path, field);
    let input_type = render_input_type(&field.r#type, &path, shapes);
    let encoded = render_input_node("value", &field.r#type, &path, shapes);
    let mut output = field_documentation(field);
    let _ = write!(
        output,
        "def {type_name}.{name} (value : {input_type}) ({receiver} : {type_name}) : {type_name} :=\n  \
           ⟨{receiver}.values.insert \"{}\" ({encoded})⟩\n\n",
        escape_string(&field.provider_name)
    );
    output
}

/// A nested object type that gets its own Lean declaration: a builder for an input block or
/// a phantom marker for a computed-only shape.
#[derive(Debug)]
struct NestedType<'a> {
    /// The first path at which this shape occurs; it names the type.
    path: Vec<String>,
    name: String,
    fields: &'a [BindingField],
    builder: bool,
    /// How many paths share this shape.
    occurrences: usize,
}

/// The nested types of one module with structural sharing. Provider schemas unroll recursive
/// blocks to a fixed depth, so a resource can contain thousands of nested paths but only a few
/// dozen distinct shapes (`aws_wafv2_web_acl_rule`: 21,025 paths, 73 shapes). Every path maps
/// to the type of the first path with the same field list, so the generated module declares
/// each shape once. Children are emitted before their parents so that a parent's setters can
/// refer to the child's `toExprNode`.
#[derive(Debug)]
struct Shapes<'a> {
    entries: Vec<NestedType<'a>>,
    names: HashMap<Vec<String>, String>,
}

impl<'a> Shapes<'a> {
    fn collect(fields: &'a [BindingField], reserved: &[&str]) -> Self {
        let mut shapes = Self {
            entries: Vec::new(),
            names: HashMap::new(),
        };
        let mut seen: HashMap<String, usize> = HashMap::new();
        for field in fields {
            shapes.visit(field, &[], true, reserved, &mut seen);
        }
        shapes
    }

    /// Declare the object shape behind `field` (if any) and, first, the shapes behind its
    /// children. A shape gets a builder only when it is an input block reached through input
    /// blocks; computed-only shapes still get an attribute structure, since the parent's
    /// attributes refer to them.
    fn visit(
        &mut self,
        field: &'a BindingField,
        parent_path: &[String],
        parent_builder: bool,
        reserved: &[&str],
        seen: &mut HashMap<String, usize>,
    ) {
        let Some(fields) = object_fields(&field.r#type) else {
            return;
        };
        let builder = parent_builder
            && (field.required || field.optional)
            && nested_container(&field.r#type).is_some();
        let path = child_path(parent_path, field);
        for child in fields {
            self.visit(child, &path, builder, reserved, seen);
        }
        self.declare(path, fields, builder, reserved, seen);
    }

    fn declare(
        &mut self,
        path: Vec<String>,
        fields: &'a [BindingField],
        builder: bool,
        reserved: &[&str],
        seen: &mut HashMap<String, usize>,
    ) {
        let key = format!(
            "{}:{}",
            builder,
            serde_json::to_string(fields).unwrap_or_default()
        );
        if let Some(&index) = seen.get(&key) {
            self.entries[index].occurrences += 1;
            let name = self.entries[index].name.clone();
            self.names.insert(path, name);
            return;
        }
        let name = nested_type_name(&path, reserved);
        seen.insert(key, self.entries.len());
        self.names.insert(path.clone(), name.clone());
        self.entries.push(NestedType {
            path,
            name,
            fields,
            builder,
            occurrences: 1,
        });
    }

    /// The Lean type standing for the object shape at `path`.
    fn name(&self, path: &[String]) -> String {
        self.names
            .get(path)
            .cloned()
            .unwrap_or_else(|| nested_type_name(path, &[]))
    }
}

/// How an input block is nested: directly, as a list/set, or as a map.
#[derive(Debug, Clone, Copy)]
enum NestedContainer {
    Single,
    Array,
    Map,
}

fn nested_container(r#type: &BindingType) -> Option<NestedContainer> {
    match r#type {
        BindingType::Object(_) => Some(NestedContainer::Single),
        BindingType::List(item) | BindingType::Set(item) => match item.as_ref() {
            BindingType::Object(_) => Some(NestedContainer::Array),
            _ => None,
        },
        BindingType::Map(item) => match item.as_ref() {
            BindingType::Object(_) => Some(NestedContainer::Map),
            _ => None,
        },
        BindingType::String
        | BindingType::Bool
        | BindingType::Number
        | BindingType::Tuple(_)
        | BindingType::Dynamic => None,
    }
}

/// The object shape behind any number of collection layers, if there is exactly one.
fn object_fields(r#type: &BindingType) -> Option<&[BindingField]> {
    match r#type {
        BindingType::Object(fields) => Some(fields),
        BindingType::List(item) | BindingType::Set(item) | BindingType::Map(item) => {
            object_fields(item)
        }
        BindingType::String
        | BindingType::Bool
        | BindingType::Number
        | BindingType::Tuple(_)
        | BindingType::Dynamic => None,
    }
}

fn render_shapes(shapes: &Shapes<'_>, module: &str) -> String {
    let mut output = String::new();
    for nested in &shapes.entries {
        let fields: Vec<_> = nested.fields.iter().collect();
        output.push_str(&render_attributes(
            &format!("{}Attributes", nested.name),
            &nested.path,
            &fields,
            &[],
            &format!(
                "The attributes of the `{}` block{}, held in `f`.",
                nested.path.join("."),
                shared_note(nested.occurrences)
            ),
            shapes,
        ));
        if nested.builder {
            output.push_str(&render_nested_builder(nested, module, shapes));
        }
    }
    output
}

/// Only required attributes and blocks are guaranteed present in state; everything else,
/// including an unset optional block, may be `null`, so its type is wrapped in the
/// optionality container `o`.
fn always_present(field: &BindingField) -> bool {
    field.required
}

/// A higher-kinded attribute structure plus its decoder (for any `Marshal f o`) and its
/// encoder at resolved state, so state round-trips through `Value`.
fn render_attributes(
    name: &str,
    parent_path: &[String],
    fields: &[&BindingField],
    reserved: &[&str],
    doc: &str,
    shapes: &Shapes<'_>,
) -> String {
    let mut output = doc_comment(doc);
    let _ = writeln!(output, "structure {name} (f o : Type → Type) where");
    for field in fields {
        output.push_str(&indent_doc(&field_documentation(field), "  "));
        let inner =
            render_hkd_type_argument(&field.r#type, &child_path(parent_path, field), shapes);
        let _ = writeln!(
            output,
            "  {} : f {}",
            safe_field_name(field, reserved),
            if always_present(field) {
                inner
            } else {
                format!("(o {inner})")
            }
        );
    }
    // Lean's structure-instance parser wants newline-separated fields aligned in one column.
    let _ = write!(
        output,
        "\ndef {name}.ofValue [Marshal f o] (value : Value) : Except String ({name} f o) := do\n  pure"
    );
    if fields.is_empty() {
        output.push_str(" {}\n\n");
    } else {
        output.push_str("\n    {");
        for (index, field) in fields.iter().enumerate() {
            let separator = if index == 0 { " " } else { "\n      " };
            let _ = write!(
                output,
                "{separator}{} := (← Marshal.{} (f := f) (o := o) value \"{}\")",
                safe_field_name(field, reserved),
                if always_present(field) {
                    "required"
                } else {
                    "optional"
                },
                escape_string(&field.provider_name)
            );
        }
        output.push_str(" }\n\n");
    }
    let _ = write!(
        output,
        "instance [Marshal f o] : FromValue ({name} f o) := ⟨{name}.ofValue⟩\n\n\
         instance : ToValue ({name} Resolved Option) :=\n  ⟨fun attributes => .object\n    ["
    );
    for (index, field) in fields.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n    , " };
        let _ = write!(
            output,
            "{separator}(\"{}\", toValue attributes.{})",
            escape_string(&field.provider_name),
            safe_field_name(field, reserved)
        );
    }
    output.push_str(" ]⟩\n\n");
    output
}

fn render_nested_builder(nested: &NestedType<'_>, module: &str, shapes: &Shapes<'_>) -> String {
    let type_name = &nested.name;
    let required_name = format!("{type_name}Required");
    let constructor_name = format!("{}Args", lower_first(type_name));
    let provider_path = nested.path.join(".");
    let required: Vec<_> = nested
        .fields
        .iter()
        .filter(|field| field.required)
        .collect();
    let mut output = format!(
        "/-- Builder for the `{provider_path}` block{}. Start with `{constructor_name}` and refine with\n`{type_name}.*` setters. -/\nabbrev {type_name} := Block \"{module}.{type_name}\"\n\n",
        shared_note(nested.occurrences)
    );
    let _ = write!(
        output,
        "/-- Required fields of `{type_name}`. -/\nstructure {required_name} where\n"
    );
    render_required_fields(&mut output, &required, &nested.path, shapes);
    let argument = if required.is_empty() { "_" } else { "required" };
    let _ = write!(
        output,
        "\ndef {constructor_name} ({argument} : {required_name}) : {type_name} :=\n  ⟨InputObject.ofList\n    ["
    );
    render_required_values(&mut output, &required, &nested.path, shapes);
    output.push_str("]⟩\n\n");
    for field in nested.fields.iter().filter(|field| field.optional) {
        output.push_str(&render_setter(
            type_name,
            "block",
            field,
            &nested.path,
            shapes,
        ));
    }
    let _ = write!(
        output,
        "def {type_name}.toExprNode (block : {type_name}) : ExprNode :=\n  block.values.toExprNode\n\n"
    );
    output
}

fn render_input_type(r#type: &BindingType, path: &[String], shapes: &Shapes<'_>) -> String {
    match nested_container(r#type) {
        Some(NestedContainer::Single) => shapes.name(path),
        Some(NestedContainer::Array) => format!("List {}", shapes.name(path)),
        Some(NestedContainer::Map) => format!("List (String × {})", shapes.name(path)),
        None => format!("Input {}", render_type_argument(r#type, path, shapes)),
    }
}

fn render_input_node(
    value: &str,
    r#type: &BindingType,
    path: &[String],
    shapes: &Shapes<'_>,
) -> String {
    let type_name = shapes.name(path);
    match nested_container(r#type) {
        Some(NestedContainer::Single) => format!("{type_name}.toExprNode {value}"),
        Some(NestedContainer::Array) => {
            format!("ExprNode.array ({value}.map {type_name}.toExprNode)")
        }
        Some(NestedContainer::Map) => format!(
            "ExprNode.object ({value}.map fun (key, block) => (key, {type_name}.toExprNode block))"
        ),
        None => format!("inputNode {value}"),
    }
}

fn render_type(r#type: &BindingType, path: &[String], shapes: &Shapes<'_>) -> String {
    match r#type {
        BindingType::String => "String".into(),
        BindingType::Bool => "Bool".into(),
        BindingType::Number => "Number".into(),
        BindingType::List(item) | BindingType::Set(item) => {
            format!("List {}", render_type_argument(item, path, shapes))
        }
        BindingType::Map(item) => format!("Map {}", render_type_argument(item, path, shapes)),
        BindingType::Tuple(_) | BindingType::Dynamic => "Value".into(),
        BindingType::Object(_) => shapes.name(path),
    }
}

/// The type of an attribute inside a higher-kinded `Attributes f`: nested objects are their
/// own `…Attributes f`, so instantiating `f` instantiates the whole tree.
fn render_hkd_type(r#type: &BindingType, path: &[String], shapes: &Shapes<'_>) -> String {
    match r#type {
        BindingType::String => "String".into(),
        BindingType::Bool => "Bool".into(),
        BindingType::Number => "Number".into(),
        BindingType::List(item) | BindingType::Set(item) => {
            format!("List {}", render_hkd_type_argument(item, path, shapes))
        }
        BindingType::Map(item) => format!("Map {}", render_hkd_type_argument(item, path, shapes)),
        BindingType::Tuple(_) | BindingType::Dynamic => "Value".into(),
        BindingType::Object(_) => format!("{}Attributes f o", shapes.name(path)),
    }
}

fn render_hkd_type_argument(r#type: &BindingType, path: &[String], shapes: &Shapes<'_>) -> String {
    match r#type {
        BindingType::String
        | BindingType::Bool
        | BindingType::Number
        | BindingType::Tuple(_)
        | BindingType::Dynamic => render_hkd_type(r#type, path, shapes),
        BindingType::List(_)
        | BindingType::Set(_)
        | BindingType::Map(_)
        | BindingType::Object(_) => {
            format!("({})", render_hkd_type(r#type, path, shapes))
        }
    }
}

fn render_type_argument(r#type: &BindingType, path: &[String], shapes: &Shapes<'_>) -> String {
    match r#type {
        BindingType::String
        | BindingType::Bool
        | BindingType::Number
        | BindingType::Tuple(_)
        | BindingType::Dynamic
        | BindingType::Object(_) => render_type(r#type, path, shapes),
        BindingType::List(_) | BindingType::Set(_) | BindingType::Map(_) => {
            format!("({})", render_type(r#type, path, shapes))
        }
    }
}

fn shared_note(occurrences: usize) -> String {
    if occurrences > 1 {
        format!(" (shared by {occurrences} block paths with the same shape)")
    } else {
        String::new()
    }
}

fn child_path(parent_path: &[String], field: &BindingField) -> Vec<String> {
    let mut path = parent_path.to_vec();
    path.push(field.public_name.clone());
    path
}

fn nested_type_name(path: &[String], reserved: &[&str]) -> String {
    let name: String = path.iter().map(|part| upper_first(part)).collect();
    safe_type_name(&name, reserved, "Block")
}

fn lower_first(value: &str) -> String {
    let mut characters = value.chars();
    characters
        .next()
        .map(|first| first.to_ascii_lowercase().to_string() + characters.as_str())
        .unwrap_or_default()
}

fn upper_first(value: &str) -> String {
    let mut characters = value.chars();
    characters
        .next()
        .map(|first| first.to_ascii_uppercase().to_string() + characters.as_str())
        .unwrap_or_default()
}

/// Names that would clash with generated members of the same `Args`/block namespace.
const SETTER_RESERVED: &[&str] = &["values", "mk", "toExprNode"];

/// Type names that generated modules already use, either from the core library (which is
/// opened) or from Lean's prelude.
const RESERVED_TYPE_NAMES: &[&str] = &[
    "Type",
    "Prop",
    "Sort",
    "String",
    "Bool",
    "Nat",
    "Int",
    "Float",
    "Char",
    "List",
    "Array",
    "Option",
    "Unit",
    "Value",
    "Number",
    "Map",
    "Expr",
    "ExprNode",
    "Input",
    "InputObject",
    "Identifier",
    "Address",
    "Resource",
    "DataSource",
    "Provider",
    "Infra",
    "Args",
    "Required",
    "Block",
    "Dependable",
    "Managed",
    "Interpolated",
    "Attributes",
    "State",
    "Partial",
    "Resolved",
    "Marshal",
    "FromValue",
    "ToValue",
    "Lean",
    "Inframe",
];

fn safe_type_name(name: &str, reserved: &[&str], suffix: &str) -> String {
    if RESERVED_TYPE_NAMES.contains(&name) || reserved.contains(&name) {
        format!("{name}{suffix}")
    } else {
        name.to_owned()
    }
}

fn safe_handle_name(name: &str, node: &str) -> String {
    safe_type_name(name, &[node], "Handle")
}

/// Lean 4 tokens that cannot be used as plain identifiers.
fn lean_reserved(name: &str) -> bool {
    matches!(
        name,
        "abbrev"
            | "at"
            | "attribute"
            | "axiom"
            | "break"
            | "by"
            | "calc"
            | "catch"
            | "class"
            | "continue"
            | "declare_syntax_cat"
            | "decreasing_by"
            | "def"
            | "deriving"
            | "do"
            | "elab"
            | "else"
            | "end"
            | "example"
            | "exists"
            | "export"
            | "extends"
            | "false"
            | "finally"
            | "for"
            | "forall"
            | "from"
            | "fun"
            | "generalizing"
            | "have"
            | "hiding"
            | "if"
            | "import"
            | "in"
            | "include"
            | "inductive"
            | "infix"
            | "infixl"
            | "infixr"
            | "instance"
            | "let"
            | "local"
            | "macro"
            | "macro_rules"
            | "match"
            | "matches"
            | "meta"
            | "module"
            | "mut"
            | "mutual"
            | "namespace"
            | "nofun"
            | "nomatch"
            | "noncomputable"
            | "nonrec"
            | "notation"
            | "omit"
            | "only"
            | "opaque"
            | "open"
            | "partial"
            | "postfix"
            | "prefix"
            | "private"
            | "protected"
            | "public"
            | "renaming"
            | "repeat"
            | "return"
            | "scoped"
            | "section"
            | "set_option"
            | "show"
            | "sorry"
            | "structure"
            | "suffices"
            | "syntax"
            | "termination_by"
            | "then"
            | "theorem"
            | "this"
            | "true"
            | "try"
            | "universe"
            | "unless"
            | "unsafe"
            | "until"
            | "using"
            | "variable"
            | "where"
            | "while"
            | "with"
    )
}

fn safe_field_name(field: &BindingField, reserved: &[&str]) -> String {
    let name = &field.public_name;
    if lean_reserved(name)
        || reserved.contains(&name.as_str())
        || name.starts_with(|c: char| c.is_ascii_digit())
    {
        format!("{name}_")
    } else {
        name.clone()
    }
}

fn escape_string(value: &str) -> String {
    let mut output = String::with_capacity(value.len());
    for character in value.chars() {
        match character {
            '\\' => output.push_str("\\\\"),
            '"' => output.push_str("\\\""),
            '\n' => output.push_str("\\n"),
            '\r' => output.push_str("\\r"),
            '\t' => output.push_str("\\t"),
            other => output.push(other),
        }
    }
    output
}

/// Lean block comments nest, so both delimiters must be neutralised inside doc text.
fn escape_doc(value: &str) -> String {
    value.replace("-/", "- /").replace("/-", "/ -")
}

fn first_line(description: &str) -> String {
    escape_doc(description.lines().next().unwrap_or_default().trim_end())
}

fn doc_comment(text: &str) -> String {
    let text = text.trim();
    if text.is_empty() {
        return String::new();
    }
    let lines: Vec<_> = text.lines().map(str::trim_end).collect();
    if lines.len() == 1 {
        return format!("/-- {} -/\n", lines[0]);
    }
    let mut output = String::from("/-- ");
    output.push_str(lines[0]);
    for line in &lines[1..] {
        output.push('\n');
        output.push_str(line);
    }
    output.push_str(" -/\n");
    output
}

fn indent_doc(doc: &str, indent: &str) -> String {
    let mut output = String::new();
    for line in doc.lines() {
        let _ = writeln!(output, "{indent}{line}");
    }
    output
}

/// The description of a field followed by the descriptions of its direct nested fields, so
/// that hovers on a block-typed field explain the block's contents. Only one level is listed:
/// provider schemas unroll recursive blocks to a fixed depth (AWS WAF rules reach 21,000
/// nested paths), and listing whole subtrees made the documentation quadratic in that size.
fn field_documentation(field: &BindingField) -> String {
    let mut text = field
        .description
        .as_deref()
        .map(str::trim)
        .filter(|description| !description.is_empty())
        .map(escape_doc)
        .unwrap_or_default();
    let documented_children: Vec<_> = object_fields(&field.r#type)
        .unwrap_or_default()
        .iter()
        .filter_map(|child| {
            child
                .description
                .as_deref()
                .map(str::trim)
                .filter(|description| !description.is_empty())
                .map(|description| (child.public_name.as_str(), description))
        })
        .collect();
    if !documented_children.is_empty() {
        if !text.is_empty() {
            text.push('\n');
        }
        for (name, description) in documented_children {
            let _ = write!(text, "\n- `{name}`: {}", first_line(description));
        }
    }
    doc_comment(&text)
}

#[cfg(test)]
mod tests {
    use inframe_binding_model::{BindingProvider, BindingType};

    use super::*;

    fn field(
        provider_name: &str,
        public_name: &str,
        r#type: BindingType,
        required: bool,
        optional: bool,
        computed: bool,
    ) -> BindingField {
        BindingField {
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
        }
    }

    #[allow(clippy::too_many_lines)]
    fn package() -> BindingPackage {
        let mut name = field("name", "name", BindingType::String, true, false, false);
        name.description = Some("The tag name.\nMust be unique within the account.".into());
        let mut id = field("id", "id", BindingType::String, false, false, true);
        id.description = Some("The provider-assigned tag identifier.".into());
        let nested_name = field("name", "name", BindingType::String, true, false, false);
        let mut auto_scale = field(
            "auto_scale",
            "autoScale",
            BindingType::Bool,
            false,
            true,
            false,
        );
        auto_scale.description = Some("Whether automatic scaling is enabled.".into());
        let mut actual_node_count = field(
            "actual_node_count",
            "actualNodeCount",
            BindingType::Number,
            false,
            false,
            true,
        );
        actual_node_count.description = Some("The current number of nodes.".into());
        let taint_key = field("key", "key", BindingType::String, true, false, false);
        let taint = field(
            "taint",
            "taint",
            BindingType::List(Box::new(BindingType::Object(vec![taint_key]))),
            false,
            true,
            false,
        );
        let mut node_pool = field(
            "node_pool",
            "nodePool",
            BindingType::List(Box::new(BindingType::Object(vec![
                nested_name,
                auto_scale,
                actual_node_count,
                taint,
            ]))),
            true,
            false,
            false,
        );
        node_pool.block = true;
        let mut kube_config = field(
            "kube_config",
            "kubeConfig",
            BindingType::List(Box::new(BindingType::Object(vec![field(
                "raw_config",
                "rawConfig",
                BindingType::String,
                false,
                false,
                true,
            )]))),
            false,
            false,
            true,
        );
        kube_config.description = Some("Credentials for the cluster.".into());
        let end = field("end", "end", BindingType::String, false, true, false);
        let values = field(
            "values",
            "values",
            BindingType::List(Box::new(BindingType::String)),
            false,
            true,
            false,
        );
        let labels = field(
            "labels",
            "labels",
            BindingType::Map(Box::new(BindingType::String)),
            false,
            true,
            false,
        );
        BindingPackage {
            provider: BindingProvider {
                source: "digitalocean/digitalocean".into(),
                version: "2.100.0".into(),
                public_name: "Digitalocean".into(),
                fields: vec![field(
                    "token",
                    "token",
                    BindingType::String,
                    false,
                    true,
                    false,
                )],
            },
            resources: vec![BindingItem {
                provider_type: "digitalocean_tag".into(),
                public_name: "Tag".into(),
                fields: vec![end, id, kube_config, labels, name, node_pool, values],
            }],
            data_sources: vec![BindingItem {
                provider_type: "digitalocean_tag".into(),
                public_name: "Tag".into(),
                fields: vec![field(
                    "name",
                    "name",
                    BindingType::String,
                    true,
                    false,
                    false,
                )],
            }],
        }
    }

    fn core() -> CoreDependency {
        CoreDependency::Path("../..".into())
    }

    #[test]
    #[allow(clippy::too_many_lines)]
    fn emits_a_typed_resource_module() {
        let generated = render_package(&package(), "DigitalOcean", "abc", &core()).unwrap();
        let provider = &generated.files[Path::new("DigitalOcean/Provider.lean")];
        assert!(provider.contains("inductive DigitalOceanProvider"));
        assert!(
            provider.contains(
                "def configure (a : Args) : Infra (Inframe.Provider DigitalOceanProvider)"
            )
        );
        assert!(provider.contains(
            "addProvider (Identifier.mk \"digitalocean\") \"digitalocean/digitalocean\" \"= 2.100.0\" none a.values"
        ));
        assert!(provider.contains("def Args.token (value : Input String) (a : Args) : Args"));

        let source = &generated.files[Path::new("DigitalOcean/Resource/Tag.lean")];
        assert!(source.contains("namespace DigitalOcean.Resource.Tag"));
        assert!(source.contains("inductive TagResource"));
        assert!(source.contains("structure Required where\n  /-- The tag name.\n  Must be unique within the account. -/\n  name : Input String"));
        assert!(source.contains("def create (name : String) (a : Args) (valid : validIdentifier name = true := by decide)"));
        assert!(source.contains(
            "def createWith (name : String) (a : Args) (options : ResourceOptions DigitalOcean.Provider.DigitalOceanProvider)"
        ));
        assert!(source.contains(
            "requireProvider (Identifier.mk \"digitalocean\") \"digitalocean/digitalocean\" \"= 2.100.0\""
        ));
        assert!(source.contains(
            "addResource options (Identifier.mk \"digitalocean_tag\") ⟨name, valid⟩ a.values"
        ));
        assert!(source.contains("      id := resourceAttr handle [\"id\"]"));
        assert!(source.contains(
            "instance : Inframe.Dependable Tag := ⟨fun handle => handle.resource.address⟩"
        ));
        assert!(
            source.contains(
                "instance : Inframe.Managed Tag := ⟨fun handle => handle.resource.address⟩"
            )
        );
        assert!(source.contains("structure Attributes (f o : Type → Type) where"));
        assert!(source.contains(
            "  /-- The provider-assigned tag identifier. -/
  id : f (o String)"
        ));
        assert!(source.contains(
            "structure Tag extends Attributes Input Resolved where
  resource : Resource TagResource"
        ));
        assert!(source.contains("abbrev State := Attributes Resolved Option"));
        assert!(source.contains(
            "def Attributes.ofValue [Marshal f o] (value : Value) : Except String (Attributes f o) := do"
        ));
        assert!(source.contains("id := (← Marshal.optional (f := f) (o := o) value \"id\")"));
        assert!(source.contains(
            "instance [Marshal f o] : FromValue (Attributes f o) := ⟨Attributes.ofValue⟩"
        ));
        assert!(source.contains("instance : ToValue (Attributes Resolved Option) :="));
        assert!(source.contains("(\"node_pool\", toValue attributes.nodePool)"));
        assert!(source.contains("abbrev NodePool := Block \"DigitalOcean.Resource.Tag.NodePool\""));
        assert!(source.contains("abbrev Args := Block \"DigitalOcean.Resource.Tag.Args\""));
        assert!(source.contains("structure NodePoolRequired where\n  name : Input String"));
        assert!(source.contains("def nodePoolArgs (required : NodePoolRequired) : NodePool"));
        assert!(source.contains("/-- Whether automatic scaling is enabled. -/\ndef NodePool.autoScale (value : Input Bool) (block : NodePool) : NodePool"));
        assert!(!source.contains("NodePool.actualNodeCount"));
        assert!(source.contains("nodePool : List NodePool"));
        assert!(source.contains("nodePool : f (List (NodePoolAttributes f o))"));
        assert!(source.contains("structure NodePoolAttributes (f o : Type → Type) where"));
        assert!(source.contains("taint : f (o (List (NodePoolTaintAttributes f o)))"));
        assert!(source.contains(
            "(\"node_pool\", ExprNode.array (required.nodePool.map NodePool.toExprNode))"
        ));
        assert!(source.contains(
            "def NodePool.taint (value : List NodePoolTaint) (block : NodePool) : NodePool"
        ));
        assert!(source.contains(
            "structure KubeConfigAttributes (f o : Type → Type) where\n  rawConfig : f (o String)"
        ));
        assert!(!source.contains("inductive KubeConfig"));
        assert!(source.contains("kubeConfig : f (o (List (KubeConfigAttributes f o)))"));
        assert!(source.contains("def Args.end_ (value : Input String) (a : Args) : Args"));
        assert!(
            source.contains("def Args.values_ (value : Input (List String)) (a : Args) : Args")
        );
        assert!(source.contains("labels : f (o (Map String))"));
        assert!(source.contains("end DigitalOcean.Resource.Tag"));

        let taint_position = source.find("structure NodePoolTaintAttributes").unwrap();
        let pool_position = source.find("structure NodePoolAttributes").unwrap();
        assert!(
            taint_position < pool_position,
            "children are emitted before parents"
        );

        let data = &generated.files[Path::new("DigitalOcean/Data/Tag.lean")];
        assert!(data.contains("def readWith (name : String) (a : Args) (options : DataSourceOptions DigitalOcean.Provider.DigitalOceanProvider)"));
        assert!(data.contains("dataSourceAttr handle [\"name\"]"));
        assert!(data.contains(
            "instance : Inframe.Dependable Tag := ⟨fun handle => handle.dataSource.address⟩"
        ));
        assert!(!data.contains("instance : Inframe.Managed Tag"));

        let root = &generated.files[Path::new("DigitalOcean.lean")];
        assert!(root.contains("import DigitalOcean.Provider\nimport DigitalOcean.Resource.Tag\nimport DigitalOcean.Data.Tag\n"));

        let manifest = &generated.files[Path::new("lake-manifest.json")];
        assert!(manifest.contains("\"dir\": \"../..\""));
        assert!(manifest.contains("\"name\": \"«generated-digitalocean»\""));

        let lakefile = &generated.files[Path::new("lakefile.toml")];
        assert!(lakefile.contains("name = \"generated-digitalocean\""));
        assert!(lakefile.contains("[[require]]\nname = \"inframe\"\npath = \"../..\""));
        assert!(lakefile.contains("globs = [\"DigitalOcean.*\"]"));
        assert_eq!(
            generated.files[Path::new("lean-toolchain")],
            format!("{LEAN_TOOLCHAIN}\n")
        );
    }

    #[test]
    fn identical_nested_shapes_share_one_type() {
        let shape = || {
            BindingType::List(Box::new(BindingType::Object(vec![
                field("key", "key", BindingType::String, true, false, false),
                field("value", "value", BindingType::String, false, true, false),
            ])))
        };
        let mut package = package();
        package.resources[0].fields = vec![
            field("primary", "primary", shape(), true, false, false),
            field("secondary", "secondary", shape(), false, true, false),
            field(
                "different",
                "different",
                BindingType::List(Box::new(BindingType::Object(vec![field(
                    "key",
                    "key",
                    BindingType::Number,
                    true,
                    false,
                    false,
                )]))),
                false,
                true,
                false,
            ),
        ];
        let generated = render_package(&package, "DigitalOcean", "abc", &core()).unwrap();
        let source = &generated.files[Path::new("DigitalOcean/Resource/Tag.lean")];
        assert!(source.contains("abbrev Primary := Block"));
        assert!(source.contains("(shared by 2 block paths with the same shape)"));
        assert!(!source.contains("abbrev Secondary"));
        assert!(source.contains("primary : List Primary"));
        assert!(source.contains("def Args.secondary (value : List Primary) (a : Args) : Args"));
        assert!(source.contains("secondary : f (o (List (PrimaryAttributes f o)))"));
        assert!(source.contains("abbrev Different := Block"));
        assert!(source.contains("def primaryArgs (required : PrimaryRequired) : Primary"));
        assert_eq!(source.matches("def Primary.value ").count(), 1);
    }

    #[test]
    fn git_core_dependency_is_rendered() {
        let generated = render_package(
            &package(),
            "DigitalOcean",
            "abc",
            &CoreDependency::Git {
                url: "https://github.com/by77er/inframe".into(),
                rev: "main".into(),
                sub_dir: Some("lean".into()),
            },
        )
        .unwrap();
        let lakefile = &generated.files[Path::new("lakefile.toml")];
        assert!(lakefile.contains(
            "git = \"https://github.com/by77er/inframe\"\nrev = \"main\"\nsubDir = \"lean\""
        ));
        assert!(
            !generated
                .files
                .contains_key(Path::new("lake-manifest.json"))
        );
    }

    #[test]
    fn output_is_deterministic() {
        let first = render_package(&package(), "DigitalOcean", "abc", &core()).unwrap();
        let second = render_package(&package(), "DigitalOcean", "abc", &core()).unwrap();
        assert_eq!(first, second);
    }

    #[test]
    fn rejects_invalid_module_roots() {
        assert!(render_package(&package(), "digitalOcean", "abc", &core()).is_err());
        assert!(render_package(&package(), "", "abc", &core()).is_err());
    }

    #[test]
    fn doc_delimiters_are_neutralised() {
        assert_eq!(escape_doc("a -/ b /- c"), "a - / b / - c");
        assert_eq!(lake_version("2.100.0"), "2.100.0");
        assert_eq!(lake_version("v2"), "0.0.0");
    }
}
