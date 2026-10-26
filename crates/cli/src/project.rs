use std::collections::BTreeMap;
use std::ffi::OsStr;
use std::fs;
use std::io;
use std::path::{Component, Path, PathBuf};
use std::process::{Command, ExitStatus, Output};
use std::time::SystemTime;

use anyhow::{Context, Result, bail};
use inframe_emit_lean::{CoreDependency, LEAN_TOOLCHAIN};
use inframe_graph_ir::GraphDocument;
use inframe_opentofu::Workspace;
use serde::Deserialize;
use serde_json::{Map, Value};

pub const DEFAULT_CONFIG: &str = "inframe.toml";

/// The public repository of the Lean core library, used when a project does not point
/// `[lean.core]` at a local checkout.
pub const INFRAME_REPOSITORY: &str = "https://github.com/by77er/inframe";

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProjectConfig {
    pub purescript: Option<PureScriptConfig>,
    pub lean: Option<LeanConfig>,
    #[serde(default)]
    pub providers: BTreeMap<String, ProviderConfig>,
    #[serde(default)]
    pub workspace: WorkspaceConfig,
    #[serde(default)]
    pub stacks: BTreeMap<String, StackConfig>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProviderConfig {
    pub source: String,
    pub version: String,
    pub module_root: Option<String>,
    /// The resource-type prefix removed to form module names (`google_` for a `google-beta`
    /// provider). Inferred from the provider name and its resource types when unset.
    pub strip_prefix: Option<String>,
    /// Override the PureScript package directory.
    pub output: Option<PathBuf>,
    /// Override the Lean package directory.
    pub lean_output: Option<PathBuf>,
}

/// The frontend language a stack is written in.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, clap::ValueEnum)]
#[serde(rename_all = "lowercase")]
pub enum Frontend {
    /// Spelled as in `inframe.toml` (`frontend = "purescript"`); clap would otherwise expect
    /// `pure-script`.
    #[value(name = "purescript", alias = "pure-script")]
    PureScript,
    Lean,
}

impl Frontend {
    pub fn name(self) -> &'static str {
        match self {
            Self::PureScript => "PureScript",
            Self::Lean => "Lean",
        }
    }
}

/// One generated package for one provider and one frontend.
#[derive(Debug)]
pub struct FrontendTarget {
    pub frontend: Frontend,
    pub module_root: String,
    pub output: PathBuf,
    /// How a generated Lean package finds the core library; `None` for PureScript.
    pub lean_core: Option<CoreDependency>,
}

