//! Everything the page knows and decides: what is open, what is selected, where each thing
//! stands and is heading, what the camera sees, and what a click lands on. The page draws
//! what this says and reports input back; it holds no state of its own beyond the theme.

use std::collections::{BTreeMap, HashMap, HashSet};

use serde_json::{Value, json};

use crate::camera::{Camera, Rig, ZOOM_RANGE};
use crate::layout::{Mode, Placed, Sizes, layout};
use crate::model::{BuildStatus, Edge, EdgeKind, Model, NodeKind, StackModel};
use crate::tree::{Grouping, KIND_ORDER, Role, Tree, kind_label, kind_plural, strip_provider};

/// Floats per box handed to the renderer: position, size, tone, flags, grow, lift, dim.
pub const INSTANCE_FLOATS: usize = 11;

/// The surface a box is painted as; the page maps each to a color of its theme.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Tone {
    Neutral = 0,
    Resource = 1,
    Read = 2,
    Output = 3,
    /// A closed group.
    Group = 4,
    SlabEven = 5,
    SlabOdd = 6,
    Stack = 7,
    /// The mark of a node the state holds.
    Applied = 8,
    /// The mark of a node declared but not applied.
    Pending = 9,
}

pub mod flag {
    pub const SLAB: u32 = 1;
    pub const SELECTED: u32 = 2;
    pub const RELATED: u32 = 4;
    pub const DIM: u32 = 8;
    pub const HOVER: u32 = 16;
    pub const MATCH: u32 = 32;
    pub const FAILED: u32 = 64;
    pub const BUILDING: u32 = 128;
    /// A mark rather than an item: it has no label and cannot be picked.
    pub const MARK: u32 = 256;
    pub const CONTAINER: u32 = 512;
}

#[derive(Debug, Clone, Copy)]
struct Anim {
    rect: [f32; 6],
    /// 0 to 1 as the box rises out of the ground; below 0 while it waits its turn.
    grow: f32,
    /// How far the box floats above where it stands: hovered and selected boxes lift.
    lift: f32,
    /// 0 to 1 as the box recedes because something else is selected or matched.
    dim: f32,
}

/// A box that is no longer shown, sinking toward the group that closed over it.
#[derive(Debug, Clone, Copy)]
struct Ghost {
    rect: [f32; 6],
    toward: (f32, f32),
    grow: f32,
    tone: Tone,
    flags: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Link {
    from: usize,
    to: usize,
    kind: EdgeKind,
    count: usize,
    muted: bool,
}

#[derive(Debug, Default)]
pub struct View {
    model: Option<Model>,
    tree: Tree,
    grouping: Grouping,
    mode: Mode,
    /// Ids of open groups (Explore only; the map opens everything).
    expanded: HashSet<String>,
    /// Stacks seen before, so that a new one gets its default expansion once.
    known_stacks: HashSet<String>,
    selected: Option<String>,
    hovered: Option<String>,
    query: String,
    all_links: bool,

    /// Edges between nodes, as indices into `tree.nodes`.
    edges: Vec<(usize, usize, usize, usize)>,
    outgoing: Vec<Vec<usize>>,
    incoming: Vec<Vec<usize>>,
    /// Nodes matching the query; `None` without a query.
    matching: Option<HashSet<usize>>,
    /// Stacks with at least one applied node: only there do marks say anything.
    marked_stacks: HashSet<usize>,

    placed: Vec<Placed>,
    /// Counts layouts, so that the page can tell when the boxes it knows are no longer
    /// the boxes being drawn (a resize re-lays the map out between commands).
    revision: u32,
    /// The visible box each node is shown by: itself, or its nearest closed ancestor.
    anchor: Vec<Option<usize>>,
    box_of: HashMap<usize, usize>,
    related: HashSet<usize>,
    inside: HashSet<usize>,
    links: Vec<Link>,

    camera: Camera,
    goal: Camera,
    /// Whether the camera still follows the content, or the user has taken it.
    following: bool,
    fitted: bool,
    viewport: (f32, f32),
    /// How wide each character is drawn, so that blocks can be sized to their text.
    metrics: Option<Metrics>,
    anims: HashMap<String, Anim>,
    ghosts: Vec<Ghost>,
    /// Whether the tree was rebuilt since the last layout, so that item indices of the
    /// previous layout no longer mean anything.
    rebuilt: bool,
    /// The pixel a zoom is anchored on and the ground point that stays under it.
    zoom_anchor: Option<(f32, f32, f32, f32)>,
    /// Whether to animate at all; off for readers who ask for reduced motion.
    still: bool,
    instances: Vec<f32>,
    matrix: [f32; 16],
}

/// Advance widths, in ems, of the printable ASCII characters in the two faces the canvas
/// writes with: the bold sans of names and the monospace of types and values.
#[derive(Debug, Clone)]
pub struct Metrics {
    pub sans: Vec<f32>,
    pub mono: Vec<f32>,
}

/// The configuration rows a node shows when everything is open.
const MAX_ROWS: usize = 12;
const ROW: f32 = 15.0;
const ROW_SIZE: f32 = 10.0;

fn ease(current: f32, goal: f32, k: f32) -> f32 {
    if (goal - current).abs() < 1e-3 {
        goal
    } else {
        current + (goal - current) * k
    }
}

impl View {
    #[must_use]
    pub fn new() -> Self {
        Self {
            following: true,
            viewport: (1200.0, 800.0),
            ..Self::default()
        }
    }

    // ----- input -----

    pub fn set_model(&mut self, model: Model) {
        let first = self.model.is_none();
        self.model = Some(model);
        self.rebuild();
        let few = self
            .model
            .as_ref()
            .is_some_and(|model| model.stacks.len() <= 6);
        // A project with few stacks opens them one level; more than that stay closed, and
        // a stack that appears later is left for the reader to open.
        let stacks: Vec<usize> = self.tree.items[0].children.clone();
        for &stack in &stacks {
            let id = self.tree.items[stack].id.clone();
            if self.known_stacks.insert(id) && first && few {
                self.open_chain(stack);
            }
        }
        self.relayout();
    }

    pub fn set_grouping(&mut self, grouping: Grouping) {
        if self.grouping == grouping {
            return;
        }
        self.grouping = grouping;
        if self.model.is_none() {
            return;
        }
        // Group ids differ between groupings; keep the stacks open and start over below them.
        self.expanded.retain(|id| !id.contains('/'));
        if self
            .selected
            .as_deref()
            .is_some_and(|id| id.starts_with("s:") && id.contains('/'))
        {
            self.selected = None;
        }
        self.rebuild();
        let stacks: Vec<usize> = self.tree.items[0].children.clone();
        for stack in stacks {
            if self.expanded.contains(&self.tree.items[stack].id) {
                self.open_chain(stack);
            }
        }
        self.following = true;
        self.relayout();
    }

    pub fn set_mode(&mut self, mode: Mode) {
        if self.mode != mode {
            self.mode = mode;
            self.following = true;
            self.relayout();
        }
    }

    /// A click on an item: open a closed group, close an open one that is already selected,
    /// and select otherwise.
    pub fn click(&mut self, id: &str) {
        let Some(item) = self.tree.find(id) else {
            return;
        };
        let data = &self.tree.items[item];
        let openable =
            data.is_container() && !data.children.is_empty() && self.mode == Mode::Explore;
        if openable && !self.expanded.contains(id) {
            self.open_chain(item);
            self.selected = Some(id.to_owned());
            self.relayout();
            self.bring_into_view(item);
        } else if openable && self.selected.as_deref() == Some(id) {
            self.expanded.remove(id);
            self.relayout();
        } else if self.selected.as_deref() == Some(id) {
            self.selected = None;
            self.refresh_links();
        } else {
            self.selected = Some(id.to_owned());
            self.refresh_links();
        }
    }

    /// Open or close a group without selecting it.
    pub fn toggle(&mut self, id: &str) {
        let Some(item) = self.tree.find(id) else {
            return;
        };
        if self.mode != Mode::Explore || self.tree.items[item].children.is_empty() {
            return;
        }
        if !self.expanded.remove(id) {
            self.open_chain(item);
        }
        self.relayout();
        if self.expanded.contains(id) {
            self.bring_into_view(item);
        }
    }

