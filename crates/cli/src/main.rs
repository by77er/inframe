use std::ffi::OsString;
use std::fs;
use std::io::{self, Read};
use std::path::{Path, PathBuf};
use std::{collections::BTreeMap, env};

use anyhow::{Context, Result, bail};
use clap::{Args, Parser, Subcommand};
use inframe_binding_model::derive_bindings;
use inframe_emit_purescript::render_package;
use inframe_graph_ir::GraphDocument;
use inframe_opentofu::{OpenTofu, Workspace, secret_variable_name, to_pretty_json};
use inframe_provider_schema::{ProviderRequest, SchemaAcquirer, normalize_schema};

mod project;

use project::{DEFAULT_CONFIG, Project};

#[derive(Debug, Parser)]
#[command(
    name = "inframe",
    version,
    about = "Pure graph frontend and compiler for OpenTofu"
)]
struct Cli {
    #[arg(long, global = true, default_value = "tofu")]
    tofu_binary: PathBuf,
    /// Project configuration path.
    #[arg(long, global = true, default_value = DEFAULT_CONFIG)]
    project: PathBuf,
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Create or inspect project-level configuration.
    Project {
        #[command(subcommand)]
        command: ProjectCommand,
    },
    /// Compile a configured PureScript stack to Graph IR without running `OpenTofu`.
    Build(BuildArgs),
    /// Acquire and generate provider bindings.
    Provider {
        #[command(subcommand)]
        command: ProviderCommand,
    },
    /// Validate and inspect Graph IR without running `OpenTofu`.
    Graph {
        #[command(subcommand)]
        command: GraphCommand,
    },
    /// Lower Graph IR to an `OpenTofu` JSON configuration.
    Render(RenderArgs),
    /// Prepare a stack and run `tofu init`.
    Init(RunArgs),
    /// Prepare a stack and run `tofu validate`.
    Validate(RunArgs),
    /// Prepare a stack and run `tofu plan`.
    Plan(RunArgs),
    /// Prepare a stack and run `tofu apply`.
    Apply(RunArgs),
    /// Prepare a stack and run `tofu destroy`.
    Destroy(RunArgs),
    /// Run `tofu show -json` in an existing stack.
    Show(ExistingStackArgs),
    /// Run `tofu output -json` in an existing stack.
    Output(ExistingStackArgs),
}

#[derive(Debug, Subcommand)]
enum ProjectCommand {
    /// Create a starter inframe.toml without overwriting an existing file.
    Init,
}

#[derive(Debug, Args)]
struct BuildArgs {
    #[arg(long)]
    stack: String,
    /// Override the configured generated-graph path.
    #[arg(long)]
    output: Option<PathBuf>,
}

#[derive(Debug, Subcommand)]
enum ProviderCommand {
    /// Print deterministic metadata about an acquired provider schema.
    Inspect(ProviderInspectArgs),
    /// Generate an importable PureScript provider package.
    Generate(ProviderGenerateArgs),
}

#[derive(Debug, Args)]
struct ProviderInspectArgs {
    #[arg(long)]
    source: String,
    #[arg(long)]
    version: String,
    /// Read a raw `tofu providers schema -json` fixture instead of acquiring it.
    #[arg(long)]
    schema_json: Option<PathBuf>,
    /// Write the normalized schema to this path.
    #[arg(long)]
    output: Option<PathBuf>,
}

#[derive(Debug, Args)]
struct ProviderGenerateArgs {
    /// Generate only this provider from inframe.toml.
    provider: Option<String>,
    /// Override the configured provider source (requires --version).
    #[arg(long, requires = "version")]
    source: Option<String>,
    /// Override the configured provider version (requires --source).
    #[arg(long, requires = "source")]
    version: Option<String>,
    #[arg(long)]
    module_root: Option<String>,
    #[arg(long)]
    output: Option<PathBuf>,
    /// Read a raw `tofu providers schema -json` fixture instead of acquiring it.
    #[arg(long)]
    schema_json: Option<PathBuf>,
}

#[derive(Debug, Subcommand)]
enum GraphCommand {
    /// Validate structural invariants and all graph-local references.
    Validate(GraphPathArgs),
    /// Print a compact summary and derived dependency edges.
    Inspect(GraphPathArgs),
    /// Print the JSON Schema for Graph IR 1.x.
    Schema(GraphSchemaArgs),
}