#[derive(Debug)]
pub struct ProviderGeneration {
    pub name: String,
    pub source: String,
    pub version: String,
    pub strip_prefix: Option<String>,
    pub targets: Vec<FrontendTarget>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct PureScriptConfig {
    #[serde(default = "default_purescript_directory")]
    pub directory: PathBuf,
    pub package: String,
    #[serde(default = "default_main")]
    pub main: String,
    pub test: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct LeanConfig {
    /// The Lake package directory of the infrastructure program.
    #[serde(default = "default_lean_directory")]
    pub directory: PathBuf,
    /// The Lake executable that prints the default stack's Graph IR.
    #[serde(default = "default_lean_main")]
    pub main: String,
    /// The Lake executable that checks the default stack's policies.
    pub test: Option<String>,
    /// Where generated packages find the `inframe` core library.
    #[serde(default)]
    pub core: LeanCoreConfig,
}

#[derive(Debug, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct LeanCoreConfig {
    /// A checkout of the core library, relative to the project root.
    pub path: Option<PathBuf>,
    /// A git repository containing the core library.
    pub git: Option<String>,
    pub rev: Option<String>,
    pub subdir: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct WorkspaceConfig {
    #[serde(default = "default_workspace_directory")]
    pub directory: PathBuf,
    #[serde(default = "default_graph_directory")]
    pub graph_directory: PathBuf,
}

impl Default for WorkspaceConfig {
    fn default() -> Self {
        Self {
            directory: default_workspace_directory(),
            graph_directory: default_graph_directory(),
        }
    }
}

#[derive(Debug, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct StackConfig {
    /// Which configured frontend builds this stack; required when both are configured.
    pub frontend: Option<Frontend>,
    pub main: Option<String>,
    pub test: Option<String>,
    /// The statement a stack must prove (or pass) before `plan` and `apply`.
    pub gate: Option<GateConfig>,
    #[serde(default)]
    pub backend: BackendConfig,
}

/// A stack's deployment gate. Inframe writes a module that imports `module` and checks
/// `policy` against `program` itself, so the statement is the project's and not the test
/// module's, and it requires the graph of `program` to be the graph the stack's `main`
/// prints. For Lean the module states `Inframe.Gated policy program` and proves it with
/// `proof` (or evaluates it), and rejects every declaration outside the Lean toolchain that
/// rests on `sorry`, `native_decide`, or a declared axiom, or whose compiled code is swapped
/// with `implemented_by`. PureScript has no proofs, so its gate evaluates the policy.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct GateConfig {
    /// The module that defines, or imports, the names below.
    pub module: String,
    /// The `Infra` program that is deployed. In PureScript a dotted name is a value of
    /// another module (`Infra.Platform.infrastructure`).
    pub program: String,
    /// The `Policy` its graph must satisfy.
    pub policy: String,
    /// Lean only: a theorem of `Inframe.Gated policy program`. Without one the gate evaluates
    /// the validator and the policy, which scales past kernel `decide` but is a check, not a
    /// proof.
    pub proof: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct BackendConfig {
    #[serde(rename = "type", alias = "kind", default = "default_backend_kind")]
    pub kind: String,
    #[serde(default)]
    pub config: BTreeMap<String, toml::Value>,
}

impl Default for BackendConfig {
    fn default() -> Self {
        Self {
            kind: default_backend_kind(),
            config: BTreeMap::new(),
        }
    }
}

#[derive(Debug)]
pub struct Project {
    root: PathBuf,
    config: ProjectConfig,
}

impl Project {
    pub fn load(path: &Path) -> Result<Self> {
        let source = fs::read_to_string(path)
            .with_context(|| format!("failed to read project config {}", path.display()))?;
        let config: ProjectConfig = toml::from_str(&source)
            .with_context(|| format!("failed to decode project config {}", path.display()))?;
        if config.purescript.is_none() && config.lean.is_none() {
            bail!("project config must declare a [purescript] or [lean] frontend");
        }
        if let Some(purescript) = &config.purescript {
            if purescript.package.trim().is_empty() {
                bail!("purescript.package cannot be empty");
            }
            if purescript.main.trim().is_empty() {
                bail!("purescript.main cannot be empty");
            }
            if purescript.test.as_deref().is_some_and(str::is_empty) {
                bail!("purescript.test cannot be empty");
            }
        }
        if let Some(lean) = &config.lean {
            if lean.main.trim().is_empty() {
                bail!("lean.main cannot be empty");
            }
            if lean.test.as_deref().is_some_and(str::is_empty) {
                bail!("lean.test cannot be empty");
            }
            let core = &lean.core;
            if core.path.is_some() && core.git.is_some() {
                bail!("lean.core must set either `path` or `git`, not both");
            }
            if core.git.is_none() && (core.rev.is_some() || core.subdir.is_some()) {
                bail!("lean.core `rev` and `subdir` require `git`");
            }
        }
        for (name, provider) in &config.providers {
            if !valid_component_name(name) {
                bail!("invalid provider name `{name}` in project config");
            }
            if provider.source.trim().is_empty() {
                bail!("source for provider `{name}` cannot be empty");
            }
            if provider.version.trim().is_empty() {
                bail!("version for provider `{name}` cannot be empty");
            }
        }
        if config.stacks.is_empty() {
            bail!("project config must declare at least one [stacks.<name>] table");
        }
        for (name, stack) in &config.stacks {
            if !valid_stack_name(name) {
                bail!("invalid stack name `{name}` in project config");
            }
            if !valid_backend_kind(&stack.backend.kind) {
                bail!(
                    "invalid OpenTofu backend type `{}` for stack `{name}`",
                    stack.backend.kind
                );
            }
            if stack.main.as_deref().is_some_and(str::is_empty) {
                bail!("main entry point for stack `{name}` cannot be empty");
            }
            if stack.test.as_deref().is_some_and(str::is_empty) {
                bail!("test entry point for stack `{name}` cannot be empty");
            }
            match stack.frontend {
                Some(Frontend::PureScript) if config.purescript.is_none() => {
                    bail!(
                        "stack `{name}` selects the purescript frontend but [purescript] is not configured"
                    )
                }
                Some(Frontend::Lean) if config.lean.is_none() => {
                    bail!("stack `{name}` selects the lean frontend but [lean] is not configured")
                }
                _ => {}
            }
            validate_backend_config(name, &stack.backend.config)?;
            if let Some(gate) = &stack.gate {
                validate_gate(name, gate)?;
            }
        }
        let root = path
            .parent()
            .filter(|parent| !parent.as_os_str().is_empty())
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf();
        let project = Self { root, config };
        for (name, stack) in &project.config.stacks {
            let proof = stack.gate.as_ref().is_some_and(|gate| gate.proof.is_some());
            if proof && project.stack_frontend(name)? == Frontend::PureScript {
                bail!(
                    "stack `{name}` is PureScript, which has no proofs; drop `stacks.{name}.gate.proof` and the gate evaluates its policy"
                );
            }
        }
        Ok(project)
    }

    pub fn stack(&self, name: &str) -> Result<&StackConfig> {
        self.config
            .stacks
            .get(name)
            .with_context(|| format!("stack `{name}` is not declared in the project config"))
    }

    /// Every declared stack, in name order.
    pub fn stack_names(&self) -> impl Iterator<Item = &str> {
        self.config.stacks.keys().map(String::as_str)
    }

    /// Every stack `graph` (built from `stack`) reads must be another declared stack.
    pub fn check_stack_references(&self, stack: &str, graph: &GraphDocument) -> Result<()> {
        for reference in &graph.stack_references {
            if reference.stack == stack {
                bail!("stack `{stack}` reads its own outputs through a stack reference");
            }
            if !self.config.stacks.contains_key(&reference.stack) {
                bail!(
                    "stack `{stack}` reads stack `{}`, which is not declared in the project config",
                    reference.stack
                );
            }
        }
        Ok(())
    }

    /// Replace `graph`'s stack references with `terraform_remote_state` data sources reading
    /// each stack's configured backend. A `local` backend's state lives in that stack's own
    /// directory under `workspace_base`, so its path is made absolute here.
    pub fn resolve_stack_references(
        &self,
        graph: GraphDocument,
        workspace_base: &Path,
    ) -> Result<GraphDocument> {
        graph.resolve_stack_references(|stack| {
            let (kind, mut config) = self.backend_json(stack)?;
            if kind == "local" {
                let producer = Workspace::new(workspace_base, stack)?;
                let state = match config.get("path") {
                    Some(Value::String(path)) => producer.root().join(path),
                    Some(_) => {
                        bail!("the `path` of stack `{stack}`'s local backend must be a string")
                    }
                    None => producer.root().join("terraform.tfstate"),
                };
                let state = std::path::absolute(&state).with_context(|| {
                    format!("failed to resolve the state path of stack `{stack}`")
                })?;
                config.insert(
                    "path".to_owned(),
                    Value::String(state.to_string_lossy().into_owned()),
                );
            }
            Ok((kind.to_owned(), config))
        })
    }

    pub fn workspace_directory(&self) -> PathBuf {
        self.root.join(&self.config.workspace.directory)
    }

