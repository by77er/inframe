//! `inframe serve`: a local web server showing the project's stacks as a live hierarchy.
//!
//! One thread watches the project: it rebuilds a stack when its sources change, re-reads its
//! local state when that changes, and publishes a new model each time. The other threads
//! answer HTTP: the page, the current model, and an event stream that announces each new
//! model so the page can follow along. The protocol is small enough to speak with the
//! standard library, so the CLI gains no dependency for it.

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

use crate::project::{self, Project};
use model::{AppliedState, BuildStatus, Built, ProjectInfo, StackSnapshot, StateSnapshot};

const PAGE: &str = include_str!("ui.html");

/// How often the event stream says it is still there, so a closed tab is noticed.
const KEEP_ALIVE: Duration = Duration::from_secs(15);

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

pub fn run(arguments: &ServeArgs, project_path: &Path) -> Result<()> {
    // Fail on a project that cannot be read at all before taking the port.
    let project = Project::load(project_path)?;
    for stack in &arguments.stacks {
        project.stack(stack)?;
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
        project_path.to_path_buf(),
        arguments.stacks.clone(),
        Duration::from_millis(arguments.poll_ms),
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
    for stream in listener.incoming() {
        let Ok(stream) = stream else { continue };
        let published = Arc::clone(&published);
        thread::spawn(move || {
            // A connection that fails mid-response is the browser's to retry.
            let _ = handle(&stream, &published, loopback);
        });
    }
    Ok(())
}

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

struct Watcher {
    project_path: PathBuf,
    selected: Vec<String>,
    poll: Duration,
    published: Arc<Published>,
    project: Option<Project>,
    project_seen: Option<SystemTime>,
    info: ProjectInfo,
    stacks: BTreeMap<String, Watched>,
}

impl Watcher {
    fn new(
        project_path: PathBuf,
        selected: Vec<String>,
        poll: Duration,
        published: Arc<Published>,
    ) -> Self {
        Self {
            project_seen: modified(&project_path),
            project_path,
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
    fn adopt(&mut self, project: Project) {
        let root = fs::canonicalize(project.root()).unwrap_or_else(|_| project.root().to_owned());
        self.info = ProjectInfo {
            name: root.file_name().map_or_else(
                || "project".to_owned(),
                |name| name.to_string_lossy().into_owned(),
            ),
            root: root.display().to_string(),
            error: None,
        };
        let mut stacks = BTreeMap::new();
        for name in project.stack_names() {
            if !self.selected.is_empty() && !self.selected.iter().any(|stack| stack == name) {
                continue;
            }
            let previous = self.stacks.remove(name);
            let frontend = project
                .stack_frontend(name)
                .map_or("unknown", |frontend| frontend.name());
            stacks.insert(
                name.to_owned(),
                Watched {
                    snapshot: StackSnapshot {
                        name: name.to_owned(),
                        frontend,
                        backend: project.backend_kind(name).unwrap_or_default().to_owned(),
                        gated: project.gate(name).ok().flatten().is_some(),
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
        match Project::load(&self.project_path) {
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
            let newest = project
                .stack_watch_directories(name)
                .unwrap_or_default()
                .iter()
                .filter_map(|directory| project::newest_source_mtime(directory))
                .max();
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
                .render_with_origins(&name);
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
        let base = project.workspace_directory();
        let mut changed = false;
        for (name, watched) in &mut self.stacks {
            let state = match project.local_state_path(name, &base) {
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
fn handle(stream: &TcpStream, published: &Published, loopback: bool) -> io::Result<()> {
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
        "/" | "/index.html" => respond(
            stream,
            "200 OK",
            "text/html; charset=utf-8",
            PAGE.as_bytes(),
        ),
        "/api/model" => {
            let (_, document) = published.get();
            respond(stream, "200 OK", "application/json", document.as_bytes())
        }
        "/api/events" => events(stream, published),
        _ => respond(stream, "404 Not Found", "text/plain", b"not found\n"),
    }
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
