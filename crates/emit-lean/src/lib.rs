//! Deterministic Lean 4 provider-binding emitter.
//!
//! Renders a language-neutral [`BindingPackage`] into a Lake package whose modules mirror
//! the PureScript adapters: one module per resource and data source, a provider module,
//! argument records with nested block records, and typed symbolic handles. Logical names are
//! validated at compile time through the core library's `Identifier` proofs, and the number
//! of entries a nested block may have is in the record's types (exactly one, at most one) or
//! in a `blocksInRange` obligation the caller discharges by `decide`.

use std::collections::HashSet;
use std::collections::hash_map::{Entry, HashMap};
use std::fmt::{self, Write as _};
use std::path::{Path, PathBuf};

use inframe_binding_model::emit::{self, FileJob, Output, SchemaDigest};
use inframe_binding_model::{
    BindingField, BindingItem, BindingPackage, BindingProvider, BindingType, Fields, object_fields,
    path_count,
};
use rustc_hash::FxBuildHasher;
use serde::Serialize;
use thiserror::Error;

pub use inframe_binding_model::emit::GeneratedPackage;

/// The Lean toolchain pinned by generated packages and by the core library.
pub const LEAN_TOOLCHAIN: &str = "leanprover/lean4:v4.33.1";

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

/// Renders the whole package in memory.
pub fn render_package(
    package: &BindingPackage,
    module_root: &str,
    schema_sha256: &(impl SchemaDigest + ?Sized),
    core: &CoreDependency,
) -> Result<GeneratedPackage, EmitError> {
    let files = package_files(package, module_root, schema_sha256, core)?;
    Ok(GeneratedPackage::render(&files))
}

/// Renders the package straight into `output`, every module streamed to its file and the
/// modules spread over all cores. The files are those of [`render_package`], byte for byte.
pub fn write_package(
    package: &BindingPackage,
    module_root: &str,
    schema_sha256: &(impl SchemaDigest + ?Sized),
    core: &CoreDependency,
    output: &Path,
) -> Result<(), EmitError> {
    let files = package_files(package, module_root, schema_sha256, core)?;
    emit::write_files(files, output)?;
    Ok(())
}

fn package_files<'a, D: SchemaDigest + ?Sized>(
    package: &'a BindingPackage,
    module_root: &'a str,
    schema_sha256: &'a D,
    core: &CoreDependency,
) -> Result<Vec<FileJob<'a>>, EmitError> {
    if !valid_module_root(module_root) {
        return Err(EmitError::InvalidModuleRoot(module_root.to_owned()));
    }
    let mut files = Vec::with_capacity(package.resources.len() + package.data_sources.len() + 7);
    let mut modules = vec![format!("{module_root}.Provider")];
    files.push(FileJob::new(
        module_path(&modules[0]),
        path_count(&package.provider.fields),
        move |out| render_provider(out, package, module_root),
    ));
    for (items, kind, data_source) in [
        (&package.resources, "Resource", false),
        (&package.data_sources, "Data", true),
    ] {
        for item in items {
            let module = format!("{module_root}.{kind}.{}", item.public_name);
            let path = module_path(&module);
            modules.push(module.clone());
            files.push(FileJob::new(path, path_count(&item.fields), move |out| {
                render_item(
                    out,
                    item,
                    &module,
                    module_root,
                    &package.provider,
                    data_source,
                );
            }));
        }
    }
    let mut root = header_comment(&package.provider);
    for module in &modules {
        let _ = writeln!(root, "import {module}");
    }
    files.push(FileJob::text(module_path(module_root), root));
    // Weightless, so it is rendered after the modules, by when the digest is likely ready.
    files.push(FileJob::new("provider-manifest.json", 0, move |out| {
        let manifest = Manifest {
            provider_source: &package.provider.source,
            provider_version: &package.provider.version,
            schema_sha256: &schema_sha256.sha256(),
            generator_version: env!("CARGO_PKG_VERSION"),
            binding_model_version: "1.0",
            graph_ir_version: "1.0",
            lean_toolchain: LEAN_TOOLCHAIN,
        };
        let mut manifest =
            serde_json::to_string_pretty(&manifest).expect("a manifest of strings serializes");
        manifest.push('\n');
        out.push_str(&manifest);
    }));
    files.push(FileJob::text(
        "README.md",
        format!(
            "# {module_root}\n\nGenerated Lean 4 bindings for `{}` `{}`. Do not edit by hand.\n",
            package.provider.source, package.provider.version
        ),
    ));
    files.push(FileJob::text(
        "lean-toolchain",
        format!("{LEAN_TOOLCHAIN}\n"),
    ));
    files.push(FileJob::text(
        "lakefile.toml",
        render_lakefile(package, module_root, core),
    ));
    if let CoreDependency::Path(path) = core {
        files.push(FileJob::text(
            "lake-manifest.json",
            render_manifest(&package.provider, path),
        ));
    }
    Ok(files)
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

fn render_provider(out: &mut Output<'_>, package: &BindingPackage, module_root: &str) {
    let provider = &package.provider;
    let fields = &provider.fields;
    let marker = provider_marker(module_root);
    out.push_str(&header_comment(provider));
    let _ = write!(
        out,
        "import Inframe\n\nnamespace {module_root}.Provider\n\nopen Inframe\n\n"
    );
    let _ = write!(
        out,
        "/-- Phantom type tagging handles to configured `{}` providers. -/\ninductive {marker}\n\n",
        provider.source
    );
    let shapes = Shapes::collect(fields, &[&marker]);
    let mut ranged = HashSet::new();
    render_shapes(out, &shapes, &mut ranged);
    render_args_structure(
        out,
        "Args",
        ROOT,
        fields,
        &format!("Arguments for the `{}` provider.", provider.source),
        &shapes,
        &mut ranged,
    );
    let obligation = block_obligation(&ranged);
    let local_name = provider_local_name_from_source(&provider.source);
    let version = format!("= {}", provider.version);
    let _ = write!(
        out,
        "/-- Configure the default `{local_name}` provider. -/\n\
         def configure (a : Args){} : Infra (Inframe.Provider {marker}) :=\n  \
           addProvider (Identifier.mk \"{local_name}\") \"{}\" \"{version}\" none a.toInputObject\n\n\
         /-- Configure an aliased `{local_name}` provider. The alias is validated at compile time. -/\n\
         def configureAs (alias : String) (a : Args) (valid : validIdentifier alias = true := by valid_identifier){} :\n    \
           Infra (Inframe.Provider {marker}) :=\n  \
           addProvider (Identifier.mk \"{local_name}\") \"{}\" \"{version}\" (some ⟨alias, valid⟩) a.toInputObject\n\n\
         end {module_root}.Provider\n",
        obligation.consumed,
        Escaped(&provider.source),
        obligation.consumed,
        Escaped(&provider.source)
    );
}