    /// Select an item (or nothing), opening the groups above it so that it can be seen.
    pub fn select(&mut self, id: Option<&str>, reveal: bool) {
        self.selected = id
            .filter(|id| self.tree.find(id).is_some())
            .map(str::to_owned);
        let item = self.selected.as_deref().and_then(|id| self.tree.find(id));
        if let (Some(item), true) = (item, reveal) {
            let mut at = self.tree.items[item].parent;
            while let Some(parent) = at {
                self.expanded.insert(self.tree.items[parent].id.clone());
                at = self.tree.items[parent].parent;
            }
            self.relayout();
            self.bring_into_view(item);
        } else {
            self.refresh_links();
        }
    }

    pub fn hover(&mut self, id: Option<&str>) {
        let id = id.map(str::to_owned);
        if self.hovered != id {
            self.hovered = id;
            self.refresh_links();
        }
    }

    pub fn set_query(&mut self, query: &str) {
        query.trim().to_lowercase().clone_into(&mut self.query);
        self.refresh_matches();
    }

    pub fn set_all_links(&mut self, all: bool) {
        self.all_links = all;
        self.refresh_links();
    }

    /// Open every group below `id`.
    pub fn expand_all(&mut self, id: &str) {
        let Some(item) = self.tree.find(id) else {
            return;
        };
        let mut pending = vec![item];
        while let Some(at) = pending.pop() {
            let data = &self.tree.items[at];
            if data.is_container() && !data.children.is_empty() {
                self.expanded.insert(data.id.clone());
                pending.extend(&data.children);
            }
        }
        self.relayout();
        self.bring_into_view(item);
    }

    /// Close everything below the stacks.
    pub fn collapse_all(&mut self) {
        self.expanded.clear();
        self.following = true;
        self.relayout();
    }

    /// Select and show the first node matching the query.
    pub fn first_match(&mut self) {
        let first = self
            .matching
            .as_ref()
            .and_then(|matching| matching.iter().min().copied());
        if let Some(node) = first {
            let id = self.tree.items[self.tree.leaf_of[node]].id.clone();
            self.select(Some(&id), true);
        }
    }

    pub fn fit(&mut self) {
        self.zoom_anchor = None;
        self.following = true;
        self.follow();
    }

    pub fn focus(&mut self, id: &str) {
        if let Some(bounds) = self.tree.find(id).and_then(|item| self.bounds_of(item)) {
            self.following = false;
            self.zoom_anchor = None;
            self.goal =
                self.goal
                    .framing(bounds.0, bounds.1, self.viewport.0, self.viewport.1, 0.8);
        }
    }

    pub fn set_tilt(&mut self, yaw: f32, pitch: f32) {
        self.goal.yaw = yaw;
        self.goal.pitch = pitch.clamp(0.3, 1.5607);
        if self.following {
            self.follow();
        }
    }

    /// Drag the ground: the point under `(x0, y0)` moves to `(x1, y1)`.
    pub fn pan(&mut self, x0: f32, y0: f32, x1: f32, y1: f32) {
        let rig = self.camera.rig(self.viewport.0, self.viewport.1);
        if let (Some(from), Some(to)) = (rig.ground(x0, y0), rig.ground(x1, y1)) {
            self.camera.x -= to.0 - from.0;
            self.camera.y -= to.1 - from.1;
            self.goal = Camera {
                zoom: self.goal.zoom,
                yaw: self.goal.yaw,
                pitch: self.goal.pitch,
                ..self.camera
            };
            self.zoom_anchor = None;
            self.following = false;
        }
    }

    /// Zoom by `factor`, keeping the ground point under `(x, y)` where it is. The zoom eases
    /// to its new level, and the anchor holds through every frame of the way.
    pub fn zoom(&mut self, x: f32, y: f32, factor: f32) {
        let anchor = match self.zoom_anchor {
            Some(anchor) if (anchor.0 - x).abs() < 2.0 && (anchor.1 - y).abs() < 2.0 => {
                Some(anchor)
            }
            _ => self
                .camera
                .rig(self.viewport.0, self.viewport.1)
                .ground(x, y)
                .map(|ground| (x, y, ground.0, ground.1)),
        };
        self.zoom_anchor = anchor;
        self.goal = Camera {
            zoom: (self.goal.zoom * factor).clamp(ZOOM_RANGE.0, ZOOM_RANGE.1),
            x: self.camera.x,
            y: self.camera.y,
            ..self.goal
        };
        self.following = false;
    }

    /// Whether to animate; without it every change lands at once.
    pub fn set_motion(&mut self, motion: bool) {
        self.still = !motion;
    }

    /// The box under a pixel, as an index into the scene's boxes.
    #[must_use]
    pub fn pick(&self, x: f32, y: f32) -> Option<usize> {
        let rig = self.camera.rig(self.viewport.0, self.viewport.1);
        let ray = rig.ray(x, y);
        let mut best: Option<(f32, usize)> = None;
        for (index, placed) in self.placed.iter().enumerate() {
            let rect = self.current(placed);
            let hit = rig.hit(
                ray,
                [rect[0], rect[1], rect[2]],
                [rect[0] + rect[3], rect[1] + rect[4], rect[2] + rect[5]],
            );
            if let Some(t) = hit {
                if best.is_none_or(|(nearest, _)| t < nearest) {
                    best = Some((t, index));
                }
            }
        }
        best.map(|(_, index)| index)
    }

    /// The page's measure of its two faces; blocks are sized from it from then on.
    pub fn set_metrics(&mut self, metrics: Metrics) {
        self.metrics = Some(metrics);
        if self.model.is_some() {
            self.relayout();
        }
    }

    /// How wide `text` is drawn at `size`, from the page's metrics or a fair guess without.
    fn width(&self, text: &str, mono: bool, size: f32) -> f32 {
        let table = self
            .metrics
            .as_ref()
            .map(|metrics| if mono { &metrics.mono } else { &metrics.sans });
        let fallback = if mono { 0.6 } else { 0.58 };
        let ems: f32 = text
            .chars()
            .map(|character| {
                let index = (character as usize).wrapping_sub(32);
                table
                    .and_then(|table| table.get(index))
                    .copied()
                    .unwrap_or(fallback)
            })
            .sum();
        ems * size
    }

    /// What is written on an item: its name, and a line saying what it is.
    fn caption(&self, index: usize) -> (String, String) {
        let item = &self.tree.items[index];
        let Some(model) = &self.model else {
            return (item.label.clone(), String::new());
        };
        if let Some(node) = item.node {
            let data = self.tree.node(model, node);
            let sub = match data.kind {
                NodeKind::Output => "output".to_owned(),
                NodeKind::StackReference => "stack".to_owned(),
                NodeKind::Provider => "provider".to_owned(),
                NodeKind::Resource | NodeKind::Data => {
                    let prefix = if data.kind == NodeKind::Data {
                        "data."
                    } else {
                        ""
                    };
                    strip_provider(
                        &format!("{prefix}{}", data.type_name),
                        data.provider.as_deref().unwrap_or(""),
                    )
                }
            };
            return (data.name.clone(), sub);
        }
        let count = item.leaves.len();
        let noun = if count == 1 { "node" } else { "nodes" };
        let sub = match (item.role, self.stack(index)) {
            (Role::Stack, Some(stack)) if stack.status == BuildStatus::Building => {
                format!("{} · building…", stack.frontend)
            }
            (Role::Stack, Some(stack)) if stack.status == BuildStatus::Failed && count == 0 => {
                format!("{} · build failed", stack.frontend)
            }
            (Role::Stack, Some(stack)) if stack.status == BuildStatus::Failed => {
                format!("{} · {count} {noun} · last build failed", stack.frontend)
            }
            (Role::Stack, Some(stack)) => format!("{} · {count} {noun}", stack.frontend),
            (role, _) => format!("{} · {count}", role.noun()),
        };
        (item.label.clone(), sub)
    }