#[derive(Debug, Args)]
struct GraphPathArgs {
    /// Graph IR path, or `-` for stdin. Omit to use a configured stack graph.
    #[arg(conflicts_with = "stack")]
    graph: Option<PathBuf>,
    /// Resolve the last built graph for this project stack.
    #[arg(long, required_unless_present = "graph")]
    stack: Option<String>,
}

#[derive(Debug, Args)]
struct GraphSchemaArgs {
    /// Output path, or `-` for stdout.
    #[arg(long, default_value = "-")]
    output: PathBuf,
}

#[derive(Debug, Args)]
struct RenderArgs {
    /// Graph IR path, or `-` for stdin.
    #[arg(long)]
    graph: PathBuf,
    /// Output path, or `-` for stdout.
    #[arg(long)]
    output: PathBuf,
}

#[derive(Debug, Args)]
struct RunArgs {
    #[arg(long)]
    stack: String,
    /// Graph IR path, or `-` for stdin.
    #[arg(long)]
    graph: Option<PathBuf>,
    #[arg(long)]
    workspace: Option<PathBuf>,
    /// Arguments passed directly to `OpenTofu` after `--`.
    #[arg(last = true)]
    tofu_args: Vec<OsString>,
}

#[derive(Debug, Args)]
struct ExistingStackArgs {
    #[arg(long)]
    stack: String,
    #[arg(long)]
    workspace: Option<PathBuf>,
    /// Arguments passed directly to `OpenTofu` after `--`.
    #[arg(last = true)]
    tofu_args: Vec<OsString>,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Command::Project { command } => project_command(&command, &cli.project),
        Command::Build(arguments) => build_project(&arguments, &cli.project),
        Command::Provider { command } => provider_command(command, &cli.project, &cli.tofu_binary),
        Command::Graph { command } => graph_command(command, &cli.project),
        Command::Render(arguments) => render(&arguments),
        Command::Init(arguments) => run_graph("init", &arguments, &cli.project, &cli.tofu_binary),
        Command::Validate(arguments) => {
            run_graph("validate", &arguments, &cli.project, &cli.tofu_binary)
        }
        Command::Plan(arguments) => run_graph("plan", &arguments, &cli.project, &cli.tofu_binary),
        Command::Apply(arguments) => run_graph("apply", &arguments, &cli.project, &cli.tofu_binary),
        Command::Destroy(arguments) => {
            run_graph("destroy", &arguments, &cli.project, &cli.tofu_binary)
        }
        Command::Show(arguments) => {
            run_existing_json("show", &arguments, &cli.project, &cli.tofu_binary)
        }
        Command::Output(arguments) => {
            run_existing_json("output", &arguments, &cli.project, &cli.tofu_binary)
        }
    }
}

fn project_command(command: &ProjectCommand, project_path: &Path) -> Result<()> {
    match command {
        ProjectCommand::Init => {
            project::initialize(project_path)?;
            println!("created {}", project_path.display());
            Ok(())
        }
    }
}

fn build_project(arguments: &BuildArgs, project_path: &Path) -> Result<()> {
    let project = Project::load(project_path)?;
    let (_, path) = project.build(&arguments.stack, arguments.output.as_deref())?;
    println!("built stack `{}` to {}", arguments.stack, path.display());
    Ok(())
}

fn provider_command(
    command: ProviderCommand,
    project_path: &Path,
    tofu_binary: &Path,
) -> Result<()> {
    match command {
        ProviderCommand::Inspect(arguments) => {
            let request = ProviderRequest {
                source: arguments.source,
                version: arguments.version,
            };
            let schema = load_provider_schema(&request, arguments.schema_json, tofu_binary)?;
            println!("provider: {}@{}", schema.source, schema.version);
            println!("resources: {}", schema.resources.len());
            println!("data sources: {}", schema.data_sources.len());
            println!("sha256: {}", schema.sha256()?);
            if let Some(output) = arguments.output {
                write_text(&output, &schema.canonical_json()?)?;
            }
            Ok(())
        }
        ProviderCommand::Generate(arguments) => {
            generate_providers(arguments, project_path, tofu_binary)
        }
    }
}

#[derive(Debug)]
struct ProviderGeneration {
    source: String,
    version: String,
    module_root: String,
    output: PathBuf,
}