/// The extra parameter of a builder whose `Args` carry a `blocksInRange` obligation: a record
/// whose block lists have literal length discharges it automatically (`blocks_in_range`), a
/// record built from run-time lists needs the caller's proof. `forwarded` names the proof so
/// the convenience builder can pass it on with `discharge`; `consumed` is for the builder that
/// only demands it.
struct BlockObligation {
    forwarded: &'static str,
    consumed: &'static str,
    discharge: &'static str,
}

fn block_obligation(ranged: &HashSet<String>) -> BlockObligation {
    if ranged.contains("Args") {
        BlockObligation {
            forwarded: "\n    (blocks : a.blocksInRange = true := by blocks_in_range)",
            consumed: "\n    (_blocks : a.blocksInRange = true := by blocks_in_range)",
            discharge: " blocks",
        }
    } else {
        BlockObligation {
            forwarded: "",
            consumed: "",
            discharge: "",
        }
    }
}

#[allow(clippy::too_many_lines)]
fn render_item(
    out: &mut Output<'_>,
    item: &BindingItem,
    module: &str,
    module_root: &str,
    provider: &BindingProvider,
    data_source: bool,
) {
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
    out.push_str(&header_comment(provider));
    let _ = write!(
        out,
        "import Inframe\nimport {module_root}.Provider\n\nnamespace {module}\n\nopen Inframe\n\n"
    );
    let _ = write!(
        out,
        "/-- Phantom type tagging handles to `{}` {kind}s. -/\ninductive {node}\n\n",
        item.provider_type
    );
    let shapes = Shapes::collect(&item.fields, &[&handle_name, &node]);
    let mut ranged = HashSet::new();
    render_shapes(out, &shapes, &mut ranged);
    render_args_structure(
        out,
        "Args",
        ROOT,
        &item.fields,
        &format!("Arguments for `{}`.", item.provider_type),
        &shapes,
        &mut ranged,
    );
    let obligation = block_obligation(&ranged);
    let handle_fields = &item.fields;
    let handle_reserved: &[&str] = if data_source {
        &["dataSource"]
    } else {
        &["resource"]
    };
    render_attributes(
        out,
        "Attributes",
        "names",
        ROOT,
        handle_fields,
        handle_reserved,
        &format!(
            "The attributes of `{}`, held in `f`, with non-required attributes wrapped in `o`: \
             `Attributes Input Resolved` is the symbolic handle, `Attributes Resolved Option` \
             the resolved state, `Attributes Option Resolved` a fully optional view.",
            item.provider_type
        ),
        &shapes,
    );
    let _ = write!(
        out,
        "/-- A symbolic handle to `{}`. Every attribute is a symbolic input resolved by OpenTofu. -/\nstructure {handle_name} extends Attributes Input Resolved where\n",
        item.provider_type
    );
    if data_source {
        let _ = writeln!(out, "  dataSource : DataSource {node}\n");
    } else {
        let _ = writeln!(out, "  resource : Resource {node}\n");
    }
    let _ = write!(
        out,
        "/-- The resolved attributes of `{}`, decoded from `tofu show -json` with\n`ShowDocument.decode?`: required attributes are plain values, the rest `Option`. -/\nabbrev State := Attributes Resolved Option\n\n\
         /-- Every attribute optional. -/\nabbrev Partial := Attributes Option Resolved\n\n",
        item.provider_type
    );
    // Fully qualified: a nested block named `managed` or `dependable` would otherwise shadow
    // the core class inside this namespace.
    if data_source {
        let _ = write!(
            out,
            "instance : Inframe.Dependable {handle_name} := ⟨fun handle => handle.dataSource.address⟩\n\n"
        );
    } else {
        let _ = write!(
            out,
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
        out,
        "/-- Add `{}.<name>` to the graph with explicit options. The logical name is validated at\ncompile time. -/\n\
         def {operation_with} (name : String) (a : Args) (options : {options_type} {module_root}.Provider.{marker})\n    \
           (valid : validIdentifier name = true := by valid_identifier){} : Infra {handle_name} := do\n  \
           requireProvider (Identifier.mk \"{local_name}\") \"{}\" \"= {}\"\n  \
           let handle ← {add} options (Identifier.mk \"{}\") ⟨name, valid⟩ a.toInputObject\n  \
           pure\n    {{ {handle_key} := handle",
        item.provider_type,
        obligation.consumed,
        Escaped(&provider.source),
        Escaped(&provider.version),
        item.provider_type
    );
    for field in handle_fields.iter() {
        let _ = write!(
            out,
            "\n      {} := {attr} handle [\"{}\"]",
            safe_field_name(field, handle_reserved),
            Escaped(&field.provider_name)
        );
    }
    let _ = write!(
        out,
        " }}\n\n\
         /-- Add `{}.<name>` to the graph with default options. -/\n\
         def {operation} (name : String) (a : Args) (valid : validIdentifier name = true := by valid_identifier){} :\n    \
           Infra {handle_name} :=\n  \
           {operation_with} name a {default_options} valid{}\n\n\
         end {module}\n",
        item.provider_type, obligation.forwarded, obligation.discharge
    );
}

/// Names that would clash with generated members of an argument record.
const ARGS_RESERVED: &[&str] = &["mk", "toInputObject", "toExprNode"];

/// Whether a field is an argument (required or optional) rather than computed-only.
fn is_input(field: &BindingField) -> bool {
    field.required || field.optional
}

/// One record per argument shape: required attributes are plain fields, optional ones default
/// to unset, nested blocks are nested records held according to how many the schema allows
/// (one, `Option`, or `List`). `toInputObject` emits only what was set, so an untouched
/// optional field never reaches the graph. When a block list has a lower or upper bound, or a
/// nested record has one, the record also gets `blocksInRange`, and `ranged` records the
/// record names that have it so that parents and builders can require it.
fn render_args_structure(
    out: &mut Output<'_>,
    name: &str,
    parent: PathNode,
    fields: &[BindingField],
    doc: &str,
    shapes: &Shapes<'_>,
    ranged: &mut HashSet<String>,
) {
    let inputs = || fields.iter().filter(|field| is_input(field));
    write_doc_comment(out, doc, "");
    let _ = writeln!(out, "structure {name} where");
    for field in inputs() {
        write_field_documentation(out, field, "  ");
        let _ = write!(out, "  {} : ", safe_field_name(field, ARGS_RESERVED));
        render_args_field_type(out, field, parent, shapes);
        out.push('\n');
    }
    let has_inputs = inputs().next().is_some();
    // A record with no inputs never reads its argument; `_a` keeps the generated code lint-clean.
    let binder = if has_inputs { "a" } else { "_a" };
    let _ = write!(
        out,
        "\ndef {name}.toInputObject ({binder} : {name}) : InputObject :=\n  ⟨List.filterMap (fun entry => entry) ([",
    );
    for (index, field) in inputs().enumerate() {
        out.push_str(if index == 0 { " " } else { "\n    , " });
        render_args_field_entry(out, field, parent, shapes);
    }
    if has_inputs {
        out.push(' ');
    }
    let _ = write!(
        out,
        "] : List (Option (String × ExprNode)))⟩\n\n\
         def {name}.toExprNode (a : {name}) : ExprNode :=\n  a.toInputObject.toExprNode\n\n"
    );
    let constraints: Vec<_> = inputs()
        .flat_map(|field| block_constraints(field, parent, shapes, ranged))
        .collect();
    if !constraints.is_empty() {
        ranged.insert(name.to_owned());
        let (descriptions, checks): (Vec<_>, Vec<_>) = constraints.into_iter().unzip();
        let _ = write!(
            out,
            "/-- Whether the nested blocks hold as many entries as the provider schema allows: {}. \
             Builders taking this record require it; a record whose block lists have literal \
             length discharges it automatically. -/\n\
             def {name}.blocksInRange (a : {name}) : Bool :=\n  {}\n\n",
            descriptions.join(", "),
            checks.join(" && ")
        );
    }
}

/// How many entries a nested block list may hold, from the provider schema.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Multiplicity {
    /// Exactly one: the block is a single record field.
    One,
    /// At most one: the block is an `Option` field.
    AtMostOne,
    /// Any number within the bounds: a `List`, with each bound a proof obligation.
    Many { min: Option<u64>, max: Option<u64> },
}

