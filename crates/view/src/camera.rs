//! The tilted camera over the ground plane.
//!
//! The camera looks at a point on the ground from a fixed elevation and a small turn, with a
//! narrow field of view: close to an isometric drawing, with enough perspective to read depth.
//! Zoom is kept as pixels per world unit at the point looked at, so resizing the window does
//! not change the scale.

/// Vertical field of view.
const FOV: f32 = 0.42;

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
}

impl Default for Camera {
    fn default() -> Self {
        Self {
            x: 0.0,
            y: 0.0,
            zoom: 1.0,
            yaw: -0.2,
            pitch: 0.96,
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
        let focal = 1.0 / (FOV / 2.0).tan();
        let distance = height.max(1.0) / 2.0 * focal / self.zoom;
        Rig {
            eye: add([self.x, self.y, 0.0], scale(back, distance)),
            right,
            up: add(scale(toward, -sin_pitch), [0.0, 0.0, cos_pitch]),
            forward: scale(back, -1.0),
            focal,
            width: width.max(1.0),
            height: height.max(1.0),
            distance,
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
        let (near, far) = (self.distance * 0.05, self.distance * 30.0);
        let sx = self.focal * self.height / self.width;
        let sy = self.focal;
        let (a, b) = (far / (far - near), -far * near / (far - near));
        let (r, u, f, e) = (self.right, self.up, self.forward, self.eye);
        let (tr, tu, tf) = (-dot(e, r), -dot(e, u), -dot(e, f));
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

    /// The direction of the ray through the pixel `(x, y)`, not normalized.
    #[must_use]
    pub fn ray(&self, x: f32, y: f32) -> Vec3 {
        let ndc_x = (x / self.width * 2.0 - 1.0) * self.width / self.height / self.focal;
        let ndc_y = (1.0 - y / self.height * 2.0) / self.focal;
        add(
            self.forward,
            add(scale(self.right, ndc_x), scale(self.up, ndc_y)),
        )
    }

    /// Where the ray through a pixel meets the ground.
    #[must_use]
    pub fn ground(&self, x: f32, y: f32) -> Option<(f32, f32)> {
        let ray = self.ray(x, y);
        if ray[2] >= -1e-5 {
            return None;
        }
        let t = -self.eye[2] / ray[2];
        Some((self.eye[0] + ray[0] * t, self.eye[1] + ray[1] * t))
    }

    /// The pixel a world point lands on.
    #[must_use]
    pub fn project(&self, point: Vec3) -> (f32, f32) {
        let relative = add(point, scale(self.eye, -1.0));
        let depth = dot(relative, self.forward).max(1e-3);
        let x = dot(relative, self.right) * self.focal / depth * self.height / self.width;
        let y = dot(relative, self.up) * self.focal / depth;
        (
            f32::midpoint(x, 1.0) * self.width,
            f32::midpoint(1.0, -y) * self.height,
        )
    }

    /// How far along the ray through a pixel the box from `min` to `max` is hit, if it is.
    #[must_use]
    pub fn hit(&self, ray: Vec3, min: Vec3, max: Vec3) -> Option<f32> {
        let (mut near, mut far) = (0.0_f32, f32::MAX);
        for axis in 0..3 {
            if ray[axis].abs() < 1e-7 {
                if self.eye[axis] < min[axis] || self.eye[axis] > max[axis] {
                    return None;
                }
                continue;
            }
            let a = (min[axis] - self.eye[axis]) / ray[axis];
            let b = (max[axis] - self.eye[axis]) / ray[axis];
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
        let camera = Camera::default();
        let rig = camera.rig(800.0, 600.0);
        let (x, y) = rig.project([10.0, 10.0, 20.0]);
        let ray = rig.ray(x, y);
        assert!(rig.hit(ray, [0.0, 0.0, 0.0], [20.0, 20.0, 20.0]).is_some());
        assert!(
            rig.hit(ray, [200.0, 200.0, 0.0], [220.0, 220.0, 20.0])
                .is_none()
        );
    }
}
