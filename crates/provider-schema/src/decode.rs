//! Decoding schema documents in one pass, normalizing and interning as they are read.
//!
//! One serde seed per kind of JSON object: each reads its object's fields like a derived
//! `Deserialize` would (unknown fields are skipped, a repeated field is an error, so is a
//! missing required one) and hands its children the normalizer and their schema path.

use std::borrow::Cow;
use std::collections::{BTreeMap, HashSet};
use std::fmt;
use std::hash::Hash;
use std::marker::PhantomData;
use std::ops::Deref;

use rustc_hash::FxBuildHasher;
use serde::de::{self, DeserializeSeed, IgnoredAny, MapAccess, SeqAccess, Visitor};
use serde::{Deserialize, Deserializer};

use crate::shared::{self, Interner, Name, NameMap};
use crate::{
    AttributeSchema, BlockSchema, NestedBlockSchema, NestingMode, NormalizeError, ProviderRequest,
    ProviderSchema, ResourceSchema, SchemaType,
};

pub(crate) fn decode(
    bytes: &[u8],
    request: &ProviderRequest,
    accept_normalized: bool,
) -> Result<Document, serde_json::Error> {
    let seed = |normalizer| DocumentSeed {
        request,
        normalizer,
        accept_normalized,
    };
    let mut normalizer = Normalizer::default();
    // Validating the input once lets the decoder skip validating every string in it. Invalid
    // UTF-8 is decoded from the bytes, which reports where it is.
    if let Ok(text) = std::str::from_utf8(bytes) {
        let mut deserializer = serde_json::Deserializer::from_str(text);
        let document = seed(&mut normalizer).deserialize(&mut deserializer)?;
        deserializer.end()?;
        Ok(document)
    } else {
        let mut deserializer = serde_json::Deserializer::from_slice(bytes);
        let document = seed(&mut normalizer).deserialize(&mut deserializer)?;
        deserializer.end()?;
        Ok(document)
    }
}

/// A normalized node, or the first problem in it in schema order.
type Normalized<T> = Result<T, NormalizeError>;

/// A JSON object's entries, normalized, in document order.
type NamedResults<'de, T> = Vec<(Text<'de>, Normalized<T>)>;

/// A JSON string, borrowed from the input whenever it contains no escapes.
#[derive(PartialEq, Eq, PartialOrd, Ord)]
struct Text<'de>(Cow<'de, str>);

impl Deref for Text<'_> {
    type Target = str;

    fn deref(&self) -> &str {
        &self.0
    }
}

impl fmt::Debug for Text<'_> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Debug::fmt(&*self.0, formatter)
    }
}

impl<'de: 'a, 'a> Deserialize<'de> for Text<'a> {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        struct TextVisitor<'a>(PhantomData<Text<'a>>);

        impl<'de: 'a, 'a> Visitor<'de> for TextVisitor<'a> {
            type Value = Text<'a>;

            fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
                formatter.write_str("a string")
            }

            fn visit_borrowed_str<E>(self, value: &'de str) -> Result<Self::Value, E> {
                Ok(Text(Cow::Borrowed(value)))
            }

            fn visit_str<E>(self, value: &str) -> Result<Self::Value, E> {
                Ok(Text(Cow::Owned(value.to_owned())))
            }

            fn visit_string<E>(self, value: String) -> Result<Self::Value, E> {
                Ok(Text(Cow::Owned(value)))
            }
        }

        deserializer.deserialize_str(TextVisitor(PhantomData))
    }
}

/// Where a schema node sits, for error messages: built on the stack while decoding descends,
/// and formatted only when something is wrong.
#[derive(Clone, Copy)]
struct SchemaPath<'p> {
    parent: Option<&'p SchemaPath<'p>>,
    segment: Segment<'p>,
}

#[derive(Clone, Copy)]
enum Segment<'p> {
    Root(&'p str),
    Field(&'p str),
    Index(usize),
}

impl<'p> SchemaPath<'p> {
    fn root(name: &'p str) -> Self {
        Self {
            parent: None,
            segment: Segment::Root(name),
        }
    }

    fn field(&'p self, name: &'p str) -> Self {
        Self {
            parent: Some(self),
            segment: Segment::Field(name),
        }
    }

    fn index(&'p self, index: usize) -> Self {
        Self {
            parent: Some(self),
            segment: Segment::Index(index),
        }
    }
}

impl fmt::Display for SchemaPath<'_> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        if let Some(parent) = self.parent {
            fmt::Display::fmt(parent, formatter)?;
        }
        match self.segment {
            Segment::Root(name) => formatter.write_str(name),
            Segment::Field(name) => write!(formatter, ".{name}"),
            Segment::Index(index) => write!(formatter, "[{index}]"),
        }
    }
}