    /// The configuration a node shows when everything is open: its first rows, how many
    /// more there are, and where the values start across the block.
    fn rows(&self, index: usize) -> (Vec<(String, String)>, usize, f32) {
        let (Some(model), Some(node), Mode::Everything) =
            (&self.model, self.tree.items[index].node, self.mode)
        else {
            return (Vec::new(), 0, 0.0);
        };
        let data = self.tree.node(model, node);
        let rows: Vec<(String, String)> = data
            .arguments
            .iter()
            .take(MAX_ROWS)
            .map(|argument| (argument.name.clone(), argument.value.clone()))
            .collect();
        let more = data.arguments.len() + data.hidden_arguments - rows.len();
        let names = rows
            .iter()
            .map(|row| self.width(&row.0, true, ROW_SIZE))
            .fold(0.0_f32, f32::max);
        (rows, more, 13.0 + names.min(440.0) + 14.0)
    }

    /// How large every item's text makes it.
    fn sizes(&self) -> Sizes {
        let mut sizes = Sizes::default();
        for (index, item) in self.tree.items.iter().enumerate() {
            let (label, sub) = self.caption(index);
            let name = self.width(&label, false, 13.0);
            if item.is_container() {
                let detail = self.width(&sub, false, 10.5 * 0.95);
                sizes
                    .block
                    .push(((13.0 + name.max(detail) + 38.0).clamp(132.0, 560.0), 64.0));
                // A title is the name and the detail on one line, with room for the control.
                let size = if item.role == Role::Stack { 14.0 } else { 12.5 };
                let title =
                    self.width(&label, false, size) + self.width(&sub, false, size * 0.86 * 0.95);
                sizes.title.push(12.0 + title + 20.0 + 40.0);
                continue;
            }
            let detail = self.width(&sub, true, 10.5);
            let mut width = 13.0 + name.max(detail) + 20.0;
            let mut depth = 60.0;
            let (rows, more, split) = self.rows(index);
            if !rows.is_empty() {
                let values = rows
                    .iter()
                    .map(|row| self.width(&row.1, true, ROW_SIZE))
                    .fold(0.0_f32, f32::max);
                width = width.max(split + values.min(560.0) + 12.0);
                depth = 50.0 + (rows.len() + usize::from(more > 0)) as f32 * ROW + 8.0;
            }
            sizes.block.push((width.clamp(96.0, 1040.0), depth));
            sizes.title.push(0.0);
        }
        sizes
    }

    // ----- derived state -----

    fn rebuild(&mut self) {
        let Some(model) = &self.model else { return };
        self.tree = Tree::build(model, self.grouping);
        self.rebuilt = true;
        let index: HashMap<&str, usize> = self
            .tree
            .nodes
            .iter()
            .enumerate()
            .map(|(node, at)| (model.stacks[at.stack].nodes[at.index].id.as_str(), node))
            .collect();
        self.edges.clear();
        self.outgoing = vec![Vec::new(); self.tree.nodes.len()];
        self.incoming = vec![Vec::new(); self.tree.nodes.len()];
        for (stack_index, stack) in model.stacks.iter().enumerate() {
            for (edge_index, edge) in stack.edges.iter().enumerate() {
                if let (Some(&from), Some(&to)) =
                    (index.get(edge.from.as_str()), index.get(edge.to.as_str()))
                {
                    self.outgoing[from].push(self.edges.len());
                    self.incoming[to].push(self.edges.len());
                    self.edges.push((from, to, stack_index, edge_index));
                }
            }
        }
        let needs: Vec<(usize, usize)> = self
            .edges
            .iter()
            .filter(|(_, _, stack, edge)| {
                model.stacks[*stack].edges[*edge].kind != EdgeKind::Provider
            })
            .map(|(from, to, _, _)| (*from, *to))
            .collect();
        self.tree.rank(&needs);
        self.marked_stacks = model
            .stacks
            .iter()
            .enumerate()
            .filter(|(_, stack)| stack.nodes.iter().any(|node| node.applied == Some(true)))
            .map(|(index, _)| index)
            .collect();
        if self
            .selected
            .as_deref()
            .is_some_and(|id| self.tree.find(id).is_none())
        {
            self.selected = None;
        }
        if self
            .hovered
            .as_deref()
            .is_some_and(|id| self.tree.find(id).is_none())
        {
            self.hovered = None;
        }
        self.refresh_matches();
    }

    fn edge(&self, index: usize) -> &Edge {
        let (_, _, stack, edge) = self.edges[index];
        &self.model.as_ref().expect("edges come from a model").stacks[stack].edges[edge]
    }

    /// Open `item` and, while a group holds nothing but one group, that one too: a stack
    /// whose only child is its root module opens straight to what the module holds.
    fn open_chain(&mut self, mut item: usize) {
        loop {
            let data = &self.tree.items[item];
            if !data.is_container() || data.children.is_empty() {
                return;
            }
            self.expanded.insert(data.id.clone());
            match data.children.as_slice() {
                [only] if self.tree.items[*only].is_container() => item = *only,
                _ => return,
            }
        }
    }

    fn refresh_matches(&mut self) {
        self.matching = None;
        let (Some(model), false) = (&self.model, self.query.is_empty()) else {
            return;
        };
        let mut matching = HashSet::new();
        for node in 0..self.tree.nodes.len() {
            let data = self.tree.node(model, node);
            let stack = &model.stacks[self.tree.nodes[node].stack].name;
            let hit = |text: &str| text.to_lowercase().contains(&self.query);
            if hit(&data.address)
                || hit(&data.type_name)
                || hit(stack)
                || data
                    .origin
                    .as_ref()
                    .is_some_and(|origin| hit(&origin.module) || hit(&origin.declaration))
                || data
                    .arguments
                    .iter()
                    .any(|argument| hit(&argument.name) || hit(&argument.value))
            {
                matching.insert(node);
            }
        }
        self.matching = Some(matching);
    }

    fn relayout(&mut self) {
        self.revision = self.revision.wrapping_add(1);
        let before = std::mem::take(&mut self.placed);
        let painted: Vec<(Tone, u32)> = if self.rebuilt {
            Vec::new()
        } else {
            before.iter().map(|placed| self.paint(placed)).collect()
        };
        let sizes = self.sizes();
        let everything = self.mode == Mode::Everything;
        let (tree, expanded) = (&self.tree, &self.expanded);
        self.placed = layout(tree, &sizes, &|item| {
            everything || expanded.contains(&tree.items[item].id)
        });
        self.box_of = self
            .placed
            .iter()
            .enumerate()
            .map(|(index, placed)| (placed.item, index))
            .collect();
        self.anchor = vec![None; self.tree.nodes.len()];
        for (index, placed) in self.placed.iter().enumerate() {
            if !placed.slab {
                for &node in &self.tree.items[placed.item].leaves {
                    self.anchor[node] = Some(index);
                }
            }
        }
        // Anything that just appeared rises from where its nearest visible ancestor stood.
        let mut anims = HashMap::with_capacity(self.placed.len());
        for placed in &self.placed {
            let id = &self.tree.items[placed.item].id;
            let target = [placed.x, placed.y, placed.z, placed.w, placed.d, placed.h];
            let anim = self.anims.get(id).copied().unwrap_or_else(|| {
                let mut from = target;
                let mut at = self.tree.items[placed.item].parent;
                while let Some(parent) = at {
                    if let Some(known) = self.anims.get(&self.tree.items[parent].id) {
                        let (cx, cy) = (
                            known.rect[0] + known.rect[3] / 2.0,
                            known.rect[1] + known.rect[4] / 2.0,
                        );
                        from = [
                            cx - target[3] / 2.0,
                            cy - target[4] / 2.0,
                            target[2],
                            target[3],
                            target[4],
                            target[5],
                        ];
                        break;
                    }
                    at = self.tree.items[parent].parent;
                }
                Anim {
                    rect: from,
                    // The first boxes rise one after another; later arrivals rise at once.
                    grow: if self.fitted {
                        0.0
                    } else {
                        -(anims.len().min(40) as f32) * 0.03
                    },
                    lift: 0.0,
                    dim: 0.0,
                }
            });
            anims.insert(id.clone(), anim);
        }
        // What was shown and no longer is sinks toward the nearest group still standing.
        for (placed, (tone, flags)) in before.iter().zip(painted) {
            let item = &self.tree.items[placed.item];
            if anims.contains_key(&item.id) {
                continue;
            }
            let Some(rect) = self.anims.get(&item.id).map(|anim| anim.rect) else {
                continue;
            };
            let mut toward = (rect[0] + rect[3] / 2.0, rect[1] + rect[4] / 2.0);
            let mut at = item.parent;
            while let Some(parent) = at {
                if let Some(index) = self.box_of.get(&parent) {
                    let over = &self.placed[*index];
                    toward = (over.x + over.w / 2.0, over.y + over.d / 2.0);
                    break;
                }
                at = self.tree.items[parent].parent;
            }
            if self.ghosts.len() < 400 {
                self.ghosts.push(Ghost {
                    rect,
                    toward,
                    grow: 1.0,
                    tone,
                    flags: flags & !flag::SELECTED,
                });
            }
        }
        self.rebuilt = false;
        self.anims = anims;
        self.refresh_links();
        if self.following {
            self.follow();
        }
    }

