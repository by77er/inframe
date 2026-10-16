//! Decoding the normalized format, as `inframe provider inspect --output` writes it, with the
//! same interning as raw schemas. These seeds accept what the derived `Deserialize` impls
//! accept, written in the order `Serialize` writes it; anything else (a type's `value`
//! before its `kind`, say) fails the shared pass, and `read_schema_file` then decodes the
//! file with the derived impls.

use std::collections::BTreeMap;
use std::fmt;

use serde::Deserializer;
use serde::de::{self, DeserializeSeed, IgnoredAny, MapAccess, SeqAccess, Visitor};

use super::{Normalizer, Text, first_time};
use crate::shared::NameMap;
use crate::{
    AttributeSchema, BlockSchema, NestedBlockSchema, NestingMode, ResourceSchema, SchemaType,
};

/// `resources` or `data_sources`: `{"block": …}` by type name.
pub(super) struct StoredResourcesSeed<'a> {
    pub(super) normalizer: &'a mut Normalizer,
}

map_seed!(
    StoredResourcesSeed,
    BTreeMap<String, ResourceSchema>,
    "a map of resource schemas"
);

impl StoredResourcesSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<BTreeMap<String, ResourceSchema>, A::Error> {
        let mut resources = BTreeMap::new();
        while let Some(name) = map.next_key::<String>()? {
            let block = map.next_value_seed(StoredResourceSeed {
                normalizer: &mut *self.normalizer,
            })?;
            resources.insert(name, ResourceSchema { block });
        }
        Ok(resources)
    }
}

struct StoredResourceSeed<'a> {
    normalizer: &'a mut Normalizer,
}

map_seed!(StoredResourceSeed, BlockSchema, "a resource schema");

impl StoredResourceSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(self, mut map: A) -> Result<BlockSchema, A::Error> {
        let mut block = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            if &*key == "block" {
                first_time(block.is_some(), "block")?;
                block = Some(map.next_value_seed(StoredBlockSeed {
                    normalizer: &mut *self.normalizer,
                })?);
            } else {
                map.next_value::<IgnoredAny>()?;
            }
        }
        block.ok_or_else(|| de::Error::missing_field("block"))
    }
}

pub(super) struct StoredBlockSeed<'a> {
    pub(super) normalizer: &'a mut Normalizer,
}

map_seed!(StoredBlockSeed, BlockSchema, "a block schema");

impl StoredBlockSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(self, mut map: A) -> Result<BlockSchema, A::Error> {
        let mut attributes = None;
        let mut blocks = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "attributes" => {
                    first_time(attributes.is_some(), "attributes")?;
                    attributes = Some(map.next_value_seed(StoredAttributesSeed {
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                "blocks" => {
                    first_time(blocks.is_some(), "blocks")?;
                    blocks = Some(map.next_value_seed(StoredBlocksSeed {
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        Ok(BlockSchema {
            attributes: attributes.ok_or_else(|| de::Error::missing_field("attributes"))?,
            blocks: blocks.ok_or_else(|| de::Error::missing_field("blocks"))?,
        })
    }
}

/// Attributes by name: a block's, or an object type's fields.
struct StoredAttributesSeed<'a> {
    normalizer: &'a mut Normalizer,
}

map_seed!(
    StoredAttributesSeed,
    NameMap<AttributeSchema>,
    "a map of attributes"
);

impl StoredAttributesSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<NameMap<AttributeSchema>, A::Error> {
        let mut attributes = Vec::with_capacity(map.size_hint().unwrap_or(0));
        while let Some(name) = map.next_key::<Text<'de>>()? {
            let attribute = map.next_value_seed(StoredAttributeSeed {
                normalizer: &mut *self.normalizer,
            })?;
            attributes.push((self.normalizer.names.intern(&name), attribute));
        }
        Ok(NameMap::interned(
            attributes,
            &mut self.normalizer.attributes,
        ))
    }
}

struct StoredAttributeSeed<'a> {
    normalizer: &'a mut Normalizer,
}

map_seed!(StoredAttributeSeed, AttributeSchema, "an attribute schema");

impl StoredAttributeSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(self, mut map: A) -> Result<AttributeSchema, A::Error> {
        let mut r#type = None;
        let mut required = None;
        let mut optional = None;
        let mut computed = None;
        let mut sensitive = None;
        let mut description: Option<Option<Text<'de>>> = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "type" => {
                    first_time(r#type.is_some(), "type")?;
                    r#type = Some(map.next_value_seed(StoredTypeSeed {
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                "required" => {
                    first_time(required.is_some(), "required")?;
                    required = Some(map.next_value()?);
                }
                "optional" => {
                    first_time(optional.is_some(), "optional")?;
                    optional = Some(map.next_value()?);
                }
                "computed" => {
                    first_time(computed.is_some(), "computed")?;
                    computed = Some(map.next_value()?);
                }
                "sensitive" => {
                    first_time(sensitive.is_some(), "sensitive")?;
                    sensitive = Some(map.next_value()?);
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
        Ok(AttributeSchema {
            r#type: r#type.ok_or_else(|| de::Error::missing_field("type"))?,
            required: required.ok_or_else(|| de::Error::missing_field("required"))?,
            optional: optional.ok_or_else(|| de::Error::missing_field("optional"))?,
            computed: computed.ok_or_else(|| de::Error::missing_field("computed"))?,
            sensitive: sensitive.ok_or_else(|| de::Error::missing_field("sensitive"))?,
            description: description
                .flatten()
                .map(|description| self.normalizer.names.intern(&description)),
        })
    }
}

/// Nested blocks by name.
struct StoredBlocksSeed<'a> {
    normalizer: &'a mut Normalizer,
}

map_seed!(
    StoredBlocksSeed,
    NameMap<NestedBlockSchema>,
    "a map of nested blocks"
);

impl StoredBlocksSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(
        self,
        mut map: A,
    ) -> Result<NameMap<NestedBlockSchema>, A::Error> {
        let mut blocks = Vec::with_capacity(map.size_hint().unwrap_or(0));
        while let Some(name) = map.next_key::<Text<'de>>()? {
            let block = map.next_value_seed(StoredNestedBlockSeed {
                normalizer: &mut *self.normalizer,
            })?;
            blocks.push((self.normalizer.names.intern(&name), block));
        }
        Ok(NameMap::interned(blocks, &mut self.normalizer.blocks))
    }
}

struct StoredNestedBlockSeed<'a> {
    normalizer: &'a mut Normalizer,
}