/// Interned names, attribute and description text alike.
#[derive(Default)]
struct Names(HashSet<Name, FxBuildHasher>);

impl Names {
    fn intern(&mut self, text: &str) -> Name {
        if let Some(name) = self.0.get(text) {
            return name.clone();
        }
        let name = Name::from(text);
        self.0.insert(name.clone());
        name
    }
}

/// Builds normalized schemas with every name and node list interned.
#[derive(Default)]
struct Normalizer {
    names: Names,
    attributes: Interner<(Name, AttributeSchema)>,
    blocks: Interner<(Name, NestedBlockSchema)>,
}

/// The entries of one JSON object as an interned map, or the first problem among them by
/// name. Of two entries with the same name the later one is kept, as in a map.
fn name_map<T: Hash + Eq>(
    names: &mut Names,
    interner: &mut Interner<(Name, T)>,
    results: NamedResults<'_, T>,
) -> Normalized<NameMap<T>> {
    let mut entries = Vec::with_capacity(results.len());
    for (name, result) in shared::sort_unique(results) {
        entries.push((names.intern(&name), result?));
    }
    Ok(NameMap::interned(entries, interner))
}

impl Normalizer {
    fn block(
        &mut self,
        attributes: NamedResults<'_, AttributeSchema>,
        blocks: NamedResults<'_, NestedBlockSchema>,
    ) -> Normalized<BlockSchema> {
        Ok(BlockSchema {
            attributes: name_map(&mut self.names, &mut self.attributes, attributes)?,
            blocks: name_map(&mut self.names, &mut self.blocks, blocks)?,
        })
    }

    /// The type of a plugin-framework nested attribute: an object of its attributes, in a
    /// collection according to its nesting mode.
    fn nested_type(
        &mut self,
        nesting_mode: &str,
        attributes: NamedResults<'_, AttributeSchema>,
        path: &SchemaPath<'_>,
    ) -> Normalized<SchemaType> {
        let object =
            SchemaType::Object(name_map(&mut self.names, &mut self.attributes, attributes)?);
        Ok(match parse_nesting_mode(nesting_mode, path)? {
            NestingMode::Single | NestingMode::Group => object,
            NestingMode::List => SchemaType::List(Box::new(object)),
            NestingMode::Set => SchemaType::Set(Box::new(object)),
            NestingMode::Map => SchemaType::Map(Box::new(object)),
        })
    }

    /// A cty object type from its fields' types, in document order. A repeated field keeps
    /// its first position and its last type, as a JSON value's map would, and the first
    /// problem in that order wins.
    fn object_type(&mut self, mut fields: NamedResults<'_, SchemaType>) -> Normalized<SchemaType> {
        merge_repeated_keys(&mut fields);
        let mut attributes = Vec::with_capacity(fields.len());
        for (name, r#type) in fields {
            let attribute = AttributeSchema {
                r#type: r#type?,
                required: true,
                optional: false,
                computed: false,
                sensitive: false,
                description: None,
            };
            attributes.push((self.names.intern(&name), attribute));
        }
        Ok(SchemaType::Object(NameMap::interned(
            attributes,
            &mut self.attributes,
        )))
    }
}

/// Collapses each repeated key into its first position, holding the last value.
fn merge_repeated_keys<T>(entries: &mut Vec<(Text<'_>, T)>) {
    if entries.len() < 2 {
        return;
    }
    let mut order: Vec<usize> = (0..entries.len()).collect();
    // Stable, so the positions of one key stay in document order.
    order.sort_by(|&left, &right| entries[left].0.cmp(&entries[right].0));
    let mut repeated = vec![false; entries.len()];
    let mut moves = Vec::new();
    for run in order.chunk_by(|&left, &right| entries[left].0 == entries[right].0) {
        if let [first, .., last] = *run {
            moves.push((first, last));
            for &position in &run[1..] {
                repeated[position] = true;
            }
        }
    }
    for (first, last) in moves {
        entries.swap(first, last);
    }
    let mut position = 0;
    entries.retain(|_| {
        position += 1;
        !repeated[position - 1]
    });
}

fn invalid_type(path: &SchemaPath<'_>, message: impl Into<String>) -> NormalizeError {
    NormalizeError::InvalidType {
        path: path.to_string(),
        message: message.into(),
    }
}

fn parse_nesting_mode(value: &str, path: &SchemaPath<'_>) -> Normalized<NestingMode> {
    match value {
        "single" => Ok(NestingMode::Single),
        "list" => Ok(NestingMode::List),
        "set" => Ok(NestingMode::Set),
        "map" => Ok(NestingMode::Map),
        "group" => Ok(NestingMode::Group),
        mode => Err(NormalizeError::NestingMode {
            path: path.to_string(),
            mode: mode.to_owned(),
        }),
    }
}

/// Fails on the second occurrence of a field, as derived deserializers do.
fn first_time<E: de::Error>(seen: bool, field: &'static str) -> Result<(), E> {
    if seen {
        Err(E::duplicate_field(field))
    } else {
        Ok(())
    }
}

/// `null` or the value `S` decodes.
struct Nullable<S>(S);

impl<'de, S: DeserializeSeed<'de>> DeserializeSeed<'de> for Nullable<S> {
    type Value = Option<S::Value>;

    fn deserialize<D: Deserializer<'de>>(self, deserializer: D) -> Result<Self::Value, D::Error> {
        deserializer.deserialize_option(self)
    }
}