    /// The frontends this project configures, in a stable order.
    pub fn frontends(&self) -> Vec<Frontend> {
        let mut frontends = Vec::new();
        if self.config.purescript.is_some() {
            frontends.push(Frontend::PureScript);
        }
        if self.config.lean.is_some() {
            frontends.push(Frontend::Lean);
        }
        frontends
    }

    /// The frontend that builds `stack`.
    pub fn stack_frontend(&self, stack: &str) -> Result<Frontend> {
        let stack_config = self.stack(stack)?;
        if let Some(frontend) = stack_config.frontend {
            return Ok(frontend);
        }
        match self.frontends().as_slice() {
            [frontend] => Ok(*frontend),
            _ => bail!(
                "stack `{stack}` must set `frontend = \"purescript\"` or `frontend = \"lean\"` because both frontends are configured"
            ),
        }
    }

    pub fn provider_generations(
        &self,
        selected: Option<&str>,
        frontend: Option<Frontend>,
    ) -> Result<Vec<ProviderGeneration>> {
        let providers: Vec<_> = if let Some(name) = selected {
            vec![(
                name,
                self.config.providers.get(name).with_context(|| {
                    format!("provider `{name}` is not declared in the project config")
                })?,
            )]
        } else {
            self.config
                .providers
                .iter()
                .map(|(name, provider)| (name.as_str(), provider))
                .collect()
        };
        if providers.is_empty() {
            bail!("project config does not declare any [providers.<name>] tables");
        }
        let frontends: Vec<_> = self
            .frontends()
            .into_iter()
            .filter(|configured| frontend.is_none_or(|selected| selected == *configured))
            .collect();
        if frontends.is_empty() {
            bail!(
                "the {} frontend is not configured in the project config",
                frontend.map_or("requested", Frontend::name)
            );
        }

        providers
            .into_iter()
            .map(|(name, provider)| {
                let module_root = provider
                    .module_root
                    .clone()
                    .unwrap_or_else(|| pascal_case(name));
                let targets = frontends
                    .iter()
                    .map(|frontend| {
                        let output = match frontend {
                            Frontend::PureScript => provider.output.as_ref(),
                            Frontend::Lean => provider.lean_output.as_ref(),
                        }
                        .map_or_else(
                            || self.default_provider_output(*frontend, name),
                            |path| self.root.join(path),
                        );
                        Ok(FrontendTarget {
                            frontend: *frontend,
                            module_root: module_root.clone(),
                            lean_core: match frontend {
                                Frontend::PureScript => None,
                                Frontend::Lean => Some(self.lean_core_dependency(&output)?),
                            },
                            output,
                        })
                    })
                    .collect::<Result<Vec<_>>>()?;
                Ok(ProviderGeneration {
                    name: name.to_owned(),
                    source: provider.source.clone(),
                    version: provider.version.clone(),
                    strip_prefix: provider.strip_prefix.clone(),
                    targets,
                })
            })
            .collect()
    }

    pub fn default_provider_output(&self, frontend: Frontend, name: &str) -> PathBuf {
        self.root
            .join(self.frontend_directory(frontend))
            .join(".generated")
            .join(name)
    }

    /// The directory holding the sources of `stack`: its frontend's package directory.
    pub fn stack_source_directory(&self, stack: &str) -> Result<PathBuf> {
        Ok(self
            .root
            .join(self.frontend_directory(self.stack_frontend(stack)?)))
    }

    fn frontend_directory(&self, frontend: Frontend) -> PathBuf {
        match frontend {
            Frontend::PureScript => self
                .config
                .purescript
                .as_ref()
                .map_or_else(default_purescript_directory, |config| {
                    config.directory.clone()
                }),
            Frontend::Lean => self
                .config
                .lean
                .as_ref()
                .map_or_else(default_lean_directory, |config| config.directory.clone()),
        }
    }

    /// The `require` a generated Lean package at `output` uses to reach the core library.
    pub fn lean_core_dependency(&self, output: &Path) -> Result<CoreDependency> {
        let core = self
            .config
            .lean
            .as_ref()
            .map(|lean| &lean.core)
            .context("the lean frontend is not configured")?;
        if let Some(path) = &core.path {
            let target = self.root.join(path);
            return Ok(CoreDependency::Path(relative_path(output, &target)));
        }
        Ok(CoreDependency::Git {
            url: core
                .git
                .clone()
                .unwrap_or_else(|| INFRAME_REPOSITORY.to_owned()),
            rev: core.rev.clone().unwrap_or_else(|| "main".to_owned()),
            sub_dir: Some(core.subdir.clone().unwrap_or_else(|| "lean".to_owned())),
        })
    }

    pub fn graph_path(&self, stack: &str) -> PathBuf {
        self.root
            .join(&self.config.workspace.graph_directory)
            .join(format!("{stack}.json"))
    }

    pub fn backend_json(&self, stack: &str) -> Result<(&str, Map<String, Value>)> {
        let backend = &self.stack(stack)?.backend;
        let config = backend
            .config
            .iter()
            .map(|(key, value)| {
                serde_json::to_value(value)
                    .map(|value| (key.clone(), value))
                    .context("failed to translate backend config to JSON")
            })
            .collect::<Result<_>>()?;
        Ok((&backend.kind, config))
    }

    pub fn build(
        &self,
        stack: &str,
        output_override: Option<&Path>,
    ) -> Result<(GraphDocument, PathBuf)> {
        let graph = self.render(stack)?;
        let path = output_override.map_or_else(|| self.graph_path(stack), Path::to_path_buf);
        write_graph(&path, &graph)?;
        Ok((graph, path))
    }

