use std::ffi::OsString;
use std::fs;
use std::io::{self, Read};
use std::path::{Path, PathBuf};

use anyhow::{Context, Result, bail};
use clap::{Args, Parser, Subcommand};
use tofu_dag_binding_model::derive_bindings;
use tofu_dag_emit_purescript::render_package;
use tofu_dag_graph_ir::GraphDocument;
use tofu_dag_opentofu::{OpenTofu, Workspace, to_pretty_json};
use tofu_dag_provider_schema::{ProviderRequest, SchemaAcquirer, normalize_schema};

#[derive(Debug, Parser)]
#[command(
    name = "tofu-dag",
    version,
    about = "Pure graph frontend and compiler for OpenTofu"
)]
struct Cli {
    #[arg(long, global = true, default_value = "tofu")]
    tofu_binary: PathBuf,
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
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
    #[arg(long)]
    source: String,
    #[arg(long)]
    version: String,
    #[arg(long, default_value = "DigitalOcean")]
    module_root: String,
    #[arg(long)]
    output: PathBuf,
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
    /// Graph IR path, or `-` for stdin.
    graph: PathBuf,
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
    graph: PathBuf,
    #[arg(long, default_value = ".tofu-dag")]
    workspace: PathBuf,
    /// Arguments passed directly to `OpenTofu` after `--`.
    #[arg(last = true)]
    tofu_args: Vec<OsString>,
}

#[derive(Debug, Args)]
struct ExistingStackArgs {
    #[arg(long)]
    stack: String,
    #[arg(long, default_value = ".tofu-dag")]
    workspace: PathBuf,
    /// Arguments passed directly to `OpenTofu` after `--`.
    #[arg(last = true)]
    tofu_args: Vec<OsString>,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Command::Provider { command } => provider_command(command, &cli.tofu_binary),
        Command::Graph { command } => graph_command(command),
        Command::Render(arguments) => render(&arguments),
        Command::Init(arguments) => run_graph("init", &arguments, &cli.tofu_binary),
        Command::Validate(arguments) => run_graph("validate", &arguments, &cli.tofu_binary),
        Command::Plan(arguments) => run_graph("plan", &arguments, &cli.tofu_binary),
        Command::Apply(arguments) => run_graph("apply", &arguments, &cli.tofu_binary),
        Command::Destroy(arguments) => run_graph("destroy", &arguments, &cli.tofu_binary),
        Command::Show(arguments) => run_existing_json("show", &arguments, &cli.tofu_binary),
        Command::Output(arguments) => run_existing_json("output", &arguments, &cli.tofu_binary),
    }
}

fn provider_command(command: ProviderCommand, tofu_binary: &Path) -> Result<()> {
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
            let request = ProviderRequest {
                source: arguments.source,
                version: arguments.version,
            };
            let schema = load_provider_schema(&request, arguments.schema_json, tofu_binary)?;
            let hash = schema.sha256()?;
            let bindings =
                derive_bindings(&schema).context("failed to derive provider bindings")?;
            let generated = render_package(&bindings, &arguments.module_root, &hash)
                .context("failed to render PureScript package")?;
            generated
                .write_to(&arguments.output)
                .with_context(|| format!("failed to write {}", arguments.output.display()))?;
            println!(
                "generated {} resources and {} data sources in {}",
                bindings.resources.len(),
                bindings.data_sources.len(),
                arguments.output.display()
            );
            Ok(())
        }
    }
}

fn load_provider_schema(
    request: &ProviderRequest,
    fixture: Option<PathBuf>,
    tofu_binary: &Path,
) -> Result<tofu_dag_provider_schema::ProviderSchema> {
    if let Some(path) = fixture {
        let bytes = fs::read(&path).with_context(|| {
            format!("failed to read provider schema fixture {}", path.display())
        })?;
        normalize_schema(&bytes, request).context("failed to normalize provider schema fixture")
    } else {
        SchemaAcquirer::new(tofu_binary)
            .acquire(request)
            .context("failed to acquire provider schema through OpenTofu")
    }
}

fn graph_command(command: GraphCommand) -> Result<()> {
    match command {
        GraphCommand::Validate(arguments) => {
            let graph = read_graph(&arguments.graph)?;
            graph.validate()?;
            println!("valid Graph IR {}", graph.format_version);
            Ok(())
        }
        GraphCommand::Inspect(arguments) => {
            let graph = read_graph(&arguments.graph)?;
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

fn render(arguments: &RenderArgs) -> Result<()> {
    let graph = read_graph(&arguments.graph)?;
    let output = to_pretty_json(&graph)?;
    write_text(&arguments.output, &output)
}

fn run_graph(command: &str, arguments: &RunArgs, tofu_binary: &Path) -> Result<()> {
    let graph = read_graph(&arguments.graph)?;
    let workspace = Workspace::new(&arguments.workspace, &arguments.stack)?;
    workspace.write_graph(&graph)?;
    OpenTofu::new(tofu_binary).run(&workspace, command, &arguments.tofu_args)?;
    Ok(())
}

fn run_existing_json(
    command: &str,
    arguments: &ExistingStackArgs,
    tofu_binary: &Path,
) -> Result<()> {
    let workspace = Workspace::new(&arguments.workspace, &arguments.stack)?;
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