impl<'de, S: DeserializeSeed<'de>> Visitor<'de> for Nullable<S> {
    type Value = Option<S::Value>;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("an optional value")
    }

    fn visit_none<E>(self) -> Result<Self::Value, E> {
        Ok(None)
    }

    fn visit_unit<E>(self) -> Result<Self::Value, E> {
        Ok(None)
    }

    fn visit_some<D: Deserializer<'de>>(self, deserializer: D) -> Result<Self::Value, D::Error> {
        self.0.deserialize(deserializer).map(Some)
    }
}

/// Implements `DeserializeSeed` for a seed that is its own map visitor.
macro_rules! map_seed {
    ($seed:ident, $value:ty, $expecting:literal) => {
        impl<'de> DeserializeSeed<'de> for $seed<'_> {
            type Value = $value;

            fn deserialize<D: Deserializer<'de>>(
                self,
                deserializer: D,
            ) -> Result<Self::Value, D::Error> {
                deserializer.deserialize_map(self)
            }
        }

        impl<'de> Visitor<'de> for $seed<'_> {
            type Value = $value;

            fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
                formatter.write_str($expecting)
            }

            fn visit_map<A: MapAccess<'de>>(self, map: A) -> Result<Self::Value, A::Error> {
                self.fields(map)
            }
        }
    };
}

/// What decoding found: the raw format's fields, and the normalized format's when every one
/// of them is present.
pub(crate) struct Document {
    pub(crate) raw: Option<RawDocument>,
    pub(crate) normalized: Option<ProviderSchema>,
}

pub(crate) struct RawDocument {
    format_version: String,
    /// Every provider whose address matches the request, by address.
    providers: BTreeMap<String, NormalizedProvider>,
}

impl RawDocument {
    pub(crate) fn normalized(self, request: &ProviderRequest) -> Normalized<ProviderSchema> {
        if self.format_version.split('.').next() != Some("1") {
            return Err(NormalizeError::UnsupportedFormat(self.format_version));
        }
        // The first matching address in name order, as a lookup in a sorted map finds.
        let (_, provider) = self
            .providers
            .into_iter()
            .next()
            .ok_or_else(|| NormalizeError::MissingProvider(request.source.clone()))?;
        Ok(ProviderSchema {
            source: request.source.clone(),
            version: request.version.clone(),
            provider_config: provider.config?,
            resources: first_error(provider.resources)?,
            data_sources: first_error(provider.data_sources)?,
        })
    }
}

struct NormalizedProvider {
    config: Normalized<BlockSchema>,
    resources: BTreeMap<String, Normalized<ResourceSchema>>,
    data_sources: BTreeMap<String, Normalized<ResourceSchema>>,
}

fn first_error<T>(results: BTreeMap<String, Normalized<T>>) -> Normalized<BTreeMap<String, T>> {
    results
        .into_iter()
        .map(|(name, result)| Ok((name, result?)))
        .collect()
}

/// The top-level document. With `accept_normalized` the fields of a normalized schema are read
/// too, and neither format's fields are required.
struct DocumentSeed<'a> {
    request: &'a ProviderRequest,
    normalizer: &'a mut Normalizer,
    accept_normalized: bool,
}

map_seed!(DocumentSeed, Document, "a provider schema document");

