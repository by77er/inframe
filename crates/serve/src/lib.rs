//! `inframe serve`: a local web server showing a project's stacks as a live hierarchy.
//!
//! This crate is the visualizer's server side and nothing else of Inframe depends on it: the
//! CLI turns it on with its `serve` feature and hands it a [`Project`], the few things the
//! server needs to know about one. The page's own logic is the `inframe-view` crate, built
//! for WebAssembly and served from here.
//!
//! One thread watches the project: it rebuilds a stack when its sources change, re-reads its
//! local state when that changes, and publishes a new model each time. The other threads
//! answer HTTP: the page, the current model, and an event stream that announces each new
//! model so the page can follow along. The protocol is small enough to speak with the
//! standard library.

mod model;

use std::collections::BTreeMap;
use std::fs;
use std::io::{self, BufRead, BufReader, Read, Write};
use std::net::{IpAddr, SocketAddr, TcpListener, TcpStream};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Condvar, Mutex, PoisonError};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};

use inframe_graph_ir::GraphDocument;
use inframe_graph_ir::origins::Origins;
use model::{AppliedState, BuildStatus, Built, ProjectInfo, StackSnapshot, StateSnapshot};

const PAGE: &str = include_str!("page.html");
/// The page's logic: `inframe-view` built for WebAssembly by `make view-wasm` and kept in
/// the repository, so that building this crate needs no second toolchain.
const VIEW_WASM: &[u8] = include_bytes!("view.wasm");

/// How often the event stream says it is still there, so a closed tab is noticed.
const KEEP_ALIVE: Duration = Duration::from_secs(15);

/// How to serve.
#[derive(Debug, Clone)]
pub struct Options {
    /// Show only these stacks; every declared stack when empty.
    pub stacks: Vec<String>,
    pub host: IpAddr,
    /// The port to listen on; `0` picks a free one.
    pub port: u16,
    /// How often sources and state are checked for changes.
    pub poll: Duration,
    /// Serve `page.html` and `view.wasm` from this directory instead of the copies built in,
    /// for working on the page itself.
    pub assets: Option<PathBuf>,
}

/// What the server shows about a stack besides its graph.
#[derive(Debug, Clone)]
pub struct StackDescription {
    /// The frontend language, as it is written for people (`Lean`).
    pub frontend: &'static str,
    /// The backend type that keeps the stack's state (`local`, `s3`).
    pub backend: String,
    /// Whether a deployment gate is configured.
    pub gated: bool,
}

/// What the server needs of a project: its stacks, how to build one, and what to watch.
pub trait Project: Send + 'static {
    /// The directory the project lives in.
    fn root(&self) -> PathBuf;
    /// Every declared stack.
    fn stacks(&self) -> Vec<String>;
    fn describe(&self, stack: &str) -> StackDescription;
    /// Build the stack: its graph, and where its source declared each node if the frontend says.
    fn build(&self, stack: &str) -> Result<(GraphDocument, Option<Origins>)>;
    /// When anything the stack is built from last changed.
    fn last_change(&self, stack: &str) -> Option<SystemTime>;
    /// The stack's state file, when its backend keeps one on this machine.
    fn local_state(&self, stack: &str) -> Result<Option<PathBuf>>;
}

/// The model as last published, shared between the watcher and the request threads.
struct Published {
    current: Mutex<(u64, Arc<str>)>,
    changed: Condvar,
}

impl Published {
    fn get(&self) -> (u64, Arc<str>) {
        self.current
            .lock()
            .unwrap_or_else(PoisonError::into_inner)
            .clone()
    }

    fn publish(&self, project: &ProjectInfo, stacks: &[StackSnapshot]) {
        let mut current = self.current.lock().unwrap_or_else(PoisonError::into_inner);
        let version = current.0 + 1;
        let document = serde_json::to_string(&model::build(version, project, stacks))
            .expect("the model serializes");
        *current = (version, document.into());
        drop(current);
        self.changed.notify_all();
    }

    /// Block until the version moves past `seen` or `timeout` passes; returns the version.
    fn wait_past(&self, seen: u64, timeout: Duration) -> u64 {
        let current = self.current.lock().unwrap_or_else(PoisonError::into_inner);
        let (current, _) = self
            .changed
            .wait_timeout_while(current, timeout, |current| current.0 == seen)
            .unwrap_or_else(PoisonError::into_inner);
        current.0
    }
}

