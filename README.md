# Inframe

Inframe is an infrastructure-as-code interface that's actually nice to use, I hope. I'm
not a big fan of Pulumi's impurity or HCL's... everything. Inframe chooses a pure
functional approach in order to make composition, testing, and modularization
clear and easy to understand. It delegates the mechanics of resource creation
and state management to OpenTofu, and generates typed adapters for Terraform
providers in two frontend languages: LEAN 4 and PureScript. Both provide a pure
functional interface, but LEAN 4 allows more sophisticated validation and improved ergonomics.

Both frontends render the same intermediate representation.

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

```lean
def infrastructureFor (env : Environment) (databases : List Identifier) : Infra Unit := do
  let provider ← Provider.configure { token := secretEnv "DIGITALOCEAN_TOKEN" }

  let versions ← Data.KubernetesVersions.readWith "available" {}
    (dataSourceOptions |>.withProvider provider)

  let network ← Vpc.create "platform" { name := "platform", region := env.region }

  let cluster ← KubernetesCluster.createWith "platform"
    { name := "platform"
      region := env.region
      version := versions.latestVersion
      nodePool := { name := "workers", size := "s-2vcpu-4gb", nodeCount := 2, autoScale := true
                    minNodes := 2, maxNodes := env.workerMax }
      autoUpgrade := true
      vpcUuid := network.id }
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
database list, so the proof is an induction over that list.

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

A policy is a decidable proposition over the graph, so an invalid infrastructure
configuration will refuse to compile before even making it to OpenTofu.

Kernel `decide` is a proof, and its cost grows with the graph: forty instances
each carrying a four-kilobyte startup script take about nine seconds to
validate. For deployed graphs beyond that, `#assert_policy policy graph` and
`#assert_valid graph` evaluate the same checks with the compiled evaluator while
the module compiles and fail the build with the report. That is a check rather
than a proof, but it is the same gate: keep theorems for statements over every
input of a parameterized stack, and the assertions for the concrete instance.

Elements of computed nested blocks are traversed with the schema's types
(`instance.networkInterface[1].fields.networkIp`,
`instance.networkInterface.splat (·.networkIp)`), and names derived from data
carry their proofs (`site.indexed 3`, `net.slug "10.192.0.0/16"`,
`rule.append "22-tcp"`).

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
are gitignored build artifacts. Module names drop the provider's type prefix
(`google_compute_instance` becomes `ComputeInstance`); the prefix is inferred
from the provider name and its resource types, so a `google-beta` provider
strips `google_` rather than stuttering, and `strip_prefix = "google_"` in the
provider table (or `--strip-prefix`) pins it explicitly. Select one provider with `inframe provider
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

Each stack main prints one Graph IR document: in PureScript
`log (renderGraph infrastructure)`, in Lean `def main : IO Unit := emitGraph infrastructure`.
`emitGraph` renders compact JSON and writes it with `putStr`; it is the one
printing path the core's scale test exercises, and it is the whole of a stack's
`main`. Its optional test entry point runs assertions over the same pure
infrastructure value.
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
`--no-build` to the graph commands to look at the last built artifact instead,
which warns when any source under the stack's package changed after the
artifact was written. A frontend tool that fails is reported with its command
line, exit status, and stderr verbatim, and a tool that is missing from `PATH`
is named along with how to install it.
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
OpenTofu JSON into `.inframe/stacks/<stack>/`. When the stack configures a
`test` entry point, `init`, `validate`, `plan`, `apply`, `destroy`, and `tofu`
run it after building and stop if it fails, so a policy suite kept in its own
executable gates deployment and not only `inframe test`; `--skip-tests`
overrides that and says so on stderr, and a stack without a test entry point is
pointed out every time. A graph passed with `--graph` bypasses the project and
only the reference validator runs on it.

Secrets referenced with `secretEnv` are required only for the subcommands that
contact providers (`plan`, `apply`, `destroy`, and `refresh`, `import`, and
`console` through `inframe tofu`); Inframe passes them to OpenTofu as sensitive
variables without writing their values to Graph IR or OpenTofu configuration.

Anything else OpenTofu can do in the workspace goes through the same prepared
configuration with `inframe tofu --stack <name> -- <subcommand>`, for example
`-- state list`, `-- import digitalocean_droplet.web 12345`, or
`-- force-unlock <id>`.

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

### 7. Compose stacks through remote state

`terraform_remote_state` belongs to OpenTofu's builtin provider, which no
provider schema describes, so the Lean core ships it directly: `RemoteState.read`
adds the data source for a backend and exposes the other stack's outputs as
typed inputs. The backend and its non-secret configuration are the same values
the producing stack's `[stacks.<name>.backend]` table holds.

```lean
def infrastructure : Infra Unit := do
  let platform ← RemoteState.read "platform" (.gcs "acme-state" (prefix_ := "platform"))
  let cluster : Input String := platform.output "cluster_endpoint"
  let region : Input String := platform.outputOr "region" "nyc3"   -- `try` with a default
  …
```

`RemoteBackend` has constructors for `localFile`, `gcs`, `s3`, `azurerm`,
`http`, `kubernetes`, and `consul`, and `other` for any backend with its
configuration as known values. The type of an output is the consumer's claim
about what the producer exports; a policy over the consumer can still see the
reference as `data.terraform_remote_state.platform.outputs.<name>`.

### 8. Run the checks

```bash
cargo fmt --all -- --check
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings

cd purescript
spago test

cd lean
lake -q exe inframe-test
lake -q exe inframe-scale-test | inframe graph validate -
cd integration-digitalocean
lake build
```
