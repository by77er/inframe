//! Canonical, language-neutral desired-infrastructure graph.

use std::borrow::Cow;
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;

use schemars::{JsonSchema, Schema, SchemaGenerator, json_schema};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use thiserror::Error;

pub const GRAPH_FORMAT_VERSION: &str = "1.0";

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct GraphDocument {
    pub format_version: String,
    #[serde(default)]
    pub required_providers: BTreeMap<String, ProviderRequirement>,
    #[serde(default)]
    pub provider_configs: Vec<ProviderConfig>,
    #[serde(default)]
    pub resources: Vec<ResourceSpec>,
    #[serde(default)]
    pub data_sources: Vec<DataSourceSpec>,
    #[serde(default)]
    pub outputs: BTreeMap<String, OutputSpec>,
    #[serde(default)]
    pub moves: Vec<MoveSpec>,
}

impl Default for GraphDocument {
    fn default() -> Self {
        Self {
            format_version: GRAPH_FORMAT_VERSION.to_owned(),
            required_providers: BTreeMap::new(),
            provider_configs: Vec::new(),
            resources: Vec::new(),
            data_sources: Vec::new(),
            outputs: BTreeMap::new(),
            moves: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct ProviderRequirement {
    pub source: String,
    pub version: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct ProviderConfig {
    pub provider: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub alias: Option<String>,
    #[serde(default)]
    pub arguments: BTreeMap<String, Expr>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct ResourceSpec {
    #[serde(rename = "type")]
    pub resource_type: String,
    pub name: String,
    #[serde(default)]
    pub arguments: BTreeMap<String, Expr>,
    #[serde(default)]
    pub depends_on: Vec<Address>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub provider: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub lifecycle: Option<Lifecycle>,
}

impl ResourceSpec {
    #[must_use]
    pub fn address(&self) -> Address {
        Address::Resource {
            resource_type: self.resource_type.clone(),
            name: self.name.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct DataSourceSpec {
    #[serde(rename = "type")]
    pub data_source_type: String,
    pub name: String,
    #[serde(default)]
    pub arguments: BTreeMap<String, Expr>,
    #[serde(default)]
    pub depends_on: Vec<Address>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub provider: Option<String>,
}

impl DataSourceSpec {
    #[must_use]
    pub fn address(&self) -> Address {
        Address::DataSource {
            data_source_type: self.data_source_type.clone(),
            name: self.name.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct Lifecycle {
    #[serde(default, skip_serializing_if = "is_false")]
    pub create_before_destroy: bool,
    #[serde(default, skip_serializing_if = "is_false")]
    pub prevent_destroy: bool,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub ignore_changes: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub replace_triggered_by: Vec<Address>,
}

const fn is_false(value: &bool) -> bool {
    !*value
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct OutputSpec {
    pub value: Expr,
    #[serde(default, skip_serializing_if = "is_false")]
    pub sensitive: bool,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct MoveSpec {
    pub from: Address,
    pub to: Address,
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum Address {
    Resource {
        resource_type: String,
        name: String,
    },
    DataSource {
        data_source_type: String,
        name: String,
    },
}

impl JsonSchema for Address {
    fn schema_name() -> Cow<'static, str> {
        "Address".into()
    }

    fn json_schema(_generator: &mut SchemaGenerator) -> Schema {
        json_schema!({
            "type": "string",
            "pattern": "^(data\\.)?[A-Za-z_][A-Za-z0-9_-]*\\.[A-Za-z_][A-Za-z0-9_-]*$"
        })
    }
}

impl Address {
    pub fn parse(value: &str) -> Result<Self, AddressError> {
        let parts: Vec<_> = value.split('.').collect();
        match parts.as_slice() {
            [resource_type, name] if valid_identifier(resource_type) && valid_identifier(name) => {
                Ok(Self::Resource {
                    resource_type: (*resource_type).to_owned(),
                    name: (*name).to_owned(),
                })
            }
            ["data", data_source_type, name]
                if valid_identifier(data_source_type) && valid_identifier(name) =>
            {
                Ok(Self::DataSource {
                    data_source_type: (*data_source_type).to_owned(),
                    name: (*name).to_owned(),
                })
            }
            _ => Err(AddressError(value.to_owned())),
        }
    }

    #[must_use]
    pub fn is_resource(&self) -> bool {
        matches!(self, Self::Resource { .. })
    }
}

impl fmt::Display for Address {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Resource {
                resource_type,
                name,
            } => write!(formatter, "{resource_type}.{name}"),
            Self::DataSource {
                data_source_type,
                name,
            } => write!(formatter, "data.{data_source_type}.{name}"),
        }
    }
}

impl Serialize for Address {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

impl<'de> Deserialize<'de> for Address {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let value = String::deserialize(deserializer)?;
        Self::parse(&value).map_err(serde::de::Error::custom)
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum Expr {
    Literal {
        value: Value,
    },
    ResourceAttr {
        address: Address,
        path: Vec<String>,
    },
    DataSourceAttr {
        address: Address,
        path: Vec<String>,
    },
    Array {
        items: Vec<Expr>,
    },
    Object {
        fields: BTreeMap<String, Expr>,
    },
    Index {
        collection: Box<Expr>,
        key: Box<Expr>,
    },
    Conditional {
        condition: Box<Expr>,
        when_true: Box<Expr>,
        when_false: Box<Expr>,
    },
    Function {
        name: String,
        args: Vec<Expr>,
    },
    Template {
        parts: Vec<TemplatePart>,
    },
    SecretEnv {
        name: String,
    },
    UnsafeRaw {
        expression: String,
    },
}

impl Expr {
    #[must_use]
    pub fn literal(value: impl Into<Value>) -> Self {
        Self::Literal {
            value: value.into(),
        }
    }

    fn references(&self, references: &mut BTreeSet<Address>) {
        match self {
            Self::ResourceAttr { address, .. } | Self::DataSourceAttr { address, .. } => {
                references.insert(address.clone());
            }
            Self::Array { items } => {
                for item in items {
                    item.references(references);
                }
            }
            Self::Object { fields } => {
                for value in fields.values() {
                    value.references(references);
                }
            }
            Self::Index { collection, key } => {
                collection.references(references);
                key.references(references);
            }
            Self::Conditional {
                condition,
                when_true,
                when_false,
            } => {
                condition.references(references);
                when_true.references(references);
                when_false.references(references);
            }
            Self::Function { args, .. } => {
                for argument in args {
                    argument.references(references);
                }
            }
            Self::Template { parts } => {
                for part in parts {
                    if let TemplatePart::Interpolation { expression } = part {
                        expression.references(references);
                    }
                }
            }
            Self::Literal { .. } | Self::SecretEnv { .. } | Self::UnsafeRaw { .. } => {}
        }
    }

    fn collect_secret_environment_names(&self, names: &mut BTreeSet<String>) {
        match self {
            Self::SecretEnv { name } => {
                names.insert(name.clone());
            }
            Self::Array { items } => {
                for item in items {
                    item.collect_secret_environment_names(names);
                }
            }
            Self::Object { fields } => {
                for value in fields.values() {
                    value.collect_secret_environment_names(names);
                }
            }
            Self::Index { collection, key } => {
                collection.collect_secret_environment_names(names);
                key.collect_secret_environment_names(names);
            }
            Self::Conditional {
                condition,
                when_true,
                when_false,
            } => {
                condition.collect_secret_environment_names(names);
                when_true.collect_secret_environment_names(names);
                when_false.collect_secret_environment_names(names);
            }
            Self::Function { args, .. } => {
                for argument in args {
                    argument.collect_secret_environment_names(names);
                }
            }
            Self::Template { parts } => {
                for part in parts {
                    if let TemplatePart::Interpolation { expression } = part {
                        expression.collect_secret_environment_names(names);
                    }
                }
            }
            Self::Literal { .. }
            | Self::ResourceAttr { .. }
            | Self::DataSourceAttr { .. }
            | Self::UnsafeRaw { .. } => {}
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum TemplatePart {
    Literal { value: String },
    Interpolation { expression: Box<Expr> },
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Dependency {
    pub from: Address,
    pub to: Address,
    pub explicit: bool,
}

#[derive(Debug, Error, PartialEq, Eq)]
pub enum ValidationError {
    #[error("unsupported Graph IR format version `{0}`; this build supports 1.x")]
    UnsupportedVersion(String),
    #[error("invalid identifier `{value}` at {path}")]
    InvalidIdentifier { path: String, value: String },
    #[error("duplicate graph address `{0}`")]
    DuplicateAddress(Address),
    #[error("duplicate provider configuration `{0}`")]
    DuplicateProviderConfig(String),
    #[error("{owner} selects provider configuration `{provider}`, but it is not configured")]
    MissingProviderConfig { owner: String, provider: String },
    #[error("invalid secret environment variable `{value}` at {path}")]
    InvalidSecretEnvironment { path: String, value: String },
    #[error("{owner} references missing graph address `{target}`")]
    MissingReference { owner: String, target: Address },
    #[error(
        "{owner} contains a resource reference where a data-source reference is required: `{target}`"
    )]
    ReferenceKind { owner: String, target: Address },
    #[error("{owner} depends on itself")]
    SelfDependency { owner: Address },
    #[error(
        "{owner} uses data source `{target}` in replace_triggered_by; only managed resources are allowed"
    )]
    InvalidReplaceTriggeredBy { owner: Address, target: Address },
    #[error("move target `{0}` is not present in this graph")]
    MissingMoveTarget(Address),
    #[error("duplicate move target `{0}`")]
    DuplicateMoveTarget(Address),
}

#[derive(Debug, Error, PartialEq, Eq)]
#[error("invalid graph address `{0}`")]
pub struct AddressError(String);

impl GraphDocument {
    pub fn validate(&self) -> Result<(), ValidationError> {
        if self.format_version.split('.').next() != Some("1") {
            return Err(ValidationError::UnsupportedVersion(
                self.format_version.clone(),
            ));
        }

        for name in self.required_providers.keys() {
            validate_identifier("required_providers", name)?;
        }
        let mut configured_providers = BTreeSet::new();
        for (index, provider) in self.provider_configs.iter().enumerate() {
            validate_identifier(
                &format!("provider_configs[{index}].provider"),
                &provider.provider,
            )?;
            if let Some(alias) = &provider.alias {
                validate_identifier(&format!("provider_configs[{index}].alias"), alias)?;
            }
            let address = provider_address(provider);
            if !configured_providers.insert(address.clone()) {
                return Err(ValidationError::DuplicateProviderConfig(address));
            }
        }

        let mut addresses = BTreeSet::new();
        for resource in &self.resources {
            validate_identifier("resources[].type", &resource.resource_type)?;
            validate_identifier("resources[].name", &resource.name)?;
            let address = resource.address();
            if !addresses.insert(address.clone()) {
                return Err(ValidationError::DuplicateAddress(address));
            }
        }
        for data_source in &self.data_sources {
            validate_identifier("data_sources[].type", &data_source.data_source_type)?;
            validate_identifier("data_sources[].name", &data_source.name)?;
            let address = data_source.address();
            if !addresses.insert(address.clone()) {
                return Err(ValidationError::DuplicateAddress(address));
            }
        }

        for resource in &self.resources {
            validate_owner(
                &resource.address(),
                resource.arguments.values(),
                &resource.depends_on,
                &addresses,
            )?;
            validate_selected_provider(
                &resource.address().to_string(),
                resource.provider.as_deref(),
                &configured_providers,
            )?;
            validate_replacement_triggers(resource, &addresses)?;
        }
        for data_source in &self.data_sources {
            validate_owner(
                &data_source.address(),
                data_source.arguments.values(),
                &data_source.depends_on,
                &addresses,
            )?;
            validate_selected_provider(
                &data_source.address().to_string(),
                data_source.provider.as_deref(),
                &configured_providers,
            )?;
        }
        for (name, output) in &self.outputs {
            validate_expr(&format!("output.{name}"), &output.value, &addresses)?;
        }
        for (index, provider) in self.provider_configs.iter().enumerate() {
            for expression in provider.arguments.values() {
                validate_expr(
                    &format!("provider_configs[{index}]"),
                    expression,
                    &addresses,
                )?;
            }
        }

        let mut move_targets = BTreeSet::new();
        for movement in &self.moves {
            if !addresses.contains(&movement.to) {
                return Err(ValidationError::MissingMoveTarget(movement.to.clone()));
            }
            if !move_targets.insert(movement.to.clone()) {
                return Err(ValidationError::DuplicateMoveTarget(movement.to.clone()));
            }
        }
        Ok(())
    }

    pub fn dependencies(&self) -> Result<BTreeSet<Dependency>, ValidationError> {
        self.validate()?;
        let mut dependencies = BTreeSet::new();
        for resource in &self.resources {
            add_dependencies(
                &resource.address(),
                resource.arguments.values(),
                &resource.depends_on,
                &mut dependencies,
            );
        }
        for data_source in &self.data_sources {
            add_dependencies(
                &data_source.address(),
                data_source.arguments.values(),
                &data_source.depends_on,
                &mut dependencies,
            );
        }
        Ok(dependencies)
    }

    #[must_use]
    pub fn secret_environment_names(&self) -> BTreeSet<String> {
        let mut names = BTreeSet::new();
        for provider in &self.provider_configs {
            collect_secret_names(provider.arguments.values(), &mut names);
        }
        for resource in &self.resources {
            collect_secret_names(resource.arguments.values(), &mut names);
        }
        for data_source in &self.data_sources {
            collect_secret_names(data_source.arguments.values(), &mut names);
        }
        for output in self.outputs.values() {
            output.value.collect_secret_environment_names(&mut names);
        }
        names
    }

    pub fn to_canonical_json(&self) -> Result<String, serde_json::Error> {
        let mut value = serde_json::to_value(self)?;
        sort_json(&mut value);
        let mut rendered = serde_json::to_string_pretty(&value)?;
        rendered.push('\n');
        Ok(rendered)
    }

    #[must_use]
    pub fn json_schema() -> Value {
        serde_json::to_value(schemars::schema_for!(Self)).expect("schema serializes")
    }
}

fn validate_owner<'a>(
    owner: &Address,
    expressions: impl Iterator<Item = &'a Expr>,
    explicit: &[Address],
    addresses: &BTreeSet<Address>,
) -> Result<(), ValidationError> {
    for expression in expressions {
        validate_expr(&owner.to_string(), expression, addresses)?;
    }
    for target in explicit {
        if target == owner {
            return Err(ValidationError::SelfDependency {
                owner: owner.clone(),
            });
        }
        if !addresses.contains(target) {
            return Err(ValidationError::MissingReference {
                owner: owner.to_string(),
                target: target.clone(),
            });
        }
    }
    Ok(())
}

fn validate_replacement_triggers(
    resource: &ResourceSpec,
    addresses: &BTreeSet<Address>,
) -> Result<(), ValidationError> {
    let Some(lifecycle) = &resource.lifecycle else {
        return Ok(());
    };
    for target in &lifecycle.replace_triggered_by {
        if !target.is_resource() {
            return Err(ValidationError::InvalidReplaceTriggeredBy {
                owner: resource.address(),
                target: target.clone(),
            });
        }
        if !addresses.contains(target) {
            return Err(ValidationError::MissingReference {
                owner: resource.address().to_string(),
                target: target.clone(),
            });
        }
    }
    Ok(())
}

fn validate_expr(
    owner: &str,
    expression: &Expr,
    addresses: &BTreeSet<Address>,
) -> Result<(), ValidationError> {
    validate_expr_structure(owner, expression)?;
    let mut references = BTreeSet::new();
    expression.references(&mut references);
    for target in references {
        if !addresses.contains(&target) {
            return Err(ValidationError::MissingReference {
                owner: owner.to_owned(),
                target,
            });
        }
    }
    Ok(())
}

fn validate_expr_structure(owner: &str, expression: &Expr) -> Result<(), ValidationError> {
    match expression {
        Expr::ResourceAttr { address, path } => {
            if !address.is_resource() {
                return Err(ValidationError::ReferenceKind {
                    owner: owner.to_owned(),
                    target: address.clone(),
                });
            }
            validate_path(owner, path)?;
        }
        Expr::DataSourceAttr { address, path } => {
            if address.is_resource() {
                return Err(ValidationError::ReferenceKind {
                    owner: owner.to_owned(),
                    target: address.clone(),
                });
            }
            validate_path(owner, path)?;
        }
        Expr::Array { items } => {
            for item in items {
                validate_expr_structure(owner, item)?;
            }
        }
        Expr::Object { fields } => {
            for value in fields.values() {
                validate_expr_structure(owner, value)?;
            }
        }
        Expr::Index { collection, key } => {
            validate_expr_structure(owner, collection)?;
            validate_expr_structure(owner, key)?;
        }
        Expr::Conditional {
            condition,
            when_true,
            when_false,
        } => {
            validate_expr_structure(owner, condition)?;
            validate_expr_structure(owner, when_true)?;
            validate_expr_structure(owner, when_false)?;
        }
        Expr::Function { name, args } => {
            validate_identifier(owner, name)?;
            for argument in args {
                validate_expr_structure(owner, argument)?;
            }
        }
        Expr::Template { parts } => {
            for part in parts {
                if let TemplatePart::Interpolation { expression } = part {
                    validate_expr_structure(owner, expression)?;
                }
            }
        }
        Expr::SecretEnv { name } => {
            if !valid_environment_name(name) {
                return Err(ValidationError::InvalidSecretEnvironment {
                    path: owner.to_owned(),
                    value: name.clone(),
                });
            }
        }
        Expr::Literal { .. } | Expr::UnsafeRaw { .. } => {}
    }
    Ok(())
}

fn collect_secret_names<'a>(
    expressions: impl Iterator<Item = &'a Expr>,
    names: &mut BTreeSet<String>,
) {
    for expression in expressions {
        expression.collect_secret_environment_names(names);
    }
}

fn provider_address(provider: &ProviderConfig) -> String {
    match &provider.alias {
        Some(alias) => format!("{}.{alias}", provider.provider),
        None => provider.provider.clone(),
    }
}

fn validate_selected_provider(
    owner: &str,
    provider: Option<&str>,
    configured: &BTreeSet<String>,
) -> Result<(), ValidationError> {
    let Some(provider) = provider else {
        return Ok(());
    };
    let valid = match provider.split_once('.') {
        Some((local_name, alias)) => valid_identifier(local_name) && valid_identifier(alias),
        None => valid_identifier(provider),
    };
    if !valid || provider.matches('.').count() > 1 {
        return Err(ValidationError::InvalidIdentifier {
            path: format!("{owner}.provider"),
            value: provider.to_owned(),
        });
    }
    if !configured.contains(provider) {
        return Err(ValidationError::MissingProviderConfig {
            owner: owner.to_owned(),
            provider: provider.to_owned(),
        });
    }
    Ok(())
}

fn validate_path(owner: &str, path: &[String]) -> Result<(), ValidationError> {
    for element in path {
        validate_identifier(owner, element)?;
    }
    Ok(())
}

fn add_dependencies<'a>(
    owner: &Address,
    expressions: impl Iterator<Item = &'a Expr>,
    explicit: &[Address],
    output: &mut BTreeSet<Dependency>,
) {
    for expression in expressions {
        let mut references = BTreeSet::new();
        expression.references(&mut references);
        for from in references {
            output.insert(Dependency {
                from,
                to: owner.clone(),
                explicit: false,
            });
        }
    }
    for from in explicit {
        output.insert(Dependency {
            from: from.clone(),
            to: owner.clone(),
            explicit: true,
        });
    }
}

fn validate_identifier(path: &str, value: &str) -> Result<(), ValidationError> {
    if valid_identifier(value) {
        Ok(())
    } else {
        Err(ValidationError::InvalidIdentifier {
            path: path.to_owned(),
            value: value.to_owned(),
        })
    }
}

fn valid_identifier(value: &str) -> bool {
    let mut characters = value.chars();
    matches!(characters.next(), Some(first) if first == '_' || first.is_ascii_alphabetic())
        && characters.all(|character| {
            character == '_' || character == '-' || character.is_ascii_alphanumeric()
        })
}

fn valid_environment_name(value: &str) -> bool {
    let mut characters = value.chars();
    matches!(characters.next(), Some(first) if first == '_' || first.is_ascii_alphabetic())
        && characters.all(|character| character == '_' || character.is_ascii_alphanumeric())
}

fn sort_json(value: &mut Value) {
    match value {
        Value::Object(object) => {
            let old = std::mem::take(object);
            let mut entries: Vec<_> = old.into_iter().collect();
            entries.sort_by(|left, right| left.0.cmp(&right.0));
            for (key, mut value) in entries {
                sort_json(&mut value);
                object.insert(key, value);
            }
        }
        Value::Array(items) => {
            for item in items {
                sort_json(item);
            }
        }
        _ => {}
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn tag_graph() -> GraphDocument {
        let tag = ResourceSpec {
            resource_type: "digitalocean_tag".into(),
            name: "app".into(),
            arguments: BTreeMap::from([("name".into(), Expr::literal("app"))]),
            depends_on: Vec::new(),
            provider: None,
            lifecycle: None,
        };
        let read = DataSourceSpec {
            data_source_type: "digitalocean_tag".into(),
            name: "app_read".into(),
            arguments: BTreeMap::from([(
                "name".into(),
                Expr::ResourceAttr {
                    address: tag.address(),
                    path: vec!["name".into()],
                },
            )]),
            depends_on: Vec::new(),
            provider: None,
        };
        GraphDocument {
            resources: vec![tag],
            data_sources: vec![read],
            ..GraphDocument::default()
        }
    }

    #[test]
    fn address_round_trip() {
        for value in ["digitalocean_tag.app", "data.digitalocean_tag.app"] {
            let address = Address::parse(value).unwrap();
            assert_eq!(address.to_string(), value);
            assert_eq!(
                serde_json::from_str::<Address>(&format!("\"{value}\"")).unwrap(),
                address
            );
        }
    }

    #[test]
    fn derives_dependencies_from_references() {
        let dependencies = tag_graph().dependencies().unwrap();
        assert_eq!(dependencies.len(), 1);
        let edge = dependencies.first().unwrap();
        assert_eq!(edge.from.to_string(), "digitalocean_tag.app");
        assert_eq!(edge.to.to_string(), "data.digitalocean_tag.app_read");
        assert!(!edge.explicit);
    }

    #[test]
    fn rejects_missing_reference() {
        let mut graph = tag_graph();
        graph.resources.clear();
        assert!(matches!(
            graph.validate(),
            Err(ValidationError::MissingReference { .. })
        ));
    }

    #[test]
    fn canonical_json_is_stable_and_terminated() {
        let first = tag_graph().to_canonical_json().unwrap();
        let second = tag_graph().to_canonical_json().unwrap();
        assert_eq!(first, second);
        assert!(first.ends_with('\n'));
    }

    #[test]
    fn schema_is_generated() {
        let schema = GraphDocument::json_schema();
        assert_eq!(schema["title"], "GraphDocument");
        assert_eq!(schema["$defs"]["Address"]["type"], "string");
    }

    #[test]
    fn rejects_duplicate_addresses() {
        let mut graph = tag_graph();
        graph.resources.push(graph.resources[0].clone());
        assert!(matches!(
            graph.validate(),
            Err(ValidationError::DuplicateAddress(_))
        ));
    }

    #[test]
    fn discovers_and_validates_nested_secret_environment_names() {
        let mut graph = tag_graph();
        graph.resources[0].arguments.insert(
            "description".into(),
            Expr::Function {
                name: "lower".into(),
                args: vec![Expr::SecretEnv {
                    name: "DIGITALOCEAN_TOKEN".into(),
                }],
            },
        );
        graph.validate().unwrap();
        assert_eq!(
            graph.secret_environment_names(),
            BTreeSet::from(["DIGITALOCEAN_TOKEN".to_owned()])
        );

        graph.resources[0].arguments.insert(
            "invalid".into(),
            Expr::SecretEnv {
                name: "not-valid".into(),
            },
        );
        assert!(matches!(
            graph.validate(),
            Err(ValidationError::InvalidSecretEnvironment { .. })
        ));
    }

    #[test]
    fn rejects_an_unconfigured_provider_selection() {
        let mut graph = tag_graph();
        graph.resources[0].provider = Some("digitalocean.west".into());
        assert!(matches!(
            graph.validate(),
            Err(ValidationError::MissingProviderConfig { .. })
        ));
    }

    #[test]
    fn rejects_a_data_source_replace_trigger() {
        let mut graph = tag_graph();
        let data_source = graph.data_sources[0].address();
        graph.resources[0].lifecycle = Some(Lifecycle {
            replace_triggered_by: vec![data_source],
            ..Lifecycle::default()
        });

        assert!(matches!(
            graph.validate(),
            Err(ValidationError::InvalidReplaceTriggeredBy { .. })
        ));
    }
}
