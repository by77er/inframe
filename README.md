# Inframe

Inframe is an infrastructure-as-code interface that's actually nice to use, I hope. I'm
not a big fan of Pulumi's impurity or HCL's... everything. Inframe chooses a pure
functional approach in order to make composition, testing, and modularization
clear and easy to understand. It delegates the mechanics of resource creation
and state management to OpenTofu, and generates typed adapters for Terraform
providers in two frontend languages: Lean 4 and PureScript. Both provide a pure
functional interface, but Lean 4 allows more sophisticated validation and improved ergonomics.

Both frontends render the same intermediate representation.

> Disclosure: LLMs were used heavily to develop this iteration of Inframe. While
it's mostly data plumbing, be wary and look at your plans before applying if you
use this tool. It's quite experimental.

This file is the tour and the quick start. [GUIDE.md](GUIDE.md) is the reference
for everything past that, and [inframe-design.md](inframe-design.md) is the design.

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
        # Kubernetes.nodePoolTags (lit [ "platform", "workers" ])

  cluster <- Kubernetes.createWith "platform"
    ( Kubernetes.args
        { name: lit "platform"
        , nodePool: [ workers ]
        , region: lit "nyc3"
        , version: computed versions.latestVersion
        }
        # Kubernetes.autoUpgrade (lit true)
        # Kubernetes.ha (lit true)
        # Kubernetes.surgeUpgrade (lit true)
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
def infrastructure : Infra Unit := do
  let provider ← Provider.configure { token := secretEnv "DIGITALOCEAN_TOKEN" }

  let versions ← Data.KubernetesVersions.readWith "available" {}
    (dataSourceOptions |>.withProvider provider)

  let network ← Vpc.create "platform" { name := "platform", region := "nyc3" }

  let cluster ← KubernetesCluster.createWith "platform"
    { name := "platform"
      region := "nyc3"
      version := versions.latestVersion
      nodePool :=
        { name := "workers", size := "s-2vcpu-4gb", nodeCount := 2, autoScale := true
          minNodes := 2, maxNodes := 6, tags := ["platform", "workers"] }
      autoUpgrade := true
      ha := true
      surgeUpgrade := true
      vpcUuid := network.id }
    (resourceOptions
      |>.withProvider provider
      |>.createBeforeDestroy true)

  let bucket ← SpacesBucket.create "assets"
    { name := "replace-with-a-globally-unique-space-name"
      region := "nyc3"
      versioning := some { enabled := true } }

  let database ← DatabaseCluster.create "postgres"
    { engine := "pg"
      name := "platform-postgres"
      nodeCount := 1
      region := "nyc3"
      size := "db-s-1vcpu-1gb"
      privateNetworkUuid := network.id
      storageAutoscale := some { enabled := true, thresholdPercent := 80, incrementGib := 10 }
      version := "15" }

  output "cluster_endpoint" cluster.endpoint
  output "bucket_endpoint" bucket.endpoint
  output "database_host" database.host
```

The two programs render byte-identical Graph IR; `make conformance` checks that
on every change. Note what the types did along the way: `nodePool` is a single
record because the schema requires exactly one, `versioning` is an `Option`
because it allows at most one, and `network.id` is an `Input String` that
carries the dependency edge with it.

### Policies become theorems

In the repository this stack is a function, `infrastructureFor env databases`,
and the `infrastructure` above is `infrastructureFor .prod [postgres]`. The
policy from the PureScript test then becomes a theorem about every stack the
function can produce, not a check of one graph. The stack is built by recursion
over the database list, so the proof is an induction over it:

```lean
def databaseRule (database : ResourceSpec) : Option String :=
  if database.argumentRefersTo DatabaseCluster.names.privateNetworkUuid
      (.res "digitalocean_vpc" "platform") [Vpc.names.id]
  then none
  else some "private_network_uuid must reference digitalocean_vpc.platform.id"

def databaseUsesManagedVpc : Policy :=
  Policy.resourcesOfType "database-uses-managed-vpc" "digitalocean_database_cluster" databaseRule

theorem databases_use_managed_vpc (env : Environment) (databases : List Identifier) :
    databaseUsesManagedVpc.Holds (buildGraph (infrastructureFor env databases)) := by
  rw [databaseUsesManagedVpc, Policy.resourcesOfType_holds_iff]
  simp only [buildGraph, infrastructureFor, Infra.run_bind, Infra.run_pure, run_output, …]
  apply createDatabases_ok   -- induction over `databases`; see Infra/PlatformTest.lean
  …
```

The compiler checks the theorems, so `inframe test --stack lean-example` fails
on a violation, and so does every `plan` and `apply`, which run the tests
first. The full proof is in `lean/integration-digitalocean/Infra/PlatformTest.lean`.

### What Lean adds over PureScript

- A policy is a decidable proposition over the graph, so
  `theorem valid : (buildGraph infrastructure).Valid := by decide` is checked at
  compile time. For graphs too large for kernel `decide`, `#assert_valid` and
  `#assert_policy` evaluate the same checks at compile time instead.
- The schema's block-count rules are types: a block allowed at most once is an
  `Option`, one required exactly once is a plain record. Two `versioning` blocks
  or an empty `nodePool` do not type-check.
- Argument and attribute names come from generated `names` records, so a schema
  rename is a compile error rather than a policy that silently matches nothing.
- Names derived from data carry their proofs: `site.indexed 3` and
  `zone.slug host` are accepted wherever a literal name is.

## Quick start

You need Rust 1.85+, OpenTofu 1.10+, and a frontend toolchain: `elan` for
Lean 4 (it installs the version pinned in `lean/lean-toolchain`), or PureScript
0.15.16 with Spago 1.x.

Build the CLI and run the bundled DigitalOcean stack. `build`, `test`, and
`inspect` never run OpenTofu or contact the cloud.

```bash
cargo build -p inframe-cli             # or use `cargo run -q -p inframe-cli --` as `inframe`
inframe provider generate              # typed DigitalOcean adapters for both frontends

inframe build --stack lean-example     # Graph IR into .inframe/graphs/
inframe test --stack lean-example      # policy proofs and assertions
inframe graph inspect --stack lean-example

export DIGITALOCEAN_TOKEN='…'
inframe init --stack lean-example -- -input=false
inframe plan --stack lean-example
inframe apply --stack lean-example     # creates billable resources
inframe destroy --stack lean-example
```

`--stack example` is the PureScript twin of the same stack.

### Your own project

`inframe project init` writes a starter `inframe.toml`. Pin each provider once,
and declare a frontend and a stack:

```toml
[providers.digitalocean]
source = "digitalocean/digitalocean"
version = "2.100.0"
module_root = "DigitalOcean"

[lean]
directory = "lean"
main = "infra"          # Lake executables: `lake exe infra` prints the graph,
test = "infra-test"     # `lake exe infra-test` checks the policies
core = { git = "https://github.com/by77er/inframe", rev = "main", subdir = "lean" }

[stacks.dev.backend]
type = "local"
```

`inframe provider generate` emits a package per configured frontend at
`<directory>/.generated/<provider>`; gitignore it. The frontend package requires
it and the core, and pins the same toolchain as the core (copy
`lean/lean-toolchain`):

```toml
# lean/lakefile.toml
[[require]]
name = "inframe"
git = "https://github.com/by77er/inframe"
rev = "main"
subDir = "lean"

[[require]]
name = "generated-digitalocean"
path = ".generated/digitalocean"

[[lean_lib]]
name = "Infra"
globs = ["Infra.+"]

[[lean_exe]]
name = "infra"
root = "Infra.Main"

[[lean_exe]]
name = "infra-test"
root = "Infra.Test"
```

A stack's `main` builds an `Infra Unit` and prints it, and that is the whole of
it: `def main : IO Unit := emitGraph infrastructure`. The test executable holds
the policies. From there the commands are the ones above with `--stack dev`.

For PureScript, the project table is `[purescript]` with `directory`, `package`,
and `main` (a module whose `main` is `log (renderGraph infrastructure)`), the
stack says `frontend = "purescript"`, and Spago sees the generated package
through an `extraPackages` entry. [GUIDE.md](GUIDE.md) has both wirings in full,
the `inframe.toml` reference, how to read a generated module, remote state, and
adopting resources that already exist.

## Development

```bash
make check         # fmt, clippy, and both frontend packages build
make test          # Rust, PureScript, and Lean suites, plus the negative Lean cases
make conformance   # both frontends render byte-identical Graph IR for the platform stack
```
