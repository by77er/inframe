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
It is exercised in CI exactly like the PureScript one: the core library's
theorems and tests run, every generated DigitalOcean module compiles, the
integration stack is built and policy-checked through `inframe build` and
`inframe test`, and its output is validated by the Rust CLI. The platform stack
above, written in Lean, renders byte-identical Graph IR:

```lean
def infrastructureFor (env : Environment) : Infra Unit := do
  let provider ← Provider.configure (Provider.args {} |>.token (secretEnv "DIGITALOCEAN_TOKEN"))

  let versions ← Data.KubernetesVersions.readWith "available" (Data.KubernetesVersions.args {})
    (dataSourceOptions |>.withProvider provider)

  let network ← Vpc.create "platform" (Vpc.args
    { name := lit "platform"
      region := lit env.region })

  let workerPool :=
    KubernetesCluster.nodePoolArgs
      { name := lit "workers"
        size := lit "s-2vcpu-4gb" }
      |>.nodeCount (lit 2)
      |>.autoScale (lit true)
      |>.minNodes (lit 2)
      |>.maxNodes (lit env.workerMax)

  let cluster ← KubernetesCluster.createWith "platform"
    (KubernetesCluster.args
      { name := lit "platform"
        nodePool := [workerPool]
        region := lit env.region
        version := versions.latestVersion }
      |>.autoUpgrade (lit true)
      |>.vpcUuid network.id)
    (resourceOptions
      |>.withProvider provider
      |>.createBeforeDestroy true)

  let database ← DatabaseCluster.create "postgres"
    (DatabaseCluster.args
      { engine := lit "pg"
        name := lit "platform-postgres"
        nodeCount := lit 1
        region := lit env.region
        size := lit "db-s-1vcpu-1gb" }
      |>.privateNetworkUuid network.id
      |>.version (lit "15"))

  output "cluster_endpoint" cluster.endpoint
  output "database_host" database.host
```

The policy from the PureScript test becomes a theorem. Lean's kernel evaluates
the policy over the concrete graph while the module compiles, so `lake build`
(and therefore `inframe test`) fails when the stack violates it. Because the
stack is a function of `Environment`, one theorem covers every environment:

```lean
def databaseUsesManagedVpc : Policy :=
  Policy.resourcesOfType "database-uses-managed-vpc" "digitalocean_database_cluster" fun database =>
    if database.argumentRefersTo "private_network_uuid" (.res "digitalocean_vpc" "platform") ["id"]
    then none
    else some "private_network_uuid must reference digitalocean_vpc.platform.id"

theorem platform_valid : (buildGraph infrastructure).Valid := by decide

theorem platform_policies (env : Environment) :
    databaseUsesManagedVpc.Holds (buildGraph (infrastructureFor env)) := by
  cases env <;> decide

theorem database_depends_on_vpc :
    (buildGraph infrastructure).dependsOn
      (.res "digitalocean_database_cluster" "postgres") (.res "digitalocean_vpc" "platform") = true := by
  decide
```

### What Lean adds over PureScript

- **Identifiers are checked at compile time.** `Tag.create "smoke" …` carries a
  proof that `"smoke"` is a valid OpenTofu identifier, discharged by `decide`
  from the string literal. The same applies to provider aliases, output names,
  `secretEnv` variable names, and function names in `unsafeCall`. In PureScript
  these are runtime strings that `inframe graph validate` rejects later.
- **The reference validator is a theorem.** `Graph.validate` is a Lean port of
  the Rust validator (duplicate addresses, dangling references, self
  dependencies, provider selection, replacement triggers, moves). `Graph.Valid g`
  is decidable, so `by decide` proves a concrete graph valid before the CLI
  ever sees it.
- **Policies are propositions, not assertions.** A `Policy` is a function from
  `Graph` to violations; `Policy.Holds policy graph` is decidable and proved by
  the kernel. The same value prints a human-readable report at run time.
- **Proofs quantify over parameters.** A stack that is a function of an
  environment, a region list, or any other finite type is proved for all inputs
  with `cases … <;> decide`; a test only ever checks one instantiation.
- **Structural facts are theorems too.** Dependency edges (`Graph.dependsOn`),
  the set of secrets a stack needs (`Graph.secretEnvironmentNames`), and
  expression equality are all decidable, so refactors cannot silently reroute a
  reference.
- **Exact numbers.** Provider numbers are decimal `Number` literals rather than
  IEEE doubles, so `lit 2` serializes as `2` and compares exactly.
- **Ergonomics.** `Expr α` coerces to `Input α` (no `computed` wrapper), setters
  are namespaced (`|>.nodeCount (lit 2)` instead of `nodePoolNodeCount`), and
  handle fields carry provider documentation as hover text.

Everything is checked by kernel `decide`; the Lean frontend never uses
`native_decide`, so the trusted base is the Lean kernel plus the Rust validator
that still runs on the emitted document.

### Stress test

The Lean emitter was exercised against three provider schemas by generating a
package and running `lake build` on every module:

| Provider | Modules | Generate | Package | `lake build`, clean (wall, 20 cores) |
| --- | --- | --- | --- | --- |
| `digitalocean/digitalocean` 2.100.0 | 156 | < 1 s | 2 MB | 7 s |
| `hashicorp/google` 8.1.0 | 1,797 | 1.6 s | 23 MB | 2 min 13 s (10 threads, 4.1 GB peak) |
| `hashicorp/aws` 6.63.0 | 2,394 | 13 s | 24 MB | 2 min 27 s (10 threads, 4.1 GB peak) |

Every module of all three providers compiles. The runs found six reserved
words that the emitter now escapes (`continue`, `from`, `prefix`, `public`,
`meta`, `matches`) and one scaling problem that changed the emitter's design.
Six AWS resources (the WAF rule, rule group, and web ACL resources and the
QuickSight dashboard, template, and analysis resources) unroll recursive nested
blocks to 8,000 to 21,000 block paths each. Emitted one type per path, they
were 19 to 59 MB of Lean apiece, the AWS package was 213 MB, and the smallest of
them could not be elaborated within 15 GB; building the package with Lake's
default parallelism exhausted a 23 GB machine. Those paths have only 49 to 424
structurally distinct shapes, so the emitter now declares each shape once and
reuses it: the worst module is 244 KB and compiles in two seconds, and the
package fits in 24 MB. Lake has no jobs flag; if you ever need to bound its
parallelism, set `LEAN_NUM_THREADS=N`.

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