/// Serve the project configured at `config` until the process is stopped. `load` reads the
/// configuration; it is called again whenever the file changes.
pub fn serve<P: Project>(
    arguments: &Options,
    config: &Path,
    load: impl Fn(&Path) -> Result<P> + Send + 'static,
) -> Result<()> {
    // Fail on a project that cannot be read at all before taking the port.
    let project = load(config)?;
    let declared = project.stacks();
    for stack in &arguments.stacks {
        if !declared.contains(stack) {
            anyhow::bail!("stack `{stack}` is not declared in the project config");
        }
    }
    let listener = TcpListener::bind(SocketAddr::new(arguments.host, arguments.port))
        .with_context(|| {
            format!(
                "failed to listen on {}:{}; pass --port to choose another",
                arguments.host, arguments.port
            )
        })?;
    let address = listener.local_addr()?;
    let published = Arc::new(Published {
        current: Mutex::new((0, Arc::from("{}"))),
        changed: Condvar::new(),
    });
    let mut watcher = Watcher::new(
        config.to_path_buf(),
        Box::new(load),
        arguments.stacks.clone(),
        arguments.poll,
        Arc::clone(&published),
    );
    watcher.adopt(project);
    watcher.publish();

    println!("inframe serve: http://{address} (Ctrl-C to stop)");
    io::stdout().flush()?;
    if !arguments.host.is_loopback() {
        eprintln!(
            "warning: listening on {}, so anyone who can reach this machine can read the stacks' configuration",
            arguments.host
        );
    }

    thread::spawn(move || watcher.run());
    let loopback = arguments.host.is_loopback();
    let assets = Arc::new(arguments.assets.clone());
    for stream in listener.incoming() {
        let Ok(stream) = stream else { continue };
        let published = Arc::clone(&published);
        let assets = Arc::clone(&assets);
        thread::spawn(move || {
            // A connection that fails mid-response is the browser's to retry.
            let _ = handle(&stream, &published, loopback, assets.as_deref());
        });
    }
    Ok(())
}

/// Reads the project's configuration, the first time and whenever it changes.
type Load<P> = Box<dyn Fn(&Path) -> Result<P> + Send>;

/// One stack as the watcher tracks it.
struct Watched {
    snapshot: StackSnapshot,
    /// Whether a build has been attempted since the stack was (re)declared.
    attempted: bool,
    /// The newest source modification time the last build attempt saw.
    built_from: Option<SystemTime>,
    /// The state file's modification time and length when last read.
    state_seen: Option<(SystemTime, u64)>,
}

struct Watcher<P> {
    project_path: PathBuf,
    load: Load<P>,
    selected: Vec<String>,
    poll: Duration,
    published: Arc<Published>,
    project: Option<P>,
    project_seen: Option<SystemTime>,
    info: ProjectInfo,
    stacks: BTreeMap<String, Watched>,
}

impl<P: Project> Watcher<P> {
    fn new(
        project_path: PathBuf,
        load: Load<P>,
        selected: Vec<String>,
        poll: Duration,
        published: Arc<Published>,
    ) -> Self {
        Self {
            project_seen: modified(&project_path),
            project_path,
            load,
            selected,
            poll,
            published,
            project: None,
            info: ProjectInfo {
                name: String::new(),
                root: String::new(),
                error: None,
            },
            stacks: BTreeMap::new(),
        }
    }

    /// Take a freshly loaded project: keep what is known about stacks it still declares,
    /// forget the rest, and schedule everything for a build.
    fn adopt(&mut self, project: P) {
        let root = fs::canonicalize(project.root()).unwrap_or_else(|_| project.root());
        self.info = ProjectInfo {
            name: root.file_name().map_or_else(
                || "project".to_owned(),
                |name| name.to_string_lossy().into_owned(),
            ),
            root: root.display().to_string(),
            error: None,
        };
        let mut stacks = BTreeMap::new();
        for name in project.stacks() {
            if !self.selected.is_empty() && !self.selected.contains(&name) {
                continue;
            }
            let previous = self.stacks.remove(&name);
            let description = project.describe(&name);
            stacks.insert(
                name.clone(),
                Watched {
                    snapshot: StackSnapshot {
                        name,
                        frontend: description.frontend,
                        backend: description.backend,
                        gated: description.gated,
                        status: BuildStatus::Building,
                        error: None,
                        built: previous.and_then(|previous| previous.snapshot.built),
                        state: StateSnapshot::Untracked("not read yet".to_owned()),
                    },
                    attempted: false,
                    built_from: None,
                    state_seen: None,
                },
            );
        }
        self.stacks = stacks;
        self.project = Some(project);
    }

