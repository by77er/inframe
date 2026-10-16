//! Hash-consed schema storage.
//!
//! Provider schemas unroll recursive blocks to a fixed depth, so one resource can repeat the
//! same nested block thousands of times (`aws_wafv2_web_acl_rule` has 42,000 schema nodes but
//! only a few dozen distinct blocks). Interning every node list as it is built stores each
//! distinct list once, and caching its structural hash makes two copies comparable in O(1):
//! equal lists are the same allocation, so `eq` succeeds on the pointer check and later stages
//! can deduplicate by value without walking whole subtrees.

use std::collections::HashSet;
use std::fmt;
use std::hash::{BuildHasher, Hash, Hasher};
use std::ops::{Deref, Index};
use std::sync::Arc;

use rustc_hash::FxBuildHasher;
use serde::de::{MapAccess, Visitor};
use serde::ser::SerializeMap;
use serde::{Deserialize, Deserializer, Serialize, Serializer};

/// A schema identifier: attribute, block, or description text, shared between every node
/// that uses it.
pub type Name = Arc<str>;

/// An immutable slice behind a reference count, hashed once when it is built.
pub struct Shared<T> {
    hash: u64,
    items: Arc<[T]>,
}

impl<T: Hash> Shared<T> {
    #[must_use]
    pub fn new(items: Vec<T>) -> Self {
        Self {
            hash: FxBuildHasher.hash_one(items.as_slice()),
            items: items.into(),
        }
    }
}

impl<T> Shared<T> {
    /// Whether both handles point at the same allocation, which interning guarantees for
    /// equal values.
    #[must_use]
    pub fn ptr_eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.items, &other.items)
    }
}

impl<T> Clone for Shared<T> {
    fn clone(&self) -> Self {
        Self {
            hash: self.hash,
            items: Arc::clone(&self.items),
        }
    }
}

impl<T> Deref for Shared<T> {
    type Target = [T];

    fn deref(&self) -> &[T] {
        &self.items
    }
}

impl<T: Hash> Default for Shared<T> {
    fn default() -> Self {
        Self::new(Vec::new())
    }
}

impl<T: Hash> From<Vec<T>> for Shared<T> {
    fn from(items: Vec<T>) -> Self {
        Self::new(items)
    }
}

impl<T: Hash> FromIterator<T> for Shared<T> {
    fn from_iter<I: IntoIterator<Item = T>>(items: I) -> Self {
        Self::new(items.into_iter().collect())
    }
}

impl<T: PartialEq> PartialEq for Shared<T> {
    fn eq(&self, other: &Self) -> bool {
        self.ptr_eq(other) || (self.hash == other.hash && self.items[..] == other.items[..])
    }
}

impl<T: Eq> Eq for Shared<T> {}

impl<T> Hash for Shared<T> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        state.write_u64(self.hash);
    }
}

impl<T: fmt::Debug> fmt::Debug for Shared<T> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.debug_list().entries(self.items.iter()).finish()
    }
}

impl<T: Serialize> Serialize for Shared<T> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        self.items.serialize(serializer)
    }
}

impl<'de, T: Deserialize<'de> + Hash> Deserialize<'de> for Shared<T> {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        Vec::deserialize(deserializer).map(Self::new)
    }
}

/// Hands out one [`Shared`] per distinct value.
pub struct Interner<T> {
    values: HashSet<Shared<T>, FxBuildHasher>,
}

impl<T> Default for Interner<T> {
    fn default() -> Self {
        Self {
            values: HashSet::default(),
        }
    }
}

impl<T: Hash + Eq> Interner<T> {
    pub fn intern(&mut self, items: Vec<T>) -> Shared<T> {
        let candidate = Shared::new(items);
        if let Some(existing) = self.values.get(&candidate) {
            return existing.clone();
        }
        self.values.insert(candidate.clone());
        candidate
    }
}

/// Named entries sorted by name, like a `BTreeMap<String, T>` but immutable and shared: two
/// blocks with the same attributes hold the same allocation. Serializes as a JSON object with
/// its keys in order, exactly as the map it replaces.
#[derive(Clone, PartialEq, Eq, Hash)]
pub struct NameMap<T>(Shared<(Name, T)>);

impl<T: Hash> NameMap<T> {
    /// Sorts the entries by name; of two entries with the same name the later one is kept, as
    /// inserting both into a map would.
    #[must_use]
    pub fn new(entries: Vec<(Name, T)>) -> Self {
        Self(Shared::new(sort_unique(entries)))
    }

    /// Like [`NameMap::new`], but returns the interned copy when an equal map exists.
    pub fn interned(entries: Vec<(Name, T)>, interner: &mut Interner<(Name, T)>) -> Self
    where
        T: Eq,
    {
        Self(interner.intern(sort_unique(entries)))
    }
}

