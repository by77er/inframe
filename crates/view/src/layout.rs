//! Where everything stands on the ground plane. World units are CSS pixels at zoom 1; `x`
//! runs right, `y` toward the viewer, `z` up.
//!
//! The canvas has no edge, so nothing is fitted to a frame. A node or a closed group is a
//! block exactly as large as what is written on it. An open group is a slab with its
//! children standing on it, packed into as square a shape as they allow. They are placed in
//! the order of what needs what, starting from the far-left corner: what is needed first
//! stands toward that corner, and what needs it fans out from there.

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
    // Children are packed in the order of their ranks into as square a footprint as they
    // allow, using both directions: each goes where it sits nearest the far-left corner
    // against what is already placed, so what is needed first stands toward that corner and
    // what needs it fans out from there. Several widths are tried and the squarest kept.
    let (left, top) = if root { (0.0, 0.0) } else { (PAD, PAD) };
    let mut order: Vec<usize> = data.children.clone();
    order.sort_by_key(|&child| tree.items[child].rank);
    let boxes: Vec<(f32, f32)> = order.iter().map(|&child| footprint[child]).collect();
    let mut best: Option<(f32, Packing)> = None;
    for step in 0..12 {
        let limit = widest.max(area.sqrt() * (0.7 + 0.1 * step as f32));
        let packing = pack(&boxes, limit);
        let (width, depth) = (packing.width, packing.depth);
        // How far from square, with a slight lean toward wide: the view is wider than tall.
        let shape = (width / (depth * 1.25)).max(depth * 1.25 / width)
            * (1.0 + width * depth / area.max(1.0) * 0.15);
        if best.as_ref().is_none_or(|(score, ..)| shape < *score) {
            best = Some((shape, packing));
        }
    }
    let (
        _,
        Packing {
            spots,
            width,
            depth,
        },
    ) = best.expect("at least one width was tried");
    for (&child, spot) in order.iter().zip(spots) {
        offsets[child] = (left + spot.0, top + spot.1);
    }
    let (width, depth) = (left + width, top + depth);
    footprint[item] = if root {
        (width, depth)
    } else {
        ((width + PAD).max(sizes.title[item]), depth + FOOTER)
    };
}

/// Where a packing put each box, and the extent it used.
struct Packing {
    spots: Vec<(f32, f32)>,
    width: f32,
    depth: f32,
}

/// Skyline packing of `boxes`, in order, into a strip `limit` wide: each box goes where its
/// far edge is lowest, then furthest left.
fn pack(boxes: &[(f32, f32)], limit: f32) -> Packing {
    // The skyline: runs of `(x, y, width)`, left to right, saying how far down each is taken.
    let mut skyline: Vec<(f32, f32, f32)> = vec![(0.0, 0.0, limit + GAP)];
    let mut spots = Vec::with_capacity(boxes.len());
    let (mut width, mut depth) = (0.0_f32, 0.0_f32);
    for &(w, d) in boxes {
        let (w, d) = (w + GAP, d + GAP);
        let mut best: Option<(f32, f32)> = None;
        for start in 0..skyline.len() {
            let x = skyline[start].0;
            if x + w > limit + GAP + 0.5 {
                break;
            }
            let y = skyline[start..]
                .iter()
                .take_while(|run| run.0 < x + w - 0.5)
                .map(|run| run.1)
                .fold(0.0_f32, f32::max);
            if best.is_none_or(|(_, lowest)| y < lowest - 0.5) {
                best = Some((x, y));
            }
        }
        let (x, y) = best.unwrap_or((0.0, depth + GAP));
        spots.push((x, y));
        width = width.max(x + w - GAP);
        depth = depth.max(y + d - GAP);
        // Raise the skyline under the box, keeping what sticks out on either side.
        let mut next = Vec::with_capacity(skyline.len() + 2);
        for &(sx, sy, sw) in &skyline {
            if sx + sw <= x + 0.5 || sx >= x + w - 0.5 {
                next.push((sx, sy, sw));
                continue;
            }
            if sx < x {
                next.push((sx, sy, x - sx));
            }
            if sx + sw > x + w {
                next.push((x + w, sy, sx + sw - x - w));
            }
        }
        next.push((x, y + d, w));
        next.sort_by(|a, b| a.0.total_cmp(&b.0));
        skyline = next;
    }
    Packing {
        spots,
        width,
        depth,
    }
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