    fn refresh_links(&mut self) {
        self.related.clear();
        self.inside.clear();
        self.links.clear();
        if self.model.is_none() {
            return;
        }
        if let Some(item) = self.selected.as_deref().and_then(|id| self.tree.find(id)) {
            self.inside = self.tree.items[item].leaves.iter().copied().collect();
            for &node in &self.inside {
                for &edge in &self.outgoing[node] {
                    self.related.insert(self.edges[edge].1);
                }
                for &edge in &self.incoming[node] {
                    self.related.insert(self.edges[edge].0);
                }
            }
            self.related.retain(|node| !self.inside.contains(node));
        }
        let mut links: BTreeMap<(usize, usize, bool, bool), (EdgeKind, usize)> = BTreeMap::new();
        if self.all_links {
            for index in 0..self.edges.len() {
                let kind = self.edge(index).kind;
                let (from, to, _, _) = self.edges[index];
                if let (Some(a), Some(b), false) = (
                    self.anchor[from],
                    self.anchor[to],
                    kind == EdgeKind::Provider,
                ) {
                    if a != b {
                        links.entry((a, b, true, false)).or_insert((kind, 0)).1 += 1;
                    }
                }
            }
        }
        let subject = self
            .hovered
            .as_deref()
            .or(self.selected.as_deref())
            .and_then(|id| self.tree.find(id));
        if let Some(item) = subject.filter(|item| *item != 0) {
            let inside: HashSet<usize> = self.tree.items[item].leaves.iter().copied().collect();
            let own = self.box_of.get(&item).copied();
            for &node in &inside {
                for (edges, outward) in
                    [(&self.outgoing[node], true), (&self.incoming[node], false)]
                {
                    for &edge in edges {
                        let (from, to, _, _) = self.edges[edge];
                        let other = if outward { to } else { from };
                        if inside.contains(&other) {
                            continue;
                        }
                        let (Some(near), Some(far)) =
                            (own.or(self.anchor[node]), self.anchor[other])
                        else {
                            continue;
                        };
                        if near == far {
                            continue;
                        }
                        let kind = self.edge(edge).kind;
                        let key = if outward {
                            (near, far, false, kind == EdgeKind::Provider)
                        } else {
                            (far, near, false, kind == EdgeKind::Provider)
                        };
                        links.entry(key).or_insert((kind, 0)).1 += 1;
                    }
                }
            }
        }
        self.links = links
            .into_iter()
            .map(|((from, to, muted, _), (kind, count))| Link {
                from,
                to,
                kind,
                count,
                muted,
            })
            .collect();
    }

    fn bounds(&self) -> Option<([f32; 3], [f32; 3])> {
        let mut bounds: Option<([f32; 3], [f32; 3])> = None;
        for placed in &self.placed {
            let (min, max) = (
                [placed.x, placed.y, placed.z],
                [
                    placed.x + placed.w,
                    placed.y + placed.d,
                    placed.z + placed.h,
                ],
            );
            bounds = Some(match bounds {
                None => (min, max),
                Some((low, high)) => (
                    [low[0].min(min[0]), low[1].min(min[1]), low[2].min(min[2])],
                    [
                        high[0].max(max[0]),
                        high[1].max(max[1]),
                        high[2].max(max[2]),
                    ],
                ),
            });
        }
        bounds
    }

    fn bounds_of(&self, item: usize) -> Option<([f32; 3], [f32; 3])> {
        let placed = self.placed.get(*self.box_of.get(&item)?)?;
        // An open group's children stand on it; allow for the tallest block.
        Some((
            [placed.x, placed.y, placed.z],
            [
                placed.x + placed.w,
                placed.y + placed.d,
                placed.z + placed.h + if placed.slab { 34.0 } else { 0.0 },
            ],
        ))
    }

    fn follow(&mut self) {
        self.zoom_anchor = None;
        if let Some((min, max)) = self.bounds() {
            self.goal = self
                .goal
                .framing(min, max, self.viewport.0, self.viewport.1, 0.86);
        }
    }

    /// After opening or revealing `item`: if it does not fit the view where it now stands,
    /// move the camera the least that shows it, zooming out only when it is too large.
    fn bring_into_view(&mut self, item: usize) {
        if self.following {
            return;
        }
        self.zoom_anchor = None;
        let Some((min, max)) = self.bounds_of(item) else {
            return;
        };
        let rig = self.goal.rig(self.viewport.0, self.viewport.1);
        let (mut x0, mut x1, mut y0, mut y1) = (f32::MAX, f32::MIN, f32::MAX, f32::MIN);
        for corner in 0..8 {
            let (x, y) = rig.project([
                if corner & 1 == 0 { min[0] } else { max[0] },
                if corner & 2 == 0 { min[1] } else { max[1] },
                if corner & 4 == 0 { min[2] } else { max[2] },
            ]);
            x0 = x0.min(x);
            x1 = x1.max(x);
            y0 = y0.min(y);
            y1 = y1.max(y);
        }
        let (width, height) = self.viewport;
        let margin = 28.0;
        if x1 - x0 > width - 2.0 * margin || y1 - y0 > height - 2.0 * margin {
            self.goal = self.goal.framing(min, max, width, height, 0.86);
            return;
        }
        let shift = |low: f32, high: f32, size: f32| {
            if low < margin {
                margin - low
            } else if high > size - margin {
                size - margin - high
            } else {
                0.0
            }
        };
        let (dx, dy) = (shift(x0, x1, width), shift(y0, y1, height));
        if dx != 0.0 || dy != 0.0 {
            if let (Some(from), Some(to)) = (
                rig.ground(width / 2.0, height / 2.0),
                rig.ground(width / 2.0 - dx, height / 2.0 - dy),
            ) {
                self.goal.x += to.0 - from.0;
                self.goal.y += to.1 - from.1;
            }
        }
    }

    fn current(&self, placed: &Placed) -> [f32; 6] {
        self.anims.get(&self.tree.items[placed.item].id).map_or(
            [placed.x, placed.y, placed.z, placed.w, placed.d, placed.h],
            |anim| anim.rect,
        )
    }

    // ----- per frame -----

