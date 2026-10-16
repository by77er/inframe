//! Derives a language-neutral binding API from normalized provider schemas.

use std::collections::{BTreeMap, HashMap};

use inframe_provider_schema::{
    AttributeSchema, BlockSchema, Interner, NameMap, NestingMode, ProviderSchema, SchemaType,
};
pub use inframe_provider_schema::{Name, Shared};
use rustc_hash::FxBuildHasher;
use serde::{Deserialize, Serialize};
use thiserror::Error;

pub mod emit;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BindingPackage {
    pub provider: BindingProvider,
    pub resources: Vec<BindingItem>,
    pub data_sources: Vec<BindingItem>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BindingProvider {
    pub source: String,
    pub version: String,
    pub public_name: String,
    pub fields: Fields,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BindingItem {
    pub provider_type: String,
    pub public_name: String,
    pub fields: Fields,
}

impl BindingItem {
    pub fn required_inputs(&self) -> impl Iterator<Item = &BindingField> {
        self.fields.iter().filter(|field| field.required)
    }

    pub fn optional_inputs(&self) -> impl Iterator<Item = &BindingField> {
        self.fields.iter().filter(|field| field.optional)
    }

    pub fn outputs(&self) -> impl Iterator<Item = &BindingField> {
        // Configured values and nested blocks are referenceable too, so handles
        // expose the complete provider schema rather than only scalar attributes.
        self.fields.iter()
    }
}

/// A field list. Derived lists are interned, so equal lists (the same nested block repeated
/// across a provider's unrolled recursive schemas) are one allocation and compare by pointer.
pub type Fields = Shared<BindingField>;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct BindingField {
    pub provider_name: Name,
    pub public_name: Name,
    pub r#type: BindingType,
    pub required: bool,
    pub optional: bool,
    pub computed: bool,
    pub sensitive: bool,
    pub block: bool,
    pub target_reserved: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<Name>,
    /// For nested blocks, the fewest entries the provider accepts (when more than zero).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub min_items: Option<u64>,
    /// For nested blocks, the most entries the provider accepts.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub max_items: Option<u64>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(tag = "kind", content = "value", rename_all = "snake_case")]
pub enum BindingType {
    String,
    Bool,
    Number,
    List(Box<Self>),
    Set(Box<Self>),
    Map(Box<Self>),
    Object(Fields),
    Tuple(Vec<Self>),
    Dynamic,
}

#[derive(Debug, Error, PartialEq, Eq)]
pub enum DeriveError {
    #[error("provider source `{0}` has no usable name")]
    InvalidProviderName(String),
    #[error("public name `{public_name}` collides between `{first}` and `{second}`")]
    NameCollision {
        public_name: String,
        first: String,
        second: String,
    },
}

/// Choices that the provider schema alone does not settle.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct BindingOptions {
    /// The prefix removed from every resource and data-source type to form its public module
    /// name, `google_` for `google_compute_instance` → `ComputeInstance`. `None` infers it
    /// from the provider name and the types themselves (see [`infer_type_prefix`]).
    pub strip_prefix: Option<String>,
}

pub fn derive_bindings(schema: &ProviderSchema) -> Result<BindingPackage, DeriveError> {
    derive_bindings_with(schema, &BindingOptions::default())
}

pub fn derive_bindings_with(
    schema: &ProviderSchema,
    options: &BindingOptions,
) -> Result<BindingPackage, DeriveError> {
    let provider_native_name = schema
        .source
        .rsplit('/')
        .next()
        .filter(|name| !name.is_empty())
        .ok_or_else(|| DeriveError::InvalidProviderName(schema.source.clone()))?;
    let provider_name = pascal_case(provider_native_name);
    if provider_name.is_empty() {
        return Err(DeriveError::InvalidProviderName(schema.source.clone()));
    }
    let prefix = options.strip_prefix.clone().unwrap_or_else(|| {
        infer_type_prefix(
            provider_native_name,
            schema.resources.keys().chain(schema.data_sources.keys()),
        )
    });
    let mut deriver = Deriver::default();
    let resources = deriver.items(&schema.resources, &prefix)?;
    let data_sources = deriver.items(&schema.data_sources, &prefix)?;
    Ok(BindingPackage {
        provider: BindingProvider {
            source: schema.source.clone(),
            version: schema.version.clone(),
            public_name: provider_name,
            fields: deriver.fields(&schema.provider_config),
        },
        resources,
        data_sources,
    })
}

/// The prefix a provider's resource types share. `<provider>_` is the convention, but a
/// provider named with a dash (`google-beta`) still names its types after its base provider
/// (`google_compute_instance`), so the candidates are tried from longest to shortest:
/// `google-beta_`, `google_beta_`, `google_`. The first one some type starts with wins; when
/// none matches nothing is stripped.
pub fn infer_type_prefix<'a>(
    provider_native_name: &str,
    types: impl IntoIterator<Item = &'a String>,
) -> String {
    let types: Vec<&String> = types.into_iter().collect();
    let mut candidates = vec![
        format!("{provider_native_name}_"),
        format!("{}_", provider_native_name.replace('-', "_")),
    ];
    let parts: Vec<&str> = provider_native_name.split('-').collect();
    for end in (1..parts.len()).rev() {
        candidates.push(format!("{}_", parts[..end].join("_")));
    }
    candidates
        .into_iter()
        .find(|candidate| {
            types
                .iter()
                .any(|kind| kind.starts_with(candidate.as_str()))
        })
        .unwrap_or_else(|| format!("{provider_native_name}_"))
}

/// Derives field lists with every distinct list built once. Normalized schemas share their
/// repeated blocks, so the memo tables are keyed by schema value (an O(1) hash and, for shared
/// blocks, a pointer comparison) and the work is proportional to the distinct blocks rather
/// than to every path through them. Derived lists are interned as well, because different
/// schemas can derive equal bindings (a `single` and a `group` block, say).
#[derive(Default)]
struct Deriver {
    interned: Interner<BindingField>,
    blocks: HashMap<BlockSchema, Fields, FxBuildHasher>,
    objects: HashMap<NameMap<AttributeSchema>, Fields, FxBuildHasher>,
    public_names: HashMap<Name, Name, FxBuildHasher>,
}

impl Deriver {
    fn items(
        &mut self,
        schemas: &BTreeMap<String, inframe_provider_schema::ResourceSchema>,
        provider_prefix: &str,
    ) -> Result<Vec<BindingItem>, DeriveError> {
        let mut seen = BTreeMap::<String, &str>::new();
        let mut items = Vec::with_capacity(schemas.len());
        for (provider_type, schema) in schemas {
            let short_name = provider_type
                .strip_prefix(provider_prefix)
                .unwrap_or(provider_type);
            let public_name = pascal_case(short_name);
            if let Some(first) = seen.insert(public_name.clone(), provider_type) {
                return Err(DeriveError::NameCollision {
                    public_name,
                    first: first.to_owned(),
                    second: provider_type.clone(),
                });
            }
            items.push(BindingItem {
                provider_type: provider_type.clone(),
                public_name,
                fields: self.fields(&schema.block),
            });
        }
        Ok(items)
    }