fn multiplicity(field: &BindingField) -> Multiplicity {
    match field.max_items {
        Some(1) if field.required => Multiplicity::One,
        Some(1) => Multiplicity::AtMostOne,
        max => Multiplicity::Many {
            min: field.min_items,
            max,
        },
    }
}

/// The `(description, Lean check)` pairs one field contributes to its record's
/// `blocksInRange`: its own list bounds, and its nested record's obligation when it has one.
fn block_constraints(
    field: &BindingField,
    parent: PathNode,
    shapes: &Shapes<'_>,
    ranged: &HashSet<String>,
) -> Vec<(String, String)> {
    let Some(container) = nested_container(&field.r#type) else {
        return Vec::new();
    };
    let field_name = safe_field_name(field, ARGS_RESERVED);
    let record = format!("{}Args", shapes.name(parent, field));
    let mut constraints = Vec::new();
    let multiplicity = multiplicity(field);
    if let (NestedContainer::Array, Multiplicity::Many { min, max }) = (container, multiplicity) {
        if let Some(min) = min {
            constraints.push((
                format!("`{}` at least {min}", field.provider_name),
                format!("{min} ≤ a.{field_name}.length"),
            ));
        }
        if let Some(max) = max {
            constraints.push((
                format!("`{}` at most {max}", field.provider_name),
                format!("a.{field_name}.length ≤ {max}"),
            ));
        }
    }
    if ranged.contains(&record) {
        let check = match (container, field.required, multiplicity) {
            (NestedContainer::Single, true, _) | (NestedContainer::Array, _, Multiplicity::One) => {
                format!("{record}.blocksInRange a.{field_name}")
            }
            (NestedContainer::Array, false, Multiplicity::Many { .. }) if nullable_list(field) => {
                format!("a.{field_name}.all fun items => items.all {record}.blocksInRange")
            }
            (NestedContainer::Single, false, _) | (NestedContainer::Array, _, _) => {
                format!("a.{field_name}.all {record}.blocksInRange")
            }
            (NestedContainer::Map, false, _) if nullable_list(field) => format!(
                "a.{field_name}.all fun entries => entries.all fun (_, block) => {record}.blocksInRange block"
            ),
            (NestedContainer::Map, _, _) => {
                format!("a.{field_name}.all fun (_, block) => {record}.blocksInRange block")
            }
        };
        constraints.push((format!("`{}` entries in range", field.provider_name), check));
    }
    constraints
}

/// Whether an optional nested list or map is a plugin-framework *attribute* rather than a
/// legacy block. For a block, "no entries" and "unset" are the same configuration, so an
/// empty list is simply not written. For a nested attribute they differ: `null` leaves the
/// attribute unset (a computed one is then filled in by the provider), `[]` asserts that it
/// is empty, and a provider that reads an absent list back as `[]` plans a change forever if
/// the configuration keeps saying `null`. The field is therefore `Option (List …)`: `none`
/// is unset, `some []` is empty.
fn nullable_list(field: &BindingField) -> bool {
    !field.block && !field.required
}