fn generate_providers(
    arguments: ProviderGenerateArgs,
    project_path: &Path,
    tofu_binary: &Path,
) -> Result<()> {
    let mut providers = if let (Some(source), Some(version)) =
        (arguments.source.as_ref(), arguments.version.as_ref())
    {
        let name = arguments
            .provider
            .clone()
            .unwrap_or_else(|| provider_name(source).to_owned());
        let output = match arguments.output.clone() {
            Some(output) => output,
            None if project_path.is_file() => {
                Project::load(project_path)?.default_provider_output(&name)
            }
            None => PathBuf::from("purescript/.generated").join(&name),
        };
        vec![ProviderGeneration {
            source: source.clone(),
            version: version.clone(),
            module_root: arguments
                .module_root
                .clone()
                .unwrap_or_else(|| pascal_case(&name)),
            output,
        }]
    } else {
        Project::load(project_path)?
            .provider_generations(arguments.provider.as_deref())?
            .into_iter()
            .map(|provider| ProviderGeneration {
                source: provider.source,
                version: provider.version,
                module_root: provider.module_root,
                output: provider.output,
            })
            .collect()
    };

    if providers.len() > 1
        && (arguments.module_root.is_some()
            || arguments.output.is_some()
            || arguments.schema_json.is_some())
    {
        bail!(
            "--module-root, --output, and --schema-json require selecting one configured provider"
        );
    }
    if let Some(provider) = providers.first_mut() {
        if let Some(module_root) = arguments.module_root {
            provider.module_root = module_root;
        }
        if let Some(output) = arguments.output {
            provider.output = output;
        }
    }

    for provider in providers {
        let request = ProviderRequest {
            source: provider.source,
            version: provider.version,
        };
        let schema = load_provider_schema(&request, arguments.schema_json.clone(), tofu_binary)?;
        let hash = schema.sha256()?;
        let bindings = derive_bindings(&schema).context("failed to derive provider bindings")?;
        let generated = render_package(&bindings, &provider.module_root, &hash)
            .context("failed to render PureScript package")?;
        generated
            .write_to(&provider.output)
            .with_context(|| format!("failed to write {}", provider.output.display()))?;
        println!(
            "generated {} resources and {} data sources in {}",
            bindings.resources.len(),
            bindings.data_sources.len(),
            provider.output.display()
        );
    }
    Ok(())
}