    fn fields(&mut self, block: &BlockSchema) -> Fields {
        if let Some(fields) = self.blocks.get(block) {
            return fields.clone();
        }
        let mut fields = Vec::with_capacity(block.attributes.len() + block.blocks.len());
        for (name, attribute) in block.attributes.iter() {
            fields.push(self.attribute(name, attribute));
        }
        for (name, nested) in block.blocks.iter() {
            let object = BindingType::Object(self.fields(&nested.block));
            let r#type = match nested.nesting_mode {
                NestingMode::Single | NestingMode::Group => object,
                NestingMode::List => BindingType::List(Box::new(object)),
                NestingMode::Set => BindingType::Set(Box::new(object)),
                NestingMode::Map => BindingType::Map(Box::new(object)),
            };
            let public_name = self.public_name(name);
            fields.push(BindingField {
                provider_name: name.clone(),
                target_reserved: reserved_word(&public_name),
                public_name,
                r#type,
                required: nested.min_items.is_some_and(|minimum| minimum > 0),
                optional: nested.min_items.is_none_or(|minimum| minimum == 0),
                computed: false,
                sensitive: false,
                block: true,
                description: None,
                min_items: nested.min_items.filter(|minimum| *minimum > 0),
                max_items: nested.max_items,
            });
        }
        // Stable: an attribute and a block with the same name keep that order.
        fields.sort_by(|left, right| left.provider_name.cmp(&right.provider_name));
        let fields = self.interned.intern(fields);
        self.blocks.insert(block.clone(), fields.clone());
        fields
    }

    fn attribute(&mut self, name: &Name, attribute: &AttributeSchema) -> BindingField {
        let public_name = self.public_name(name);
        BindingField {
            provider_name: name.clone(),
            target_reserved: reserved_word(&public_name),
            public_name,
            r#type: self.binding_type(&attribute.r#type),
            required: attribute.required,
            optional: attribute.optional,
            computed: attribute.computed,
            sensitive: attribute.sensitive,
            block: false,
            description: attribute.description.clone(),
            min_items: None,
            max_items: None,
        }
    }

