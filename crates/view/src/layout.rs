//! Where everything stands on the ground plane. World units are CSS pixels at zoom 1; `x`
//! runs right, `y` toward the viewer, `z` up.
//!
//! The canvas has no edge, so nothing is fitted to a frame. A node or a closed group is a
//! block exactly as large as what is written on it. An open group is a slab with its
//! children standing on it in the order of what needs what, read like text: a child comes
//! after everything it depends on, so reading a group is reading in the order things can be
//! created, and associations point back the way you came.

use serde::{Deserialize, Serialize};

use crate::tree::{Role, Tree};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Mode {
    /// Groups stay closed until they are opened.
    #[default]
    Explore,
    /// Every group open, and every node showing its configuration.
    #[serde(alias = "map")]
    Everything,
}

/// One visible item: a slab (an open group) or a block (a node or a closed group).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Placed {
    pub item: usize,
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub d: f32,
    /// The height of its base above the ground.
    pub z: f32,
    pub h: f32,
    pub slab: bool,
    /// Nesting depth below the root: stacks are 0.
    pub depth: u32,
}

/// How large each item's text makes it, by item index.
#[derive(Debug, Default)]
pub struct Sizes {
    /// The footprint of the item as a block: a node, or a group while closed.
    pub block: Vec<(f32, f32)>,
    /// The width an open group needs for its title.
    pub title: Vec<f32>,
}

const GAP: f32 = 16.0;
const PAD: f32 = 16.0;
/// The band along a slab's near edge that carries its label. It is at the near edge because
/// the view is tilted: a label at the far edge would be hidden behind the slab's own children.
const FOOTER: f32 = 32.0;
const SLAB: f32 = 5.0;

/// A node's height says how much configuration it carries.
fn leaf_height(weight: f32) -> f32 {
    7.0 + weight.min(24.0) * 0.8
}

/// A closed group's height says how much is inside.
fn group_height(leaves: usize) -> f32 {
    (13.0 + 3.6 * ((leaves + 1) as f32).log2()).min(34.0)
}

/// Lay out everything `open` says is open. The root is always open.
#[must_use]
pub fn layout(tree: &Tree, sizes: &Sizes, open: &dyn Fn(usize) -> bool) -> Vec<Placed> {
    let mut placed = Vec::new();
    if tree.items.is_empty() {
        return placed;
    }
    let mut footprint = vec![(0.0, 0.0); tree.items.len()];
    let mut offsets = vec![(0.0, 0.0); tree.items.len()];
    measure(tree, sizes, open, 0, &mut footprint, &mut offsets);
    for &child in &tree.items[0].children {
        place(
            tree,
            open,
            child,
            offsets[child],
            0.0,
            0,
            &footprint,
            &offsets,
            &mut placed,
        );
    }
    placed
}

fn is_open(tree: &Tree, open: &dyn Fn(usize) -> bool, item: usize) -> bool {
    let data = &tree.items[item];
    data.role == Role::Root || (!data.children.is_empty() && open(item))
}

/// Size `item` and position its children relative to it, bottom-up.
fn measure(
    tree: &Tree,
    sizes: &Sizes,
    open: &dyn Fn(usize) -> bool,
    item: usize,
    footprint: &mut [(f32, f32)],
    offsets: &mut [(f32, f32)],
) {
    let data = &tree.items[item];
    if !data.is_container() || !is_open(tree, open, item) {
        footprint[item] = sizes.block[item];
        return;
    }
    let root = data.role == Role::Root;
    let (mut area, mut widest) = (0.0_f32, 0.0_f32);
    for &child in &data.children {
        measure(tree, sizes, open, child, footprint, offsets);
        area += (footprint[child].0 + GAP) * (footprint[child].1 + GAP);
        widest = widest.max(footprint[child].0);
    }
    // Children stand in the order of their ranks, read like text: left to right, then on to
    // the next row. Within a row a child goes under the previous one while the column stays
    // within the row's height, so a few small blocks sit beside a large open group rather
    // than each taking a column of its own. Rows wrap at the width of a rectangle of the
    // children's area in a comfortable proportion; nothing is scaled to fit it.
    let limit = widest.max((area * if root { 2.0 } else { 1.7 }).sqrt());
    let (left, top) = if root { (0.0, 0.0) } else { (PAD, PAD) };
    let mut order: Vec<usize> = data.children.clone();
    order.sort_by_key(|&child| tree.items[child].rank);
    let (mut x, mut y) = (left, top);
    let (mut row, mut width, mut depth) = (0.0_f32, 0.0_f32, 0.0_f32);
    let (mut column_w, mut column_d) = (0.0_f32, 0.0_f32);
    for child in order {
        let (w, d) = footprint[child];
        if column_d > 0.0 && column_d + GAP + d <= row + 0.5 {
            offsets[child] = (x, y + column_d + GAP);
            column_d += GAP + d;
            column_w = column_w.max(w);
            width = width.max(x + w);
            continue;
        }
        if column_d > 0.0 {
            x += column_w + GAP;
        }
        if x > left && x + w - left > limit {
            x = left;
            y += row + GAP;
            row = 0.0;
        }
        offsets[child] = (x, y);
        column_w = w;
        column_d = d;
        row = row.max(d);
        width = width.max(x + w);
        depth = depth.max(y + row);
    }
    footprint[item] = if root {
        (width, depth)
    } else {
        ((width + PAD).max(sizes.title[item]), depth + FOOTER)
    };
}

#[allow(clippy::too_many_arguments)]
fn place(
    tree: &Tree,
    open: &dyn Fn(usize) -> bool,
    item: usize,
    at: (f32, f32),
    z: f32,
    depth: u32,
    footprint: &[(f32, f32)],
    offsets: &[(f32, f32)],
    placed: &mut Vec<Placed>,
) {
    let data = &tree.items[item];
    let slab = data.is_container() && is_open(tree, open, item);
    let h = if slab {
        SLAB
    } else if data.is_container() {
        group_height(data.leaves.len())
    } else {
        leaf_height(data.weight)
    };
    placed.push(Placed {
        item,
        x: at.0,
        y: at.1,
        w: footprint[item].0,
        d: footprint[item].1,
        z,
        h,
        slab,
        depth,
    });
    if slab {
        for &child in &data.children {
            let offset = (at.0 + offsets[child].0, at.1 + offsets[child].1);
            place(
                tree,
                open,
                child,
                offset,
                z + h,
                depth + 1,
                footprint,
                offsets,
                placed,
            );
        }
    }
}