/// The field type in an argument record, with the default for optional fields.
fn render_args_field_type(
    out: &mut Output<'_>,
    field: &BindingField,
    parent: PathNode,
    shapes: &Shapes<'_>,
) {
    let Some(container) = nested_container(&field.r#type) else {
        out.push_str(if field.required {
            "Input "
        } else {
            "Option (Input "
        });
        render_type_argument(out, &field.r#type, parent, field, shapes);
        if !field.required {
            out.push_str(") := none");
        }
        return;
    };
    let record = shapes.name(parent, field);
    let _ = match (container, field.required) {
        (NestedContainer::Single, true) => write!(out, "{record}Args"),
        (NestedContainer::Single, false) => write!(out, "Option {record}Args := none"),
        (NestedContainer::Array, required) => match multiplicity(field) {
            Multiplicity::One => write!(out, "{record}Args"),
            Multiplicity::AtMostOne => write!(out, "Option {record}Args := none"),
            Multiplicity::Many { .. } if required => write!(out, "List {record}Args"),
            Multiplicity::Many { .. } if nullable_list(field) => {
                write!(out, "Option (List {record}Args) := none")
            }
            Multiplicity::Many { .. } => write!(out, "List {record}Args := []"),
        },
        (NestedContainer::Map, true) => write!(out, "List (String × {record}Args)"),
        (NestedContainer::Map, false) if nullable_list(field) => {
            write!(out, "Option (List (String × {record}Args)) := none")
        }
        (NestedContainer::Map, false) => write!(out, "List (String × {record}Args) := []"),
    };
}

/// The `Option (String × ExprNode)` entry a record field contributes to the input object.
fn render_args_field_entry(
    out: &mut Output<'_>,
    field: &BindingField,
    parent: PathNode,
    shapes: &Shapes<'_>,
) {
    let key = Escaped(&field.provider_name);
    let field_name = safe_field_name(field, ARGS_RESERVED);
    let Some(container) = nested_container(&field.r#type) else {
        let _ = if field.required {
            write!(out, "some (\"{key}\", inputNode a.{field_name})")
        } else {
            write!(
                out,
                "a.{field_name}.map fun value => (\"{key}\", inputNode value)"
            )
        };
        return;
    };
    let record = shapes.name(parent, field);
    let array = format_args!("ExprNode.array (a.{field_name}.map {record}Args.toExprNode)");
    let map = format_args!(
        "ExprNode.object (a.{field_name}.map fun (key, block) => (key, {record}Args.toExprNode block))"
    );
    let _ = match (container, field.required) {
        (NestedContainer::Single, true) => {
            write!(out, "some (\"{key}\", a.{field_name}.toExprNode)")
        }
        (NestedContainer::Single, false) => write!(
            out,
            "a.{field_name}.map fun block => (\"{key}\", block.toExprNode)"
        ),
        (NestedContainer::Array, required) => match multiplicity(field) {
            Multiplicity::One => write!(
                out,
                "some (\"{key}\", ExprNode.array [a.{field_name}.toExprNode])"
            ),
            Multiplicity::AtMostOne => write!(
                out,
                "a.{field_name}.map fun block => (\"{key}\", ExprNode.array [block.toExprNode])"
            ),
            Multiplicity::Many { .. } if required => write!(out, "some (\"{key}\", {array})"),
            Multiplicity::Many { .. } if nullable_list(field) => write!(
                out,
                "a.{field_name}.map fun items => (\"{key}\", ExprNode.array (items.map {record}Args.toExprNode))"
            ),
            Multiplicity::Many { .. } => write!(
                out,
                "if a.{field_name}.isEmpty then none else some (\"{key}\", {array})"
            ),
        },
        (NestedContainer::Map, true) => write!(out, "some (\"{key}\", {map})"),
        (NestedContainer::Map, false) if nullable_list(field) => write!(
            out,
            "a.{field_name}.map fun entries => (\"{key}\", ExprNode.object (entries.map fun (key, block) => (key, {record}Args.toExprNode block)))"
        ),
        (NestedContainer::Map, false) => write!(
            out,
            "if a.{field_name}.isEmpty then none else some (\"{key}\", {map})"
        ),
    };
}

/// A nested object type that gets its own Lean declaration: a builder for an input block or
/// a phantom marker for a computed-only shape.
#[derive(Debug)]
struct NestedType<'a> {
    /// The first path at which this shape occurs; it names the type.
    path: Vec<&'a str>,
    /// That path's node, under which the shape's own fields are looked up.
    node: PathNode,
    name: String,
    fields: &'a Fields,
    builder: bool,
    /// How many paths share this shape.
    occurrences: usize,
}

/// A path from the item's top level, as a node of [`Shapes`]' path trie.
type PathNode = u32;

/// The item's top level.
const ROOT: PathNode = 0;