impl DocumentSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(self, mut map: A) -> Result<Document, A::Error> {
        let mut format_version = None;
        let mut providers = None;
        let mut source = None;
        let mut version = None;
        let mut provider_config = None;
        let mut resources = None;
        let mut data_sources = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match (&*key, self.accept_normalized) {
                ("format_version", _) => {
                    first_time(format_version.is_some(), "format_version")?;
                    format_version = Some(map.next_value::<String>()?);
                }
                ("provider_schemas", _) => {
                    first_time(providers.is_some(), "provider_schemas")?;
                    providers = Some(map.next_value_seed(ProvidersSeed {
                        request: self.request,
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                ("source", true) => {
                    first_time(source.is_some(), "source")?;
                    source = Some(map.next_value::<String>()?);
                }
                ("version", true) => {
                    first_time(version.is_some(), "version")?;
                    version = Some(map.next_value::<String>()?);
                }
                ("provider_config", true) => {
                    first_time(provider_config.is_some(), "provider_config")?;
                    provider_config = Some(map.next_value_seed(StoredBlockSeed {
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                ("resources", true) => {
                    first_time(resources.is_some(), "resources")?;
                    resources = Some(map.next_value_seed(StoredResourcesSeed {
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                ("data_sources", true) => {
                    first_time(data_sources.is_some(), "data_sources")?;
                    data_sources = Some(map.next_value_seed(StoredResourcesSeed {
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        if !self.accept_normalized {
            if format_version.is_none() {
                return Err(de::Error::missing_field("format_version"));
            }
            if providers.is_none() {
                return Err(de::Error::missing_field("provider_schemas"));
            }
        }
        let normalized = match (source, version, provider_config, resources, data_sources) {
            (
                Some(source),
                Some(version),
                Some(provider_config),
                Some(resources),
                Some(data_sources),
            ) => Some(ProviderSchema {
                source,
                version,
                provider_config,
                resources,
                data_sources,
            }),
            _ => None,
        };
        let raw = format_version
            .zip(providers)
            .map(|(format_version, providers)| RawDocument {
                format_version,
                providers,
            });
        Ok(Document { raw, normalized })
    }
}

/// `provider_schemas`: every provider is normalized (so a problem anywhere in the JSON is
/// still found) and only the ones matching the request are kept.
struct ProvidersSeed<'a> {
    request: &'a ProviderRequest,
    normalizer: &'a mut Normalizer,
}

map_seed!(
    ProvidersSeed,
    BTreeMap<String, NormalizedProvider>,
    "a map of provider schemas"
);

impl ProvidersSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<BTreeMap<String, NormalizedProvider>, A::Error> {
        let mut providers = BTreeMap::new();
        while let Some(address) = map.next_key::<Text<'de>>()? {
            let provider = map.next_value_seed(ProviderSeed {
                normalizer: &mut *self.normalizer,
            })?;
            // A later duplicate of an address replaces it, as in a map.
            if self.request.matches(&address) {
                providers.insert(address.0.into_owned(), provider);
            }
        }
        Ok(providers)
    }
}

struct ProviderSeed<'a> {
    normalizer: &'a mut Normalizer,
}

map_seed!(ProviderSeed, NormalizedProvider, "a provider schema");

impl ProviderSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(self, mut map: A) -> Result<NormalizedProvider, A::Error> {
        let mut config = None;
        let mut resources = None;
        let mut data_sources = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "provider" => {
                    first_time(config.is_some(), "provider")?;
                    config = Some(map.next_value_seed(SchemaSeed {
                        normalizer: &mut *self.normalizer,
                        path: &SchemaPath::root("provider"),
                    })?);
                }
                "resource_schemas" => {
                    first_time(resources.is_some(), "resource_schemas")?;
                    resources = Some(map.next_value_seed(ResourcesSeed {
                        normalizer: &mut *self.normalizer,
                        prefix: "resource",
                    })?);
                }
                "data_source_schemas" => {
                    first_time(data_sources.is_some(), "data_source_schemas")?;
                    data_sources = Some(map.next_value_seed(ResourcesSeed {
                        normalizer: &mut *self.normalizer,
                        prefix: "data",
                    })?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        Ok(NormalizedProvider {
            config: config.ok_or_else(|| de::Error::missing_field("provider"))?,
            resources: resources.unwrap_or_default(),
            data_sources: data_sources.unwrap_or_default(),
        })
    }
}

/// `resource_schemas` or `data_source_schemas`, by type name.
struct ResourcesSeed<'a> {
    normalizer: &'a mut Normalizer,
    prefix: &'static str,
}

map_seed!(
    ResourcesSeed,
    BTreeMap<String, Normalized<ResourceSchema>>,
    "a map of resource schemas"
);

impl ResourcesSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<BTreeMap<String, Normalized<ResourceSchema>>, A::Error> {
        let root = SchemaPath::root(self.prefix);
        let mut schemas = BTreeMap::new();
        while let Some(name) = map.next_key::<Text<'de>>()? {
            let block = map.next_value_seed(SchemaSeed {
                normalizer: &mut *self.normalizer,
                path: &root.field(&name),
            })?;
            schemas.insert(
                name.0.into_owned(),
                block.map(|block| ResourceSchema { block }),
            );
        }
        Ok(schemas)
    }
}

/// `{"block": …}`, the schema of a provider, resource, or data source.
struct SchemaSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

map_seed!(SchemaSeed, Normalized<BlockSchema>, "a schema");

impl SchemaSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<Normalized<BlockSchema>, A::Error> {
        let mut block = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            if &*key == "block" {
                first_time(block.is_some(), "block")?;
                block = Some(map.next_value_seed(BlockSeed {
                    normalizer: &mut *self.normalizer,
                    path: self.path,
                })?);
            } else {
                map.next_value::<IgnoredAny>()?;
            }
        }
        block.ok_or_else(|| de::Error::missing_field("block"))
    }
}

/// A block: its `attributes` and nested `block_types`.
struct BlockSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

map_seed!(BlockSeed, Normalized<BlockSchema>, "a block");

impl BlockSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<Normalized<BlockSchema>, A::Error> {
        let mut attributes = None;
        let mut block_types = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "attributes" => {
                    first_time(attributes.is_some(), "attributes")?;
                    attributes = Some(map.next_value_seed(AttributesSeed {
                        normalizer: &mut *self.normalizer,
                        path: self.path,
                    })?);
                }
                "block_types" => {
                    first_time(block_types.is_some(), "block_types")?;
                    block_types = Some(map.next_value_seed(BlockTypesSeed {
                        normalizer: &mut *self.normalizer,
                        path: self.path,
                    })?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        Ok(self.normalizer.block(
            attributes.unwrap_or_default(),
            block_types.unwrap_or_default(),
        ))
    }
}

/// The attributes of a block or nested attribute type, by name.
struct AttributesSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

map_seed!(
    AttributesSeed,
    NamedResults<'de, AttributeSchema>,
    "a map of attributes"
);

impl AttributesSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<NamedResults<'de, AttributeSchema>, A::Error> {
        let mut results = Vec::with_capacity(map.size_hint().unwrap_or(0));
        while let Some(name) = map.next_key::<Text<'de>>()? {
            let result = map.next_value_seed(AttributeSeed {
                normalizer: &mut *self.normalizer,
                path: &self.path.field(&name),
            })?;
            results.push((name, result));
        }
        Ok(results)
    }
}

struct AttributeSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

map_seed!(AttributeSeed, Normalized<AttributeSchema>, "an attribute");

impl AttributeSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<Normalized<AttributeSchema>, A::Error> {
        let mut r#type = None;
        let mut nested_type = None;
        let mut required = None;
        let mut optional = None;
        let mut computed = None;
        let mut sensitive = None;
        let mut description: Option<Option<Text<'de>>> = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "type" => {
                    first_time(r#type.is_some(), "type")?;
                    r#type = Some(map.next_value_seed(Nullable(TypeSeed {
                        normalizer: &mut *self.normalizer,
                        path: self.path,
                    }))?);
                }
                "nested_type" => {
                    first_time(nested_type.is_some(), "nested_type")?;
                    nested_type = Some(map.next_value_seed(Nullable(NestedAttributeSeed {
                        normalizer: &mut *self.normalizer,
                        path: self.path,
                    }))?);
                }
                "required" => {
                    first_time(required.is_some(), "required")?;
                    required = Some(map.next_value::<bool>()?);
                }
                "optional" => {
                    first_time(optional.is_some(), "optional")?;
                    optional = Some(map.next_value::<bool>()?);
                }
                "computed" => {
                    first_time(computed.is_some(), "computed")?;
                    computed = Some(map.next_value::<bool>()?);
                }
                "sensitive" => {
                    first_time(sensitive.is_some(), "sensitive")?;
                    sensitive = Some(map.next_value::<bool>()?);
                }
                "description" => {
                    first_time(description.is_some(), "description")?;
                    description = Some(map.next_value()?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        let normalizer = self.normalizer;
        // A `type` wins over a `nested_type`; with neither the attribute is unusable.
        let r#type = match (r#type.flatten(), nested_type.flatten()) {
            (Some(r#type), _) => r#type,
            (None, Some(nested)) => nested,
            (None, None) => Err(NormalizeError::MissingType {
                path: self.path.to_string(),
            }),
        };
        Ok(r#type.map(|r#type| AttributeSchema {
            r#type,
            required: required.unwrap_or_default(),
            optional: optional.unwrap_or_default(),
            computed: computed.unwrap_or_default(),
            sensitive: sensitive.unwrap_or_default(),
            description: description
                .flatten()
                .map(|description| normalizer.names.intern(&description)),
        }))
    }
}

/// Implements the `Visitor` methods for JSON values a seed does not expect, which all decode
/// to the same problem.
macro_rules! other_values {
    (|$seed:ident| $problem:expr) => {
        fn visit_bool<E>(self, _: bool) -> Result<Self::Value, E> {
            let $seed = self;
            Ok(Err($problem))
        }

        fn visit_i64<E>(self, _: i64) -> Result<Self::Value, E> {
            let $seed = self;
            Ok(Err($problem))
        }

        fn visit_u64<E>(self, _: u64) -> Result<Self::Value, E> {
            let $seed = self;
            Ok(Err($problem))
        }

        fn visit_f64<E>(self, _: f64) -> Result<Self::Value, E> {
            let $seed = self;
            Ok(Err($problem))
        }

        fn visit_unit<E>(self) -> Result<Self::Value, E> {
            let $seed = self;
            Ok(Err($problem))
        }
    };
}

fn skip_seq<'de, A: SeqAccess<'de>>(mut seq: A) -> Result<(), A::Error> {
    while seq.next_element::<IgnoredAny>()?.is_some() {}
    Ok(())
}

fn skip_map<'de, A: MapAccess<'de>>(mut map: A) -> Result<(), A::Error> {
    while map.next_entry::<IgnoredAny, IgnoredAny>()?.is_some() {}
    Ok(())
}

/// A cty type in its JSON form, a primitive name or `[constructor, parameter]`, decoded
/// straight into an interned [`SchemaType`]. Types can be large (`definition` of
/// `aws_quicksight_analysis` spells 750 kB), and this never holds more of one than the path
/// to the value being read.
struct TypeSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

impl<'de> DeserializeSeed<'de> for TypeSeed<'_> {
    type Value = Normalized<SchemaType>;

    fn deserialize<D: Deserializer<'de>>(self, deserializer: D) -> Result<Self::Value, D::Error> {
        deserializer.deserialize_any(self)
    }
}

