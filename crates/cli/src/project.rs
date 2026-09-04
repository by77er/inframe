use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus};

use anyhow::{Context, Result, bail};
use inframe_graph_ir::GraphDocument;
use serde::Deserialize;
use serde_json::{Map, Value};

pub const DEFAULT_CONFIG: &str = "inframe.toml";

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProjectConfig {
    pub purescript: PureScriptConfig,
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
    pub output: Option<PathBuf>,
}

#[derive(Debug)]
pub struct ProviderGeneration {
    pub source: String,
    pub version: String,
    pub module_root: String,
    pub output: PathBuf,
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
        if config.purescript.package.trim().is_empty() {
            bail!("purescript.package cannot be empty");
        }
        if config.purescript.main.trim().is_empty() {
            bail!("purescript.main cannot be empty");
        }
        if config.purescript.test.as_deref().is_some_and(str::is_empty) {
            bail!("purescript.test cannot be empty");
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
                bail!("purescript main for stack `{name}` cannot be empty");
            }
            if stack.test.as_deref().is_some_and(str::is_empty) {
                bail!("purescript test for stack `{name}` cannot be empty");
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

    pub fn provider_generations(&self, selected: Option<&str>) -> Result<Vec<ProviderGeneration>> {
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

        Ok(providers
            .into_iter()
            .map(|(name, provider)| ProviderGeneration {
                source: provider.source.clone(),
                version: provider.version.clone(),
                module_root: provider
                    .module_root
                    .clone()
                    .unwrap_or_else(|| pascal_case(name)),
                output: provider.output.as_ref().map_or_else(
                    || self.default_provider_output(name),
                    |path| self.root.join(path),
                ),
            })
            .collect())
    }

    pub fn default_provider_output(&self, name: &str) -> PathBuf {
        self.root
            .join(&self.config.purescript.directory)
            .join(".generated")
            .join(name)
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
        let main = stack_config
            .main
            .as_deref()
            .unwrap_or(&self.config.purescript.main);
        let directory = self.root.join(&self.config.purescript.directory);
        let output = Command::new("spago")
            .arg("run")
            .arg("-p")
            .arg(&self.config.purescript.package)
            .arg("--main")
            .arg(main)
            .arg("--quiet")
            .current_dir(&directory)
            .output()
            .with_context(|| {
                format!(
                    "failed to start spago in {}; install it or add it to PATH",
                    directory.display()
                )
            })?;
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            bail!("spago failed while building stack `{stack}`:\n{stderr}");
        }
        let graph: GraphDocument = serde_json::from_slice(&output.stdout).with_context(|| {
            format!("PureScript entry point `{main}` did not print a Graph IR JSON document")
        })?;
        graph.validate()?;
        let path = output_override.map_or_else(|| self.graph_path(stack), Path::to_path_buf);
        write_graph(&path, &graph)?;
        Ok((graph, path))
    }

    pub fn test(&self, stack: &str) -> Result<ExitStatus> {
        let stack_config = self.stack(stack)?;
        let test = stack_config
            .test
            .as_deref()
            .or(self.config.purescript.test.as_deref())
            .with_context(|| {
                format!(
                    "stack `{stack}` has no PureScript test entry point; set `stacks.{stack}.test` or `purescript.test`"
                )
            })?;
        let directory = self.root.join(&self.config.purescript.directory);
        Command::new("spago")
            .arg("test")
            .arg("-p")
            .arg(&self.config.purescript.package)
            .arg("--main")
            .arg(test)
            .arg("--quiet")
            .current_dir(&directory)
            .status()
            .with_context(|| {
                format!(
                    "failed to start spago in {}; install it or add it to PATH",
                    directory.display()
                )
            })
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

fn pascal_case(value: &str) -> String {
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
}
