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
    let setters: Vec<_> = fields.iter().filter(|field| field.optional).collect();
    let mut exports = vec![
        "Args".to_owned(),
        "Required".to_owned(),
        "args".to_owned(),
        "configure".to_owned(),
        "configureAs".to_owned(),
    ];
    exports.extend(setters.iter().map(|field| safe_field_name(field)));
    let mut output = module_header(&format!("{module_root}.Provider"), &exports);
    output.push_str(
        "import Prelude (Unit)\n\n\
         import Data.Argonaut.Core (Json)\n\
         import Data.Maybe (Maybe(..))\n",
    );
    if fields.iter().any(|field| field.required) {
        output.push_str("import Data.Tuple (Tuple(..))\n");
    }
    output.push_str(
        "import Foreign.Object as Object\n\
         import TofuDag.Builder (Infra, addProvider)\n\
         import TofuDag.Core (Input, inputJson)\n\n",
    );
    output.push_str(&render_args(fields));
    for field in setters {
        output.push_str(&render_setter(field));
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
    exports.extend(setters.iter().map(|field| safe_field_name(field)));
    let mut output = module_header(module, &exports);
    output.push_str("import Prelude (bind, pure)\n\n");
    output.push_str("import Data.Argonaut.Core (Json)\n");
    if item.fields.iter().any(|field| field.required) {
        output.push_str("import Data.Tuple (Tuple(..))\n");
    }
    output.push_str("import Foreign.Object as Object\n");
    output.push_str("import TofuDag.Builder (Infra, ");
    output.push_str(if data_source {
        "addDataSource"
    } else {
        "addResource"
    });
    output.push_str(")\nimport TofuDag.Core (Expr, Input, ");
    output.push_str(if data_source {
        "DataSource"
    } else {
        "Resource"
    });
    output.push_str(", inputJson, ");
    output.push_str(if data_source {
        "dataSourceAttr"
    } else {
        "resourceAttr"
    });
    output.push_str(")\n\n");
    let _ = write!(output, "data {node}\n\n");
    output.push_str(&render_args(&item.fields));
    for field in setters {
        output.push_str(&render_setter(field));
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

fn render_args(fields: &[BindingField]) -> String {
    let required: Vec<_> = fields.iter().filter(|field| field.required).collect();
    let mut output = String::from("type Required =\n  {");
    for (index, field) in required.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n  , " };
        let _ = write!(
            output,
            "{separator}{} :: Input {}",
            safe_field_name(field),
            render_type_argument(&field.r#type)
        );
    }
    output.push_str("\n  }\n\nnewtype Args = Args (Object.Object Json)\n\n");
    let required_argument = if required.is_empty() { "_" } else { "required" };
    let _ = write!(
        output,
        "args :: Required -> Args\nargs {required_argument} = Args (Object.fromFoldable\n  ["
    );
    for (index, field) in required.iter().enumerate() {
        let separator = if index == 0 { " " } else { "\n  , " };
        let _ = write!(
            output,
            "{separator}Tuple \"{}\" (inputJson required.{})",
            field.provider_name,
            safe_field_name(field)
        );
    }
    output.push_str("\n  ])\n\n");
    output
}

fn render_setter(field: &BindingField) -> String {
    let name = safe_field_name(field);
    format!(
        "{name} :: Input {} -> Args -> Args\n\
         {name} value (Args values) = Args (Object.insert \"{}\" (inputJson value) values)\n\n",
        render_type_argument(&field.r#type),
        field.provider_name
    )
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
                fields: vec![id, name],
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
    }

    #[test]
    fn output_is_deterministic() {
        let first = render_package(&package(), "DigitalOcean", "abc").unwrap();
        let second = render_package(&package(), "DigitalOcean", "abc").unwrap();
        assert_eq!(first, second);
    }
}