impl<'de> Visitor<'de> for TypeSeed<'_> {
    type Value = Normalized<SchemaType>;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a cty type")
    }

    other_values!(|seed| invalid_type(seed.path, "expected a primitive or constructor array"));

    fn visit_str<E>(self, primitive: &str) -> Result<Self::Value, E> {
        Ok(match primitive {
            "string" => Ok(SchemaType::String),
            "bool" => Ok(SchemaType::Bool),
            "number" => Ok(SchemaType::Number),
            "dynamic" => Ok(SchemaType::Dynamic),
            other => Err(invalid_type(
                self.path,
                format!("unknown primitive `{other}`"),
            )),
        })
    }

    fn visit_map<A: MapAccess<'de>>(self, map: A) -> Result<Self::Value, A::Error> {
        skip_map(map)?;
        Ok(Err(invalid_type(
            self.path,
            "expected a primitive or constructor array",
        )))
    }

    fn visit_seq<A: SeqAccess<'de>>(self, mut seq: A) -> Result<Self::Value, A::Error> {
        let Some(Some(constructor)) = seq
            .next_element::<ConstructorName<'de>>()?
            .map(|name| name.0)
        else {
            skip_seq(seq)?;
            return Ok(Err(invalid_type(self.path, "missing constructor")));
        };
        let (normalizer, path) = (self.normalizer, self.path);
        let parameter = match &*constructor {
            "list" | "set" | "map" => {
                seq.next_element_seed(TypeSeed { normalizer, path })?
                    .map(|item| {
                        item.map(|item| match &*constructor {
                            "list" => SchemaType::List(Box::new(item)),
                            "set" => SchemaType::Set(Box::new(item)),
                            _ => SchemaType::Map(Box::new(item)),
                        })
                    })
            }
            "object" => seq.next_element_seed(ObjectTypeSeed { normalizer, path })?,
            "tuple" => seq.next_element_seed(TupleTypeSeed { normalizer, path })?,
            other => seq
                .next_element::<IgnoredAny>()?
                .map(|_| Err(invalid_type(path, format!("unknown constructor `{other}`")))),
        };
        // Anything after the parameter (an object's optional attributes) is not part of the type.
        skip_seq(seq)?;
        Ok(parameter.unwrap_or_else(|| Err(invalid_type(path, "missing constructor parameter"))))
    }
}