    fn binding_type(&mut self, schema_type: &SchemaType) -> BindingType {
        match schema_type {
            SchemaType::String => BindingType::String,
            SchemaType::Bool => BindingType::Bool,
            SchemaType::Number => BindingType::Number,
            SchemaType::List(item) => BindingType::List(Box::new(self.binding_type(item))),
            SchemaType::Set(item) => BindingType::Set(Box::new(self.binding_type(item))),
            SchemaType::Map(item) => BindingType::Map(Box::new(self.binding_type(item))),
            SchemaType::Object(attributes) => BindingType::Object(self.object(attributes)),
            SchemaType::Tuple(items) => {
                BindingType::Tuple(items.iter().map(|item| self.binding_type(item)).collect())
            }
            SchemaType::Dynamic => BindingType::Dynamic,
        }
    }

    fn object(&mut self, attributes: &NameMap<AttributeSchema>) -> Fields {
        if let Some(fields) = self.objects.get(attributes) {
            return fields.clone();
        }
        let fields = attributes
            .iter()
            .map(|(name, attribute)| self.attribute(name, attribute))
            .collect();
        let fields = self.interned.intern(fields);
        self.objects.insert(attributes.clone(), fields.clone());
        fields
    }

    fn public_name(&mut self, name: &Name) -> Name {
        self.public_names
            .entry(name.clone())
            .or_insert_with(|| field_name(name).into())
            .clone()
    }
}

#[must_use]
pub fn pascal_case(value: &str) -> String {
    let mut output = String::with_capacity(value.len());
    for word in split_words(value) {
        push_capitalized(&mut output, word);
    }
    output
}

#[must_use]
pub fn field_name(value: &str) -> String {
    let mut words = split_words(value);
    let Some(first) = words.next() else {
        return String::new();
    };
    let mut output = String::with_capacity(value.len());
    output.push_str(first);
    for word in words {
        push_capitalized(&mut output, word);
    }
    output
}

/// Appends `word` with its first character upper-cased (ASCII only).
pub fn push_capitalized(output: &mut String, word: &str) {
    let mut characters = word.chars();
    if let Some(first) = characters.next() {
        output.push(first.to_ascii_uppercase());
        output.push_str(characters.as_str());
    }
}

fn split_words(value: &str) -> impl Iterator<Item = &str> {
    value
        .split(|character: char| !character.is_ascii_alphanumeric())
        .filter(|part| !part.is_empty())
}

/// PureScript keywords, which a field name has to avoid.
const RESERVED_WORDS: &[&str] = &[
    "ado",
    "case",
    "class",
    "data",
    "derive",
    "do",
    "else",
    "false",
    "forall",
    "foreign",
    "hiding",
    "if",
    "import",
    "in",
    "infix",
    "infixl",
    "infixr",
    "instance",
    "kind",
    "let",
    "module",
    "newtype",
    "nominal",
    "of",
    "representational",
    "role",
    "then",
    "true",
    "type",
    "where",
];

fn reserved_word(name: &str) -> bool {
    RESERVED_WORDS.contains(&name)
}