    fn publish(&self) {
        let snapshots: Vec<_> = self
            .stacks
            .values()
            .map(|watched| watched.snapshot.clone())
            .collect();
        self.published.publish(&self.info, &snapshots);
    }

    fn run(mut self) {
        loop {
            self.reload_project();
            self.read_states();
            self.rebuild_changed();
            thread::sleep(self.poll);
        }
    }

    fn reload_project(&mut self) {
        let seen = modified(&self.project_path);
        if seen == self.project_seen {
            return;
        }
        self.project_seen = seen;
        match (self.load)(&self.project_path) {
            Ok(project) => {
                eprintln!("reloaded {}", self.project_path.display());
                self.adopt(project);
            }
            Err(error) => {
                eprintln!("{error:#}");
                self.info.error = Some(format!("{error:#}"));
            }
        }
        self.publish();
    }

    /// Build every stack whose sources changed since its last attempt. All of them are
    /// marked first, so the page shows what is queued while the first one builds.
    fn rebuild_changed(&mut self) {
        let Some(project) = &self.project else { return };
        let mut pending = Vec::new();
        for (name, watched) in &mut self.stacks {
            let newest = project.last_change(name);
            if !watched.attempted || watched.built_from != newest {
                watched.attempted = true;
                watched.built_from = newest;
                watched.snapshot.status = BuildStatus::Building;
                pending.push(name.clone());
            }
        }
        if pending.is_empty() {
            return;
        }
        self.publish();
        for name in pending {
            let started = Instant::now();
            let result = self
                .project
                .as_ref()
                .expect("a project is loaded")
                .build(&name);
            let elapsed = started.elapsed();
            let watched = self.stacks.get_mut(&name).expect("the stack is watched");
            match result {
                Ok((graph, origins)) => {
                    eprintln!(
                        "built stack `{name}` in {:.1}s ({} nodes{})",
                        elapsed.as_secs_f64(),
                        graph.resources.len() + graph.data_sources.len(),
                        if origins.is_some() {
                            ""
                        } else {
                            ", no origins"
                        }
                    );
                    watched.snapshot.status = BuildStatus::Ready;
                    watched.snapshot.error = None;
                    watched.snapshot.built = Some(Built {
                        graph,
                        origins,
                        finished_ms: now_ms(),
                        took_ms: u64::try_from(elapsed.as_millis()).unwrap_or(u64::MAX),
                    });
                }
                Err(error) => {
                    eprintln!("stack `{name}` did not build: {error:#}");
                    watched.snapshot.status = BuildStatus::Failed;
                    watched.snapshot.error = Some(format!("{error:#}"));
                }
            }
            self.publish();
        }
    }

    fn read_states(&mut self) {
        let Some(project) = &self.project else { return };
        let mut changed = false;
        for (name, watched) in &mut self.stacks {
            let state = match project.local_state(name) {
                Ok(Some(path)) => {
                    let seen = fs::metadata(&path)
                        .ok()
                        .and_then(|metadata| Some((metadata.modified().ok()?, metadata.len())));
                    if seen.is_some() && seen == watched.state_seen {
                        continue;
                    }
                    watched.state_seen = seen;
                    match seen {
                        None => StateSnapshot::Empty,
                        Some((updated, _)) => match fs::read(&path)
                            .map_err(anyhow::Error::from)
                            .and_then(|bytes| Ok(AppliedState::parse(&bytes, epoch_ms(updated))?))
                        {
                            Ok(state) => StateSnapshot::Tracked(state),
                            Err(error) => StateSnapshot::Untracked(format!(
                                "{} could not be read: {error}",
                                path.display()
                            )),
                        },
                    }
                }
                Ok(None) => StateSnapshot::Untracked(format!(
                    "state lives in the `{}` backend, which `inframe serve` does not read",
                    watched.snapshot.backend
                )),
                Err(error) => StateSnapshot::Untracked(format!("{error:#}")),
            };
            if watched.snapshot.state != state {
                watched.snapshot.state = state;
                changed = true;
            }
        }
        if changed {
            self.publish();
        }
    }
}

fn modified(path: &Path) -> Option<SystemTime> {
    fs::metadata(path)
        .and_then(|metadata| metadata.modified())
        .ok()
}

fn epoch_ms(time: SystemTime) -> u64 {
    time.duration_since(UNIX_EPOCH).map_or(0, |elapsed| {
        u64::try_from(elapsed.as_millis()).unwrap_or(u64::MAX)
    })
}

fn now_ms() -> u64 {
    epoch_ms(SystemTime::now())
}

