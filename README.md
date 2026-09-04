# Inframe

Inframe is an infrastructure-as-code interface that's actually good, I hope. I'm
not a big fan of Pulumi's impurity or HCL's... everything. Inframe chooses a
functional approach in order to make composition, testing, and modularization
clear and easy to understand. It delegates the mechanics of resource creation
and state management to OpenTofu, and generates typed adapters for Terraform
providers in two frontend languages:

- **PureScript**: infrastructure is a pure `Infra` value; policies are ordinary
  tests over the graph.
- **Lean 4**: the same pure graph, plus compile-time proofs. Resource names are
  validated when the module compiles, the reference validator is a theorem,
  and policies are decidable propositions that the Lean kernel checks, for
  every parameterization of a stack at once.

Both frontends render the same Graph IR document for the same stack (CI diffs
them), and both are driven by the same `inframe` CLI.

> Disclosure: LLMs were used heavily to develop this iteration of Inframe. While
it's mostly data plumbing, be wary and look at your plans before applying if you
use this tool. It's quite experimental.

## Example in PureScript

This stack creates a shared VPC, an autoscaling managed Kubernetes cluster, a
versioned Spaces bucket, and an autoscaling PostgreSQL database.

```purescript
infrastructure :: Infra Unit
infrastructure = do
  provider <- DigitalOcean.configure $
    DigitalOcean.args {}
      # DigitalOcean.token (secretEnv "DIGITALOCEAN_TOKEN")

  versions <- KubernetesVersions.readWith "available"
    (KubernetesVersions.args {})
    (dataSourceOptions # withProvider provider)

  network <- Vpc.create "platform" $ Vpc.args
    { name: lit "platform"
    , region: lit "nyc3"
    }

  let
    workers =
      Kubernetes.nodePoolArgs
        { name: lit "workers"
        , size: lit "s-2vcpu-4gb"
        }
        # Kubernetes.nodePoolNodeCount (lit 2.0)
        # Kubernetes.nodePoolAutoScale (lit true)
        # Kubernetes.nodePoolMinNodes (lit 2.0)
        # Kubernetes.nodePoolMaxNodes (lit 6.0)

  cluster <- Kubernetes.createWith "platform"
    ( Kubernetes.args
        { name: lit "platform"
        , nodePool: [ workers ]
        , region: lit "nyc3"
        , version: computed versions.latestVersion
        }
        # Kubernetes.autoUpgrade (lit true)
        # Kubernetes.vpcUuid (computed network.id)
    )
    ( resourceOptions
        # withProvider provider
        # createBeforeDestroy true
    )

  let
    versioning =
      Spaces.versioningArgs {}
        # Spaces.versioningEnabled (lit true)

  bucket <- Spaces.create "assets" $
    Spaces.args { name: lit "replace-with-a-globally-unique-space-name" }
      # Spaces.region (lit "nyc3")
      # Spaces.versioning [ versioning ]

  let
    storageAutoscale =
      Database.storageAutoscaleArgs { enabled: lit true }
        # Database.storageAutoscaleThresholdPercent (lit 80.0)
        # Database.storageAutoscaleIncrementGib (lit 10.0)

  database <- Database.create "postgres" $
    Database.args
      { engine: lit "pg"
      , name: lit "platform-postgres"
      , nodeCount: lit 1.0
      , region: lit "nyc3"
      , size: lit "db-s-1vcpu-1gb"
      }
      # Database.privateNetworkUuid (computed network.id)
      # Database.storageAutoscale [ storageAutoscale ]
      # Database.version (lit "15")

  output "cluster_endpoint" cluster.endpoint
  output "bucket_endpoint" bucket.endpoint
  output "database_host" database.host
```

The graph is an ordinary PureScript value before it is serialized, so tests can
enforce policies across every resource. This test fails if any DigitalOcean
database in the stack is not connected to the managed VPC:

```purescript
main :: Effect Unit
main = do
  let graph = buildGraph infrastructure
  assert $ all databaseUsesManagedVpc graph.resources

databaseUsesManagedVpc :: ResourceSpec -> Boolean
databaseUsesManagedVpc resource
  | resource.resourceType /= "digitalocean_database_cluster" = true
  | otherwise = case Object.lookup "private_network_uuid" resource.arguments of
      Just (ResourceAttribute address path) ->
        address == "digitalocean_vpc.platform" && path == [ "id" ]
      _ -> false
```

## The same stack in Lean 4

The Lean 4 frontend is a Lake package with the same graph semantics, the same
Graph IR encoder, and generated adapters produced from the same binding model.
Known values are plain literals (they coerce to provider inputs), handle
attributes are symbolic inputs, and computed strings are shaped with OpenTofu's
own functions as dot-notation (`droplet.id.tonumber`, `name.replace " " "-"`)
or interpolated with `tf!"web-{droplet.id}.internal"`.
It is exercised in CI exactly like the PureScript one: the core library's
theorems and tests run, every generated DigitalOcean module compiles, the
integration stack is built and policy-checked through `inframe build` and
`inframe test`, and its output is validated by the Rust CLI. The platform stack
above, written in Lean, renders byte-identical Graph IR:

