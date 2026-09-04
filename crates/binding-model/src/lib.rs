//! Derives a language-neutral binding API from normalized provider schemas.

use std::collections::{BTreeMap, BTreeSet};

use serde::{Deserialize, Serialize};
use thiserror::Error;
use tofu_dag_provider_schema::{
    AttributeSchema, BlockSchema, NestingMode, ProviderSchema, SchemaType,
};

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
    pub fields: Vec<BindingField>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BindingItem {
    pub provider_type: String,
    pub public_name: String,
    pub fields: Vec<BindingField>,
}

impl BindingItem {
    pub fn required_inputs(&self) -> impl Iterator<Item = &BindingField> {
        self.fields.iter().filter(|field| field.required)
    }

    pub fn optional_inputs(&self) -> impl Iterator<Item = &BindingField> {
        self.fields.iter().filter(|field| field.optional)
    }

    pub fn outputs(&self) -> impl Iterator<Item = &BindingField> {
        // Configured values are referenceable too, so handles expose every attribute.
        self.fields.iter().filter(|field| !field.block)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BindingField {
    pub provider_name: String,
    pub public_name: String,
    pub r#type: BindingType,
    pub required: bool,
    pub optional: bool,
    pub computed: bool,
    pub sensitive: bool,
    pub block: bool,
    pub target_reserved: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", content = "value", rename_all = "snake_case")]
pub enum BindingType {
    String,
    Bool,
    Number,
    List(Box<Self>),
    Set(Box<Self>),
    Map(Box<Self>),
    Object(Vec<BindingField>),
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

pub fn derive_bindings(schema: &ProviderSchema) -> Result<BindingPackage, DeriveError> {
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
    let prefix = format!("{provider_native_name}_");
    let resources = derive_items(&schema.resources, &prefix)?;
    let data_sources = derive_items(&schema.data_sources, &prefix)?;
    Ok(BindingPackage {
        provider: BindingProvider {
            source: schema.source.clone(),
            version: schema.version.clone(),
            public_name: provider_name,
            fields: derive_fields(&schema.provider_config),
        },
        resources,
        data_sources,
    })
}

fn derive_items(
    schemas: &BTreeMap<String, tofu_dag_provider_schema::ResourceSchema>,
    provider_prefix: &str,
) -> Result<Vec<BindingItem>, DeriveError> {
    let mut seen = BTreeMap::<String, String>::new();
    let mut items = Vec::with_capacity(schemas.len());
    for (provider_type, schema) in schemas {
        let short_name = provider_type
            .strip_prefix(provider_prefix)
            .unwrap_or(provider_type);
        let public_name = pascal_case(short_name);
        if let Some(first) = seen.insert(public_name.clone(), provider_type.clone()) {
            return Err(DeriveError::NameCollision {
                public_name,
                first,
                second: provider_type.clone(),
            });
        }
        items.push(BindingItem {
            provider_type: provider_type.clone(),
            public_name,
            fields: derive_fields(&schema.block),
        });
    }
    Ok(items)
}

fn derive_fields(block: &BlockSchema) -> Vec<BindingField> {
    let mut fields: Vec<_> = block
        .attributes
        .iter()
        .map(|(name, attribute)| derive_attribute(name, attribute))
        .collect();
    fields.extend(block.blocks.iter().map(|(name, block)| {
        let object = BindingType::Object(derive_fields(&block.block));
        let r#type = match block.nesting_mode {
            NestingMode::Single | NestingMode::Group => object,
            NestingMode::List => BindingType::List(Box::new(object)),
            NestingMode::Set => BindingType::Set(Box::new(object)),
            NestingMode::Map => BindingType::Map(Box::new(object)),
        };
        BindingField {
            provider_name: name.clone(),
            public_name: field_name(name),
            r#type,
            required: block.min_items.is_some_and(|minimum| minimum > 0),
            optional: block.min_items.is_none_or(|minimum| minimum == 0),
            computed: false,
            sensitive: false,
            block: true,
            target_reserved: reserved_words().contains(field_name(name).as_str()),
            description: None,
        }
    }));
    fields.sort_by(|left, right| left.provider_name.cmp(&right.provider_name));
    fields
}

fn derive_attribute(name: &str, attribute: &AttributeSchema) -> BindingField {
    let public_name = field_name(name);
    BindingField {
        provider_name: name.to_owned(),
        public_name: public_name.clone(),
        r#type: binding_type(&attribute.r#type),
        required: attribute.required,
        optional: attribute.optional,
        computed: attribute.computed,
        sensitive: attribute.sensitive,
        block: false,
        target_reserved: reserved_words().contains(public_name.as_str()),
        description: attribute.description.clone(),
    }
}

fn binding_type(schema_type: &SchemaType) -> BindingType {
    match schema_type {
        SchemaType::String => BindingType::String,
        SchemaType::Bool => BindingType::Bool,
        SchemaType::Number => BindingType::Number,
        SchemaType::List(item) => BindingType::List(Box::new(binding_type(item))),
        SchemaType::Set(item) => BindingType::Set(Box::new(binding_type(item))),
        SchemaType::Map(item) => BindingType::Map(Box::new(binding_type(item))),
        SchemaType::Object(fields) => BindingType::Object(
            fields
                .iter()
                .map(|(name, r#type)| BindingField {
                    provider_name: name.clone(),
                    public_name: field_name(name),
                    r#type: binding_type(r#type),
                    required: true,
                    optional: false,
                    computed: false,
                    sensitive: false,
                    block: false,
                    target_reserved: reserved_words().contains(field_name(name).as_str()),
                    description: None,
                })
                .collect(),
        ),
        SchemaType::Tuple(items) => BindingType::Tuple(items.iter().map(binding_type).collect()),
        SchemaType::Dynamic => BindingType::Dynamic,
    }
}

#[must_use]
pub fn pascal_case(value: &str) -> String {
    split_words(value)
        .map(|word| {
            let mut characters = word.chars();
            characters
                .next()
                .map(|first| first.to_ascii_uppercase().to_string() + characters.as_str())
                .unwrap_or_default()
        })
        .collect()
}

#[must_use]
pub fn field_name(value: &str) -> String {
    let mut words = split_words(value);
    let Some(first) = words.next() else {
        return String::new();
    };
    let mut output = first.to_owned();
    for word in words {
        let mut characters = word.chars();
        if let Some(first) = characters.next() {
            output.push(first.to_ascii_uppercase());
            output.push_str(characters.as_str());
        }
    }
    output
}

fn split_words(value: &str) -> impl Iterator<Item = &str> {
    value
        .split(|character: char| !character.is_ascii_alphanumeric())
        .filter(|part| !part.is_empty())
}

fn reserved_words() -> BTreeSet<&'static str> {
    BTreeSet::from([
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
    ])
}

#[cfg(test)]
mod tests {
    use tofu_dag_provider_schema::{BlockSchema, ProviderSchema, ResourceSchema};

    use super::*;

    #[test]
    fn derives_required_optional_computed_and_reserved_fields() {
        let block = BlockSchema {
            attributes: BTreeMap::from([
                (
                    "name".into(),
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
                    "type".into(),
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
            blocks: BTreeMap::new(),
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
        assert!(package.resources[0].fields[1].target_reserved);
        assert!(package.resources[0].fields[1].sensitive);
    }

    #[test]
    fn names_are_stable() {
        assert_eq!(pascal_case("project_resources"), "ProjectResources");
        assert_eq!(field_name("vpc_uuid"), "vpcUuid");
    }
}