map_seed!(
    StoredNestedBlockSeed,
    NestedBlockSchema,
    "a nested block schema"
);

impl StoredNestedBlockSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(self, mut map: A) -> Result<NestedBlockSchema, A::Error> {
        let mut nesting_mode = None;
        let mut min_items: Option<Option<u64>> = None;
        let mut max_items: Option<Option<u64>> = None;
        let mut block = None;
        while let Some(key) = map.next_key::<Text<'de>>()? {
            match &*key {
                "nesting_mode" => {
                    first_time(nesting_mode.is_some(), "nesting_mode")?;
                    nesting_mode = Some(map.next_value::<NestingMode>()?);
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
                    block = Some(map.next_value_seed(StoredBlockSeed {
                        normalizer: &mut *self.normalizer,
                    })?);
                }
                _ => {
                    map.next_value::<IgnoredAny>()?;
                }
            }
        }
        Ok(NestedBlockSchema {
            nesting_mode: nesting_mode.ok_or_else(|| de::Error::missing_field("nesting_mode"))?,
            min_items: min_items.flatten(),
            max_items: max_items.flatten(),
            block: block.ok_or_else(|| de::Error::missing_field("block"))?,
        })
    }
}

/// A [`SchemaType`] as `{"kind": …, "value": …}`, the kind first.
struct StoredTypeSeed<'a> {
    normalizer: &'a mut Normalizer,
}

map_seed!(StoredTypeSeed, SchemaType, "a schema type");

impl StoredTypeSeed<'_> {
    fn fields<'de, A: MapAccess<'de>>(self, mut map: A) -> Result<SchemaType, A::Error> {
        if map.next_key::<Text<'de>>()?.as_deref() != Some("kind") {
            return Err(de::Error::custom("expected the type's kind first"));
        }
        let kind = map.next_value::<Text<'de>>()?;
        let normalizer = self.normalizer;
        let r#type = match &*kind {
            "string" => SchemaType::String,
            "bool" => SchemaType::Bool,
            "number" => SchemaType::Number,
            "dynamic" => SchemaType::Dynamic,
            collection => {
                if map.next_key::<Text<'de>>()?.as_deref() != Some("value") {
                    return Err(de::Error::custom("expected the type's value"));
                }
                match collection {
                    "list" => SchemaType::List(Box::new(
                        map.next_value_seed(StoredTypeSeed { normalizer })?,
                    )),
                    "set" => SchemaType::Set(Box::new(
                        map.next_value_seed(StoredTypeSeed { normalizer })?,
                    )),
                    "map" => SchemaType::Map(Box::new(
                        map.next_value_seed(StoredTypeSeed { normalizer })?,
                    )),
                    "object" => SchemaType::Object(
                        map.next_value_seed(StoredAttributesSeed { normalizer })?,
                    ),
                    "tuple" => {
                        SchemaType::Tuple(map.next_value_seed(StoredTupleSeed { normalizer })?)
                    }
                    other => return Err(de::Error::unknown_variant(other, &[])),
                }
            }
        };
        if map.next_key::<IgnoredAny>()?.is_some() {
            return Err(de::Error::custom("unexpected field after the type"));
        }
        Ok(r#type)
    }
}

/// The element types of a tuple type.
struct StoredTupleSeed<'a> {
    normalizer: &'a mut Normalizer,
}

impl<'de> DeserializeSeed<'de> for StoredTupleSeed<'_> {
    type Value = Vec<SchemaType>;

    fn deserialize<D: Deserializer<'de>>(self, deserializer: D) -> Result<Self::Value, D::Error> {
        deserializer.deserialize_seq(self)
    }
}

impl<'de> Visitor<'de> for StoredTupleSeed<'_> {
    type Value = Vec<SchemaType>;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a list of schema types")
    }

    fn visit_seq<A: SeqAccess<'de>>(self, mut seq: A) -> Result<Self::Value, A::Error> {
        let mut elements = Vec::with_capacity(seq.size_hint().unwrap_or(0));
        while let Some(element) = seq.next_element_seed(StoredTypeSeed {
            normalizer: &mut *self.normalizer,
        })? {
            elements.push(element);
        }
        Ok(elements)
    }
}