/// The number of fields reachable from `fields` along every path, counting each repetition
/// of a shared list: a rough measure of how much text an emitter produces for them.
#[must_use]
pub fn path_count(fields: &[BindingField]) -> usize {
    fields
        .iter()
        .map(|field| 1 + object_fields(&field.r#type).map_or(0, |fields| path_count(fields)))
        .sum()
}

/// The object fields behind any number of collection layers, if there are any.
#[must_use]
pub fn object_fields(r#type: &BindingType) -> Option<&Fields> {
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

#[cfg(test)]
mod tests {
    use inframe_provider_schema::{NestedBlockSchema, ResourceSchema};

    use super::*;

    #[test]
    fn derives_required_optional_computed_and_reserved_fields() {
        let block = BlockSchema {
            attributes: NameMap::from([
                (
                    "name",
                    AttributeSchema {
                        r#type: SchemaType::String,
                        required: true,
                        optional: false,
                        computed: false,
                        sensitive: false,
                        description: Some("name of the tag".into()),
                    },
                ),
                (
                    "type",
                    AttributeSchema {
                        r#type: SchemaType::String,
                        required: false,
                        optional: true,
                        computed: true,
                        sensitive: true,
                        description: None,
                    },
                ),
            ]),
            blocks: NameMap::default(),
        };
        let schema = ProviderSchema {
            source: "digitalocean/digitalocean".into(),
            version: "2.100.0".into(),
            provider_config: BlockSchema::default(),
            resources: BTreeMap::from([("digitalocean_tag".into(), ResourceSchema { block })]),
            data_sources: BTreeMap::new(),
        };
        let package = derive_bindings(&schema).unwrap();
        assert_eq!(package.resources[0].public_name, "Tag");
        assert_eq!(package.resources[0].required_inputs().count(), 1);
        assert_eq!(package.resources[0].optional_inputs().count(), 1);
        assert_eq!(
            package.resources[0].fields[0].description.as_deref(),
            Some("name of the tag")
        );
        assert!(package.resources[0].fields[1].target_reserved);
        assert!(package.resources[0].fields[1].sensitive);
    }

    #[test]
    fn strips_the_base_provider_prefix_from_beta_providers() {
        let types = [
            "google_compute_instance".to_owned(),
            "google_storage_bucket".to_owned(),
        ];
        assert_eq!(infer_type_prefix("google-beta", &types), "google_");
        assert_eq!(infer_type_prefix("google", &types), "google_");
        assert_eq!(
            infer_type_prefix("digitalocean", &["digitalocean_tag".to_owned()]),
            "digitalocean_"
        );
        assert_eq!(infer_type_prefix("odd", &types), "odd_");

        let schema = ProviderSchema {
            source: "hashicorp/google-beta".into(),
            version: "6.0.0".into(),
            provider_config: BlockSchema::default(),
            resources: BTreeMap::from([(
                "google_compute_instance".to_owned(),
                ResourceSchema {
                    block: BlockSchema::default(),
                },
            )]),
            data_sources: BTreeMap::new(),
        };
        assert_eq!(
            derive_bindings(&schema).unwrap().resources[0].public_name,
            "ComputeInstance"
        );
        let explicit = derive_bindings_with(
            &schema,
            &BindingOptions {
                strip_prefix: Some("google_compute_".into()),
            },
        )
        .unwrap();
        assert_eq!(explicit.resources[0].public_name, "Instance");
    }

    #[test]
    fn names_are_stable() {
        assert_eq!(pascal_case("project_resources"), "ProjectResources");
        assert_eq!(field_name("vpc_uuid"), "vpcUuid");
    }

    #[test]
    fn preserves_nested_attribute_roles() {
        let nested = AttributeSchema {
            r#type: SchemaType::List(Box::new(SchemaType::Object(NameMap::from([
                (
                    "name",
                    AttributeSchema {
                        r#type: SchemaType::String,
                        required: true,
                        optional: false,
                        computed: false,
                        sensitive: false,
                        description: None,
                    },
                ),
                (
                    "actual_node_count",
                    AttributeSchema {
                        r#type: SchemaType::Number,
                        required: false,
                        optional: false,
                        computed: true,
                        sensitive: false,
                        description: None,
                    },
                ),
            ])))),
            required: true,
            optional: false,
            computed: false,
            sensitive: false,
            description: None,
        };
        let fields = Deriver::default().fields(&BlockSchema {
            attributes: NameMap::from([("node_pool", nested)]),
            blocks: NameMap::default(),
        });
        let BindingType::List(item) = &fields[0].r#type else {
            panic!("node_pool should be a list");
        };
        let BindingType::Object(children) = item.as_ref() else {
            panic!("node_pool entries should be objects");
        };
        assert!(
            children
                .iter()
                .any(|field| &*field.public_name == "name" && field.required)
        );
        assert!(
            children
                .iter()
                .any(|field| &*field.public_name == "actualNodeCount" && field.computed)
        );
    }

    #[test]
    fn exposes_nested_blocks_as_traversable_outputs() {
        let fields = Deriver::default().fields(&BlockSchema {
            attributes: NameMap::default(),
            blocks: NameMap::from([(
                "node_pool",
                NestedBlockSchema {
                    nesting_mode: NestingMode::List,
                    min_items: Some(1),
                    max_items: Some(1),
                    block: BlockSchema {
                        attributes: NameMap::from([(
                            "name",
                            AttributeSchema {
                                r#type: SchemaType::String,
                                required: true,
                                optional: false,
                                computed: false,
                                sensitive: false,
                                description: None,
                            },
                        )]),
                        blocks: NameMap::default(),
                    },
                },
            )]),
        });
        let item = BindingItem {
            provider_type: "digitalocean_kubernetes_cluster".into(),
            public_name: "KubernetesCluster".into(),
            fields,
        };

        assert!(
            item.outputs()
                .any(|field| { &*field.provider_name == "node_pool" && field.block })
        );
        let node_pool = &item.fields[0];
        assert!(node_pool.required);
        assert_eq!(node_pool.min_items, Some(1));
        assert_eq!(node_pool.max_items, Some(1));
    }
}