    /// Advance animations by `dt` milliseconds for a viewport and write the instances and
    /// the matrix. Returns whether anything is still moving.
    pub fn frame(&mut self, dt: f32, width: f32, height: f32) -> bool {
        let resized =
            (width - self.viewport.0).abs() > 0.5 || (height - self.viewport.1).abs() > 0.5;
        self.viewport = (width.max(1.0), height.max(1.0));
        if resized && self.following {
            self.follow();
        }
        if !self.fitted && !self.placed.is_empty() {
            self.follow();
            self.camera = self.goal;
            self.fitted = true;
        }
        let dt = dt.clamp(0.0, 100.0);
        let still = self.still;
        let rate = |time: f32| if still { 1.0 } else { 1.0 - (-dt / time).exp() };
        let (k, quick) = (rate(85.0), rate(55.0));
        let mut moving = self.ease_camera(k, rate(70.0));

        self.instances.clear();
        let mut marks = Vec::new();
        for placed in &self.placed {
            let item = &self.tree.items[placed.item];
            let target = [placed.x, placed.y, placed.z, placed.w, placed.d, placed.h];
            let (tone, mut flags) = self.paint(placed);
            let hovered = self.hovered.as_deref() == Some(item.id.as_str());
            if hovered {
                flags |= flag::HOVER;
            }
            let lift = if placed.slab {
                0.0
            } else if flags & flag::SELECTED != 0 {
                5.0
            } else if hovered {
                3.5
            } else {
                0.0
            };
            let dim = if flags & flag::DIM == 0 { 0.0 } else { 1.0 };
            let mark = self.mark(placed);
            let anim = self
                .anims
                .get_mut(&item.id)
                .expect("every placed item has an animation");
            for (current, goal) in anim.rect.iter_mut().zip(target) {
                let next = ease(*current, goal, k);
                moving |= next != goal;
                *current = next;
            }
            for (current, goal, k) in [
                (&mut anim.grow, 1.0, k),
                (&mut anim.lift, lift, quick),
                (&mut anim.dim, dim, quick),
            ] {
                let next = ease(*current, goal, k);
                moving |= next != goal;
                *current = next;
            }
            let (rect, grow) = (anim.rect, anim.grow.max(0.0));
            self.instances.extend(rect);
            self.instances.extend([
                f32::from(tone as u8),
                flags as f32,
                grow,
                anim.lift,
                anim.dim,
            ]);
            if let Some(applied) = mark {
                marks.push((rect, grow, applied, anim.lift, anim.dim));
            }
        }
        for (rect, grow, applied, lift, dim) in marks {
            let size = 9.0_f32.min(rect[3] * 0.2).min(rect[4] * 0.3);
            let tone = if applied {
                Tone::Applied
            } else {
                Tone::Pending
            };
            self.instances.extend([
                rect[0] + rect[3] - size - 7.0,
                rect[1] + 7.0,
                rect[2] + rect[5] * grow,
                size,
                size,
                if applied { 2.4 } else { 1.0 },
                f32::from(tone as u8),
                flag::MARK as f32,
                grow,
                lift,
                dim,
            ]);
        }
        moving |= self.sink_ghosts(rate(70.0));
        self.matrix = self.rig().matrix();
        moving
    }

    /// Move the camera toward its goal; returns whether it is still on its way.
    fn ease_camera(&mut self, k: f32, zoom_rate: f32) -> bool {
        let mut moving = false;
        let goal = self.goal;
        for (current, goal) in [
            (&mut self.camera.x, goal.x),
            (&mut self.camera.y, goal.y),
            (&mut self.camera.yaw, goal.yaw),
            (&mut self.camera.pitch, goal.pitch),
        ] {
            let next = ease(*current, goal, k);
            moving |= next != goal;
            *current = next;
        }
        // Zoom eases in its logarithm, so that zooming in and out feel alike.
        let zoom = ease(self.camera.zoom.ln(), goal.zoom.ln(), zoom_rate);
        let zooming = zoom != goal.zoom.ln();
        moving |= zooming;
        self.camera.zoom = zoom.exp();
        if let Some((x, y, ground_x, ground_y)) = self.zoom_anchor {
            // Hold the anchored ground point under its pixel while the zoom is on its way.
            if let Some(now) = self.rig().ground(x, y) {
                self.camera.x += ground_x - now.0;
                self.camera.y += ground_y - now.1;
                self.goal.x = self.camera.x;
                self.goal.y = self.camera.y;
            }
            if !zooming {
                self.zoom_anchor = None;
            }
        }
        moving
    }

    /// Shrink what was closed over toward where it went, and write it after the boxes.
    fn sink_ghosts(&mut self, rate: f32) -> bool {
        for ghost in &mut self.ghosts {
            ghost.grow = ease(ghost.grow, 0.0, rate);
            let shrink = 0.35 + 0.65 * ghost.grow;
            let (cx, cy) = (
                ghost.toward.0
                    + (ghost.rect[0] + ghost.rect[3] / 2.0 - ghost.toward.0) * ghost.grow,
                ghost.toward.1
                    + (ghost.rect[1] + ghost.rect[4] / 2.0 - ghost.toward.1) * ghost.grow,
            );
            let (w, d) = (ghost.rect[3] * shrink, ghost.rect[4] * shrink);
            self.instances.extend([
                cx - w / 2.0,
                cy - d / 2.0,
                ghost.rect[2],
                w,
                d,
                ghost.rect[5],
                f32::from(ghost.tone as u8),
                ghost.flags as f32,
                ghost.grow,
                0.0,
                1.0 - ghost.grow,
            ]);
        }
        self.ghosts.retain(|ghost| ghost.grow > 0.02);
        !self.ghosts.is_empty()
    }

    fn rig(&self) -> Rig {
        self.camera.rig(self.viewport.0, self.viewport.1)
    }

    fn stack(&self, item: usize) -> Option<&StackModel> {
        self.model.as_ref()?.stacks.get(self.tree.items[item].stack)
    }

    fn paint(&self, placed: &Placed) -> (Tone, u32) {
        let item = &self.tree.items[placed.item];
        let model = self.model.as_ref().expect("placed items come from a model");
        let mut flags = 0;
        let tone = if let Some(node) = item.node {
            match self.tree.node(model, node).kind {
                NodeKind::Resource => Tone::Resource,
                NodeKind::Data | NodeKind::StackReference => Tone::Read,
                NodeKind::Output => Tone::Output,
                NodeKind::Provider => Tone::Neutral,
            }
        } else {
            flags |= flag::CONTAINER;
            if placed.slab {
                flags |= flag::SLAB;
                match placed.depth {
                    0 => Tone::Stack,
                    depth if depth % 2 == 1 => Tone::SlabOdd,
                    _ => Tone::SlabEven,
                }
            } else {
                Tone::Group
            }
        };
        if item.role == Role::Stack {
            match self.stack(placed.item).map(|stack| stack.status) {
                Some(BuildStatus::Failed) => flags |= flag::FAILED,
                Some(BuildStatus::Building) => flags |= flag::BUILDING,
                _ => {}
            }
        }
        let selected = self.selected.as_deref() == Some(item.id.as_str());
        if selected {
            flags |= flag::SELECTED;
        }
        if !placed.slab {
            let covers = |set: &HashSet<usize>| item.leaves.iter().any(|node| set.contains(node));
            let related = covers(&self.related);
            if related {
                flags |= flag::RELATED;
            }
            if self.selected.is_some() && !selected && !related && !covers(&self.inside) {
                flags |= flag::DIM;
            }
            if let Some(matching) = &self.matching {
                if covers(matching) {
                    flags |= flag::MATCH;
                } else {
                    flags |= flag::DIM;
                }
            }
        }
        (tone, flags)
    }

    fn mark(&self, placed: &Placed) -> Option<bool> {
        let item = &self.tree.items[placed.item];
        let node = item.node?;
        if !self.marked_stacks.contains(&item.stack) || placed.w < 60.0 || placed.d < 30.0 {
            return None;
        }
        self.tree.node(self.model.as_ref()?, node).applied
    }

    #[must_use]
    pub fn revision(&self) -> u32 {
        self.revision
    }

    /// Pixels per world unit where the camera looks, for the page to size its text by.
    #[must_use]
    pub fn zoom_level(&self) -> f32 {
        self.camera.zoom
    }

    #[must_use]
    pub fn instances(&self) -> &[f32] {
        &self.instances
    }

    #[must_use]
    pub fn matrix(&self) -> &[f32; 16] {
        &self.matrix
    }

    // ----- what the page shows beside the canvas -----