/// The first element of a constructor array, when it is a string.
struct ConstructorName<'de>(Option<Text<'de>>);

impl<'de> Deserialize<'de> for ConstructorName<'de> {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        Ok(Self(deserializer.deserialize_any(ConstructorVisitor)?.ok()))
    }
}

struct ConstructorVisitor;

impl<'de> Visitor<'de> for ConstructorVisitor {
    type Value = Result<Text<'de>, ()>;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a constructor name")
    }

    other_values!(|_seed| ());

    fn visit_borrowed_str<E>(self, value: &'de str) -> Result<Self::Value, E> {
        Ok(Ok(Text(Cow::Borrowed(value))))
    }

    fn visit_str<E>(self, value: &str) -> Result<Self::Value, E> {
        Ok(Ok(Text(Cow::Owned(value.to_owned()))))
    }

    fn visit_seq<A: SeqAccess<'de>>(self, seq: A) -> Result<Self::Value, A::Error> {
        skip_seq(seq).map(|()| Err(()))
    }

    fn visit_map<A: MapAccess<'de>>(self, map: A) -> Result<Self::Value, A::Error> {
        skip_map(map).map(|()| Err(()))
    }
}

/// The parameter of `["object", …]`: field types by name.
struct ObjectTypeSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

impl<'de> DeserializeSeed<'de> for ObjectTypeSeed<'_> {
    type Value = Normalized<SchemaType>;

    fn deserialize<D: Deserializer<'de>>(self, deserializer: D) -> Result<Self::Value, D::Error> {
        deserializer.deserialize_any(self)
    }
}