    /// Run the stack's `main` and check the Graph IR it prints, without writing it.
    pub fn render(&self, stack: &str) -> Result<GraphDocument> {
        let stack_config = self.stack(stack)?;
        let frontend = self.stack_frontend(stack)?;
        let (mut command, main) = match frontend {
            Frontend::PureScript => {
                let config = self.purescript_config()?;
                let main = stack_config.main.as_deref().unwrap_or(&config.main);
                (self.spago(config, "run", main), main)
            }
            Frontend::Lean => {
                let config = self.lean_config()?;
                let main = stack_config.main.as_deref().unwrap_or(&config.main);
                warn_toolchain_mismatch(&self.root.join(&config.directory));
                (self.lake(config, main), main)
            }
        };
        let tool = frontend_tool(frontend);
        let directory = self.root.join(self.frontend_directory(frontend));
        let output = match command.output() {
            Ok(output) => output,
            Err(error) if error.kind() == io::ErrorKind::NotFound => bail!(
                "`{tool}` was not found on PATH, so stack `{stack}` cannot be built; {}",
                install_hint(frontend)
            ),
            Err(error) => {
                return Err(error).with_context(|| {
                    format!("failed to start `{tool}` in {}", directory.display())
                });
            }
        };
        if !output.status.success() {
            bail!(
                "{}",
                child_failure_report(
                    &format!("`{tool}` failed while building stack `{stack}`"),
                    &command,
                    &directory,
                    &output
                )
            );
        }
        let graph: GraphDocument = serde_json::from_slice(&output.stdout).with_context(|| {
            let mut message = format!(
                "{} entry point `{main}` did not print a Graph IR JSON document",
                frontend.name()
            );
            let stderr = String::from_utf8_lossy(&output.stderr);
            if !stderr.trim().is_empty() {
                message.push_str("\nstderr of the entry point:\n");
                message.push_str(stderr.trim_end());
            }
            message
        })?;
        graph.validate()?;
        self.check_stack_references(stack, &graph)?;
        Ok(graph)
    }

    /// The test entry point that checks `stack`'s policies, if one is configured: the
    /// stack's own `test`, else the frontend's default.
    pub fn test_entry_point(&self, stack: &str) -> Result<Option<&str>> {
        let stack_config = self.stack(stack)?;
        let default = match self.stack_frontend(stack)? {
            Frontend::PureScript => self.purescript_config()?.test.as_deref(),
            Frontend::Lean => self.lean_config()?.test.as_deref(),
        };
        Ok(stack_config.test.as_deref().or(default))
    }

    pub fn test(&self, stack: &str) -> Result<ExitStatus> {
        let frontend = self.stack_frontend(stack)?;
        let mut command = match frontend {
            Frontend::PureScript => {
                let config = self.purescript_config()?;
                let test = self.test_entry_point(stack)?.with_context(|| {
                    format!(
                        "stack `{stack}` has no PureScript test entry point; set `stacks.{stack}.test` or `purescript.test`"
                    )
                })?;
                self.spago(config, "test", test)
            }
            Frontend::Lean => {
                let config = self.lean_config()?;
                let test = self.test_entry_point(stack)?.with_context(|| {
                    format!(
                        "stack `{stack}` has no Lean test executable; set `stacks.{stack}.test` or `lean.test`"
                    )
                })?;
                self.lake(config, test)
            }
        };
        match command.status() {
            Ok(status) => Ok(status),
            Err(error) if error.kind() == io::ErrorKind::NotFound => bail!(
                "`{}` was not found on PATH, so the tests of stack `{stack}` cannot run; {}",
                frontend_tool(frontend),
                install_hint(frontend)
            ),
            Err(error) => Err(error).with_context(|| {
                format!(
                    "failed to start `{}` in {}",
                    frontend_tool(frontend),
                    self.root.join(self.frontend_directory(frontend)).display()
                )
            }),
        }
    }

    /// The stack's deployment gate, if it configures one.
    pub fn gate(&self, stack: &str) -> Result<Option<&GateConfig>> {
        Ok(self.stack(stack)?.gate.as_ref())
    }

    /// Run `stack`'s gate (see `GateConfig`) and require the graph it checked to be `emitted`,
    /// the graph the stack's `main` printed.
    pub fn run_gate(&self, stack: &str, emitted: &GraphDocument) -> Result<()> {
        let gate = self
            .gate(stack)?
            .with_context(|| format!("stack `{stack}` has no `[stacks.{stack}.gate]`"))?;
        let gate_directory = self.workspace_directory().join("gates").join(stack);
        fs::create_dir_all(&gate_directory)
            .with_context(|| format!("failed to create {}", gate_directory.display()))?;
        let gate_directory = std::path::absolute(&gate_directory)
            .with_context(|| format!("failed to resolve {}", gate_directory.display()))?;
        let checked = match self.stack_frontend(stack)? {
            Frontend::Lean => self.run_lean_gate(stack, gate, &gate_directory)?,
            Frontend::PureScript => self.run_purescript_gate(stack, gate, &gate_directory)?,
        };
        if &checked != emitted {
            bail!(
                "the gate of stack `{stack}` checked the graph of `{}`, but the stack's `main` prints a different graph; \
                 make `main` emit `{}` or point the gate at the program it emits",
                gate.program,
                gate.program
            );
        }
        Ok(())
    }

    /// Elaborate the Lean gate module with `lake env lean`; it writes the graph it checked.
    fn run_lean_gate(
        &self,
        stack: &str,
        gate: &GateConfig,
        gate_directory: &Path,
    ) -> Result<GraphDocument> {
        let directory = self.root.join(&self.lean_config()?.directory);
        let source_path = gate_directory.join("Gate.lean");
        let graph_path = gate_directory.join("graph.json");
        match fs::remove_file(&graph_path) {
            Ok(()) => {}
            Err(error) if error.kind() == io::ErrorKind::NotFound => {}
            Err(error) => {
                return Err(error)
                    .with_context(|| format!("failed to remove {}", graph_path.display()));
            }
        }
        write_text(&source_path, &lean_gate_source(stack, gate, &graph_path)?)?;

        let mut build = Command::new("lake");
        build
            .arg("-q")
            .arg("build")
            .arg("Inframe.Gate")
            .arg(&gate.module)
            .current_dir(&directory);
        run_tool(
            &mut build,
            Frontend::Lean,
            &directory,
            &format!("building the gate of stack `{stack}`"),
        )?;
        let mut check = Command::new("lake");
        check
            .arg("env")
            .arg("lean")
            .arg(&source_path)
            .current_dir(&directory);
        run_tool(
            &mut check,
            Frontend::Lean,
            &directory,
            &format!("the gate of stack `{stack}` failed"),
        )?;
        read_graph_file(&graph_path).with_context(|| {
            format!("the gate of stack `{stack}` did not write the graph it checked")
        })
    }

