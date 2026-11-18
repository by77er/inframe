//! `inframe serve`: the CLI's side of the visualizer, compiled with the `serve` feature. The
//! server and the page live in `inframe-serve` and `inframe-view`; this hands them a project.

use std::net::IpAddr;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};

use anyhow::Result;
use inframe_graph_ir::GraphDocument;
use inframe_graph_ir::origins::Origins;
use inframe_serve::{Options, StackDescription};

use crate::project::{self, Project};

#[derive(Debug, clap::Args)]
pub struct ServeArgs {
    /// Show only these stacks; every declared stack by default.
    #[arg(long = "stack")]
    stacks: Vec<String>,
    /// The address to listen on. The default is reachable from this machine only.
    #[arg(long, default_value = "127.0.0.1")]
    host: IpAddr,
    /// The port to listen on; `0` picks a free one.
    #[arg(long, default_value_t = 7878)]
    port: u16,
    /// How often sources and state are checked for changes, in milliseconds.
    #[arg(long, default_value_t = 700, value_parser = clap::value_parser!(u64).range(50..))]
    poll_ms: u64,
    /// Serve `page.html` and `view.wasm` from this directory instead of the copies built into
    /// the binary, for working on the page itself.
    #[arg(long, hide = true)]
    assets: Option<PathBuf>,
}

impl inframe_serve::Project for Project {
    fn root(&self) -> PathBuf {
        Project::root(self).to_owned()
    }

    fn stacks(&self) -> Vec<String> {
        self.stack_names().map(str::to_owned).collect()
    }

    fn describe(&self, stack: &str) -> StackDescription {
        StackDescription {
            frontend: self
                .stack_frontend(stack)
                .map_or("unknown", |frontend| frontend.name()),
            backend: self.backend_kind(stack).unwrap_or_default().to_owned(),
            gated: self.gate(stack).ok().flatten().is_some(),
        }
    }

    fn build(&self, stack: &str) -> Result<(GraphDocument, Option<Origins>)> {
        self.render_with_origins(stack)
    }

    fn last_change(&self, stack: &str) -> Option<SystemTime> {
        self.stack_watch_directories(stack)
            .unwrap_or_default()
            .iter()
            .filter_map(|directory| project::newest_source_mtime(directory))
            .max()
    }

    fn local_state(&self, stack: &str) -> Result<Option<PathBuf>> {
        self.local_state_path(stack, &self.workspace_directory())
    }
}

pub fn run(arguments: &ServeArgs, project_path: &Path) -> Result<()> {
    let options = Options {
        stacks: arguments.stacks.clone(),
        host: arguments.host,
        port: arguments.port,
        poll: Duration::from_millis(arguments.poll_ms),
        assets: arguments.assets.clone(),
    };
    inframe_serve::serve(&options, project_path, Project::load)
}