```lean
def infrastructureFor (env : Environment) (databases : List Identifier) : Infra Unit := do
  let provider ← Provider.configure (Provider.args {} |>.token (secretEnv "DIGITALOCEAN_TOKEN"))

  let versions ← Data.KubernetesVersions.readWith "available" (Data.KubernetesVersions.args {})
    (dataSourceOptions |>.withProvider provider)

  let network ← Vpc.create "platform" (Vpc.args
    { name := "platform"
      region := env.region })

  let workerPool :=
    KubernetesCluster.nodePoolArgs
      { name := "workers"
        size := "s-2vcpu-4gb" }
      |>.nodeCount 2
      |>.autoScale true
      |>.minNodes 2
      |>.maxNodes env.workerMax

  let cluster ← KubernetesCluster.createWith "platform"
    (KubernetesCluster.args
      { name := "platform"
        nodePool := [workerPool]
        region := env.region
        version := versions.latestVersion }
      |>.autoUpgrade true
      |>.vpcUuid network.id)
    (resourceOptions
      |>.withProvider provider
      |>.createBeforeDestroy true)

  -- One cluster per requested database, each on the VPC (plain recursion over the list).
  let clusters ← createDatabases env network databases

  output "cluster_endpoint" cluster.endpoint
  outputDatabaseHost clusters
```

The policy from the PureScript test becomes a theorem about every stack this
program can produce, not about one graph. The stack is a function of its
database list, so the proof is an induction over that list; the core's `run`
lemmas compute what each builder step adds to the graph. `lake build` (and
therefore `inframe test`) fails if the stack stops satisfying it:

```lean
def databaseRule (database : ResourceSpec) : Option String :=
  if database.argumentRefersTo "private_network_uuid" (.res "digitalocean_vpc" "platform") ["id"]
  then none
  else some "private_network_uuid must reference digitalocean_vpc.platform.id"

def databaseUsesManagedVpc : Policy :=
  Policy.resourcesOfType "database-uses-managed-vpc" "digitalocean_database_cluster" databaseRule

theorem databases_use_managed_vpc (env : Environment) (databases : List Identifier) :
    databaseUsesManagedVpc.Holds (buildGraph (infrastructureFor env databases)) := by
  rw [databaseUsesManagedVpc, Policy.resourcesOfType_holds_iff]
  simp only [buildGraph, infrastructureFor, Infra.run_bind, Infra.run_pure, run_output, ...]
  apply createDatabases_ok   -- induction on `databases`, see Infra/PlatformTest.lean
  ...
```

### What Lean adds over PureScript

- **Policies are checked by the compiler, for every input.** A policy is a
  decidable proposition over the graph, so `theorem … := by decide` makes
  `lake build` (and `inframe test`) fail on a violating stack. A stack that is
  a function of its inputs is proved for all of them: finite parameters by
  `cases … <;> decide`, and unbounded ones such as a list of databases by
  induction. A test only ever samples instantiations.
- **The graph is valid before the CLI sees it.** Logical names, aliases,
  outputs, and secret variable names carry validity proofs discharged from
  their literals, and the reference validator (duplicate addresses, dangling
  references, provider selection, replacement triggers, moves) is a theorem
  about the concrete graph rather than a later error from `inframe graph
  validate`.

Everything goes through kernel `decide`, never `native_decide`, so the trusted
base is the Lean kernel plus the Rust validator that still runs on the emitted
document. The emitter has been run against the DigitalOcean, Google, and AWS
providers; see [lean-stress-test.md](lean-stress-test.md).

## How to use it

### 1. Install and build

You need Rust 1.85+, OpenTofu 1.10+, and one frontend toolchain: PureScript
0.15.16 with Spago 1.x, or the Lean 4 toolchain pinned in `lean/lean-toolchain`
(install `elan`, which reads that file). From this repository:

```bash
cargo build -p inframe-cli
```

Use `cargo run -q -p inframe-cli --` in place of `inframe` below if the binary
is not on your `PATH`.

### 2. Configure and generate providers

Declare each pin once in `inframe.toml`:

```toml
[providers.digitalocean]
source = "digitalocean/digitalocean"
version = "2.100.0"
module_root = "DigitalOcean"
```

Then generate every configured provider:

```bash
inframe provider generate
```

This emits one package per configured frontend. By convention the PureScript
package above goes to `<purescript.directory>/.generated/digitalocean` and the
Lean package to `<lean.directory>/.generated/digitalocean`. Generated adapters
are gitignored build artifacts. Select one provider with `inframe provider
generate digitalocean` and one frontend with `--frontend purescript|lean`;
`--source`, `--version`, `--module-root`, and `--output` are available for ad
hoc generation or overrides. `--schema-json` accepts a raw or normalized schema
fixture for reproducible offline builds.