impl<T> NameMap<T> {
    #[must_use]
    pub fn len(&self) -> usize {
        self.0.len()
    }

    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    #[must_use]
    pub fn iter(&self) -> impl ExactSizeIterator<Item = (&Name, &T)> {
        self.0.iter().map(|(name, value)| (name, value))
    }

    #[must_use]
    pub fn keys(&self) -> impl ExactSizeIterator<Item = &Name> {
        self.0.iter().map(|(name, _)| name)
    }

    #[must_use]
    pub fn values(&self) -> impl ExactSizeIterator<Item = &T> {
        self.0.iter().map(|(_, value)| value)
    }

    #[must_use]
    pub fn get(&self, name: &str) -> Option<&T> {
        self.0
            .binary_search_by(|(key, _)| key.as_ref().cmp(name))
            .ok()
            .map(|index| &self.0[index].1)
    }

    /// The shared entry list, for callers that memoize work per distinct map.
    #[must_use]
    pub fn entries(&self) -> &Shared<(Name, T)> {
        &self.0
    }
}

/// Sorts entries by key; of two entries with the same key the later one is kept, as inserting
/// both into a map would.
pub(crate) fn sort_unique<K: Ord, T>(mut entries: Vec<(K, T)>) -> Vec<(K, T)> {
    // Stable, so equal keys stay in input order and `dedup_by` can keep the last of them.
    entries.sort_by(|(left, _), (right, _)| left.cmp(right));
    entries.dedup_by(|later, kept| {
        if later.0 == kept.0 {
            std::mem::swap(later, kept);
            true
        } else {
            false
        }
    });
    entries
}

impl<T: Hash> Default for NameMap<T> {
    fn default() -> Self {
        Self(Shared::default())
    }
}

impl<T> Index<&str> for NameMap<T> {
    type Output = T;

    fn index(&self, name: &str) -> &T {
        self.get(name)
            .unwrap_or_else(|| panic!("no entry named `{name}`"))
    }
}

impl<K: Into<Name>, T: Hash> FromIterator<(K, T)> for NameMap<T> {
    fn from_iter<I: IntoIterator<Item = (K, T)>>(entries: I) -> Self {
        Self::new(
            entries
                .into_iter()
                .map(|(name, value)| (name.into(), value))
                .collect(),
        )
    }
}

impl<K: Into<Name>, T: Hash, const N: usize> From<[(K, T); N]> for NameMap<T> {
    fn from(entries: [(K, T); N]) -> Self {
        entries.into_iter().collect()
    }
}

impl<T: fmt::Debug> fmt::Debug for NameMap<T> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.debug_map().entries(self.iter()).finish()
    }
}

impl<T: Serialize> Serialize for NameMap<T> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut map = serializer.serialize_map(Some(self.len()))?;
        for (name, value) in self.iter() {
            map.serialize_entry(name, value)?;
        }
        map.end()
    }
}

impl<'de, T: Deserialize<'de> + Hash> Deserialize<'de> for NameMap<T> {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        struct EntriesVisitor<T>(std::marker::PhantomData<T>);

        impl<'de, T: Deserialize<'de> + Hash> Visitor<'de> for EntriesVisitor<T> {
            type Value = NameMap<T>;

            fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
                formatter.write_str("a map")
            }

            fn visit_map<A: MapAccess<'de>>(self, mut map: A) -> Result<Self::Value, A::Error> {
                let mut entries = Vec::with_capacity(map.size_hint().unwrap_or(0));
                while let Some(entry) = map.next_entry::<Name, T>()? {
                    entries.push(entry);
                }
                Ok(NameMap::new(entries))
            }
        }

        deserializer.deserialize_map(EntriesVisitor(std::marker::PhantomData))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn interned_values_share_one_allocation() {
        let mut interner = Interner::default();
        let first = interner.intern(vec![1, 2, 3]);
        let second = interner.intern(vec![1, 2, 3]);
        let third = interner.intern(vec![1, 2]);
        assert!(first.ptr_eq(&second));
        assert!(!first.ptr_eq(&third));
        // Equality is by value even without interning.
        assert_eq!(Shared::new(vec![1, 2]), third);
    }

    #[test]
    fn name_maps_sort_and_keep_the_last_duplicate() {
        let map = NameMap::from([("b", 1), ("a", 2), ("b", 3)]);
        assert_eq!(
            map.keys().map(AsRef::as_ref).collect::<Vec<&str>>(),
            ["a", "b"]
        );
        assert_eq!(map["b"], 3);
        assert_eq!(map.get("c"), None);
        assert_eq!(serde_json::to_string(&map).unwrap(), r#"{"a":2,"b":3}"#);
        let parsed: NameMap<i32> = serde_json::from_str(r#"{"b":1,"a":2,"b":3}"#).unwrap();
        assert_eq!(parsed, map);
    }
}
