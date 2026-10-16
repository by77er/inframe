//! `OpenTofu` provider-schema acquisition and language-neutral normalization.

use std::collections::BTreeMap;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;

use ring::digest;
use serde::{Deserialize, Serialize};
use serde_json::json;
use tempfile::TempDir;
use thiserror::Error;

mod compact;
mod decode;
mod shared;

pub use compact::read_compact_json;
pub use shared::{Interner, Name, NameMap, Shared};

use decode::{Document, decode};

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

    /// Whether a `provider_schemas` address names this provider.
    fn matches(&self, address: &str) -> bool {
        address == self.source
            || address
                .strip_suffix(self.source.as_str())
                .is_some_and(|prefix| prefix.ends_with('/'))
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

    /// The SHA-256 of the compact JSON encoding, streamed into the hasher rather than built
    /// in memory first. For a large provider (AWS: 24 MB of JSON) hashing is the most
    /// expensive step after decoding, so it uses `ring`'s assembly implementation, about
    /// twice as fast as a portable one on CPUs without SHA extensions.
    pub fn sha256(&self) -> Result<String, serde_json::Error> {
        struct Hashing(digest::Context);

        impl io::Write for Hashing {
            fn write(&mut self, bytes: &[u8]) -> io::Result<usize> {
                self.0.update(bytes);
                Ok(bytes.len())
            }

            fn flush(&mut self) -> io::Result<()> {
                Ok(())
            }
        }

        let hashing = Hashing(digest::Context::new(&digest::SHA256));
        let mut writer = io::BufWriter::with_capacity(1 << 16, hashing);
        serde_json::to_writer(&mut writer, self)?;
        let hashing = writer
            .into_inner()
            .map_err(|error| serde_json::Error::io(error.into_error()))?;
        Ok(hex::encode(hashing.0.finish()))
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default, Serialize, Deserialize)]
pub struct BlockSchema {
    pub attributes: NameMap<AttributeSchema>,
    pub blocks: NameMap<NestedBlockSchema>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ResourceSchema {
    pub block: BlockSchema,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct AttributeSchema {
    pub r#type: SchemaType,
    pub required: bool,
    pub optional: bool,
    pub computed: bool,
    pub sensitive: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<Name>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct NestedBlockSchema {
    pub nesting_mode: NestingMode,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub min_items: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_items: Option<u64>,
    pub block: BlockSchema,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NestingMode {
    Single,
    List,
    Set,
    Map,
    Group,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(tag = "kind", content = "value", rename_all = "snake_case")]
pub enum SchemaType {
    String,
    Bool,
    Number,
    List(Box<Self>),
    Set(Box<Self>),
    Map(Box<Self>),
    Object(NameMap<AttributeSchema>),
    Tuple(Vec<Self>),
    Dynamic,
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

/// Decodes `tofu providers schema -json` output and normalizes the requested provider.
///
/// The document is decoded in one pass straight from `bytes`, and every block is normalized
/// and interned the moment its JSON ends, so no raw tree is ever built: memory beyond the
/// input is the normalized schema itself. Normalization problems are carried as values until
/// the whole document has decoded, and the first one in schema order wins, so they are
/// reported with the same precedence as decoding everything before normalizing anything:
/// malformed JSON, then the format version, then a missing provider, then the first invalid
/// node (the provider configuration, then resources and data sources by name, attributes
/// before blocks by name within each block).
pub fn normalize_schema(
    bytes: &[u8],
    request: &ProviderRequest,
) -> Result<ProviderSchema, NormalizeError> {
    let document = decode(bytes, request, false)?;
    document
        .raw
        .expect("raw decoding requires the raw fields")
        .normalized(request)
}

/// A provider schema file, in either of the formats `--schema-json` accepts.
#[derive(Debug)]
pub enum SchemaFile {
    /// Already normalized, as written by `inframe provider inspect --output`.
    Normalized(ProviderSchema),
    /// Raw `tofu providers schema -json` output, normalized for the request.
    Raw(ProviderSchema),
}

/// Reads a schema file that may be in either format. A file that decodes as a normalized
/// schema is one; anything else is read as raw `OpenTofu` output, and its problems are
/// reported as [`normalize_schema`] reports them.
///
/// Both formats' fields are read in the same pass. Only when some value in it fails to decode
/// is the file decoded again as each format in turn, which settles what it is and which
/// problem to report exactly as decoding it twice up front would.
pub fn read_schema_file(
    bytes: &[u8],
    request: &ProviderRequest,
) -> Result<SchemaFile, NormalizeError> {
    match decode(bytes, request, true) {
        Ok(Document {
            normalized: Some(schema),
            ..
        }) => Ok(SchemaFile::Normalized(schema)),
        Ok(Document { raw: Some(raw), .. }) => raw.normalized(request).map(SchemaFile::Raw),
        _ => match serde_json::from_slice::<ProviderSchema>(bytes) {
            Ok(schema) => Ok(SchemaFile::Normalized(schema)),
            Err(_) => normalize_schema(bytes, request).map(SchemaFile::Raw),
        },
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
              "name": {
                "type": "string",
                "required": true,
                "description": "name of the tag"
              },
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

    /// Plugin-framework providers emit empty object types as a `nested_type` with a
    /// `nesting_mode` and no `attributes` map.
    #[test]
    fn tolerates_nested_types_without_attributes() {
        let fixture = br#"{
          "format_version": "1.0",
          "provider_schemas": {
            "registry.opentofu.org/cloudflare/cloudflare": {
              "provider": { "block": { "attributes": {} } },
              "resource_schemas": {
                "cloudflare_pages_project": { "block": { "attributes": {
                  "bindings": {
                    "nested_type": { "nesting_mode": "list" },
                    "optional": true
                  }
                } } }
              }
            }
          }
        }"#;
        let request = ProviderRequest {
            source: "cloudflare/cloudflare".into(),
            version: "5.24.0".into(),
        };
        let schema = normalize_schema(fixture, &request).unwrap();
        let bindings = &schema.resources["cloudflare_pages_project"]
            .block
            .attributes["bindings"];
        assert_eq!(
            bindings.r#type,
            SchemaType::List(Box::new(SchemaType::Object(NameMap::default())))
        );
    }

    #[test]
    fn normalizes_fixture() {
        let schema = normalize_schema(FIXTURE, &request()).unwrap();
        let tag = &schema.resources["digitalocean_tag"].block;
        assert!(tag.attributes["name"].required);
        assert!(tag.attributes["id"].computed);
        assert_eq!(tag.attributes["name"].r#type, SchemaType::String);
        assert_eq!(
            tag.attributes["name"].description.as_deref(),
            Some("name of the tag")
        );
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
}