Point a Spago `extraPackages` entry at the conventional directory and depend on
the generated package:

```yaml
workspace:
  extraPackages:
    generated-digitalocean:
      path: .generated/digitalocean
```

A Lean project requires the generated package and the core library from its
`lakefile.toml`; the generated package's own lakefile already points at the
core library configured in `[lean.core]`:

```toml
[[require]]
name = "inframe"
path = ".."

[[require]]
name = "generated-digitalocean"
path = ".generated/digitalocean"
```

Generated adapters are ordinary PureScript source, so the PureScript language
server provides completion, inferred signatures, hover types, and navigation
after `spago build`. Open the configured `purescript` directory as the editor
workspace (or add it as a workspace folder) so the language server finds its
`spago.yaml`. Provider attribute descriptions are emitted as PureScript `-- |`
documentation on generated setters and as field catalogs on `Required` and
symbolic handle types. Those declarations appear in language-server hovers and
generated compiler documentation; direct record-field hovers may show only the
field type, depending on editor support.

### 3. Configure the project and stacks

`inframe project init` creates a starter `inframe.toml`. A project connects its
PureScript package and entry points to named OpenTofu stacks:

```toml
[purescript]
directory = "purescript"
package = "integration-digitalocean"
main = "Infra.Main"

[workspace]
directory = ".inframe"
graph_directory = ".inframe/graphs"

[stacks.smoke.backend]
type = "local"

[stacks.platform]
main = "Infra.Platform"
test = "Infra.PlatformTest"

[stacks.platform.backend]
type = "local"
```

Each stack main prints one Graph IR document with `renderGraph`; its optional
test entry point runs assertions over the same pure infrastructure value.
Reusable infrastructure is just ordinary pure functions called while
constructing its `Infra` value.

A project may instead, or additionally, declare a Lean frontend. For Lean
stacks `main` and `test` name Lake executables (`lake exe <name>`) whose root
modules print the graph and check policies; when both frontends are configured
each stack picks one:

```toml
[lean]
directory = "lean/integration-digitalocean"
main = "infra"
core = { path = "lean" }   # or { git = "https://github.com/by77er/inframe", rev = "...", subdir = "lean" }

[stacks.platform]
frontend = "lean"
main = "platform"
test = "platform-test"
```

This repository configures both: the `example` stack is PureScript and the
`lean-example` stack is Lean, and `make conformance` checks that they build the
same document.

### 4. Build, test, and inspect the graph

```bash
inframe build --stack platform
inframe test --stack platform
inframe graph inspect --stack platform
inframe graph validate --stack platform
```

Every command that takes `--stack` builds the stack first, so `inspect`,
`validate`, `plan`, and `apply` always reflect the current source; pass
`--no-build` to the graph commands to look at the last built artifact instead.
`inspect` prints a tree of provider pins, configured arguments, resources, data
sources, symbolic outputs, moves, and dependency edges. An explicit JSON path
or `-` for stdin remains available for debugging. `build` does not invoke
OpenTofu or contact the cloud. `test` runs the stack's configured test entry
point and preserves its exit status; the test library and structure remain the
project's choice. For a Lean stack the policy theorems in the test executable's
modules are checked by the compiler before the executable runs, so a violated
policy fails the build.

### 5. Initialize, validate, and apply

```bash
inframe init --stack platform -- -input=false
inframe validate --stack platform

export DIGITALOCEAN_TOKEN='...'
inframe plan --stack platform
inframe apply --stack platform
inframe output --stack platform
inframe destroy --stack platform
```

Lifecycle commands rebuild the configured entry point and write deterministic
OpenTofu JSON into `.inframe/stacks/<stack>/`. Secrets referenced with
`secretEnv` are required only for `plan`, `apply`, and `destroy`; Inframe passes
them to OpenTofu as sensitive variables without writing their values to Graph
IR or OpenTofu configuration.

### 6. Configure remote state

Inframe uses OpenTofu's built-in backends rather than vendoring a state server.
Select any backend per stack and keep only non-secret settings in
`inframe.toml`:

```toml
[stacks.prod.backend]
type = "http"

[stacks.prod.backend.config]
address = "https://state.example.com/states/prod"
lock_address = "https://state.example.com/states/prod/lock"
unlock_address = "https://state.example.com/states/prod/lock"
```

Supply credentials through that backend's standard environment variables—for
example, `TF_HTTP_USERNAME` and `TF_HTTP_PASSWORD`. Inframe rejects
secret-looking backend keys because OpenTofu may persist backend configuration
in its working directory.

### 7. Run the checks

```bash
cargo fmt --all -- --check
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings

cd purescript
spago test

cd lean
lake -q exe inframe-test
cd integration-digitalocean
lake build
```
