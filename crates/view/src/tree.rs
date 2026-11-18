//! The hierarchy a project is shown as: stacks, then groups chosen by a [`Grouping`], then
//! nodes. Containment is the tree; associations stay edges between its leaves.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use crate::model::{Model, Node, NodeKind, StackModel};

/// How the nodes of a stack are grouped.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Grouping {
    /// By where the source declares them: module, then definition.
    #[default]
    Source,
    /// By provider, then resource type.
    Provider,
    /// By kind of node.
    Kind,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    Root,
    Stack,
    Module,
    Definition,
    Provider,
    Type,
    Kind,
    /// Nodes of a stack with origins whose own origin is not recorded.
    Loose,
    Leaf,
}

impl Role {
    /// What the role is called beside a label.
    #[must_use]
    pub const fn noun(self) -> &'static str {
        match self {
            Self::Root => "project",
            Self::Stack => "stack",
            Self::Module => "module",
            Self::Definition => "def",
            Self::Provider => "provider",
            Self::Type => "type",
            Self::Kind | Self::Loose => "group",
            Self::Leaf => "node",
        }
    }
}

/// A node of the model, addressed by its stack and its position there.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NodeRef {
    pub stack: usize,
    pub index: usize,
}

#[derive(Debug, Clone)]
pub struct Item {
    /// Stable across rebuilds of the same grouping: expansion and selection are kept by it.
    pub id: String,
    pub label: String,
    /// The unabbreviated name, when `label` shortens it.
    pub full: Option<String>,
    pub role: Role,
    /// The stack the item belongs to; `usize::MAX` for the root.
    pub stack: usize,
    /// The node a leaf stands for, as an index into [`Tree::nodes`].
    pub node: Option<usize>,
    pub parent: Option<usize>,
    pub children: Vec<usize>,
    /// Every node below (or at) the item, as indices into [`Tree::nodes`].
    pub leaves: Vec<usize>,
    /// How much configuration the item holds: the sum of its nodes' weights.
    pub weight: f32,
}

impl Item {
    #[must_use]
    pub fn is_container(&self) -> bool {
        self.role != Role::Leaf
    }
}

#[derive(Debug, Default)]
pub struct Tree {
    /// `items[0]` is the root.
    pub items: Vec<Item>,
    pub nodes: Vec<NodeRef>,
    /// The leaf item of each node.
    pub leaf_of: Vec<usize>,
}

pub const KIND_ORDER: [NodeKind; 5] = [
    NodeKind::Provider,
    NodeKind::Resource,
    NodeKind::Data,
    NodeKind::StackReference,
    NodeKind::Output,
];

#[must_use]
pub const fn kind_plural(kind: NodeKind) -> &'static str {
    match kind {
        NodeKind::Provider => "Providers",
        NodeKind::Resource => "Resources",
        NodeKind::Data => "Data sources",
        NodeKind::StackReference => "Stack references",
        NodeKind::Output => "Outputs",
    }
}

#[must_use]
pub const fn kind_label(kind: NodeKind) -> &'static str {
    match kind {
        NodeKind::Provider => "Provider configuration",
        NodeKind::Resource => "Resource",
        NodeKind::Data => "Data source",
        NodeKind::StackReference => "Stack reference",
        NodeKind::Output => "Output",
    }
}

impl Tree {
    #[must_use]
    pub fn build(model: &Model, grouping: Grouping) -> Self {
        let mut tree = Self::default();
        tree.push(
            None,
            "root".to_owned(),
            model.project.name.clone(),
            Role::Root,
            usize::MAX,
        );
        for (stack_index, stack) in model.stacks.iter().enumerate() {
            let first = tree.nodes.len();
            tree.nodes
                .extend((0..stack.nodes.len()).map(|index| NodeRef {
                    stack: stack_index,
                    index,
                }));
            tree.leaf_of.resize(tree.nodes.len(), 0);
            let nodes: Vec<usize> = (first..tree.nodes.len()).collect();
            let id = format!("s:{}", stack.name);
            let item = tree.push(Some(0), id, stack.name.clone(), Role::Stack, stack_index);
            let by_source = grouping == Grouping::Source
                && stack.nodes.iter().any(|node| node.origin.is_some());
            if by_source {
                tree.by_source(item, stack, &nodes);
            } else if grouping == Grouping::Kind {
                tree.by_kind(item, stack, &nodes);
            } else {
                tree.by_provider(item, stack, &nodes);
            }
        }
        tree.finish(model);
        tree
    }

