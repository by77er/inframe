//! The document `inframe serve` hands the page: every stack of the project as nodes that know
//! where the source declared them, and the associations between them. The server builds it
//! and the page reads it through these same types.

use serde::{Deserialize, Serialize};

/// Where the stack's source declared one node.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct Origin {
    /// The source module, for example `Infra.Platform`.
    pub module: String,
    /// The declaration the node is added in; empty at the top level of a module.
    #[serde(default)]
    pub declaration: String,
    /// The one-based line of the call; `0` when unknown.
    #[serde(default)]
    pub line: u32,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Model {
    /// Increases every time anything below changes; the event stream announces it.
    pub version: u64,
    pub project: ProjectInfo,
    pub stacks: Vec<StackModel>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProjectInfo {
    pub name: String,
    pub root: String,
    /// Why `inframe.toml` could not be loaded, when the stacks shown are from its last
    /// readable version.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BuildStatus {
    /// Being built for the first time, or rebuilt after a source change.
    Building,
    Ready,
    /// The last build failed; the nodes shown, if any, are those of the last good build.
    Failed,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct StackModel {
    pub name: String,
    pub frontend: String,
    pub backend: String,
    pub gated: bool,
    pub status: BuildStatus,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub built_at_ms: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub build_ms: Option<u64>,
    /// Whether the frontend said where nodes were declared; without it the source hierarchy
    /// is not available and the stack is laid out by provider and type alone.
    pub has_origins: bool,
    pub state: StateModel,
    pub nodes: Vec<Node>,
    pub edges: Vec<Edge>,
    /// Managed resources the state holds but the graph no longer declares: the next apply
    /// destroys them.
    pub unmanaged: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct StateModel {
    pub tracked: bool,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub serial: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub updated_ms: Option<u64>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NodeKind {
    Provider,
    Resource,
    Data,
    /// Another stack of the project whose outputs this stack reads.
    StackReference,
    Output,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Node {
    /// Unique across the project: `<stack>/<key>`.
    pub id: String,
    pub kind: NodeKind,
    /// The address as `OpenTofu` prints it, or `provider.<address>` / `output.<name>`.
    pub address: String,
    /// The provider type (`digitalocean_vpc`); empty for outputs.
    #[serde(rename = "type")]
    pub type_name: String,
    pub name: String,
    /// The provider's local name, for grouping.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub provider: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub origin: Option<Origin>,
    pub arguments: Vec<Argument>,
    /// Arguments past the row limit, not listed.
    #[serde(default, skip_serializing_if = "is_zero")]
    pub hidden_arguments: usize,
    /// Lifecycle settings and other flags worth a badge (`create before destroy`, `sensitive`).
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub flags: Vec<String>,
    /// How much configuration the node carries: one plus its argument leaves.
    pub weight: usize,
    /// Whether the state holds the node; absent when the state is not tracked.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub applied: Option<bool>,
}

#[allow(clippy::trivially_copy_pass_by_ref)]
const fn is_zero(value: &usize) -> bool {
    *value == 0
}

/// One leaf of a node's configuration: nested blocks and objects are flattened into dotted
/// paths (`node_pool.auto_scale`, `rule[0].type`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Argument {
    pub name: String,
    pub value: String,
    /// The nodes the value refers to, by id.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub references: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EdgeKind {
    /// An argument or output value reads an attribute of the target.
    Reference,
    /// An explicit `depends_on`.
    DependsOn,
    /// `replace_triggered_by`.
    ReplaceTrigger,
    /// The node is created through the target provider configuration.
    Provider,
    /// A stack reference reads the target output of another stack.
    Stack,
}

/// `from` needs `to`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Edge {
    pub from: String,
    pub to: String,
    pub kind: EdgeKind,
    /// What carries the association, for example `private_network_uuid → id`.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub via: Vec<String>,
}