    /// The boxes in instance order, with what to write on them, and the links to draw.
    #[must_use]
    pub fn scene(&self) -> Value {
        let Some(model) = &self.model else {
            return json!({ "boxes": [], "links": [] });
        };
        let boxes: Vec<Value> = self
            .placed
            .iter()
            .map(|placed| {
                let item = &self.tree.items[placed.item];
                let (label, sub) = self.caption(placed.item);
                let (rows, more, split) = self.rows(placed.item);
                json!({
                    "id": item.id,
                    "label": label,
                    "sub": sub,
                    "icon": item.node.map_or("group", |node| kind_key(self.tree.node(model, node).kind)),
                    "container": item.is_container(),
                    "slab": placed.slab,
                    "openable": item.is_container() && !item.children.is_empty() && self.mode == Mode::Explore,
                    "depth": placed.depth,
                    // Where the box is heading, which is what its text is fitted to.
                    "w": placed.w,
                    "d": placed.d,
                    // A node's configuration, written on it when everything is open.
                    "rows": rows,
                    "more": more,
                    "split": split,
                })
            })
            .collect();
        let links: Vec<Value> = self
            .links
            .iter()
            .map(|link| json!({ "from": link.from, "to": link.to, "kind": link.kind, "count": link.count, "muted": link.muted }))
            .collect();
        json!({ "boxes": boxes, "links": links })
    }

    /// The outline: the same tree, open where the canvas is open.
    #[must_use]
    pub fn outline(&self) -> Value {
        let Some(model) = &self.model else {
            return json!([]);
        };
        let mut rows = Vec::new();
        let mut pending: Vec<(usize, usize)> = self.tree.items[0]
            .children
            .iter()
            .rev()
            .map(|&child| (child, 0))
            .collect();
        while let Some((index, depth)) = pending.pop() {
            let item = &self.tree.items[index];
            let open = item.is_container()
                && (self.mode == Mode::Everything || self.expanded.contains(&item.id));
            let node = item.node.map(|node| self.tree.node(model, node));
            let small = node.map(|data| match data.kind {
                NodeKind::Provider => String::new(),
                NodeKind::StackReference => "stack".to_owned(),
                NodeKind::Output => "output".to_owned(),
                _ => strip_provider(&data.type_name, data.provider.as_deref().unwrap_or("")),
            });
            rows.push(json!({
                "id": item.id,
                "depth": depth,
                "label": item.label,
                "small": small,
                "tone": node.map_or("group", |data| kind_key(data.kind)),
                "count": item.is_container().then_some(item.leaves.len()),
                "open": (item.is_container() && !item.children.is_empty()).then_some(open),
                "selected": self.selected.as_deref() == Some(item.id.as_str()),
                "dim": self.matching.as_ref().is_some_and(|matching| !item.leaves.iter().any(|leaf| matching.contains(leaf))),
            }));
            if open {
                pending.extend(item.children.iter().rev().map(|&child| (child, depth + 1)));
            }
        }
        Value::Array(rows)
    }

    /// What the top bar says.
    #[must_use]
    pub fn summary(&self) -> Value {
        let Some(model) = &self.model else {
            return json!({});
        };
        let named = |status: BuildStatus| -> Vec<&str> {
            model
                .stacks
                .iter()
                .filter(|stack| stack.status == status)
                .map(|stack| stack.name.as_str())
                .collect()
        };
        json!({
            "project": model.project.name,
            "version": model.version,
            "building": named(BuildStatus::Building),
            "failed": named(BuildStatus::Failed),
            "built_at_ms": model.stacks.iter().filter_map(|stack| stack.built_at_ms).max(),
            "matches": self.matching.as_ref().map(HashSet::len),
            "grouping": self.grouping,
            "mode": self.mode,
            "all_links": self.all_links,
            "following": self.following,
            "selected": self.selected,
        })
    }

    fn link_row(&self, model: &Model, node: usize, note: &str, from_stack: usize) -> Value {
        let data = self.tree.node(model, node);
        let stack = self.tree.nodes[node].stack;
        let prefix = if stack == from_stack {
            String::new()
        } else {
            format!("{} · ", model.stacks[stack].name)
        };
        json!({ "id": data.id, "label": format!("{prefix}{}", data.address), "tone": kind_key(data.kind), "note": note, "mono": true })
    }

    /// Everything the inspector shows for the selection, or for the project without one.
    #[must_use]
    pub fn inspect(&self) -> Value {
        let Some(model) = &self.model else {
            return json!({ "type": "empty" });
        };
        let Some(item_index) = self.selected.as_deref().and_then(|id| self.tree.find(id)) else {
            return json!({
                "type": "project",
                "project": model.project,
                "marks": !self.marked_stacks.is_empty(),
                "stacks": model.stacks.iter().map(|stack| json!({
                    "id": format!("s:{}", stack.name),
                    "name": stack.name,
                    "status": stack.status,
                    "nodes": stack.nodes.len(),
                    "edges": stack.edges.len(),
                })).collect::<Vec<_>>(),
            });
        };
        if let Some(node) = self.tree.items[item_index].node {
            self.inspect_node(model, item_index, node)
        } else {
            self.inspect_group(model, item_index)
        }
    }

    fn inspect_node(&self, model: &Model, item_index: usize, node: usize) -> Value {
        let item = &self.tree.items[item_index];
        let stack = &model.stacks[item.stack];
        let describe = |edge: &Edge| match edge.kind {
            EdgeKind::Reference | EdgeKind::Stack => edge.via.join(", "),
            EdgeKind::DependsOn => "depends on".to_owned(),
            EdgeKind::ReplaceTrigger => "is replaced with".to_owned(),
            EdgeKind::Provider => "is created through".to_owned(),
        };
        let rows = |edges: &[usize], outward: bool| -> Vec<Value> {
            edges
                .iter()
                .map(|&edge| {
                    let (from, to, _, _) = self.edges[edge];
                    self.link_row(
                        model,
                        if outward { to } else { from },
                        &describe(self.edge(edge)),
                        item.stack,
                    )
                })
                .collect()
        };
        let data = self.tree.node(model, node);
        json!({
            "type": "node",
            "id": item.id,
            "node": data,
            "kind_label": kind_label(data.kind),
            "stack": stack.name,
            "frontend": stack.frontend,
            "has_origins": stack.has_origins,
            "state_reason": stack.state.reason,
            "depends": rows(&self.outgoing[node], true),
            "used_by": rows(&self.incoming[node], false),
        })
    }

    fn inspect_group(&self, model: &Model, item_index: usize) -> Value {
        let item = &self.tree.items[item_index];
        let stack = &model.stacks[item.stack];
        let inside: HashSet<usize> = item.leaves.iter().copied().collect();
        // The other end of an association, lifted to the largest group that does not hold
        // any of the selection: associations then read group to group.
        let owner = |node: usize| {
            let mut other = self.tree.leaf_of[node];
            let mut at = self.tree.items[other].parent;
            while let Some(parent) = at {
                if parent == 0
                    || self.tree.items[parent]
                        .leaves
                        .iter()
                        .any(|leaf| inside.contains(leaf))
                {
                    break;
                }
                other = parent;
                at = self.tree.items[parent].parent;
            }
            other
        };
        let mut outward: BTreeMap<usize, usize> = BTreeMap::new();
        let mut inward: BTreeMap<usize, usize> = BTreeMap::new();
        for &node in &item.leaves {
            for &edge in &self.outgoing[node] {
                let (_, to, _, _) = self.edges[edge];
                if !inside.contains(&to) && self.edge(edge).kind != EdgeKind::Provider {
                    *outward.entry(owner(to)).or_default() += 1;
                }
            }
            for &edge in &self.incoming[node] {
                let (from, _, _, _) = self.edges[edge];
                if !inside.contains(&from) && self.edge(edge).kind != EdgeKind::Provider {
                    *inward.entry(owner(from)).or_default() += 1;
                }
            }
        }
        let rows = |entries: BTreeMap<usize, usize>| -> Vec<Value> {
            let mut entries: Vec<_> = entries.into_iter().collect();
            entries.sort_by_key(|entry| std::cmp::Reverse(entry.1));
            entries
                .into_iter()
                .map(|(other, count)| {
                    let data = &self.tree.items[other];
                    let associations = format!("{count} association{}", if count == 1 { "" } else { "s" });
                    if let Some(node) = data.node {
                        return self.link_row(model, node, &associations, item.stack);
                    }
                    let place = match data.role {
                        Role::Definition => format!("definition in {}", data.parent.map(|parent| self.tree.trail(parent)).unwrap_or_default()),
                        role => role.noun().to_owned(),
                    };
                    json!({ "id": data.id, "label": data.label, "tone": "group", "note": format!("{place} · {associations}") })
                })
                .collect()
        };
        let counts: Vec<Value> = KIND_ORDER
            .iter()
            .filter_map(|&kind| {
                let count = item.leaves.iter().filter(|&&node| self.tree.node(model, node).kind == kind).count();
                (count > 0).then(|| json!({ "kind": kind_key(kind), "label": kind_plural(kind), "count": count }))
            })
            .collect();
        let children: Vec<Value> = item
            .children
            .iter()
            .map(|&child| {
                let data = &self.tree.items[child];
                let tone = data
                    .node
                    .map_or("group", |node| kind_key(self.tree.node(model, node).kind));
                let note = if data.is_container() {
                    format!("{} · {}", data.role.noun(), data.leaves.len())
                } else {
                    String::new()
                };
                json!({ "id": data.id, "label": data.label, "tone": tone, "note": note })
            })
            .collect();
        json!({
            "type": "group",
            "id": item.id,
            "role": item.role,
            "title": item.full.as_deref().unwrap_or(&item.label),
            "trail": self.tree.trail(item_index),
            "stack": (item.role == Role::Stack).then_some(stack),
            "nodes": item.leaves.len(),
            "counts": counts,
            "children": children,
            "depends": rows(outward),
            "used_by": rows(inward),
            "openable": !item.children.is_empty() && self.mode == Mode::Explore,
            "open": self.expanded.contains(&item.id),
        })
    }