    #[must_use]
    pub fn node<'a>(&self, model: &'a Model, node: usize) -> &'a Node {
        let at = self.nodes[node];
        &model.stacks[at.stack].nodes[at.index]
    }

    fn push(
        &mut self,
        parent: Option<usize>,
        id: String,
        label: String,
        role: Role,
        stack: usize,
    ) -> usize {
        let index = self.items.len();
        self.items.push(Item {
            id,
            label,
            full: None,
            role,
            stack,
            node: None,
            parent,
            children: Vec::new(),
            leaves: Vec::new(),
            weight: 0.0,
        });
        if let Some(parent) = parent {
            self.items[parent].children.push(index);
        }
        index
    }

    fn leaf(&mut self, parent: usize, stack: &StackModel, node: usize) {
        let data = &stack.nodes[self.nodes[node].index];
        let stack_index = self.items[parent].stack;
        let item = self.push(
            Some(parent),
            data.id.clone(),
            data.name.clone(),
            Role::Leaf,
            stack_index,
        );
        self.items[item].node = Some(node);
        self.items[item].weight = data.weight.max(2) as f32;
        self.leaf_of[node] = item;
    }

    /// Module path (a module holding only one submodule folds into it), then definition.
    fn by_source(&mut self, parent: usize, stack: &StackModel, nodes: &[usize]) {
        let mut root = Module::default();
        let mut loose = Vec::new();
        for &node in nodes {
            let Some(origin) = &stack.nodes[self.nodes[node].index].origin else {
                loose.push(node);
                continue;
            };
            let mut at = &mut root;
            for segment in origin.module.split('.') {
                let position = at
                    .modules
                    .iter()
                    .position(|module| module.segment == segment);
                let position = position.unwrap_or_else(|| {
                    let path = if at.path.is_empty() {
                        segment.to_owned()
                    } else {
                        format!("{}.{segment}", at.path)
                    };
                    at.modules.push(Module {
                        segment: segment.to_owned(),
                        path,
                        ..Module::default()
                    });
                    at.modules.len() - 1
                });
                at = &mut at.modules[position];
            }
            at.nodes.push(node);
        }

        for module in &root.modules {
            emit(self, parent, stack, module, &module.segment);
        }
        if !loose.is_empty() {
            let id = format!("{}/m:", self.items[parent].id);
            let stack_index = self.items[parent].stack;
            let rest = self.push(
                Some(parent),
                id,
                "No recorded origin".to_owned(),
                Role::Loose,
                stack_index,
            );
            for node in loose {
                self.leaf(rest, stack, node);
            }
        }
    }

    fn by_provider(&mut self, parent: usize, stack: &StackModel, nodes: &[usize]) {
        let stack_index = self.items[parent].stack;
        let mut providers: Vec<(String, usize, BTreeMap<String, Vec<usize>>)> = Vec::new();
        let mut others: Vec<(NodeKind, Vec<usize>)> = Vec::new();
        for &node in nodes {
            let data = &stack.nodes[self.nodes[node].index];
            if matches!(data.kind, NodeKind::Output | NodeKind::StackReference) {
                match others.iter_mut().find(|(kind, _)| *kind == data.kind) {
                    Some((_, members)) => members.push(node),
                    None => others.push((data.kind, vec![node])),
                }
                continue;
            }
            let name = data
                .provider
                .clone()
                .unwrap_or_else(|| "unknown".to_owned());
            let position = providers.iter().position(|(known, _, _)| *known == name);
            let position = position.unwrap_or_else(|| {
                let id = format!("{}/p:{name}", self.items[parent].id);
                let item = self.push(Some(parent), id, name.clone(), Role::Provider, stack_index);
                providers.push((name.clone(), item, BTreeMap::new()));
                providers.len() - 1
            });
            if data.kind == NodeKind::Provider {
                self.leaf(providers[position].1, stack, node);
            } else {
                let prefix = if data.kind == NodeKind::Data {
                    "data."
                } else {
                    ""
                };
                providers[position]
                    .2
                    .entry(format!("{prefix}{}", data.type_name))
                    .or_default()
                    .push(node);
            }
        }
        for (name, item, types) in providers {
            for (type_name, members) in types {
                if let [only] = members.as_slice() {
                    self.leaf(item, stack, *only);
                    continue;
                }
                let id = format!("{}/t:{type_name}", self.items[item].id);
                let label = strip_provider(&type_name, &name);
                let typed = self.push(Some(item), id, label, Role::Type, stack_index);
                self.items[typed].full = Some(type_name);
                for node in members {
                    self.leaf(typed, stack, node);
                }
            }
        }
        for (kind, members) in others {
            let id = format!("{}/k:{kind:?}", self.items[parent].id);
            let group = self.push(
                Some(parent),
                id,
                kind_plural(kind).to_owned(),
                Role::Kind,
                stack_index,
            );
            for node in members {
                self.leaf(group, stack, node);
            }
        }
    }

    fn by_kind(&mut self, parent: usize, stack: &StackModel, nodes: &[usize]) {
        let stack_index = self.items[parent].stack;
        for kind in KIND_ORDER {
            let members: Vec<usize> = nodes
                .iter()
                .copied()
                .filter(|node| stack.nodes[self.nodes[*node].index].kind == kind)
                .collect();
            if members.is_empty() {
                continue;
            }
            let id = format!("{}/k:{kind:?}", self.items[parent].id);
            let group = self.push(
                Some(parent),
                id,
                kind_plural(kind).to_owned(),
                Role::Kind,
                stack_index,
            );
            for node in members {
                self.leaf(group, stack, node);
            }
        }
    }

    /// Fill in weights and leaves bottom-up, and order children: groups first, heaviest
    /// first, then nodes by kind and name. The order depends only on the model, so expanding
    /// a group never reshuffles its siblings.
    fn finish(&mut self, model: &Model) {
        for index in (0..self.items.len()).rev() {
            if let Some(node) = self.items[index].node {
                self.items[index].leaves = vec![node];
            }
            let mut children = std::mem::take(&mut self.items[index].children);
            children.sort_by(|&a, &b| {
                let (a, b) = (&self.items[a], &self.items[b]);
                let rank = |item: &Item| {
                    item.node.map_or(0, |node| {
                        1 + KIND_ORDER
                            .iter()
                            .position(|kind| *kind == self.node(model, node).kind)
                            .unwrap_or(0)
                    })
                };
                rank(a)
                    .cmp(&rank(b))
                    .then(if a.is_container() {
                        b.weight.total_cmp(&a.weight)
                    } else {
                        std::cmp::Ordering::Equal
                    })
                    .then_with(|| a.label.cmp(&b.label))
                    .then_with(|| a.id.cmp(&b.id))
            });
            self.items[index].children = children;
            if let Some(parent) = self.items[index].parent {
                let weight = self.items[index].weight;
                let leaves = self.items[index].leaves.clone();
                self.items[parent].weight += weight;
                // Children are visited in descending index, so prepend to keep model order.
                self.items[parent].leaves.splice(0..0, leaves);
            }
        }
    }

    #[must_use]
    pub fn find(&self, id: &str) -> Option<usize> {
        self.items.iter().position(|item| item.id == id)
    }

    /// The labels from the stack down to `item`, joined for display.
    #[must_use]
    pub fn trail(&self, item: usize) -> String {
        let mut names = Vec::new();
        let mut at = Some(item);
        while let Some(index) = at {
            if index != 0 {
                names.push(self.items[index].label.as_str());
            }
            at = self.items[index].parent;
        }
        names.reverse();
        names.join(" › ")
    }
}