    /// Compile the PureScript gate module with `purs` against the package's sources (its
    /// tests included) into the package's output directory, run it with `node`, and read the
    /// graph it prints.
    fn run_purescript_gate(
        &self,
        stack: &str,
        gate: &GateConfig,
        gate_directory: &Path,
    ) -> Result<GraphDocument> {
        let config = self.purescript_config()?;
        let directory = self.root.join(&config.directory);
        let source_path = gate_directory.join("InframeGate.purs");
        write_text(&source_path, &purescript_gate_source(stack, gate))?;

        let mut build = Command::new("spago");
        build
            .arg("build")
            .arg("-p")
            .arg(&config.package)
            .arg("--quiet")
            .current_dir(&directory);
        run_tool(
            &mut build,
            Frontend::PureScript,
            &directory,
            &format!("building the gate of stack `{stack}`"),
        )?;
        let mut sources = Command::new("spago");
        sources
            .arg("sources")
            .arg("-p")
            .arg(&config.package)
            .arg("--quiet")
            .current_dir(&directory);
        let globs = run_tool(
            &mut sources,
            Frontend::PureScript,
            &directory,
            &format!("listing the sources of stack `{stack}`"),
        )?;
        let globs = gate_source_globs(&String::from_utf8_lossy(&globs), gate, &directory);
        let globs_path = gate_directory.join("sources.txt");
        fs::write(&globs_path, globs)
            .with_context(|| format!("failed to write {}", globs_path.display()))?;

        let mut compile = Command::new("purs");
        compile
            .arg("compile")
            .arg("--source-globs-file")
            .arg(&globs_path)
            .arg(&source_path)
            .arg("--output")
            .arg("output")
            .current_dir(&directory);
        run_tool(
            &mut compile,
            Frontend::PureScript,
            &directory,
            &format!("compiling the gate of stack `{stack}`"),
        )?;
        let module = std::path::absolute(directory.join("output/InframeGate/index.js"))
            .context("failed to resolve the compiled gate module")?;
        let module = serde_json::to_string(&module.to_string_lossy())
            .context("failed to quote the compiled gate module path")?;
        let mut run = Command::new("node");
        run.arg("--input-type=module")
            .arg("-e")
            .arg(format!(
                "import {{ pathToFileURL }} from 'node:url';\n\
                 const gate = await import(pathToFileURL({module}).href);\n\
                 try {{ gate.main(); }} catch (error) {{ console.error(error.message); process.exit(1); }}\n"
            ))
            .current_dir(&directory);
        let printed = run_tool(
            &mut run,
            Frontend::PureScript,
            &directory,
            &format!("the gate of stack `{stack}` failed"),
        )?;
        serde_json::from_slice(&printed).with_context(|| {
            format!("the gate of stack `{stack}` did not print the graph it checked")
        })
    }

    fn purescript_config(&self) -> Result<&PureScriptConfig> {
        self.config
            .purescript
            .as_ref()
            .context("the purescript frontend is not configured")
    }

    fn lean_config(&self) -> Result<&LeanConfig> {
        self.config
            .lean
            .as_ref()
            .context("the lean frontend is not configured")
    }

    fn spago(&self, config: &PureScriptConfig, subcommand: &str, main: &str) -> Command {
        let mut command = Command::new("spago");
        command
            .arg(subcommand)
            .arg("-p")
            .arg(&config.package)
            .arg("--main")
            .arg(main)
            .arg("--quiet")
            .current_dir(self.root.join(&config.directory));
        command
    }