/// The nested types of one module with structural sharing. Provider schemas unroll recursive
/// blocks to a fixed depth, so a resource can contain thousands of nested paths but only a few
/// dozen distinct shapes (`aws_wafv2_web_acl_rule`: 21,025 paths, 73 shapes). Every path maps
/// to the type of the first path with the same field list, so the generated module declares
/// each shape once. Children are emitted before their parents so that a parent's setters can
/// refer to the child's `toExprNode`.
///
/// Shapes are keyed by their interned field list, whose hash is cached and whose equality is a
/// pointer comparison, and paths are kept as a trie of `(parent, field name)` edges, so
/// collecting a resource costs one hash lookup per path.
#[derive(Debug)]
struct Shapes<'a> {
    entries: Vec<NestedType<'a>>,
    /// Entry indices by builder flag and field list.
    by_fields: HashMap<(bool, &'a Fields), usize, FxBuildHasher>,
    /// Trie edges: the child node of `parent` reached through a field's public name.
    children: HashMap<(PathNode, &'a str), PathNode, FxBuildHasher>,
    /// For every trie node, the shape last declared at it (none for the root).
    declared: Vec<Option<usize>>,
}

impl<'a> Shapes<'a> {
    fn collect(fields: &'a Fields, reserved: &[&str]) -> Self {
        let mut shapes = Self {
            entries: Vec::new(),
            by_fields: HashMap::default(),
            children: HashMap::default(),
            declared: vec![None],
        };
        let mut path = Vec::new();
        for field in fields.iter() {
            shapes.visit(field, ROOT, &mut path, true, reserved);
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
        parent: PathNode,
        path: &mut Vec<&'a str>,
        parent_builder: bool,
        reserved: &[&str],
    ) {
        let Some(fields) = object_fields(&field.r#type) else {
            return;
        };
        let builder =
            parent_builder && is_input(field) && nested_container(&field.r#type).is_some();
        let node = self.child(parent, &field.public_name);
        path.push(&field.public_name);
        for child in fields.iter() {
            self.visit(child, node, path, builder, reserved);
        }
        let shape = match self.by_fields.entry((builder, fields)) {
            Entry::Occupied(entry) => {
                let index = *entry.get();
                self.entries[index].occurrences += 1;
                index
            }
            Entry::Vacant(entry) => {
                let index = self.entries.len();
                entry.insert(index);
                self.entries.push(NestedType {
                    path: path.clone(),
                    node,
                    name: nested_type_name(path, reserved),
                    fields,
                    builder,
                    occurrences: 1,
                });
                index
            }
        };
        self.declared[node as usize] = Some(shape);
        path.pop();
    }

    fn child(&mut self, parent: PathNode, segment: &'a str) -> PathNode {
        let next = PathNode::try_from(self.declared.len()).expect("fewer than 2^32 paths");
        let node = *self.children.entry((parent, segment)).or_insert(next);
        if node == next {
            self.declared.push(None);
        }
        node
    }

    /// The Lean type standing for the object shape of `field`, a field of the record at
    /// `parent`. Every object-typed field below the item was visited by [`Shapes::collect`].
    fn name(&self, parent: PathNode, field: &BindingField) -> &str {
        let index = self
            .children
            .get(&(parent, field.public_name.as_ref()))
            .and_then(|&node| self.declared[node as usize])
            .expect("object shapes are collected before they are rendered");
        &self.entries[index].name
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

fn render_shapes(out: &mut Output<'_>, shapes: &Shapes<'_>, ranged: &mut HashSet<String>) {
    for nested in &shapes.entries {
        let path = nested.path.join(".");
        let note = shared_note(nested.occurrences);
        render_attributes(
            out,
            &format!("{}Attributes", nested.name),
            &format!("{}Attributes.names", nested.name),
            nested.node,
            nested.fields,
            &[],
            &format!("The attributes of the `{path}` block{note}, held in `f`."),
            shapes,
        );
        if nested.builder {
            render_args_structure(
                out,
                &format!("{}Args", nested.name),
                nested.node,
                nested.fields,
                &format!("Arguments for the `{path}` block{note}."),
                shapes,
                ranged,
            );
        }
    }
}

/// Only required attributes and blocks are guaranteed present in state; everything else,
/// including an unset optional block, may be `null`, so its type is wrapped in the
/// optionality container `o`.
fn always_present(field: &BindingField) -> bool {
    field.required
}

/// A higher-kinded attribute structure plus its decoder (for any `Marshal f o`), its encoder
/// at resolved state, so state round-trips through `Value`, and `names_name`: the same
/// structure instantiated at `fun _ => String`, holding each attribute's provider name.
#[allow(clippy::too_many_arguments)]
fn render_attributes(
    out: &mut Output<'_>,
    name: &str,
    names_name: &str,
    parent: PathNode,
    fields: &[BindingField],
    reserved: &[&str],
    doc: &str,
    shapes: &Shapes<'_>,
) {
    write_doc_comment(out, doc, "");
    let _ = writeln!(out, "structure {name} (f o : Type → Type) where");
    for field in fields {
        write_field_documentation(out, field, "  ");
        let _ = write!(out, "  {} : f ", safe_field_name(field, reserved));
        if always_present(field) {
            render_hkd_type_argument(out, &field.r#type, parent, field, shapes);
        } else {
            out.push_str("(o ");
            render_hkd_type_argument(out, &field.r#type, parent, field, shapes);
            out.push(')');
        }
        out.push('\n');
    }
    // Lean's structure-instance parser wants newline-separated fields aligned in one column.
    let _ = write!(
        out,
        "\ndef {name}.ofValue [Marshal f o] ({} : Value) : Except String ({name} f o) := do\n  pure",
        if fields.is_empty() { "_value" } else { "value" }
    );
    if fields.is_empty() {
        out.push_str(" {}\n\n");
    } else {
        out.push_str("\n    {");
        for (index, field) in fields.iter().enumerate() {
            let separator = if index == 0 { " " } else { "\n      " };
            let _ = write!(
                out,
                "{separator}{} := (← Marshal.{} (f := f) (o := o) value \"{}\")",
                safe_field_name(field, reserved),
                if always_present(field) {
                    "required"
                } else {
                    "optional"
                },
                Escaped(&field.provider_name)
            );
        }
        out.push_str(" }\n\n");
    }
    let _ = write!(
        out,
        "instance [Marshal f o] : FromValue ({name} f o) := ⟨{name}.ofValue⟩\n\n\
         instance : ToValue ({name} Resolved Option) :=\n  ⟨fun {} => .object\n    [",
        if fields.is_empty() { "_" } else { "attributes" }
    );
    for (index, field) in fields.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n    , " };
        let _ = write!(
            out,
            "{separator}(\"{}\", toValue attributes.{})",
            Escaped(&field.provider_name),
            safe_field_name(field, reserved)
        );
    }
    out.push_str(" ]⟩\n\n");
    // Attribute names as a record shaped like the attributes: `names.nodePool = "node_pool"`.
    // Policies (`resource.argument? names.size`) and `ignoreChanges [names.nodeCount]` then name
    // attributes through the generated record, so a schema rename is a compile error rather
    // than a silently unmatched string.
    let _ = write!(
        out,
        "/-- The provider-side name of every attribute, as a record shaped like the attributes \
         themselves, so policies and `ignoreChanges` never spell provider names as raw strings. \
         `@[simp]` so that proofs by `simp` see the strings behind the record. -/\n\
         @[simp] def {names_name} : {name} (fun _ => String) (fun _ => String) :=\n  "
    );
    if fields.is_empty() {
        out.push_str("{}\n\n");
    } else {
        out.push('{');
        for (index, field) in fields.iter().enumerate() {
            let separator = if index == 0 { " " } else { "\n    " };
            let _ = write!(
                out,
                "{separator}{} := \"{}\"",
                safe_field_name(field, reserved),
                Escaped(&field.provider_name)
            );
        }
        out.push_str(" }\n\n");
    }
    render_symbolic_fields(out, name, fields, reserved);
}

/// The same structure read off a symbolic value of it: an element of a computed list
/// (`cluster.nodePool[0].fields.nodes`) or a splat (`cluster.nodePool.splat (·.name)`) is
/// traversed with the schema's types rather than through `Input.field` and a claimed type.
fn render_symbolic_fields(
    out: &mut Output<'_>,
    name: &str,
    fields: &[BindingField],
    reserved: &[&str],
) {
    let _ = write!(
        out,
        "/-- The typed attributes of a symbolic `{name}` value, behind `Input.fields`: \
         `value.fields.<attribute>` for an element of a computed list, and the projection \
         `Input.splat` maps over every element. -/\n\
         def {name}.ofInput ({} : Input ({name} Input Resolved)) : {name} Input Resolved :=\n  ",
        if fields.is_empty() { "_value" } else { "value" }
    );
    if fields.is_empty() {
        out.push_str("{}\n\n");
    } else {
        out.push('{');
        for (index, field) in fields.iter().enumerate() {
            let separator = if index == 0 { " " } else { "\n    " };
            let _ = write!(
                out,
                "{separator}{} := value.schemaField \"{}\"",
                safe_field_name(field, reserved),
                Escaped(&field.provider_name)
            );
        }
        out.push_str(" }\n\n");
    }
    let _ = write!(
        out,
        "instance : Inframe.SymbolicFields ({name} Input Resolved) := ⟨{name}.ofInput⟩\n\n"
    );
}

/// The phantom type of an input or attribute: nested objects are their attribute structure at
/// the handle instantiation, so a handle and its arguments agree on names. `field` (a field of
/// the record at `parent`) names the object shape, whatever collections it sits in.
fn render_type(
    out: &mut Output<'_>,
    r#type: &BindingType,
    parent: PathNode,
    field: &BindingField,
    shapes: &Shapes<'_>,
) {
    match r#type {
        BindingType::String => out.push_str("String"),
        BindingType::Bool => out.push_str("Bool"),
        BindingType::Number => out.push_str("Number"),
        BindingType::List(item) | BindingType::Set(item) => {
            out.push_str("List ");
            render_type_argument(out, item, parent, field, shapes);
        }
        BindingType::Map(item) => {
            out.push_str("Map ");
            render_type_argument(out, item, parent, field, shapes);
        }
        BindingType::Tuple(_) | BindingType::Dynamic => out.push_str("Value"),
        BindingType::Object(_) => {
            let _ = write!(
                out,
                "{}Attributes Input Resolved",
                shapes.name(parent, field)
            );
        }
    }
}

/// The type of an attribute inside a higher-kinded `Attributes f`: nested objects are their
/// own `…Attributes f`, so instantiating `f` instantiates the whole tree.
fn render_hkd_type(
    out: &mut Output<'_>,
    r#type: &BindingType,
    parent: PathNode,
    field: &BindingField,
    shapes: &Shapes<'_>,
) {
    match r#type {
        BindingType::String => out.push_str("String"),
        BindingType::Bool => out.push_str("Bool"),
        BindingType::Number => out.push_str("Number"),
        BindingType::List(item) | BindingType::Set(item) => {
            out.push_str("List ");
            render_hkd_type_argument(out, item, parent, field, shapes);
        }
        BindingType::Map(item) => {
            out.push_str("Map ");
            render_hkd_type_argument(out, item, parent, field, shapes);
        }
        BindingType::Tuple(_) | BindingType::Dynamic => out.push_str("Value"),
        BindingType::Object(_) => {
            let _ = write!(out, "{}Attributes f o", shapes.name(parent, field));
        }
    }
}

/// Whether a type needs parentheses as an argument.
fn compound(r#type: &BindingType) -> bool {
    matches!(
        r#type,
        BindingType::List(_) | BindingType::Set(_) | BindingType::Map(_) | BindingType::Object(_)
    )
}

fn render_hkd_type_argument(
    out: &mut Output<'_>,
    r#type: &BindingType,
    parent: PathNode,
    field: &BindingField,
    shapes: &Shapes<'_>,
) {
    if compound(r#type) {
        out.push('(');
        render_hkd_type(out, r#type, parent, field, shapes);
        out.push(')');
    } else {
        render_hkd_type(out, r#type, parent, field, shapes);
    }
}

fn render_type_argument(
    out: &mut Output<'_>,
    r#type: &BindingType,
    parent: PathNode,
    field: &BindingField,
    shapes: &Shapes<'_>,
) {
    if compound(r#type) {
        out.push('(');
        render_type(out, r#type, parent, field, shapes);
        out.push(')');
    } else {
        render_type(out, r#type, parent, field, shapes);
    }
}

fn shared_note(occurrences: usize) -> String {
    if occurrences > 1 {
        format!(" (shared by {occurrences} block paths with the same shape)")
    } else {
        String::new()
    }
}

fn nested_type_name(path: &[&str], reserved: &[&str]) -> String {
    let mut name = String::new();
    for part in path {
        inframe_binding_model::push_capitalized(&mut name, part);
    }
    safe_type_name(name, reserved, "Block")
}

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

fn safe_type_name(mut name: String, reserved: &[&str], suffix: &str) -> String {
    if RESERVED_TYPE_NAMES.contains(&name.as_str()) || reserved.contains(&name.as_str()) {
        name.push_str(suffix);
    }
    name
}

fn safe_handle_name(name: &str, node: &str) -> String {
    safe_type_name(name.to_owned(), &[node], "Handle")
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

/// A field's Lean name: its public name, with `_` appended when that is a keyword, one of
/// `reserved`, or starts with a digit.
struct SafeFieldName<'a> {
    name: &'a str,
    suffixed: bool,
}

impl fmt::Display for SafeFieldName<'_> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.name)?;
        if self.suffixed {
            formatter.write_str("_")?;
        }
        Ok(())
    }
}

fn safe_field_name<'a>(field: &'a BindingField, reserved: &[&str]) -> SafeFieldName<'a> {
    let name: &str = &field.public_name;
    SafeFieldName {
        name,
        suffixed: lean_reserved(name)
            || reserved.contains(&name)
            || name.starts_with(|c: char| c.is_ascii_digit()),
    }
}

/// A string as the body of a Lean string literal.
struct Escaped<'a>(&'a str);

impl fmt::Display for Escaped<'_> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let mut rest = self.0;
        while let Some(index) = rest.find(['\\', '"', '\n', '\r', '\t']) {
            formatter.write_str(&rest[..index])?;
            formatter.write_str(match rest.as_bytes()[index] {
                b'\\' => "\\\\",
                b'"' => "\\\"",
                b'\n' => "\\n",
                b'\r' => "\\r",
                _ => "\\t",
            })?;
            rest = &rest[index + 1..];
        }
        formatter.write_str(rest)
    }
}

/// Lean block comments nest, so both delimiters must be neutralised inside doc text.
fn escape_doc(value: &str) -> String {
    value.replace("-/", "- /").replace("/-", "/ -")
}

fn first_line(description: &str) -> String {
    escape_doc(description.lines().next().unwrap_or_default().trim_end())
}

/// A `/-- … -/` comment holding `text`, every line prefixed with `indent`; nothing when the
/// text is blank.
fn write_doc_comment(out: &mut Output<'_>, text: &str, indent: &str) {
    let text = text.trim();
    if text.is_empty() {
        return;
    }
    let mut lines = text.lines().map(str::trim_end);
    out.push_str(indent);
    out.push_str("/-- ");
    out.push_str(lines.next().unwrap_or_default());
    for line in lines {
        out.push('\n');
        out.push_str(indent);
        out.push_str(line);
    }
    out.push_str(" -/\n");
}

fn has_description(field: &BindingField) -> bool {
    field
        .description
        .as_deref()
        .is_some_and(|description| !description.trim().is_empty())
}

/// The description of a field followed by the descriptions of its direct nested fields, so
/// that hovers on a block-typed field explain the block's contents. Only one level is listed:
/// provider schemas unroll recursive blocks to a fixed depth (AWS WAF rules reach 21,000
/// nested paths), and listing whole subtrees made the documentation quadratic in that size.
fn write_field_documentation(out: &mut Output<'_>, field: &BindingField, indent: &str) {
    let children = object_fields(&field.r#type).map_or(&[][..], |fields| &fields[..]);
    if !has_description(field) && !children.iter().any(has_description) {
        return;
    }
    let mut text = field
        .description
        .as_deref()
        .map(str::trim)
        .filter(|description| !description.is_empty())
        .map(escape_doc)
        .unwrap_or_default();
    if children.iter().any(has_description) {
        if !text.is_empty() {
            text.push('\n');
        }
        for child in children {
            if let Some(description) = child
                .description
                .as_deref()
                .map(str::trim)
                .filter(|description| !description.is_empty())
            {
                let _ = write!(
                    text,
                    "\n- `{}`: {}",
                    child.public_name,
                    first_line(description)
                );
            }
        }
    }
    write_doc_comment(out, &text, indent);
}

#[cfg(test)]
mod tests {
    use inframe_binding_model::{BindingProvider, BindingType};

    use super::*;

    fn object(fields: Vec<BindingField>) -> BindingType {
        BindingType::Object(fields.into())
    }

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
            min_items: None,
            max_items: None,
        }
    }

    /// A nested block with the given entry bounds.
    fn block(
        name: &str,
        fields: Vec<BindingField>,
        min_items: Option<u64>,
        max_items: Option<u64>,
    ) -> BindingField {
        let required = min_items.is_some_and(|minimum| minimum > 0);
        BindingField {
            block: true,
            min_items: min_items.filter(|minimum| *minimum > 0),
            max_items,
            ..field(
                name,
                &inframe_binding_model::field_name(name),
                BindingType::List(Box::new(object(fields))),
                required,
                !required,
                false,
            )
        }
    }

    #[test]
    fn block_cardinality_shapes_the_argument_record() {
        let mut bounded = package();
        let entry = || {
            vec![field(
                "value",
                "value",
                BindingType::String,
                true,
                false,
                false,
            )]
        };
        bounded.resources[0].fields = vec![
            field("name", "name", BindingType::String, true, false, false),
            block("exactly_one", entry(), Some(1), Some(1)),
            block("at_most_one", entry(), None, Some(1)),
            block("at_least_one", entry(), Some(1), None),
            block("bounded", entry(), Some(1), Some(3)),
            block("unbounded", entry(), None, None),
            // A block whose own list is unbounded but whose entries carry an obligation.
            block(
                "outer",
                vec![block("inner", entry(), Some(2), None)],
                None,
                Some(1),
            ),
        ]
        .into();
        let generated = render_package(&bounded, "DigitalOcean", "abc", &core()).unwrap();
        let source = &generated.files[Path::new("DigitalOcean/Resource/Tag.lean")];
        assert!(source.contains("  exactlyOne : ExactlyOneArgs\n"));
        assert!(source.contains("  atMostOne : Option ExactlyOneArgs := none\n"));
        assert!(source.contains("  atLeastOne : List ExactlyOneArgs\n"));
        assert!(source.contains("  bounded : List ExactlyOneArgs\n"));
        assert!(source.contains("  unbounded : List ExactlyOneArgs := []\n"));
        assert!(
            source.contains("some (\"exactly_one\", ExprNode.array [a.exactlyOne.toExprNode])")
        );
        assert!(source.contains(
            "a.atMostOne.map fun block => (\"at_most_one\", ExprNode.array [block.toExprNode])"
        ));
        assert!(source.contains(
            "def OuterArgs.blocksInRange (a : OuterArgs) : Bool :=\n  2 ≤ a.inner.length\n"
        ));
        assert!(source.contains(
            "def Args.blocksInRange (a : Args) : Bool :=\n  1 ≤ a.atLeastOne.length && 1 ≤ a.bounded.length && a.bounded.length ≤ 3 && a.outer.all OuterArgs.blocksInRange\n"
        ));
        assert!(source.contains(
            "(valid : validIdentifier name = true := by valid_identifier)\n    (_blocks : a.blocksInRange = true := by blocks_in_range) : Infra Tag := do"
        ));
        assert!(source.contains(
            "(valid : validIdentifier name = true := by valid_identifier)\n    (blocks : a.blocksInRange = true := by blocks_in_range) :\n    Infra Tag :=\n  createWith name a resourceOptions valid blocks\n"
        ));
        assert!(!source.contains("ExactlyOneArgs.blocksInRange"));

        // Without bounds nothing changes: no obligation, no extra parameter.
        let plain = render_package(&package(), "DigitalOcean", "abc", &core()).unwrap();
        let plain = &plain.files[Path::new("DigitalOcean/Resource/Tag.lean")];
        assert!(!plain.contains("blocksInRange"));
        assert!(plain.contains("createWith name a resourceOptions valid\n"));
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
            BindingType::List(Box::new(object(vec![taint_key]))),
            false,
            true,
            false,
        );
        let mut node_pool = field(
            "node_pool",
            "nodePool",
            BindingType::List(Box::new(object(vec![
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
            BindingType::List(Box::new(object(vec![field(
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
                )]
                .into(),
            },
            resources: vec![BindingItem {
                provider_type: "digitalocean_tag".into(),
                public_name: "Tag".into(),
                fields: vec![end, id, kube_config, labels, name, node_pool, values].into(),
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
                )]
                .into(),
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
            "addProvider (Identifier.mk \"digitalocean\") \"digitalocean/digitalocean\" \"= 2.100.0\" none a.toInputObject"
        ));
        assert!(provider.contains("structure Args where\n  token : Option (Input String) := none"));
        assert!(provider.contains("a.token.map fun value => (\"token\", inputNode value)"));

        let source = &generated.files[Path::new("DigitalOcean/Resource/Tag.lean")];
        assert!(source.contains("namespace DigitalOcean.Resource.Tag"));
        assert!(source.contains("inductive TagResource"));
        // Attributes: one higher-kinded structure, handle and state instantiate it.
        assert!(source.contains("structure Attributes (f o : Type → Type) where"));
        assert!(
            source.contains("  /-- The provider-assigned tag identifier. -/\n  id : f (o String)")
        );
        assert!(source.contains("  name : f String"));
        assert!(source.contains("nodePool : f (List (NodePoolAttributes f o))"));
        // Symbolic elements of computed lists are traversed with the schema's types.
        assert!(source.contains(
            "def NodePoolAttributes.ofInput (value : Input (NodePoolAttributes Input Resolved)) : NodePoolAttributes Input Resolved :="
        ));
        assert!(source.contains("actualNodeCount := value.schemaField \"actual_node_count\""));
        assert!(source.contains("taint := value.schemaField \"taint\""));
        assert!(source.contains(
            "instance : Inframe.SymbolicFields (NodePoolAttributes Input Resolved) := ⟨NodePoolAttributes.ofInput⟩"
        ));
        assert!(source.contains(
            "instance : Inframe.SymbolicFields (Attributes Input Resolved) := ⟨Attributes.ofInput⟩"
        ));
        assert!(source.contains("kubeConfig : f (o (List (KubeConfigAttributes f o)))"));
        assert!(source.contains("labels : f (o (Map String))"));
        assert!(source.contains(
            "structure Tag extends Attributes Input Resolved where\n  resource : Resource TagResource"
        ));
        assert!(source.contains("abbrev State := Attributes Resolved Option"));
        assert!(source.contains(
            "def Attributes.ofValue [Marshal f o] (value : Value) : Except String (Attributes f o) := do"
        ));
        assert!(source.contains("id := (← Marshal.optional (f := f) (o := o) value \"id\")"));
        assert!(source.contains("name := (← Marshal.required (f := f) (o := o) value \"name\")"));
        assert!(source.contains(
            "instance [Marshal f o] : FromValue (Attributes f o) := ⟨Attributes.ofValue⟩"
        ));
        assert!(source.contains("instance : ToValue (Attributes Resolved Option) :="));
        assert!(source.contains("(\"node_pool\", toValue attributes.nodePool)"));
        // Attribute names as values, for policies and `ignoreChanges`.
        assert!(source.contains(
            "@[simp] def names : Attributes (fun _ => String) (fun _ => String) :=\n  { end_ := \"end\"\n    id := \"id\""
        ));
        assert!(source.contains("nodePool := \"node_pool\""));
        assert!(source.contains(
            "@[simp] def NodePoolAttributes.names : NodePoolAttributes (fun _ => String) (fun _ => String) :="
        ));
        assert!(source.contains("structure NodePoolAttributes (f o : Type → Type) where"));
        assert!(source.contains("taint : f (o (List (NodePoolTaintAttributes f o)))"));
        assert!(source.contains(
            "structure KubeConfigAttributes (f o : Type → Type) where\n  rawConfig : f (o String)"
        ));
        // Arguments: one record with defaults, nested records for blocks.
        assert!(source.contains("structure Args where"));
        assert!(source.contains("  name : Input String\n"));
        assert!(source.contains("  nodePool : List NodePoolArgs\n"));
        assert!(source.contains("  end_ : Option (Input String) := none"));
        assert!(source.contains("  labels : Option (Input (Map String)) := none"));
        assert!(source.contains("  values : Option (Input (List String)) := none"));
        assert!(!source.contains("  id : Option (Input String) := none\n  kubeConfig"));
        assert!(source.contains(
            "structure NodePoolArgs where\n  name : Input String\n  /-- Whether automatic scaling is enabled. -/\n  autoScale : Option (Input Bool) := none\n  taint : Option (List NodePoolTaintArgs) := none"
        ));
        assert!(!source.contains("actualNodeCount : Option"));
        assert!(source.contains("def Args.toInputObject (a : Args) : InputObject :="));
        assert!(source.contains("some (\"name\", inputNode a.name)"));
        assert!(source.contains(
            "some (\"node_pool\", ExprNode.array (a.nodePool.map NodePoolArgs.toExprNode))"
        ));
        assert!(source.contains("a.end_.map fun value => (\"end\", inputNode value)"));
        // `taint` is a nested attribute (not a block) in this fixture: `none` is unset and
        // `some []` is an empty list, so an empty list is written as `[]`.
        assert!(source.contains("taint : Option (List NodePoolTaintArgs) := none"));
        assert!(source.contains(
            "a.taint.map fun items => (\"taint\", ExprNode.array (items.map NodePoolTaintArgs.toExprNode))"
        ));
        assert!(source.contains("def NodePoolArgs.toExprNode (a : NodePoolArgs) : ExprNode :="));
        // Handle construction and creation.
        assert!(source.contains("def create (name : String) (a : Args) (valid : validIdentifier name = true := by valid_identifier)"));
        assert!(source.contains(
            "def createWith (name : String) (a : Args) (options : ResourceOptions DigitalOcean.Provider.DigitalOceanProvider)"
        ));
        assert!(source.contains(
            "requireProvider (Identifier.mk \"digitalocean\") \"digitalocean/digitalocean\" \"= 2.100.0\""
        ));
        assert!(source.contains(
            "addResource options (Identifier.mk \"digitalocean_tag\") ⟨name, valid⟩ a.toInputObject"
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
        assert!(source.contains("end DigitalOcean.Resource.Tag"));

        let taint_position = source.find("structure NodePoolTaintAttributes").unwrap();
        let pool_position = source.find("structure NodePoolAttributes").unwrap();
        assert!(
            taint_position < pool_position,
            "children are emitted before parents"
        );

        let data = &generated.files[Path::new("DigitalOcean/Data/Tag.lean")];
        assert!(data.contains(
            "def readWith (name : String) (a : Args) (options : DataSourceOptions DigitalOcean.Provider.DigitalOceanProvider)"
        ));
        assert!(data.contains("dataSourceAttr handle [\"name\"]"));
        assert!(data.contains(
            "instance : Inframe.Dependable Tag := ⟨fun handle => handle.dataSource.address⟩"
        ));
        assert!(!data.contains("instance : Inframe.Managed Tag"));

        let root = &generated.files[Path::new("DigitalOcean.lean")];
        assert!(root.contains(
            "import DigitalOcean.Provider\nimport DigitalOcean.Resource.Tag\nimport DigitalOcean.Data.Tag\n"
        ));

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
            BindingType::List(Box::new(object(vec![
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
                BindingType::List(Box::new(object(vec![field(
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
        ]
        .into();
        let generated = render_package(&package, "DigitalOcean", "abc", &core()).unwrap();
        let source = &generated.files[Path::new("DigitalOcean/Resource/Tag.lean")];
        assert_eq!(source.matches("structure PrimaryArgs where").count(), 1);
        assert!(source.contains("(shared by 2 block paths with the same shape)"));
        assert!(!source.contains("structure SecondaryArgs"));
        assert!(source.contains("  primary : List PrimaryArgs\n"));
        assert!(source.contains("  secondary : Option (List PrimaryArgs) := none"));
        assert!(source.contains("secondary : f (o (List (PrimaryAttributes f o)))"));
        assert!(source.contains("structure DifferentArgs where"));
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

    /// A legacy block list drops its empty value (unset and empty are one configuration);
    /// an empty attribute structure binds no unused names.
    #[test]
    fn optional_block_lists_are_dropped_when_empty() {
        let mut package = package();
        let mut rule = field(
            "rule",
            "rule",
            BindingType::List(Box::new(object(vec![field(
                "port",
                "port",
                BindingType::String,
                false,
                true,
                false,
            )]))),
            false,
            true,
            false,
        );
        rule.block = true;
        let mut empty = field(
            "empty",
            "empty",
            BindingType::List(Box::new(object(Vec::new()))),
            false,
            true,
            false,
        );
        empty.block = true;
        let mut fields = package.resources[0].fields.to_vec();
        fields.push(rule);
        fields.push(empty);
        package.resources[0].fields = fields.into();
        let generated = render_package(&package, "DigitalOcean", "abc", &core()).unwrap();
        let source = &generated.files[Path::new("DigitalOcean/Resource/Tag.lean")];
        assert!(source.contains("rule : List RuleArgs := []"));
        assert!(source.contains(
            "if a.rule.isEmpty then none else some (\"rule\", ExprNode.array (a.rule.map RuleArgs.toExprNode))"
        ));
        assert!(source.contains("def EmptyAttributes.ofValue [Marshal f o] (_value : Value)"));
        assert!(source.contains("⟨fun _ => .object\n    [ ]⟩"));
        assert!(source.contains(
            "def EmptyAttributes.ofInput (_value : Input (EmptyAttributes Input Resolved))"
        ));
        assert!(!source.contains("(value : Value) : Except String (EmptyAttributes"));
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
