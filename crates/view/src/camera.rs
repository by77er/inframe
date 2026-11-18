//! The tilted camera over the ground plane.
//!
//! The camera looks at a point on the ground from an elevation and a turn. It is either a
//! perspective camera with a narrow field of view, which reads as depth, or an orthographic
//! one, which is what an isometric drawing is: parallel lines stay parallel and a block is
//! the same size wherever it stands. Zoom is kept as pixels per world unit at the point
//! looked at, so resizing the window does not change the scale, and neither does moving
//! between the two: the field of view narrows while the camera backs away, and once the
//! rays are all but parallel the projection becomes exactly orthographic.

/// Vertical field of view of the perspective camera.
const FOV: f32 = 0.42;
/// Below this field of view the projection is orthographic.
const PARALLEL: f32 = 0.02;
/// How far in front of and behind the point looked at the scene may reach.
const REACH: f32 = 60_000.0;

/// The turn and elevation of a true isometric view: the three axes foreshorten equally.
pub const ISOMETRIC: (f32, f32) = (-std::f32::consts::FRAC_PI_4, 0.615_479_7);

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Camera {
    /// The ground point at the center of the view.
    pub x: f32,
    pub y: f32,
    /// Pixels per world unit at that point.
    pub zoom: f32,
    /// The turn about the vertical axis, in radians.
    pub yaw: f32,
    /// The elevation above the horizon, in radians; a quarter turn looks straight down.
    pub pitch: f32,
    /// 1 for the perspective camera, 0 for the orthographic one, and between while changing.
    pub perspective: f32,
}

impl Default for Camera {
    fn default() -> Self {
        Self {
            x: 0.0,
            y: 0.0,
            zoom: 1.0,
            yaw: -0.2,
            pitch: 0.96,
            perspective: 1.0,
        }
    }
}

pub const ZOOM_RANGE: (f32, f32) = (0.06, 5.0);

type Vec3 = [f32; 3];