/// A module of a stack's source while its nodes are gathered: the modules below it and the
/// nodes declared directly in it.
#[derive(Default)]
struct Module {
    segment: String,
    path: String,
    modules: Vec<Module>,
    nodes: Vec<usize>,
}

/// Add `module` under `parent`, folding a module that holds only one submodule into it.
fn emit(tree: &mut Tree, parent: usize, stack: &StackModel, mut module: &Module, label: &str) {
    let mut label = label.to_owned();
    while module.nodes.is_empty() && module.modules.len() == 1 {
        module = &module.modules[0];
        label = format!("{label}.{}", module.segment);
    }
    let stack_index = tree.items[parent].stack;
    let id = format!("{}/m:{}", tree.items[parent].id, module.path);
    let item = tree.push(Some(parent), id, label, Role::Module, stack_index);
    tree.items[item].full = Some(module.path.clone());
    let mut definitions: Vec<(String, usize)> = Vec::new();
    for &node in &module.nodes {
        let name = stack.nodes[tree.nodes[node].index]
            .origin
            .as_ref()
            .map_or("", |origin| origin.declaration.as_str());
        if name.is_empty() {
            tree.leaf(item, stack, node);
            continue;
        }
        let found = definitions
            .iter()
            .find(|(known, _)| known == name)
            .map(|entry| entry.1);
        let definition = found.unwrap_or_else(|| {
            let id = format!("{}/d:{name}", tree.items[item].id);
            let short = name.rsplit('.').next().unwrap_or(name).to_owned();
            let definition = tree.push(Some(item), id, short, Role::Definition, stack_index);
            tree.items[definition].full = Some(name.to_owned());
            definitions.push((name.to_owned(), definition));
            definition
        });
        tree.leaf(definition, stack, node);
    }
    for child in &module.modules {
        emit(tree, item, stack, child, &child.segment);
    }
}

/// `digitalocean_vpc` as `vpc` under its provider, keeping a `data.` prefix.
#[must_use]
pub fn strip_provider(type_name: &str, provider: &str) -> String {
    let (prefix, rest) = type_name
        .strip_prefix("data.")
        .map_or(("", type_name), |rest| ("data.", rest));
    let rest = rest
        .strip_prefix(provider)
        .and_then(|rest| rest.strip_prefix('_'))
        .unwrap_or(rest);
    format!("{prefix}{rest}")
}