impl<'de> Visitor<'de> for ObjectTypeSeed<'_> {
    type Value = Normalized<SchemaType>;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("an object type's fields")
    }

    other_values!(|seed| invalid_type(seed.path, "object parameter is not an object"));

    fn visit_str<E>(self, _: &str) -> Result<Self::Value, E> {
        Ok(Err(invalid_type(
            self.path,
            "object parameter is not an object",
        )))
    }

    fn visit_seq<A: SeqAccess<'de>>(self, seq: A) -> Result<Self::Value, A::Error> {
        skip_seq(seq)?;
        Ok(Err(invalid_type(
            self.path,
            "object parameter is not an object",
        )))
    }

    fn visit_map<A: MapAccess<'de>>(self, mut map: A) -> Result<Self::Value, A::Error> {
        let mut fields = Vec::with_capacity(map.size_hint().unwrap_or(0));
        while let Some(name) = map.next_key::<Text<'de>>()? {
            let r#type = map.next_value_seed(TypeSeed {
                normalizer: &mut *self.normalizer,
                path: &self.path.field(&name),
            })?;
            fields.push((name, r#type));
        }
        Ok(self.normalizer.object_type(fields))
    }
}

/// The parameter of `["tuple", …]`: element types by position.
struct TupleTypeSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

impl<'de> DeserializeSeed<'de> for TupleTypeSeed<'_> {
    type Value = Normalized<SchemaType>;

    fn deserialize<D: Deserializer<'de>>(self, deserializer: D) -> Result<Self::Value, D::Error> {
        deserializer.deserialize_any(self)
    }
}

impl<'de> Visitor<'de> for TupleTypeSeed<'_> {
    type Value = Normalized<SchemaType>;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a tuple type's elements")
    }

    other_values!(|seed| invalid_type(seed.path, "tuple parameter is not an array"));

    fn visit_str<E>(self, _: &str) -> Result<Self::Value, E> {
        Ok(Err(invalid_type(
            self.path,
            "tuple parameter is not an array",
        )))
    }

    fn visit_map<A: MapAccess<'de>>(self, map: A) -> Result<Self::Value, A::Error> {
        skip_map(map)?;
        Ok(Err(invalid_type(
            self.path,
            "tuple parameter is not an array",
        )))
    }

    fn visit_seq<A: SeqAccess<'de>>(self, mut seq: A) -> Result<Self::Value, A::Error> {
        let mut elements = Vec::with_capacity(seq.size_hint().unwrap_or(0));
        let mut problem = None;
        for index in 0.. {
            let Some(element) = seq.next_element_seed(TypeSeed {
                normalizer: &mut *self.normalizer,
                path: &self.path.index(index),
            })?
            else {
                break;
            };
            // The first problem by position wins; the elements after it are still decoded.
            match element {
                Ok(element) => elements.push(element),
                Err(error) => {
                    problem.get_or_insert(error);
                }
            }
        }
        Ok(problem.map_or(Ok(SchemaType::Tuple(elements)), Err))
    }
}

/// A plugin-framework `nested_type`: a nesting mode and the attributes of its object.
struct NestedAttributeSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

map_seed!(NestedAttributeSeed, Normalized<SchemaType>, "a nested type");