fn add(a: Vec3, b: Vec3) -> Vec3 {
    [a[0] + b[0], a[1] + b[1], a[2] + b[2]]
}
fn scale(a: Vec3, s: f32) -> Vec3 {
    [a[0] * s, a[1] * s, a[2] * s]
}
fn dot(a: Vec3, b: Vec3) -> f32 {
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

/// The camera resolved for a viewport: its position and axes.
#[derive(Debug, Clone, Copy)]
pub struct Rig {
    pub eye: Vec3,
    /// Screen right, screen up, and into the screen, in world coordinates.
    pub right: Vec3,
    pub up: Vec3,
    pub forward: Vec3,
    focal: f32,
    width: f32,
    height: f32,
    distance: f32,
    /// Pixels per world unit, when the projection is orthographic.
    parallel: Option<f32>,
}

impl Camera {
    #[must_use]
    pub fn rig(&self, width: f32, height: f32) -> Rig {
        let (sin_yaw, cos_yaw) = self.yaw.sin_cos();
        let (sin_pitch, cos_pitch) = self.pitch.sin_cos();
        // `toward` is the ground direction that points at the viewer.
        let toward = [sin_yaw, cos_yaw, 0.0];
        let right = [cos_yaw, -sin_yaw, 0.0];
        let back = add(scale(toward, cos_pitch), [0.0, 0.0, sin_pitch]);
        let fov = FOV * self.perspective;
        let parallel = (fov < PARALLEL).then_some(self.zoom);
        let focal = 1.0 / (fov.max(PARALLEL) / 2.0).tan();
        let distance = if parallel.is_some() {
            REACH
        } else {
            height.max(1.0) / 2.0 * focal / self.zoom
        };
        Rig {
            eye: add([self.x, self.y, 0.0], scale(back, distance)),
            right,
            up: add(scale(toward, -sin_pitch), [0.0, 0.0, cos_pitch]),
            forward: scale(back, -1.0),
            focal,
            width: width.max(1.0),
            height: height.max(1.0),
            distance,
            parallel,
        }
    }

    /// Frame the box from `min` to `max` with a margin, keeping the current angles.
    #[must_use]
    pub fn framing(&self, min: Vec3, max: Vec3, width: f32, height: f32, margin: f32) -> Self {
        let rig = self.rig(width, height);
        let (mut u0, mut u1, mut v0, mut v1) = (f32::MAX, f32::MIN, f32::MAX, f32::MIN);
        for corner in 0..8 {
            let point = [
                if corner & 1 == 0 { min[0] } else { max[0] },
                if corner & 2 == 0 { min[1] } else { max[1] },
                if corner & 4 == 0 { min[2] } else { max[2] },
            ];
            let (u, v) = (dot(point, rig.right), dot(point, rig.up));
            u0 = u0.min(u);
            u1 = u1.max(u);
            v0 = v0.min(v);
            v1 = v1.max(v);
        }
        // The ground point whose screen position is the middle of those extents.
        let (u, v) = (f32::midpoint(u0, u1), f32::midpoint(v0, v1));
        let toward = [self.yaw.sin(), self.yaw.cos(), 0.0];
        let along = -v / self.pitch.sin().max(0.05);
        let target = add(scale(rig.right, u), scale(toward, along));
        let zoom = (width * margin / (u1 - u0).max(1.0)).min(height * margin / (v1 - v0).max(1.0));
        Self {
            x: target[0],
            y: target[1],
            zoom: zoom.clamp(ZOOM_RANGE.0, 1.6),
            ..*self
        }
    }
}

impl Rig {
    /// The view-projection matrix, column-major, for a clip space with depth 0 to 1.
    #[must_use]
    pub fn matrix(&self) -> [f32; 16] {
        let (r, u, f, e) = (self.right, self.up, self.forward, self.eye);
        let (tr, tu, tf) = (-dot(e, r), -dot(e, u), -dot(e, f));
        if let Some(zoom) = self.parallel {
            // Orthographic: no division by depth, so the last row is constant.
            let (sx, sy, sz) = (
                2.0 * zoom / self.width,
                2.0 * zoom / self.height,
                1.0 / (2.0 * REACH),
            );
            return [
                sx * r[0],
                sy * u[0],
                sz * f[0],
                0.0,
                sx * r[1],
                sy * u[1],
                sz * f[1],
                0.0,
                sx * r[2],
                sy * u[2],
                sz * f[2],
                0.0,
                sx * tr,
                sy * tu,
                sz * tf,
                1.0,
            ];
        }
        let near = (self.distance * 0.05).max(self.distance - REACH);
        let far = self.distance + REACH.max(self.distance * 29.0);
        let sx = self.focal * self.height / self.width;
        let sy = self.focal;
        let (a, b) = (far / (far - near), -far * near / (far - near));
        [
            sx * r[0],
            sy * u[0],
            a * f[0],
            f[0],
            sx * r[1],
            sy * u[1],
            a * f[1],
            f[1],
            sx * r[2],
            sy * u[2],
            a * f[2],
            f[2],
            sx * tr,
            sy * tu,
            a * tf + b,
            tf,
        ]
    }

    /// The ray through the pixel `(x, y)`: where it starts and its direction, not normalized.
    /// Perspective rays all start at the eye; orthographic rays are parallel and start apart.
    #[must_use]
    pub fn ray(&self, x: f32, y: f32) -> (Vec3, Vec3) {
        if let Some(zoom) = self.parallel {
            let across = scale(self.right, (x - self.width / 2.0) / zoom);
            let along = scale(self.up, (self.height / 2.0 - y) / zoom);
            return (add(self.eye, add(across, along)), self.forward);
        }
        let ndc_x = (x / self.width * 2.0 - 1.0) * self.width / self.height / self.focal;
        let ndc_y = (1.0 - y / self.height * 2.0) / self.focal;
        let direction = add(
            self.forward,
            add(scale(self.right, ndc_x), scale(self.up, ndc_y)),
        );
        (self.eye, direction)
    }

    /// Where the ray through a pixel meets the ground.
    #[must_use]
    pub fn ground(&self, x: f32, y: f32) -> Option<(f32, f32)> {
        let (origin, ray) = self.ray(x, y);
        if ray[2] >= -1e-5 {
            return None;
        }
        let t = -origin[2] / ray[2];
        Some((origin[0] + ray[0] * t, origin[1] + ray[1] * t))
    }

    /// The pixel a world point lands on.
    #[must_use]
    pub fn project(&self, point: Vec3) -> (f32, f32) {
        let relative = add(point, scale(self.eye, -1.0));
        if let Some(zoom) = self.parallel {
            return (
                self.width / 2.0 + dot(relative, self.right) * zoom,
                self.height / 2.0 - dot(relative, self.up) * zoom,
            );
        }
        let depth = dot(relative, self.forward).max(1e-3);
        let x = dot(relative, self.right) * self.focal / depth * self.height / self.width;
        let y = dot(relative, self.up) * self.focal / depth;
        (
            f32::midpoint(x, 1.0) * self.width,
            f32::midpoint(1.0, -y) * self.height,
        )
    }

    /// How far along a ray the box from `min` to `max` is hit, if it is.
    #[must_use]
    pub fn hit(origin: Vec3, ray: Vec3, min: Vec3, max: Vec3) -> Option<f32> {
        let (mut near, mut far) = (0.0_f32, f32::MAX);
        for axis in 0..3 {
            if ray[axis].abs() < 1e-7 {
                if origin[axis] < min[axis] || origin[axis] > max[axis] {
                    return None;
                }
                continue;
            }
            let a = (min[axis] - origin[axis]) / ray[axis];
            let b = (max[axis] - origin[axis]) / ray[axis];
            near = near.max(a.min(b));
            far = far.min(a.max(b));
        }
        (near <= far).then_some(near)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn projecting_then_casting_returns_to_the_ground_point() {
        let camera = Camera {
            x: 120.0,
            y: -40.0,
            zoom: 0.8,
            ..Camera::default()
        };
        let rig = camera.rig(1200.0, 800.0);
        let (x, y) = rig.project([camera.x, camera.y, 0.0]);
        assert!(
            (x - 600.0).abs() < 0.01 && (y - 400.0).abs() < 0.01,
            "{x} {y}"
        );
        for point in [(300.0, 200.0), (-50.0, -400.0)] {
            let (px, py) = rig.project([point.0, point.1, 0.0]);
            let (gx, gy) = rig.ground(px, py).unwrap();
            assert!((gx - point.0).abs() < 0.05 && (gy - point.1).abs() < 0.05);
        }
        // One world unit at the target is `zoom` pixels across the screen.
        let (ax, _) = rig.project([camera.x, camera.y, 0.0]);
        let (bx, _) = rig.project(add([camera.x, camera.y, 0.0], rig.right));
        assert!((bx - ax - 0.8).abs() < 0.01);
    }

    #[test]
    fn framing_brings_the_whole_box_into_view() {
        let camera =
            Camera::default().framing([0.0, 0.0, 0.0], [2000.0, 900.0, 40.0], 1000.0, 700.0, 0.9);
        let rig = camera.rig(1000.0, 700.0);
        for corner in [
            [0.0, 0.0, 0.0],
            [2000.0, 900.0, 0.0],
            [2000.0, 0.0, 40.0],
            [0.0, 900.0, 40.0],
        ] {
            let (x, y) = rig.project(corner);
            assert!(
                (0.0..=1000.0).contains(&x) && (0.0..=700.0).contains(&y),
                "{corner:?} at {x} {y}"
            );
        }
    }

    #[test]
    fn rays_hit_the_boxes_they_point_at() {
        for perspective in [1.0, 0.0] {
            let camera = Camera {
                perspective,
                ..Camera::default()
            };
            let rig = camera.rig(800.0, 600.0);
            let (x, y) = rig.project([10.0, 10.0, 20.0]);
            let (origin, ray) = rig.ray(x, y);
            assert!(Rig::hit(origin, ray, [0.0, 0.0, 0.0], [20.0, 20.0, 20.0]).is_some());
            assert!(Rig::hit(origin, ray, [200.0, 200.0, 0.0], [220.0, 220.0, 20.0]).is_none());
        }
    }

    /// Through the matrix, as the page draws: clip coordinates divided by w, as pixels.
    fn drawn(rig: &Rig, point: [f32; 3], size: (f32, f32)) -> (f32, f32) {
        let m = rig.matrix();
        let row =
            |r: usize| m[r] * point[0] + m[4 + r] * point[1] + m[8 + r] * point[2] + m[12 + r];
        let w = row(3);
        (
            f32::midpoint(row(0) / w, 1.0) * size.0,
            (1.0 - row(1) / w) / 2.0 * size.1,
        )
    }

    #[test]
    fn the_orthographic_camera_keeps_parallels_parallel_and_sizes_equal() {
        let camera = Camera {
            yaw: ISOMETRIC.0,
            pitch: ISOMETRIC.1,
            perspective: 0.0,
            zoom: 0.5,
            ..Camera::default()
        };
        let size = (1200.0, 800.0);
        let rig = camera.rig(size.0, size.1);
        // The same edge, near and far: identical on screen, which perspective would not give.
        let edge = |at: [f32; 3], along: [f32; 3]| {
            let (a, b) = (drawn(&rig, at, size), drawn(&rig, add(at, along), size));
            (b.0 - a.0, b.1 - a.1)
        };
        for along in [[100.0, 0.0, 0.0], [0.0, 100.0, 0.0], [0.0, 0.0, 100.0]] {
            let (near, far) = (
                edge([0.0, 900.0, 0.0], along),
                edge([400.0, -900.0, 50.0], along),
            );
            assert!(
                (near.0 - far.0).abs() < 1e-2 && (near.1 - far.1).abs() < 1e-2,
                "{near:?} {far:?}"
            );
        }
        // Isometric: the three axes foreshorten equally.
        let length = |along| {
            let e = edge([0.0, 0.0, 0.0], along);
            e.0.hypot(e.1)
        };
        let (x, y, z) = (
            length([100.0, 0.0, 0.0]),
            length([0.0, 100.0, 0.0]),
            length([0.0, 0.0, 100.0]),
        );
        assert!((x - y).abs() < 0.05 && (x - z).abs() < 0.05, "{x} {y} {z}");
        // The matrix, the projection and the rays agree, and the ground under a pixel is found.
        let point = [130.0, -70.0, 0.0];
        let (px, py) = rig.project(point);
        let through = drawn(&rig, point, size);
        assert!((px - through.0).abs() < 0.05 && (py - through.1).abs() < 0.05);
        let ground = rig.ground(px, py).unwrap();
        assert!((ground.0 - point[0]).abs() < 0.05 && (ground.1 - point[1]).abs() < 0.05);
        // A perspective camera does draw the far edge shorter.
        let rig = Camera {
            perspective: 1.0,
            ..camera
        }
        .rig(size.0, size.1);
        let edge = |at: [f32; 3]| {
            let (a, b) = (
                drawn(&rig, at, size),
                drawn(&rig, add(at, [100.0, 0.0, 0.0]), size),
            );
            (b.0 - a.0).hypot(b.1 - a.1)
        };
        assert!((edge([900.0, 900.0, 0.0]) - edge([-900.0, -900.0, 0.0])).abs() > 1.0);
    }

    /// Moving between the two cameras keeps the scale where the camera looks.
    #[test]
    fn narrowing_the_field_of_view_keeps_the_scale_at_the_target() {
        let size = (1000.0, 700.0);
        for perspective in [1.0, 0.5, 0.1, 0.04, 0.0] {
            let rig = Camera {
                zoom: 0.8,
                perspective,
                ..Camera::default()
            }
            .rig(size.0, size.1);
            let across = drawn(&rig, rig.right, size).0 - drawn(&rig, [0.0, 0.0, 0.0], size).0;
            assert!((across - 0.8).abs() < 0.01, "{perspective}: {across}");
        }
    }
}