    /// Lake executables print program output on stdout and build logs on stderr, so a
    /// quiet `lake exe` is a clean Graph IR producer.
    fn lake(&self, config: &LeanConfig, executable: &str) -> Command {
        let mut command = Command::new("lake");
        command
            .arg("-q")
            .arg("exe")
            .arg(executable)
            .current_dir(self.root.join(&config.directory));
        command
    }
}

/// The module `run_lean_gate` elaborates. Everything the project names is spliced in as a
/// name (checked by `valid_qualified_name` when the project loads); the statement is fixed
/// here.
fn lean_gate_source(stack: &str, gate: &GateConfig, graph_path: &Path) -> Result<String> {
    let graph_path = graph_path
        .to_str()
        .filter(|path| !path.chars().any(char::is_control))
        .with_context(|| format!("the gate path {} is not plain UTF-8", graph_path.display()))?;
    let graph_path = graph_path.replace('\\', "\\\\").replace('"', "\\\"");
    let (module, program, policy) = (&gate.module, &gate.program, &gate.policy);
    let check = match &gate.proof {
        Some(proof) => format!(
            "/-- The gate of stack `{stack}`, stated by Inframe and proved by `{proof}`. -/\n\
             theorem InframeGate.holds : Inframe.Gated ({policy}) ({program}) := ({proof})\n\n\
             #assert_standard_axioms InframeGate.holds\n"
        ),
        None => format!(
            "#assert_valid (Inframe.buildGraph ({program}))\n\
             #assert_policy ({policy}) (Inframe.buildGraph ({program}))\n\
             #assert_standard_axioms\n"
        ),
    };
    Ok(format!(
        "-- Written by `inframe` for stack `{stack}` on every run; edits are overwritten.\n\
         import Inframe.Gate\n\
         import {module}\n\n\
         {check}\
         #assert_compiled_as_proved\n\n\
         #eval Inframe.writeGraph \"{graph_path}\" ({program})\n"
    ))
}

/// The module `run_purescript_gate` compiles. A dotted name is a value of the module before
/// its last dot, imported qualified, since a PureScript module does not re-export what it
/// imports; a bare name is a value of the gate's `module`.
fn purescript_gate_source(stack: &str, gate: &GateConfig) -> String {
    let mut modules = vec![gate.module.clone()];
    let mut reference = |name: &str| {
        let (module, value) = name
            .rsplit_once('.')
            .map_or((gate.module.as_str(), name), |(module, value)| {
                (module, value)
            });
        let index = modules
            .iter()
            .position(|known| known == module)
            .unwrap_or_else(|| {
                modules.push(module.to_owned());
                modules.len() - 1
            });
        format!("Gated{index}.{value}")
    };
    let policy = reference(&gate.policy);
    let program = reference(&gate.program);
    let imports: String = modules
        .iter()
        .enumerate()
        .map(|(index, module)| format!("import {module} as Gated{index}\n"))
        .collect::<Vec<_>>()
        .concat();
    format!(
        "-- Written by `inframe` for stack `{stack}` on every run; edits are overwritten.\n\
         module InframeGate (main) where\n\n\
         import Prelude (Unit)\n\
         import Effect (Effect)\n\
         import Inframe.Gate (gate)\n\
         {imports}\n\
         main :: Effect Unit\n\
         main = gate {policy} {program}\n"
    )
}

/// The sources the PureScript gate compiles. `spago sources` lists the `test` globs of every
/// workspace package, whose test-only dependencies are not installed for this one, so a test
/// glob is kept only when it holds a module the gate imports, as `spago test` would.
fn gate_source_globs(globs: &str, gate: &GateConfig, directory: &Path) -> String {
    let modules: Vec<PathBuf> = [&gate.module, &gate.program, &gate.policy]
        .into_iter()
        .flat_map(|name| {
            let module = name.rsplit_once('.').map(|(module, _)| module);
            [Some(gate.module.as_str()), module]
        })
        .flatten()
        .map(|module| PathBuf::from(format!("{}.purs", module.replace('.', "/"))))
        .collect();
    globs
        .lines()
        .filter(|glob| {
            let Some(root) = glob.strip_suffix("/**/*.purs") else {
                return true;
            };
            if Path::new(root).file_name() != Some(OsStr::new("test")) {
                return true;
            }
            modules
                .iter()
                .any(|module| directory.join(root).join(module).is_file())
        })
        .flat_map(|glob| [glob, "\n"])
        .collect()
}

/// Run a frontend tool, reporting its output if it fails, and return its stdout.
fn run_tool(
    command: &mut Command,
    frontend: Frontend,
    directory: &Path,
    failure: &str,
) -> Result<Vec<u8>> {
    let program = command.get_program().to_string_lossy().into_owned();
    let output = match command.output() {
        Ok(output) => output,
        Err(error) if error.kind() == io::ErrorKind::NotFound => bail!(
            "`{program}` was not found on PATH; {}",
            install_hint(frontend)
        ),
        Err(error) => {
            return Err(error).with_context(|| {
                format!("failed to start `{program}` in {}", directory.display())
            });
        }
    };
    if !output.status.success() {
        bail!(
            "{}",
            child_failure_report(failure, command, directory, &output)
        );
    }
    Ok(output.stdout)
}

fn frontend_tool(frontend: Frontend) -> &'static str {
    match frontend {
        Frontend::PureScript => "spago",
        Frontend::Lean => "lake",
    }
}

/// The core library is built with one Lean toolchain; a project pinning another gets a
/// Lake build against mismatched `.olean`s, which fails in ways that do not name the cause.
fn warn_toolchain_mismatch(directory: &Path) {
    let path = directory.join("lean-toolchain");
    let Ok(pinned) = fs::read_to_string(&path) else {
        return;
    };
    let pinned = pinned.trim();
    if !pinned.is_empty() && pinned != LEAN_TOOLCHAIN {
        eprintln!(
            "warning: {} pins `{pinned}` but the inframe core library is built with `{LEAN_TOOLCHAIN}`; \
             pin the same toolchain to build against the core's compiled modules",
            path.display()
        );
    }
}

fn install_hint(frontend: Frontend) -> &'static str {
    match frontend {
        Frontend::PureScript => {
            "install PureScript and Spago (`npm install -g purescript spago`) or add them to PATH"
        }
        Frontend::Lean => {
            "install elan (https://github.com/leanprover/elan) and add `~/.elan/bin` to PATH"
        }
    }
}

/// What a failed child process said, verbatim: the command line, its directory, its exit
/// status, and its stderr. An empty stderr is stated rather than left as a blank line, and
/// then the tail of stdout is shown in case the error went there.
fn child_failure_report(
    headline: &str,
    command: &Command,
    directory: &Path,
    output: &Output,
) -> String {
    let mut report = format!(
        "{headline} ({})\ncommand: {}\ndirectory: {}\n",
        output.status,
        render_command(command),
        directory.display()
    );
    let stderr = String::from_utf8_lossy(&output.stderr);
    if stderr.trim().is_empty() {
        report.push_str("stderr: (empty)\n");
    } else {
        report.push_str("stderr:\n");
        report.push_str(stderr.trim_end());
        report.push('\n');
    }
    // Some tools (`purs`, `lean`) report their errors on stdout.
    let stdout = String::from_utf8_lossy(&output.stdout);
    if !stdout.trim().is_empty() {
        let lines: Vec<&str> = stdout.lines().collect();
        let tail = &lines[lines.len().saturating_sub(20)..];
        report.push_str("stdout (tail):\n");
        report.push_str(&tail.join("\n"));
        report.push('\n');
    }
    report
}

