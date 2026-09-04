//! `OpenTofu` provider-schema acquisition and language-neutral normalization.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use tempfile::TempDir;
use thiserror::Error;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderRequest {
    pub source: String,
    pub version: String,
}

impl ProviderRequest {
    #[must_use]
    pub fn local_name(&self) -> &str {
        self.source.rsplit('/').next().unwrap_or(&self.source)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProviderSchema {
    pub source: String,
    pub version: String,
    pub provider_config: BlockSchema,
    pub resources: BTreeMap<String, ResourceSchema>,
    pub data_sources: BTreeMap<String, ResourceSchema>,
}

impl ProviderSchema {
    pub fn canonical_json(&self) -> Result<String, serde_json::Error> {
        let mut output = serde_json::to_string_pretty(self)?;
        output.push('\n');
        Ok(output)
    }

    pub fn sha256(&self) -> Result<String, serde_json::Error> {
        let bytes = serde_json::to_vec(self)?;
        Ok(hex::encode(Sha256::digest(bytes)))
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct BlockSchema {
    pub attributes: BTreeMap<String, AttributeSchema>,
    pub blocks: BTreeMap<String, NestedBlockSchema>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ResourceSchema {
    pub block: BlockSchema,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AttributeSchema {
    pub r#type: SchemaType,
    pub required: bool,
    pub optional: bool,
    pub computed: bool,
    pub sensitive: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct NestedBlockSchema {
    pub nesting_mode: NestingMode,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub min_items: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_items: Option<u64>,
    pub block: BlockSchema,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NestingMode {
    Single,
    List,
    Set,
    Map,
    Group,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", content = "value", rename_all = "snake_case")]
pub enum SchemaType {
    String,
    Bool,
    Number,
    List(Box<Self>),
    Set(Box<Self>),
    Map(Box<Self>),
    Object(BTreeMap<String, AttributeSchema>),
    Tuple(Vec<Self>),
    Dynamic,
}

#[derive(Debug, Deserialize)]
struct RawDocument {
    format_version: String,
    provider_schemas: BTreeMap<String, RawProvider>,
}

#[derive(Debug, Deserialize)]
struct RawProvider {
    provider: RawSchema,
    #[serde(default)]
    resource_schemas: BTreeMap<String, RawSchema>,
    #[serde(default)]
    data_source_schemas: BTreeMap<String, RawSchema>,
}

#[derive(Debug, Deserialize)]
struct RawSchema {
    block: RawBlock,
}

#[derive(Debug, Default, Deserialize)]
struct RawBlock {
    #[serde(default)]
    attributes: BTreeMap<String, RawAttribute>,
    #[serde(default)]
    block_types: BTreeMap<String, RawNestedBlock>,
}

#[derive(Debug, Deserialize)]
struct RawAttribute {
    #[serde(default)]
    r#type: Option<Value>,
    #[serde(default)]
    nested_type: Option<RawNestedAttribute>,
    #[serde(default)]
    required: bool,
    #[serde(default)]
    optional: bool,
    #[serde(default)]
    computed: bool,
    #[serde(default)]
    sensitive: bool,
    #[serde(default)]
    description: Option<String>,
}

#[derive(Debug, Deserialize)]
struct RawNestedAttribute {
    nesting_mode: String,
    attributes: BTreeMap<String, RawAttribute>,
}

#[derive(Debug, Deserialize)]
struct RawNestedBlock {
    nesting_mode: String,
    #[serde(default)]
    min_items: Option<u64>,
    #[serde(default)]
    max_items: Option<u64>,
    block: RawBlock,
}

#[derive(Debug, Error)]
pub enum NormalizeError {
    #[error("provider schema JSON could not be decoded")]
    Json(#[from] serde_json::Error),
    #[error("unsupported provider schema format version `{0}`")]
    UnsupportedFormat(String),
    #[error("schema response did not contain provider `{0}`")]
    MissingProvider(String),
    #[error("attribute `{path}` has neither a type nor a nested type")]
    MissingType { path: String },
    #[error("invalid cty type at `{path}`: {message}")]
    InvalidType { path: String, message: String },
    #[error("unsupported nesting mode `{mode}` at `{path}`")]
    NestingMode { path: String, mode: String },
}

pub fn normalize_schema(
    bytes: &[u8],
    request: &ProviderRequest,
) -> Result<ProviderSchema, NormalizeError> {
    let document: RawDocument = serde_json::from_slice(bytes)?;
    if document.format_version.split('.').next() != Some("1") {
        return Err(NormalizeError::UnsupportedFormat(document.format_version));
    }
    let provider = document
        .provider_schemas
        .into_iter()
        .find(|(address, _)| {
            address == &request.source || address.ends_with(&format!("/{}", request.source))
        })
        .map(|(_, provider)| provider)
        .ok_or_else(|| NormalizeError::MissingProvider(request.source.clone()))?;

    Ok(ProviderSchema {
        source: request.source.clone(),
        version: request.version.clone(),
        provider_config: normalize_block(provider.provider.block, "provider")?,
        resources: normalize_resources(provider.resource_schemas, "resource")?,
        data_sources: normalize_resources(provider.data_source_schemas, "data")?,
    })
}

fn normalize_resources(
    schemas: BTreeMap<String, RawSchema>,
    prefix: &str,
) -> Result<BTreeMap<String, ResourceSchema>, NormalizeError> {
    schemas
        .into_iter()
        .map(|(name, schema)| {
            Ok((
                name.clone(),
                ResourceSchema {
                    block: normalize_block(schema.block, &format!("{prefix}.{name}"))?,
                },
            ))
        })
        .collect()
}

fn normalize_block(raw: RawBlock, path: &str) -> Result<BlockSchema, NormalizeError> {
    let attributes = raw
        .attributes
        .into_iter()
        .map(|(name, attribute)| {
            let child_path = format!("{path}.{name}");
            Ok((name, normalize_attribute(attribute, &child_path)?))
        })
        .collect::<Result<_, NormalizeError>>()?;
    let blocks = raw
        .block_types
        .into_iter()
        .map(|(name, nested)| {
            let child_path = format!("{path}.{name}");
            Ok((
                name,
                NestedBlockSchema {
                    nesting_mode: parse_nesting_mode(&nested.nesting_mode, &child_path)?,
                    min_items: nested.min_items,
                    max_items: nested.max_items,
                    block: normalize_block(nested.block, &child_path)?,
                },
            ))
        })
        .collect::<Result<_, NormalizeError>>()?;
    Ok(BlockSchema { attributes, blocks })
}

fn normalize_attribute(raw: RawAttribute, path: &str) -> Result<AttributeSchema, NormalizeError> {
    let r#type = match (raw.r#type, raw.nested_type) {
        (Some(value), _) => parse_type(&value, path)?,
        (None, Some(nested)) => {
            let fields = nested
                .attributes
                .into_iter()
                .map(|(name, attribute)| {
                    let field_path = format!("{path}.{name}");
                    Ok((name, normalize_attribute(attribute, &field_path)?))
                })
                .collect::<Result<_, NormalizeError>>()?;
            let object = SchemaType::Object(fields);
            match parse_nesting_mode(&nested.nesting_mode, path)? {
                NestingMode::Single | NestingMode::Group => object,
                NestingMode::List => SchemaType::List(Box::new(object)),
                NestingMode::Set => SchemaType::Set(Box::new(object)),
                NestingMode::Map => SchemaType::Map(Box::new(object)),
            }
        }
        (None, None) => {
            return Err(NormalizeError::MissingType {
                path: path.to_owned(),
            });
        }
    };
    Ok(AttributeSchema {
        r#type,
        required: raw.required,
        optional: raw.optional,
        computed: raw.computed,
        sensitive: raw.sensitive,
        description: raw.description,
    })
}

fn parse_type(value: &Value, path: &str) -> Result<SchemaType, NormalizeError> {
    if let Some(primitive) = value.as_str() {
        return match primitive {
            "string" => Ok(SchemaType::String),
            "bool" => Ok(SchemaType::Bool),
            "number" => Ok(SchemaType::Number),
            "dynamic" => Ok(SchemaType::Dynamic),
            other => Err(invalid_type(path, format!("unknown primitive `{other}`"))),
        };
    }
    let array = value
        .as_array()
        .ok_or_else(|| invalid_type(path, "expected a primitive or constructor array"))?;
    let constructor = array
        .first()
        .and_then(Value::as_str)
        .ok_or_else(|| invalid_type(path, "missing constructor"))?;
    let parameter = array
        .get(1)
        .ok_or_else(|| invalid_type(path, "missing constructor parameter"))?;
    match constructor {
        "list" => Ok(SchemaType::List(Box::new(parse_type(parameter, path)?))),
        "set" => Ok(SchemaType::Set(Box::new(parse_type(parameter, path)?))),
        "map" => Ok(SchemaType::Map(Box::new(parse_type(parameter, path)?))),
        "object" => {
            let object = parameter
                .as_object()
                .ok_or_else(|| invalid_type(path, "object parameter is not an object"))?;
            Ok(SchemaType::Object(
                object
                    .iter()
                    .map(|(name, value)| {
                        Ok((
                            name.clone(),
                            AttributeSchema {
                                r#type: parse_type(value, &format!("{path}.{name}"))?,
                                required: true,
                                optional: false,
                                computed: false,
                                sensitive: false,
                                description: None,
                            },
                        ))
                    })
                    .collect::<Result<_, NormalizeError>>()?,
            ))
        }
        "tuple" => {
            let values = parameter
                .as_array()
                .ok_or_else(|| invalid_type(path, "tuple parameter is not an array"))?;
            Ok(SchemaType::Tuple(
                values
                    .iter()
                    .enumerate()
                    .map(|(index, value)| parse_type(value, &format!("{path}[{index}]")))
                    .collect::<Result<_, _>>()?,
            ))
        }
        other => Err(invalid_type(path, format!("unknown constructor `{other}`"))),
    }
}

fn invalid_type(path: &str, message: impl Into<String>) -> NormalizeError {
    NormalizeError::InvalidType {
        path: path.to_owned(),
        message: message.into(),
    }
}

fn parse_nesting_mode(value: &str, path: &str) -> Result<NestingMode, NormalizeError> {
    match value {
        "single" => Ok(NestingMode::Single),
        "list" => Ok(NestingMode::List),
        "set" => Ok(NestingMode::Set),
        "map" => Ok(NestingMode::Map),
        "group" => Ok(NestingMode::Group),
        mode => Err(NormalizeError::NestingMode {
            path: path.to_owned(),
            mode: mode.to_owned(),
        }),
    }
}

#[derive(Debug, Clone)]
pub struct SchemaAcquirer {
    tofu_binary: PathBuf,
}

impl Default for SchemaAcquirer {
    fn default() -> Self {
        Self::new("tofu")
    }
}

impl SchemaAcquirer {
    pub fn new(tofu_binary: impl Into<PathBuf>) -> Self {
        Self {
            tofu_binary: tofu_binary.into(),
        }
    }

    pub fn acquire(&self, request: &ProviderRequest) -> Result<ProviderSchema, AcquireError> {
        let directory = TempDir::new()?;
        write_bootstrap(directory.path(), request)?;
        self.run(
            directory.path(),
            &["init", "-backend=false", "-input=false"],
        )?;
        let output = Command::new(&self.tofu_binary)
            .args(["providers", "schema", "-json"])
            .current_dir(directory.path())
            .output()
            .map_err(|source| AcquireError::Spawn {
                binary: self.tofu_binary.clone(),
                source,
            })?;
        if !output.status.success() {
            return Err(AcquireError::Exit {
                command: "providers schema -json".into(),
                stderr: String::from_utf8_lossy(&output.stderr).into_owned(),
            });
        }
        normalize_schema(&output.stdout, request).map_err(AcquireError::Normalize)
    }

    fn run(&self, directory: &Path, arguments: &[&str]) -> Result<(), AcquireError> {
        let output = Command::new(&self.tofu_binary)
            .args(arguments)
            .current_dir(directory)
            .output()
            .map_err(|source| AcquireError::Spawn {
                binary: self.tofu_binary.clone(),
                source,
            })?;
        if output.status.success() {
            Ok(())
        } else {
            Err(AcquireError::Exit {
                command: arguments.join(" "),
                stderr: String::from_utf8_lossy(&output.stderr).into_owned(),
            })
        }
    }
}

fn write_bootstrap(directory: &Path, request: &ProviderRequest) -> Result<(), std::io::Error> {
    let config = json!({
        "terraform": {
            "required_providers": {
                request.local_name(): {
                    "source": request.source,
                    "version": format!("= {}", request.version),
                }
            }
        }
    });
    fs::write(
        directory.join("main.tofu.json"),
        serde_json::to_vec_pretty(&config).expect("bootstrap config serializes"),
    )
}

#[derive(Debug, Error)]
pub enum AcquireError {
    #[error("failed to prepare temporary provider workspace")]
    Io(#[from] std::io::Error),
    #[error("failed to start OpenTofu binary at {binary}")]
    Spawn {
        binary: PathBuf,
        #[source]
        source: std::io::Error,
    },
    #[error("`tofu {command}` failed: {stderr}")]
    Exit { command: String, stderr: String },
    #[error("failed to normalize provider schema")]
    Normalize(#[source] NormalizeError),
}

#[cfg(test)]
mod tests {
    use super::*;

    const FIXTURE: &[u8] = br#"{
      "format_version": "1.0",
      "provider_schemas": {
        "registry.opentofu.org/digitalocean/digitalocean": {
          "provider": { "block": { "attributes": {} } },
          "resource_schemas": {
            "digitalocean_tag": { "block": { "attributes": {
              "id": { "type": "string", "computed": true },
              "name": { "type": "string", "required": true },
              "node_pool": {
                "nested_type": {
                  "nesting_mode": "list",
                  "attributes": {
                    "actual_node_count": { "type": "number", "computed": true },
                    "auto_scale": { "type": "bool", "optional": true },
                    "name": { "type": "string", "required": true }
                  }
                },
                "required": true
              }
            } } }
          },
          "data_source_schemas": {}
        }
      }
    }"#;

    fn request() -> ProviderRequest {
        ProviderRequest {
            source: "digitalocean/digitalocean".into(),
            version: "2.100.0".into(),
        }
    }

    #[test]
    fn normalizes_fixture() {
        let schema = normalize_schema(FIXTURE, &request()).unwrap();
        let tag = &schema.resources["digitalocean_tag"].block;
        assert!(tag.attributes["name"].required);
        assert!(tag.attributes["id"].computed);
        assert_eq!(tag.attributes["name"].r#type, SchemaType::String);
        let SchemaType::List(node_pool) = &tag.attributes["node_pool"].r#type else {
            panic!("node_pool should be a list");
        };
        let SchemaType::Object(fields) = node_pool.as_ref() else {
            panic!("node_pool entries should be objects");
        };
        assert!(fields["name"].required);
        assert!(fields["auto_scale"].optional);
        assert!(fields["actual_node_count"].computed);
    }

    #[test]
    fn normalized_hash_is_deterministic() {
        let first = normalize_schema(FIXTURE, &request()).unwrap();
        let second = normalize_schema(FIXTURE, &request()).unwrap();
        assert_eq!(first.sha256().unwrap(), second.sha256().unwrap());
    }

    #[test]
    fn parses_compound_cty_types() {
        assert_eq!(
            parse_type(&json!(["list", ["map", "bool"]]), "test").unwrap(),
            SchemaType::List(Box::new(SchemaType::Map(Box::new(SchemaType::Bool))))
        );
    }
}