    /// The short text shown beside the pointer over a box.
    #[must_use]
    pub fn tip(&self, id: &str) -> Value {
        let (Some(model), Some(index)) = (&self.model, self.tree.find(id)) else {
            return Value::Null;
        };
        let item = &self.tree.items[index];
        if let Some(node) = item.node {
            let data = self.tree.node(model, node);
            let origin = data.origin.as_ref().map(|origin| {
                if origin.declaration.is_empty() {
                    origin.module.clone()
                } else {
                    format!("{} › {}", origin.module, origin.declaration)
                }
            });
            let state = data.applied.map(|applied| {
                if applied {
                    "applied"
                } else {
                    "not applied yet"
                }
            });
            let counts = format!(
                "{} · {} depends on · {} used by",
                kind_label(data.kind),
                self.outgoing[node].len(),
                self.incoming[node].len()
            );
            return json!({ "title": data.address, "lines": [origin, Some(counts), state.map(str::to_owned)] });
        }
        let open = self.expanded.contains(&item.id) || self.mode == Mode::Everything;
        let hint = if item.children.is_empty() {
            None
        } else if self.mode == Mode::Everything {
            Some("double-click to zoom in")
        } else if open {
            Some("click to select · again to close")
        } else {
            Some("click to open")
        };
        json!({
            "title": item.full.as_deref().unwrap_or(&item.label),
            "lines": [Some(format!("{} · {} node{}", item.role.noun(), item.leaves.len(), if item.leaves.len() == 1 { "" } else { "s" })), hint.map(str::to_owned)],
        })
    }
}

const fn kind_key(kind: NodeKind) -> &'static str {
    match kind {
        NodeKind::Provider => "provider",
        NodeKind::Resource => "resource",
        NodeKind::Data => "data",
        NodeKind::StackReference => "stack_reference",
        NodeKind::Output => "output",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::{Argument, Node, Origin, ProjectInfo, StateModel};

    fn node(stack: &str, address: &str, module: &str, declaration: &str) -> Node {
        let (type_name, name) = address.rsplit_once('.').unwrap();
        let kind = if address.starts_with("output.") {
            NodeKind::Output
        } else {
            NodeKind::Resource
        };
        Node {
            id: format!("{stack}/{address}"),
            kind,
            address: address.to_owned(),
            type_name: if kind == NodeKind::Output {
                String::new()
            } else {
                type_name.to_owned()
            },
            name: name.to_owned(),
            provider: Some("cloud".to_owned()),
            origin: (!module.is_empty()).then(|| Origin {
                module: module.to_owned(),
                declaration: declaration.to_owned(),
                line: 1,
            }),
            arguments: vec![Argument {
                name: "name".to_owned(),
                value: format!("\"{name}\""),
                references: Vec::new(),
            }],
            hidden_arguments: 0,
            flags: Vec::new(),
            weight: 4,
            applied: None,
        }
    }

    fn edge(from: &str, to: &str) -> Edge {
        Edge {
            from: from.to_owned(),
            to: to.to_owned(),
            kind: EdgeKind::Reference,
            via: vec!["vpc → id".to_owned()],
        }
    }

    fn model() -> Model {
        let app = StackModel {
            name: "app".to_owned(),
            frontend: "Lean".to_owned(),
            backend: "local".to_owned(),
            gated: false,
            status: BuildStatus::Ready,
            error: None,
            built_at_ms: Some(1),
            build_ms: Some(1),
            has_origins: true,
            state: StateModel {
                tracked: false,
                reason: None,
                serial: None,
                updated_ms: None,
            },
            nodes: vec![
                node("app", "cloud_vpc.main", "Infra.App.Network", "network"),
                node("app", "cloud_db.main", "Infra.App.Data", "database"),
                node("app", "cloud_db.replica", "Infra.App.Data", "database"),
                node("app", "output.host", "Infra.App", "stack"),
            ],
            edges: vec![
                edge("app/cloud_db.main", "app/cloud_vpc.main"),
                edge("app/cloud_db.replica", "app/cloud_vpc.main"),
                edge("app/output.host", "app/cloud_db.main"),
            ],
            unmanaged: Vec::new(),
        };
        Model {
            version: 1,
            project: ProjectInfo {
                name: "demo".to_owned(),
                root: "/demo".to_owned(),
                error: None,
            },
            stacks: vec![app],
        }
    }

    fn ready() -> View {
        let mut view = View::new();
        view.set_model(model());
        view.frame(16.0, 1200.0, 800.0);
        view
    }

    fn labels(view: &View) -> Vec<String> {
        view.scene()["boxes"]
            .as_array()
            .unwrap()
            .iter()
            .map(|entry| entry["label"].as_str().unwrap().to_owned())
            .collect()
    }

    #[test]
    fn a_stack_opens_to_its_modules_and_no_further() {
        let view = ready();
        // The stack and its only module `Infra.App` open in one step; what they hold is closed.
        assert_eq!(
            labels(&view),
            ["app", "Infra.App", "Data", "Network", "stack"]
        );
        let scene = view.scene();
        let slabs: Vec<bool> = scene["boxes"]
            .as_array()
            .unwrap()
            .iter()
            .map(|entry| entry["slab"].as_bool().unwrap())
            .collect();
        assert_eq!(slabs, [true, true, false, false, false]);
    }

    #[test]
    fn clicking_opens_selects_and_closes() {
        let mut view = ready();
        let data = "s:app/m:Infra.App/m:Infra.App.Data";
        view.click(data);
        // `Data` holds one definition, so it opens straight to the definition's nodes.
        assert_eq!(
            labels(&view),
            [
                "app",
                "Infra.App",
                "Data",
                "database",
                "main",
                "replica",
                "Network",
                "stack"
            ]
        );
        assert_eq!(view.summary()["selected"], data);
        view.click(data);
        assert_eq!(labels(&view).len(), 5);
        // Revealing a node opens every group above it.
        view.select(Some("app/cloud_db.replica"), true);
        assert!(labels(&view).contains(&"replica".to_owned()));
    }

    #[test]
    fn links_attach_to_the_closed_group_that_hides_a_node() {
        let mut view = ready();
        view.select(Some("s:app/m:Infra.App/m:Infra.App.Data"), false);
        let scene = view.scene();
        let boxes = scene["boxes"].as_array().unwrap();
        let name = |index: &Value| {
            boxes[index.as_u64().unwrap() as usize]["label"]
                .as_str()
                .unwrap()
                .to_owned()
        };
        let mut links: Vec<(String, String, u64)> = scene["links"]
            .as_array()
            .unwrap()
            .iter()
            .map(|link| {
                (
                    name(&link["from"]),
                    name(&link["to"]),
                    link["count"].as_u64().unwrap(),
                )
            })
            .collect();
        links.sort();
        // Both databases read the VPC: one link, counted twice, from group to group.
        assert_eq!(
            links,
            [
                ("Data".to_owned(), "Network".to_owned(), 2),
                ("stack".to_owned(), "Data".to_owned(), 1)
            ]
        );
        let inspect = view.inspect();
        assert_eq!(inspect["depends"][0]["label"], "Network");
        assert_eq!(inspect["depends"][0]["note"], "module · 2 associations");
    }

    #[test]
    fn the_map_shows_every_node_at_once() {
        let mut view = ready();
        view.set_mode(Mode::Everything);
        view.frame(16.0, 1200.0, 800.0);
        let shown = labels(&view);
        for name in ["main", "replica", "host"] {
            assert!(shown.contains(&name.to_owned()), "{shown:?}");
        }
        assert_eq!(view.instances().len() % INSTANCE_FLOATS, 0);
    }

    /// In both layouts, at every expansion: blocks never overlap, and everything standing on
    /// a slab is within it.
    #[test]
    fn nothing_overlaps_and_children_stay_on_their_group() {
        let mut view = ready();
        let check = |view: &View, when: &str| {
            let tree = &view.tree;
            for (index, a) in view.placed.iter().enumerate() {
                if let Some(parent) = tree.items[a.item]
                    .parent
                    .and_then(|parent| view.box_of.get(&parent))
                {
                    let slab = &view.placed[*parent];
                    assert!(
                        a.x >= slab.x - 0.01
                            && a.y >= slab.y - 0.01
                            && a.x + a.w <= slab.x + slab.w + 0.01
                            && a.y + a.d <= slab.y + slab.d + 0.01,
                        "{when}: {} leaves {}",
                        tree.items[a.item].id,
                        tree.items[slab.item].id
                    );
                }
                for b in &view.placed[index + 1..] {
                    let related = |x: usize, y: usize| {
                        let mut at = Some(x);
                        while let Some(item) = at {
                            if item == y {
                                return true;
                            }
                            at = tree.items[item].parent;
                        }
                        false
                    };
                    if related(a.item, b.item) || related(b.item, a.item) {
                        continue;
                    }
                    let apart = a.x + a.w <= b.x + 0.01
                        || b.x + b.w <= a.x + 0.01
                        || a.y + a.d <= b.y + 0.01
                        || b.y + b.d <= a.y + 0.01;
                    assert!(
                        apart,
                        "{when}: {} overlaps {}",
                        tree.items[a.item].id, tree.items[b.item].id
                    );
                }
            }
        };
        check(&view, "as opened");
        view.click("s:app/m:Infra.App/m:Infra.App.Data");
        check(&view, "one module open");
        view.expand_all("s:app");
        check(&view, "everything open");
        view.collapse_all();
        check(&view, "everything closed");
        for aspect in [0.7, 1.6, 2.4] {
            view.set_mode(Mode::Everything);
            view.frame(16.0, 1000.0 * aspect, 1000.0);
            check(&view, "map");
        }
    }

    /// A stack written as one long definition opens to its resource families, each holding
    /// its nodes, and every node is still reachable.
    #[test]
    fn a_crowded_definition_is_split_by_resource_family() {
        let mut model = model();
        let stack = &mut model.stacks[0];
        stack.nodes.clear();
        stack.edges.clear();
        for index in 0..9 {
            stack.nodes.push(node(
                "app",
                &format!("cloud_iam_role.r{index}"),
                "Infra.App",
                "cell",
            ));
            stack.nodes.push(node(
                "app",
                &format!("cloud_s3_bucket.b{index}"),
                "Infra.App",
                "cell",
            ));
        }
        stack
            .nodes
            .push(node("app", "cloud_vpc.only", "Infra.App", "cell"));
        stack
            .nodes
            .push(node("app", "output.one", "Infra.App", "cell"));
        stack
            .nodes
            .push(node("app", "output.two", "Infra.App", "cell"));
        let mut view = View::new();
        view.set_model(model);
        view.frame(16.0, 1200.0, 800.0);
        // Stack, module and definition open in one step; the definition shows families.
        assert_eq!(
            labels(&view),
            ["app", "Infra.App", "cell", "iam", "s3", "outputs", "only"]
        );
        let outline = view.outline();
        let iam = outline
            .as_array()
            .unwrap()
            .iter()
            .find(|row| row["label"] == "iam")
            .unwrap();
        assert_eq!(iam["count"], 9);
        view.click("s:app/m:Infra.App/d:cell/f:s3");
        assert!(labels(&view).contains(&"b4".to_owned()));
        assert_eq!(view.inspect()["role"], "family");
        assert_eq!(view.inspect()["nodes"], 9);
    }

    /// What is needed comes before what needs it, at every level, and a block is as wide as
    /// its text: nothing is fitted to a frame.
    #[test]
    fn dependencies_come_first_and_blocks_fit_their_text() {
        let mut model = model();
        model.stacks[0].nodes.push(node(
            "app",
            "cloud_load_balancer_listener_rule.a_rule_with_a_very_long_descriptive_name",
            "Infra.App.Network",
            "network",
        ));
        let mut view = View::new();
        view.set_model(model);
        view.set_metrics(Metrics {
            sans: vec![0.6; 95],
            mono: vec![0.6; 95],
        });
        view.frame(16.0, 1200.0, 800.0);
        let at = |view: &View, label: &str| {
            let index = labels(view)
                .iter()
                .position(|known| known == label)
                .unwrap_or_else(|| panic!("{label} is not shown"));
            view.placed[index]
        };
        // Modules: Network is needed by Data, which the stack's output needs. In reading
        // order (across, and down within a column) each comes after what it needs.
        let before = |a: Placed, b: Placed| a.x + a.w <= b.x || (a.x == b.x && a.y + a.d <= b.y);
        assert!(before(at(&view, "Network"), at(&view, "Data")));
        assert!(before(at(&view, "Data"), at(&view, "stack")));
        view.set_mode(Mode::Everything);
        let (long, short) = (
            at(&view, "a_rule_with_a_very_long_descriptive_name"),
            at(&view, "replica"),
        );
        assert!(long.w > short.w + 150.0, "{} against {}", long.w, short.w);
        assert!(
            long.w >= 13.0 + 41.0 * 0.6 * 13.0,
            "the name fits: {}",
            long.w
        );
        // Every node shows its configuration, and is as deep as its rows.
        let scene = view.scene();
        let replica = scene["boxes"]
            .as_array()
            .unwrap()
            .iter()
            .find(|entry| entry["label"] == "replica")
            .unwrap();
        assert_eq!(replica["rows"][0][0], "name");
        assert_eq!(replica["rows"][0][1], "\"replica\"");
        assert!(short.d > 60.0);
    }

    #[test]
    fn picking_finds_the_box_under_a_pixel() {
        let mut view = ready();
        for _ in 0..80 {
            view.frame(16.0, 1200.0, 800.0);
        }
        let scene = view.scene();
        let boxes = scene["boxes"].as_array().unwrap();
        let index = boxes
            .iter()
            .position(|entry| entry["label"] == "Network")
            .unwrap();
        let at = &view.instances()[index * INSTANCE_FLOATS..];
        let top = [at[0] + at[3] / 2.0, at[1] + at[4] / 2.0, at[2] + at[5]];
        let (x, y) = view.rig().project(top);
        assert_eq!(view.pick(x, y), Some(index));
        assert_eq!(view.pick(2.0, 2.0), None);
    }

    #[test]
    fn a_query_dims_what_does_not_match_and_reveals_the_first_that_does() {
        let mut view = ready();
        view.set_query("REPLICA");
        assert_eq!(view.summary()["matches"], 1);
        view.first_match();
        assert_eq!(view.summary()["selected"], "app/cloud_db.replica");
        let answer: Value =
            serde_json::from_str(&view.command(r#"{"op":"query","text":""}"#)).unwrap();
        assert!(answer["summary"]["matches"].is_null());
        assert!(view.command("{").contains("error"));
    }
}