fn render_command(command: &Command) -> String {
    std::iter::once(command.get_program())
        .chain(command.get_args())
        .map(|part| part.to_string_lossy().into_owned())
        .collect::<Vec<_>>()
        .join(" ")
}

/// Where `binary` resolves: as given when it names a path, otherwise the first match on
/// PATH. `None` means running it would fail with "not found".
pub fn find_executable(binary: &Path) -> Option<PathBuf> {
    if binary.components().count() > 1 {
        return binary.is_file().then(|| binary.to_path_buf());
    }
    let path = std::env::var_os("PATH")?;
    std::env::split_paths(&path)
        .map(|directory| directory.join(binary))
        .find(|candidate| candidate.is_file())
}

const BUILD_OUTPUT_DIRECTORIES: &[&str] = &[
    ".lake",
    ".spago",
    ".inframe",
    ".git",
    ".jj",
    "output",
    "node_modules",
    "target",
];

/// The newest modification time of any file under `directory`, skipping build output
/// directories. `None` when nothing readable is there.
pub fn newest_source_mtime(directory: &Path) -> Option<SystemTime> {
    let mut newest = None;
    let mut pending = vec![directory.to_path_buf()];
    while let Some(current) = pending.pop() {
        let Ok(entries) = fs::read_dir(&current) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            let Ok(metadata) = entry.metadata() else {
                continue;
            };
            if metadata.is_dir() {
                let skipped = path
                    .file_name()
                    .and_then(OsStr::to_str)
                    .is_some_and(|name| BUILD_OUTPUT_DIRECTORIES.contains(&name));
                if !skipped {
                    pending.push(path);
                }
            } else if let Ok(modified) = metadata.modified() {
                newest = Some(newest.map_or(modified, |current: SystemTime| current.max(modified)));
            }
        }
    }
    newest
}

pub fn initialize(path: &Path) -> Result<()> {
    if path.exists() {
        bail!(
            "refusing to overwrite existing project config {}",
            path.display()
        );
    }
    if let Some(parent) = path
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
    {
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;
    }
    fs::write(path, PROJECT_TEMPLATE)
        .with_context(|| format!("failed to write project config {}", path.display()))
}

fn write_graph(path: &Path, graph: &GraphDocument) -> Result<()> {
    if let Some(parent) = path
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
    {
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;
    }
    fs::write(path, graph.to_canonical_json()?)
        .with_context(|| format!("failed to write generated graph {}", path.display()))
}

fn write_text(path: &Path, contents: &str) -> Result<()> {
    fs::write(path, contents).with_context(|| format!("failed to write {}", path.display()))
}

fn read_graph_file(path: &Path) -> Result<GraphDocument> {
    let bytes = fs::read(path).with_context(|| format!("failed to read {}", path.display()))?;
    serde_json::from_slice(&bytes)
        .with_context(|| format!("{} is not a Graph IR document", path.display()))
}

/// Lexically normalize a path: resolve `.` and `..` without touching the filesystem.
fn normalize(path: &Path) -> PathBuf {
    let absolute = if path.is_absolute() {
        path.to_path_buf()
    } else {
        std::env::current_dir()
            .unwrap_or_else(|_| PathBuf::from("/"))
            .join(path)
    };
    let mut normalized = PathBuf::new();
    for component in absolute.components() {
        match component {
            Component::CurDir => {}
            Component::ParentDir => {
                normalized.pop();
            }
            other => normalized.push(other.as_os_str()),
        }
    }
    normalized
}

/// The relative path from directory `from` to directory `to`, as written in a lakefile.
pub fn relative_path(from: &Path, to: &Path) -> String {
    let from = normalize(from);
    let to = normalize(to);
    let from_components: Vec<_> = from.components().collect();
    let to_components: Vec<_> = to.components().collect();
    let common = from_components
        .iter()
        .zip(&to_components)
        .take_while(|(left, right)| left == right)
        .count();
    let mut parts: Vec<String> = vec!["..".to_owned(); from_components.len() - common];
    parts.extend(
        to_components[common..]
            .iter()
            .map(|component| component.as_os_str().to_string_lossy().into_owned()),
    );
    if parts.is_empty() {
        ".".to_owned()
    } else {
        parts.join("/")
    }
}

/// Gate names are spliced into the module the gate writes, so each must be a dotted name.
fn validate_gate(stack: &str, gate: &GateConfig) -> Result<()> {
    for (field, value) in [
        ("module", Some(&gate.module)),
        ("program", Some(&gate.program)),
        ("policy", Some(&gate.policy)),
        ("proof", gate.proof.as_ref()),
    ] {
        if let Some(value) = value.filter(|value| !valid_qualified_name(value)) {
            bail!(
                "`stacks.{stack}.gate.{field}` must be a dotted name such as `Infra.Platform.policies`, not `{value}`"
            );
        }
    }
    Ok(())
}

fn validate_backend_config(stack: &str, config: &BTreeMap<String, toml::Value>) -> Result<()> {
    for (key, value) in config {
        if secret_like_key(key) {
            bail!(
                "backend config for stack `{stack}` contains secret-like key `{key}`; use the backend's environment variables instead"
            );
        }
        validate_backend_value(stack, key, value)?;
    }
    Ok(())
}

fn validate_backend_value(stack: &str, path: &str, value: &toml::Value) -> Result<()> {
    match value {
        toml::Value::Table(table) => {
            for (key, value) in table {
                let child = format!("{path}.{key}");
                if secret_like_key(key) {
                    bail!(
                        "backend config for stack `{stack}` contains secret-like key `{child}`; use the backend's environment variables instead"
                    );
                }
                validate_backend_value(stack, &child, value)?;
            }
        }
        toml::Value::Array(items) => {
            for (index, value) in items.iter().enumerate() {
                validate_backend_value(stack, &format!("{path}[{index}]"), value)?;
            }
        }
        _ => {}
    }
    Ok(())
}