impl NestedAttributeSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<Normalized<SchemaType>, A::Error> {
        let mut nesting_mode: Option<Text<'de>> = None;
        let mut attributes = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "nesting_mode" => {
                    first_time(nesting_mode.is_some(), "nesting_mode")?;
                    nesting_mode = Some(map.next_value()?);
                }
                // Absent for an empty object type; plugin-framework providers emit a
                // `nesting_mode` with no attribute map for those.
                "attributes" => {
                    first_time(attributes.is_some(), "attributes")?;
                    attributes = Some(map.next_value_seed(AttributesSeed {
                        normalizer: &mut *self.normalizer,
                        path: self.path,
                    })?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        let nesting_mode = nesting_mode.ok_or_else(|| de::Error::missing_field("nesting_mode"))?;
        Ok(self
            .normalizer
            .nested_type(&nesting_mode, attributes.unwrap_or_default(), self.path))
    }
}

/// The nested blocks of a block, by name.
struct BlockTypesSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

map_seed!(
    BlockTypesSeed,
    NamedResults<'de, NestedBlockSchema>,
    "a map of nested blocks"
);

impl BlockTypesSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<NamedResults<'de, NestedBlockSchema>, A::Error> {
        let mut results = Vec::with_capacity(map.size_hint().unwrap_or(0));
        while let Some(name) = map.next_key::<Text<'de>>()? {
            let result = map.next_value_seed(NestedBlockSeed {
                normalizer: &mut *self.normalizer,
                path: &self.path.field(&name),
            })?;
            results.push((name, result));
        }
        Ok(results)
    }
}

struct NestedBlockSeed<'a> {
    normalizer: &'a mut Normalizer,
    path: &'a SchemaPath<'a>,
}

map_seed!(
    NestedBlockSeed,
    Normalized<NestedBlockSchema>,
    "a nested block"
);

impl NestedBlockSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<Normalized<NestedBlockSchema>, A::Error> {
        let mut nesting_mode: Option<Text<'de>> = None;
        let mut min_items: Option<Option<u64>> = None;
        let mut max_items: Option<Option<u64>> = None;
        let mut block = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "nesting_mode" => {
                    first_time(nesting_mode.is_some(), "nesting_mode")?;
                    nesting_mode = Some(map.next_value()?);
                }
                "min_items" => {
                    first_time(min_items.is_some(), "min_items")?;
                    min_items = Some(map.next_value()?);
                }
                "max_items" => {
                    first_time(max_items.is_some(), "max_items")?;
                    max_items = Some(map.next_value()?);
                }
                "block" => {
                    first_time(block.is_some(), "block")?;
                    block = Some(map.next_value_seed(BlockSeed {
                        normalizer: &mut *self.normalizer,
                        path: self.path,
                    })?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        let nesting_mode = nesting_mode.ok_or_else(|| de::Error::missing_field("nesting_mode"))?;
        let block = block.ok_or_else(|| de::Error::missing_field("block"))?;
        // The nesting mode is checked before anything inside the block.
        Ok(
            parse_nesting_mode(&nesting_mode, self.path).and_then(|nesting_mode| {
                Ok(NestedBlockSchema {
                    nesting_mode,
                    min_items: min_items.flatten(),
                    max_items: max_items.flatten(),
                    block: block?,
                })
            }),
        )
    }
}

mod stored;

use stored::{StoredBlockSeed, StoredResourcesSeed};

#[cfg(test)]
mod tests {
    use super::*;

    fn parse_type(json: &str) -> Normalized<SchemaType> {
        let mut normalizer = Normalizer::default();
        TypeSeed {
            normalizer: &mut normalizer,
            path: &SchemaPath::root("test"),
        }
        .deserialize(&mut serde_json::Deserializer::from_str(json))
        .unwrap()
    }

    #[test]
    fn parses_compound_cty_types() {
        assert_eq!(
            parse_type(r#"["list", ["map", "bool"]]"#).unwrap(),
            SchemaType::List(Box::new(SchemaType::Map(Box::new(SchemaType::Bool))))
        );
        assert_eq!(
            parse_type(r#"["object", {"a": "string"}, ["a"]]"#).unwrap(),
            SchemaType::Object(NameMap::from([(
                "a",
                AttributeSchema {
                    r#type: SchemaType::String,
                    required: true,
                    optional: false,
                    computed: false,
                    sensitive: false,
                    description: None,
                }
            )]))
        );
        let error = parse_type(r#"["tuple", ["string", "bad", ["map", "worse"]]]"#).unwrap_err();
        assert_eq!(
            error.to_string(),
            "invalid cty type at `test[1]`: unknown primitive `bad`"
        );
    }

    /// A repeated key in a cty object type keeps its first position and its last value.
    #[test]
    fn repeated_object_type_keys_keep_the_last_value() {
        let SchemaType::Object(fields) =
            parse_type(r#"["object", {"b": "string", "a": "bool", "b": "number"}]"#).unwrap()
        else {
            panic!("an object type");
        };
        assert_eq!(fields["b"].r#type, SchemaType::Number);
        assert_eq!(fields["a"].r#type, SchemaType::Bool);
        let error =
            parse_type(r#"["object", {"x": "string", "y": "bad", "x": "worse"}]"#).unwrap_err();
        assert_eq!(
            error.to_string(),
            "invalid cty type at `test.x`: unknown primitive `worse`"
        );
    }
}
