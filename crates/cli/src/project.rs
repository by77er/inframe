use std::collections::BTreeMap;
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::process::{Command, ExitStatus};

use anyhow::{Context, Result, bail};
use inframe_emit_lean::CoreDependency;
use inframe_graph_ir::GraphDocument;
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
    /// Override the PureScript package directory.
    pub output: Option<PathBuf>,
    /// Override the Lean package directory.
    pub lean_output: Option<PathBuf>,
}

/// The frontend language a stack is written in.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, clap::ValueEnum)]
#[serde(rename_all = "lowercase")]
pub enum Frontend {
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
    #[serde(default)]
    pub backend: BackendConfig,
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
        }
        let root = path
            .parent()
            .filter(|parent| !parent.as_os_str().is_empty())
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf();
        Ok(Self { root, config })
    }

    pub fn stack(&self, name: &str) -> Result<&StackConfig> {
        self.config
            .stacks
            .get(name)
            .with_context(|| format!("stack `{name}` is not declared in the project config"))
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
                (self.lake(config, main), main)
            }
        };
        let output = command.output().with_context(|| {
            format!(
                "failed to start {} in {}; install it or add it to PATH",
                frontend_tool(frontend),
                self.frontend_directory(frontend).display()
            )
        })?;
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            bail!(
                "{} failed while building stack `{stack}`:\n{stderr}",
                frontend_tool(frontend)
            );
        }
        let graph: GraphDocument = serde_json::from_slice(&output.stdout).with_context(|| {
            format!(
                "{} entry point `{main}` did not print a Graph IR JSON document",
                frontend.name()
            )
        })?;
        graph.validate()?;
        let path = output_override.map_or_else(|| self.graph_path(stack), Path::to_path_buf);
        write_graph(&path, &graph)?;
        Ok((graph, path))
    }

    pub fn test(&self, stack: &str) -> Result<ExitStatus> {
        let stack_config = self.stack(stack)?;
        let frontend = self.stack_frontend(stack)?;
        let mut command = match frontend {
            Frontend::PureScript => {
                let config = self.purescript_config()?;
                let test = stack_config
                    .test
                    .as_deref()
                    .or(config.test.as_deref())
                    .with_context(|| {
                        format!(
                            "stack `{stack}` has no PureScript test entry point; set `stacks.{stack}.test` or `purescript.test`"
                        )
                    })?;
                self.spago(config, "test", test)
            }
            Frontend::Lean => {
                let config = self.lean_config()?;
                let test = stack_config
                    .test
                    .as_deref()
                    .or(config.test.as_deref())
                    .with_context(|| {
                        format!(
                            "stack `{stack}` has no Lean test executable; set `stacks.{stack}.test` or `lean.test`"
                        )
                    })?;
                self.lake(config, test)
            }
        };
        command.status().with_context(|| {
            format!(
                "failed to start {} in {}; install it or add it to PATH",
                frontend_tool(frontend),
                self.frontend_directory(frontend).display()
            )
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

fn frontend_tool(frontend: Frontend) -> &'static str {
    match frontend {
        Frontend::PureScript => "spago",
        Frontend::Lean => "lake",
    }
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
