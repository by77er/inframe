//! Where everything stands on the ground plane. World units are CSS pixels at zoom 1; `x`
//! runs right, `y` toward the viewer, `z` up.
//!
//! Two layouts share the scene. *Explore* shows a group as a closed block until it is opened;
//! an open group is a slab with its children standing on it, packed in rows. *Map* opens
//! everything at once and fills a rectangle, each node's area following how much configuration
//! it carries.

use std::collections::HashSet;

use serde::{Deserialize, Serialize};

use crate::tree::{Role, Tree};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Mode {
    #[default]
    Explore,
    Map,
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

const LEAF: (f32, f32) = (172.0, 62.0);
const GROUP: (f32, f32) = (188.0, 74.0);
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

#[must_use]
pub fn layout(tree: &Tree, expanded: &HashSet<String>, mode: Mode, aspect: f32) -> Vec<Placed> {
    let mut placed = Vec::new();
    if tree.items.is_empty() {
        return placed;
    }
    match mode {
        Mode::Explore => {
            let mut sizes = vec![(0.0, 0.0); tree.items.len()];
            let mut offsets = vec![(0.0, 0.0); tree.items.len()];
            measure(tree, expanded, 0, &mut sizes, &mut offsets);
            for &child in &tree.items[0].children {
                place(
                    tree,
                    expanded,
                    child,
                    offsets[child],
                    0.0,
                    0,
                    &sizes,
                    &offsets,
                    &mut placed,
                );
            }
        }
        Mode::Map => map(tree, aspect, &mut placed),
    }
    placed
}

fn open(tree: &Tree, expanded: &HashSet<String>, item: usize) -> bool {
    let item = &tree.items[item];
    item.role == Role::Root || (!item.children.is_empty() && expanded.contains(&item.id))
}

/// Size `item` and position its children relative to it, bottom-up.
fn measure(
    tree: &Tree,
    expanded: &HashSet<String>,
    item: usize,
    sizes: &mut [(f32, f32)],
    offsets: &mut [(f32, f32)],
) {
    let data = &tree.items[item];
    if !data.is_container() {
        sizes[item] = LEAF;
        return;
    }
    if !open(tree, expanded, item) {
        sizes[item] = GROUP;
        return;
    }
    let root = data.role == Role::Root;
    let mut area = 0.0;
    let mut widest: f32 = 0.0;
    for &child in &data.children {
        measure(tree, expanded, child, sizes, offsets);
        area += (sizes[child].0 + GAP) * (sizes[child].1 + GAP);
        widest = widest.max(sizes[child].0);
    }
    // Rows as wide as a rectangle of the children's area in a comfortable proportion.
    let target = widest.max((area * if root { 1.9 } else { 1.7 }).sqrt());
    let (left, top) = if root { (0.0, 0.0) } else { (PAD, PAD) };
    // Skyline packing: each child goes where it sits highest (then leftmost) against what
    // is already placed, so small blocks fill in beside and under a large open group
    // instead of leaving the rest of its row empty.
    let mut skyline: Vec<(f32, f32, f32)> = vec![(left, top, target.max(widest) + GAP)];
    let (mut width, mut depth) = (0.0_f32, 0.0_f32);
    for &child in &data.children {
        let (w, d) = (sizes[child].0 + GAP, sizes[child].1 + GAP);
        let end = left + target.max(widest) + GAP;
        let mut best: Option<(f32, f32)> = None;
        for start in 0..skyline.len() {
            let x = skyline[start].0;
            if x + w > end + 0.5 {
                break;
            }
            let y = skyline[start..]
                .iter()
                .take_while(|segment| segment.0 < x + w - 0.5)
                .map(|segment| segment.1)
                .fold(0.0_f32, f32::max);
            if best.is_none_or(|(_, lowest)| y < lowest - 0.5) {
                best = Some((x, y));
            }
        }
        let (x, y) = best.unwrap_or((left, depth + GAP));
        offsets[child] = (x, y);
        width = width.max(x + w - GAP);
        depth = depth.max(y + d - GAP);
        // Raise the skyline under the child, keeping what sticks out on either side.
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
    let (y, row) = (depth, 0.0_f32);
    sizes[item] = if root {
        (width, y + row)
    } else {
        (width.max(left + GROUP.0) + PAD, y + row + FOOTER)
    };
}

#[allow(clippy::too_many_arguments)]
fn place(
    tree: &Tree,
    expanded: &HashSet<String>,
    item: usize,
    at: (f32, f32),
    z: f32,
    depth: u32,
    sizes: &[(f32, f32)],
    offsets: &[(f32, f32)],
    placed: &mut Vec<Placed>,
) {
    let data = &tree.items[item];
    let slab = data.is_container() && open(tree, expanded, item);
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
        w: sizes[item].0,
        d: sizes[item].1,
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
                expanded,
                child,
                offset,
                z + h,
                depth + 1,
                sizes,
                offsets,
                placed,
            );
        }
    }
}

struct Rect {
    x: f32,
    y: f32,
    w: f32,
    d: f32,
}