fn secret_like_key(key: &str) -> bool {
    let normalized = key.to_ascii_lowercase();
    [
        "password",
        "secret",
        "token",
        "access_key",
        "credential",
        "private_key",
    ]
    .iter()
    .any(|needle| normalized.contains(needle))
}

/// The stacks of `graphs` ordered so that every stack comes after the stacks it reads, the
/// order to apply them in: a depth-first order seeded by stack name. A cycle of stack references is an error,
/// since no order deploys it.
pub fn stack_order(graphs: &BTreeMap<String, GraphDocument>) -> Result<Vec<String>> {
    let mut order = Vec::new();
    for stack in graphs.keys() {
        visit_stack(stack, graphs, &mut Vec::new(), &mut order)?;
    }
    Ok(order)
}

/// Depth-first step of `stack_order`: `visiting` is the current path, so meeting one of its
/// stacks again closes a cycle.
fn visit_stack<'a>(
    stack: &'a str,
    graphs: &'a BTreeMap<String, GraphDocument>,
    visiting: &mut Vec<&'a str>,
    order: &mut Vec<String>,
) -> Result<()> {
    if order.iter().any(|done| done == stack) {
        return Ok(());
    }
    if let Some(start) = visiting.iter().position(|open| *open == stack) {
        let mut cycle = visiting[start..].to_vec();
        cycle.push(stack);
        bail!("stack references form a cycle: {}", cycle.join(" -> "));
    }
    visiting.push(stack);
    for reference in &graphs[stack].stack_references {
        if graphs.contains_key(&reference.stack) {
            visit_stack(&reference.stack, graphs, visiting, order)?;
        }
    }
    visiting.pop();
    order.push(stack.to_owned());
    Ok(())
}

fn valid_stack_name(value: &str) -> bool {
    valid_component_name(value)
}

fn valid_component_name(value: &str) -> bool {
    !value.is_empty()
        && value != "."
        && value != ".."
        && value
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || matches!(character, '-' | '_'))
}

/// A dotted name of plain identifiers (`Infra.PlatformTest`, `policies`), which is all a gate
/// splices into the module it writes, in either frontend.
fn valid_qualified_name(value: &str) -> bool {
    value.split('.').all(|component| {
        let mut characters = component.chars();
        characters
            .next()
            .is_some_and(|first| first.is_alphabetic() || first == '_')
            && characters.all(|character| {
                character.is_alphanumeric() || matches!(character, '_' | '\'' | '!' | '?')
            })
    })
}

pub fn pascal_case(value: &str) -> String {
    value
        .split(|character: char| !character.is_ascii_alphanumeric())
        .filter(|part| !part.is_empty())
        .map(|part| {
            let mut characters = part.chars();
            characters
                .next()
                .map(|first| first.to_ascii_uppercase().to_string() + characters.as_str())
                .unwrap_or_default()
        })
        .collect()
}

fn valid_backend_kind(value: &str) -> bool {
    let mut characters = value.chars();
    matches!(characters.next(), Some(first) if first == '_' || first.is_ascii_alphabetic())
        && characters.all(|character| character == '_' || character.is_ascii_alphanumeric())
}

fn default_purescript_directory() -> PathBuf {
    PathBuf::from("purescript")
}

fn default_lean_directory() -> PathBuf {
    PathBuf::from("lean")
}

fn default_lean_main() -> String {
    "infra".to_owned()
}

fn default_workspace_directory() -> PathBuf {
    PathBuf::from(".inframe")
}

fn default_graph_directory() -> PathBuf {
    PathBuf::from(".inframe/graphs")
}

fn default_main() -> String {
    "Main".to_owned()
}

fn default_backend_kind() -> String {
    "local".to_owned()
}

const PROJECT_TEMPLATE: &str = r#"[purescript]
directory = "purescript"
package = "my-infrastructure"
main = "Main"

# Or write stacks in Lean 4. `main` and `test` name Lake executables (`lake exe <name>`).
# [lean]
# directory = "lean"
# main = "infra"
# test = "infra-test"
# core = { git = "https://github.com/by77er/inframe", rev = "main", subdir = "lean" }

[providers.digitalocean]
source = "digitalocean/digitalocean"
version = "2.100.0"
module_root = "DigitalOcean"

[workspace]
directory = ".inframe"
graph_directory = ".inframe/graphs"

[stacks.dev.backend]
type = "local"

# A Lean stack names the statement that gates `plan` and `apply`: Inframe proves (or, without
# `proof`, evaluates) `Inframe.Gated policy program` and refuses `sorry`, `native_decide`, and
# `implemented_by`.
# [stacks.dev.gate]
# module = "Infra.Test"
# program = "infrastructure"
# policy = "policies"
# proof = "infrastructure_gated"
"#;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_backend_secrets_in_project_files() {
        let config = BTreeMap::from([(
            "access_token".to_owned(),
            toml::Value::String("do-not-store-this".to_owned()),
        )]);
        assert!(validate_backend_config("prod", &config).is_err());
    }

    #[test]
    fn stack_and_backend_names_cannot_escape_the_workspace() {
        assert!(valid_stack_name("preview-42"));
        assert!(!valid_stack_name("../prod"));
        assert!(valid_backend_kind("s3"));
        assert!(!valid_backend_kind("http/backend"));
    }

    #[test]
    fn relative_paths_are_computed_lexically() {
        assert_eq!(
            relative_path(
                Path::new("/repo/lean/integration/.generated/digitalocean"),
                Path::new("/repo/lean")
            ),
            "../../.."
        );
        assert_eq!(
            relative_path(
                Path::new("/repo/infra/.generated/x"),
                Path::new("/repo/core/lib")
            ),
            "../../../core/lib"
        );
        assert_eq!(
            relative_path(Path::new("/repo/a"), Path::new("/repo/a")),
            "."
        );
        assert_eq!(
            relative_path(Path::new("/repo/a/./b/../b"), Path::new("/repo/c")),
            "../../c"
        );
    }
}