fn provider_name(source: &str) -> &str {
    source.rsplit('/').next().unwrap_or(source)
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

fn load_provider_schema(
    request: &ProviderRequest,
    fixture: Option<PathBuf>,
    tofu_binary: &Path,
) -> Result<inframe_provider_schema::ProviderSchema> {
    if let Some(path) = fixture {
        let bytes = fs::read(&path).with_context(|| {
            format!("failed to read provider schema fixture {}", path.display())
        })?;
        if let Ok(schema) =
            serde_json::from_slice::<inframe_provider_schema::ProviderSchema>(&bytes)
        {
            if schema.source != request.source || schema.version != request.version {
                bail!(
                    "normalized schema identifies {}@{}, expected {}@{}",
                    schema.source,
                    schema.version,
                    request.source,
                    request.version
                );
            }
            Ok(schema)
        } else {
            normalize_schema(&bytes, request).context("failed to normalize provider schema fixture")
        }
    } else {
        SchemaAcquirer::new(tofu_binary)
            .acquire(request)
            .context("failed to acquire provider schema through OpenTofu")
    }
}

fn graph_command(command: GraphCommand, project_path: &Path) -> Result<()> {
    match command {
        GraphCommand::Validate(arguments) => {
            let graph = read_selected_graph(&arguments, project_path)?;
            graph.validate()?;
            println!("valid Graph IR {}", graph.format_version);
            Ok(())
        }
        GraphCommand::Inspect(arguments) => {
            let graph = read_selected_graph(&arguments, project_path)?;
            let dependencies = graph.dependencies()?;
            println!("format: {}", graph.format_version);
            println!("providers: {}", graph.required_providers.len());
            println!("resources: {}", graph.resources.len());
            println!("data sources: {}", graph.data_sources.len());
            println!("outputs: {}", graph.outputs.len());
            println!("dependencies: {}", dependencies.len());
            for dependency in dependencies {
                let kind = if dependency.explicit {
                    "explicit"
                } else {
                    "inferred"
                };
                println!("  {} -> {} ({kind})", dependency.from, dependency.to);
            }
            Ok(())
        }
        GraphCommand::Schema(arguments) => {
            let mut output = serde_json::to_string_pretty(&GraphDocument::json_schema())?;
            output.push('\n');
            write_text(&arguments.output, &output)
        }
    }
}

fn read_selected_graph(arguments: &GraphPathArgs, project_path: &Path) -> Result<GraphDocument> {
    if let Some(path) = &arguments.graph {
        return read_graph(path);
    }

    let stack = arguments
        .stack
        .as_deref()
        .context("either a graph path or --stack is required")?;
    let project = Project::load(project_path)?;
    project.stack(stack)?;
    let path = project.graph_path(stack);
    read_graph(&path).with_context(|| {
        format!(
            "no built graph found for stack `{stack}`; run `inframe build --stack {stack}` first"
        )
    })
}

fn render(arguments: &RenderArgs) -> Result<()> {
    let graph = read_graph(&arguments.graph)?;
    let output = to_pretty_json(&graph)?;
    write_text(&arguments.output, &output)
}

fn run_graph(
    command: &str,
    arguments: &RunArgs,
    project_path: &Path,
    tofu_binary: &Path,
) -> Result<()> {
    let (graph, workspace) = if let Some(path) = &arguments.graph {
        let graph = read_graph(path)?;
        let base = arguments
            .workspace
            .clone()
            .unwrap_or_else(|| PathBuf::from(".inframe"));
        (graph, Workspace::new(base, &arguments.stack)?)
    } else {
        let project = Project::load(project_path)?;
        let (graph, _) = project.build(&arguments.stack, None)?;
        let base = arguments
            .workspace
            .clone()
            .unwrap_or_else(|| project.workspace_directory());
        let workspace = Workspace::new(base, &arguments.stack)?;
        let (backend_kind, backend_config) = project.backend_json(&arguments.stack)?;
        workspace.write_backend(backend_kind, &backend_config)?;
        (graph, workspace)
    };
    workspace.write_graph(&graph)?;
    let environment = if matches!(command, "plan" | "apply" | "destroy") {
        secret_environment(&graph)?
    } else {
        BTreeMap::new()
    };
    OpenTofu::new(tofu_binary).run_with_env(
        &workspace,
        command,
        &arguments.tofu_args,
        &environment,
    )?;
    Ok(())
}

fn run_existing_json(
    command: &str,
    arguments: &ExistingStackArgs,
    project_path: &Path,
    tofu_binary: &Path,
) -> Result<()> {
    let base = match &arguments.workspace {
        Some(workspace) => workspace.clone(),
        None if project_path.is_file() => Project::load(project_path)?.workspace_directory(),
        None => PathBuf::from(".inframe"),
    };
    let workspace = Workspace::new(base, &arguments.stack)?;
    if !workspace.root().is_dir() {
        bail!(
            "stack workspace does not exist: {}",
            workspace.root().display()
        );
    }
    let value =
        OpenTofu::new(tofu_binary).output_json(&workspace, command, &arguments.tofu_args)?;
    println!("{}", serde_json::to_string_pretty(&value)?);
    Ok(())
}

fn secret_environment(graph: &GraphDocument) -> Result<BTreeMap<OsString, OsString>> {
    graph
        .secret_environment_names()
        .into_iter()
        .map(|name| {
            let value = env::var_os(&name).with_context(|| {
                format!("required secret environment variable `{name}` is not set")
            })?;
            let target = format!("TF_VAR_{}", secret_variable_name(&name));
            Ok((OsString::from(target), value))
        })
        .collect()
}

fn read_graph(path: &Path) -> Result<GraphDocument> {
    let mut input = Vec::new();
    if path == Path::new("-") {
        io::stdin()
            .read_to_end(&mut input)
            .context("failed to read Graph IR from stdin")?;
    } else {
        input = fs::read(path)
            .with_context(|| format!("failed to read Graph IR from {}", path.display()))?;
    }
    serde_json::from_slice(&input).context("failed to decode Graph IR JSON")
}

fn write_text(path: &Path, contents: &str) -> Result<()> {
    if path == Path::new("-") {
        print!("{contents}");
        Ok(())
    } else {
        if let Some(parent) = path
            .parent()
            .filter(|parent| !parent.as_os_str().is_empty())
        {
            fs::create_dir_all(parent)
                .with_context(|| format!("failed to create {}", parent.display()))?;
        }
        fs::write(path, contents).with_context(|| format!("failed to write {}", path.display()))
    }
}