/// Squarified treemap rows: split `rect` among `items` in proportion to their weights,
/// keeping each cell as close to square as the order allows.
fn squarify(items: &[(usize, f32)], mut rect: Rect) -> Vec<(usize, Rect)> {
    let total: f32 = items.iter().map(|item| item.1).sum();
    let mut cells = Vec::new();
    if total <= 0.0 || rect.w <= 0.0 || rect.d <= 0.0 {
        return cells;
    }
    let scale = rect.w * rect.d / total;
    let worst = |row: &[(usize, f32)], extra: Option<f32>, side: f32| {
        let areas = row.iter().map(|entry| entry.1).chain(extra);
        let (mut sum, mut max, mut min) = (0.0_f32, 0.0_f32, f32::MAX);
        for area in areas {
            sum += area;
            max = max.max(area);
            min = min.min(area);
        }
        (side * side * max / (sum * sum)).max(sum * sum / (side * side * min))
    };
    let mut row: Vec<(usize, f32)> = Vec::new();
    let mut index = 0;
    let flush = |row: &mut Vec<(usize, f32)>, rect: &mut Rect, cells: &mut Vec<(usize, Rect)>| {
        let side = rect.w.min(rect.d);
        let sum: f32 = row.iter().map(|entry| entry.1).sum();
        let thickness = sum / side;
        let mut offset = 0.0;
        let wide = rect.w >= rect.d;
        for &(item, area) in row.iter() {
            let length = area / thickness;
            cells.push((
                item,
                if wide {
                    Rect {
                        x: rect.x,
                        y: rect.y + offset,
                        w: thickness,
                        d: length,
                    }
                } else {
                    Rect {
                        x: rect.x + offset,
                        y: rect.y,
                        w: length,
                        d: thickness,
                    }
                },
            ));
            offset += length;
        }
        if wide {
            rect.x += thickness;
            rect.w -= thickness;
        } else {
            rect.y += thickness;
            rect.d -= thickness;
        }
        row.clear();
    };
    while index < items.len() {
        let area = items[index].1 * scale;
        let side = rect.w.min(rect.d);
        if row.is_empty() || worst(&row, Some(area), side) <= worst(&row, None, side) {
            row.push((items[index].0, area));
            index += 1;
        } else {
            flush(&mut row, &mut rect, &mut cells);
        }
    }
    if !row.is_empty() {
        flush(&mut row, &mut rect, &mut cells);
    }
    cells
}

/// World area given to one unit of weight in the map.
const MAP_AREA: f32 = 2300.0;

fn map(tree: &Tree, aspect: f32, placed: &mut Vec<Placed>) {
    let root = &tree.items[0];
    // A stack with nothing to show still gets a cell large enough to read its status.
    let total: f32 = root
        .children
        .iter()
        .map(|&stack| tree.items[stack].weight)
        .sum();
    let floor = (total * 0.12).max(10.0);
    let stacks: Vec<(usize, f32)> = {
        let mut stacks: Vec<_> = root
            .children
            .iter()
            .map(|&stack| (stack, tree.items[stack].weight.max(floor)))
            .collect();
        stacks.sort_by(|a, b| b.1.total_cmp(&a.1));
        stacks
    };
    // Enough ground that a typical node has room for its name, whatever the weights are;
    // the canvas is free, so a large project simply makes a large map.
    let leaves = root.leaves.len().max(1) as f32;
    let area = (stacks.iter().map(|stack| stack.1).sum::<f32>() * MAP_AREA).max(leaves * 21_000.0);
    let aspect = aspect.clamp(0.6, 2.6);
    let w = (area * aspect).sqrt();
    for (stack, rect) in squarify(
        &stacks,
        Rect {
            x: 0.0,
            y: 0.0,
            w,
            d: area / w,
        },
    ) {
        map_item(tree, stack, &rect, 0.0, 0, placed);
    }
}

fn map_item(tree: &Tree, item: usize, rect: &Rect, z: f32, depth: u32, placed: &mut Vec<Placed>) {
    let data = &tree.items[item];
    let gap = if depth == 0 { 8.0 } else { 4.0 };
    let (x, y) = (rect.x + gap, rect.y + gap);
    let (w, d) = ((rect.w - 2.0 * gap).max(1.0), (rect.d - 2.0 * gap).max(1.0));
    if !data.is_container() {
        placed.push(Placed {
            item,
            x,
            y,
            w,
            d,
            z,
            h: leaf_height(data.weight),
            slab: false,
            depth,
        });
        return;
    }
    let (foot, pad) = if depth == 0 { (30.0, 8.0) } else { (24.0, 5.0) };
    let inner = Rect {
        x: x + pad,
        y: y + pad,
        w: w - 2.0 * pad,
        d: d - foot - pad,
    };
    let closed = data.children.is_empty() || inner.w < 44.0 || inner.d < 26.0;
    if closed {
        // A group too small to open that holds one node shows the node itself.
        if let [only] = data.leaves.as_slice() {
            return map_item(tree, tree.leaf_of[*only], rect, z, depth, placed);
        }
        let h = if data.children.is_empty() {
            SLAB
        } else {
            group_height(data.leaves.len())
        };
        placed.push(Placed {
            item,
            x,
            y,
            w,
            d,
            z,
            h,
            slab: data.children.is_empty(),
            depth,
        });
        return;
    }
    placed.push(Placed {
        item,
        x,
        y,
        w,
        d,
        z,
        h: SLAB,
        slab: true,
        depth,
    });
    let mut children: Vec<(usize, f32)> = data
        .children
        .iter()
        .map(|&child| (child, tree.items[child].weight.max(3.0)))
        .collect();
    children.sort_by(|a, b| b.1.total_cmp(&a.1));
    for (child, cell) in squarify(&children, inner) {
        map_item(tree, child, &cell, z + SLAB, depth + 1, placed);
    }
}
