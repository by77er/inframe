//! What `inframe serve` shows and how. [`model`] is the document the server builds and the
//! page reads. The rest is the page's logic (the hierarchy, what is open, where things
//! stand, the camera, what a click lands on), written once here and compiled to
//! WebAssembly for the page, so that it is tested as ordinary Rust and behaves the same in
//! every browser.

pub mod camera;
pub mod layout;
pub mod model;
pub mod tree;
pub mod view;

#[cfg(target_arch = "wasm32")]
mod abi;

use serde::Deserialize;
use serde_json::{Value, json};

use layout::Mode;
use tree::Grouping;
pub use view::View;

/// What the page asks of the view. Each is one JSON object with an `op`.
#[derive(Debug, Deserialize)]
#[serde(tag = "op", rename_all = "snake_case")]
enum Command {
    Model {
        model: Box<model::Model>,
    },
    Grouping {
        value: Grouping,
    },
    Mode {
        value: Mode,
    },
    Click {
        id: String,
    },
    Toggle {
        id: String,
    },
    Select {
        id: Option<String>,
        #[serde(default)]
        reveal: bool,
    },
    Hover {
        id: Option<String>,
    },
    Query {
        text: String,
    },
    AllLinks {
        value: bool,
    },
    ExpandAll {
        id: String,
    },
    CollapseAll,
    FirstMatch,
    Fit,
    Focus {
        id: String,
    },
    Tilt {
        yaw: f32,
        pitch: f32,
    },
    Tip {
        id: String,
    },
    Refresh,
}

impl View {
    /// Run one command and answer with what the page now has to show. Hovering and asking
    /// for a tip answer with just that; everything else answers with the whole of it.
    pub fn command(&mut self, command: &str) -> String {
        let command: Command = match serde_json::from_str(command) {
            Ok(command) => command,
            Err(error) => return json!({ "error": error.to_string() }).to_string(),
        };
        match command {
            Command::Model { model } => self.set_model(*model),
            Command::Grouping { value } => self.set_grouping(value),
            Command::Mode { value } => self.set_mode(value),
            Command::Click { id } => self.click(&id),
            Command::Toggle { id } => self.toggle(&id),
            Command::Select { id, reveal } => self.select(id.as_deref(), reveal),
            Command::Query { text } => self.set_query(&text),
            Command::AllLinks { value } => self.set_all_links(value),
            Command::ExpandAll { id } => self.expand_all(&id),
            Command::CollapseAll => self.collapse_all(),
            Command::FirstMatch => self.first_match(),
            Command::Fit => self.fit(),
            Command::Focus { id } => self.focus(&id),
            Command::Tilt { yaw, pitch } => self.set_tilt(yaw, pitch),
            Command::Refresh => {}
            Command::Hover { id } => {
                self.hover(id.as_deref());
                return json!({ "links": self.scene()["links"] }).to_string();
            }
            Command::Tip { id } => return json!({ "tip": self.tip(&id) }).to_string(),
        }
        let scene: Value = self.scene();
        json!({
            "scene": scene,
            "outline": self.outline(),
            "inspect": self.inspect(),
            "summary": self.summary(),
        })
        .to_string()
    }
}
