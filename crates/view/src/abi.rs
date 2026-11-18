//! The WebAssembly surface: a handful of exports over one `View`.
//!
//! Text crosses as UTF-8 in the module's memory. The page allocates with `iv_alloc`, writes
//! a command, and calls `iv_command`; the answer stays in a buffer the page reads through
//! `iv_result_ptr` and `iv_result_len` before its next call. Per-frame data (the instances
//! and the matrix) is read straight out of memory the same way. This is the only module
//! that needs `unsafe`: the exports must be unmangled and take raw pointers.
#![allow(unsafe_code)]

use std::sync::{Mutex, MutexGuard, PoisonError};

use crate::view::{INSTANCE_FLOATS, View};

struct State {
    view: View,
    result: String,
}

static STATE: Mutex<Option<State>> = Mutex::new(None);

fn with<T>(run: impl FnOnce(&mut State) -> T) -> T {
    let mut guard: MutexGuard<'_, Option<State>> =
        STATE.lock().unwrap_or_else(PoisonError::into_inner);
    run(guard.get_or_insert_with(|| State {
        view: View::new(),
        result: String::new(),
    }))
}

/// Reserve `len` bytes for the page to write a command into.
#[unsafe(no_mangle)]
pub extern "C" fn iv_alloc(len: usize) -> *mut u8 {
    let mut buffer = Vec::<u8>::with_capacity(len.max(1));
    let pointer = buffer.as_mut_ptr();
    std::mem::forget(buffer);
    pointer
}

/// Run the command the page wrote at `pointer`, and take the buffer back.
///
/// # Safety
/// `pointer` must come from `iv_alloc(len)` and hold `len` initialized bytes; it is freed here.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn iv_command(pointer: *mut u8, len: usize) {
    // SAFETY: the caller hands back exactly the allocation `iv_alloc(len)` made, filled.
    let bytes = unsafe { Vec::from_raw_parts(pointer, len, len.max(1)) };
    let command = String::from_utf8_lossy(&bytes);
    with(|state| state.result = state.view.command(&command));
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_result_ptr() -> *const u8 {
    with(|state| state.result.as_ptr())
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_result_len() -> usize {
    with(|state| state.result.len())
}

/// Advance by `dt` milliseconds; nonzero while anything is still moving.
#[unsafe(no_mangle)]
pub extern "C" fn iv_frame(dt: f32, width: f32, height: f32) -> u32 {
    with(|state| u32::from(state.view.frame(dt, width, height)))
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_instances_ptr() -> *const f32 {
    with(|state| state.view.instances().as_ptr())
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_instance_count() -> usize {
    with(|state| state.view.instances().len() / INSTANCE_FLOATS)
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_matrix_ptr() -> *const f32 {
    with(|state| state.view.matrix().as_ptr())
}

/// The box under a pixel, or -1.
#[unsafe(no_mangle)]
pub extern "C" fn iv_pick(x: f32, y: f32) -> i32 {
    with(|state| {
        state
            .view
            .pick(x, y)
            .map_or(-1, |index| i32::try_from(index).unwrap_or(-1))
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_pan(x0: f32, y0: f32, x1: f32, y1: f32) {
    with(|state| state.view.pan(x0, y0, x1, y1));
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_zoom(x: f32, y: f32, factor: f32) {
    with(|state| state.view.zoom(x, y, factor));
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_zoom_level() -> f32 {
    with(|state| state.view.zoom_level())
}

#[unsafe(no_mangle)]
pub extern "C" fn iv_revision() -> u32 {
    with(|state| state.view.revision())
}