/// Answer one request. Only `GET` exists, and when the server listens on loopback the
/// `Host` header has to name this machine: a page elsewhere that resolves its own name to
/// 127.0.0.1 would otherwise read the model through the visitor's browser.
fn handle(
    stream: &TcpStream,
    published: &Published,
    loopback: bool,
    assets: Option<&Path>,
) -> io::Result<()> {
    stream.set_read_timeout(Some(Duration::from_secs(5)))?;
    let mut reader = BufReader::new(stream.try_clone()?);
    let mut request_line = String::new();
    reader.by_ref().take(8192).read_line(&mut request_line)?;
    let mut host = None;
    for _ in 0..100 {
        let mut header = String::new();
        if reader.by_ref().take(8192).read_line(&mut header)? == 0 || header.trim().is_empty() {
            break;
        }
        if let Some((name, value)) = header.split_once(':') {
            if name.eq_ignore_ascii_case("host") {
                host = Some(value.trim().to_owned());
            }
        }
    }
    let mut parts = request_line.split_whitespace();
    let (method, target) = (parts.next().unwrap_or(""), parts.next().unwrap_or(""));
    let path = target.split('?').next().unwrap_or("");

    if loopback && !host.as_deref().is_some_and(names_this_machine) {
        return respond(
            stream,
            "403 Forbidden",
            "text/plain",
            b"unexpected Host header\n",
        );
    }
    if method != "GET" {
        return respond(
            stream,
            "405 Method Not Allowed",
            "text/plain",
            b"GET only\n",
        );
    }
    match path {
        "/" | "/index.html" => {
            let page = asset(assets, "page.html", PAGE.as_bytes());
            respond(stream, "200 OK", "text/html; charset=utf-8", &page)
        }
        "/view.wasm" => {
            let module = asset(assets, "view.wasm", VIEW_WASM);
            respond(stream, "200 OK", "application/wasm", &module)
        }
        "/api/model" => {
            let (_, document) = published.get();
            respond(stream, "200 OK", "application/json", document.as_bytes())
        }
        "/api/events" => events(stream, published),
        _ => respond(stream, "404 Not Found", "text/plain", b"not found\n"),
    }
}

/// A built-in asset, or the file of that name under `--assets` when it can be read.
fn asset(
    directory: Option<&Path>,
    name: &str,
    built_in: &'static [u8],
) -> std::borrow::Cow<'static, [u8]> {
    directory
        .and_then(|directory| fs::read(directory.join(name)).ok())
        .map_or(built_in.into(), Into::into)
}

fn names_this_machine(host: &str) -> bool {
    let name = host
        .strip_prefix('[')
        .and_then(|rest| rest.split_once(']'))
        .map_or_else(
            || host.rsplit_once(':').map_or(host, |(name, _)| name),
            |(name, _)| name,
        );
    name.eq_ignore_ascii_case("localhost")
        || name
            .parse::<IpAddr>()
            .is_ok_and(|address| address.is_loopback())
}

fn respond(
    mut stream: &TcpStream,
    status: &str,
    content_type: &str,
    body: &[u8],
) -> io::Result<()> {
    write!(
        stream,
        "HTTP/1.1 {status}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\n\
         Cache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n",
        body.len()
    )?;
    stream.write_all(body)?;
    stream.flush()
}

/// Server-sent events: the current version at once, then each new one as it is published.
/// The stream ends when a write fails, which is how a closed tab shows.
fn events(mut stream: &TcpStream, published: &Published) -> io::Result<()> {
    stream.write_all(
        b"HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-store\r\n\
          X-Accel-Buffering: no\r\nConnection: close\r\n\r\nretry: 1000\n\n",
    )?;
    let mut seen = 0;
    loop {
        let version = published.wait_past(seen, KEEP_ALIVE);
        if version == seen {
            stream.write_all(b": still here\n\n")?;
        } else {
            seen = version;
            write!(stream, "event: model\ndata: {version}\n\n")?;
        }
        stream.flush()?;
    }
}

#[cfg(test)]
mod tests {
    use super::names_this_machine;

    #[test]
    fn only_loopback_names_pass_the_host_check() {
        for host in [
            "localhost:7878",
            "LOCALHOST",
            "127.0.0.1:7878",
            "[::1]:7878",
            "127.0.0.2",
        ] {
            assert!(names_this_machine(host), "{host}");
        }
        for host in [
            "evil.example:7878",
            "192.168.1.4:7878",
            "localhost.evil.example",
            "",
        ] {
            assert!(!names_this_machine(host), "{host}");
        }
    }
}
