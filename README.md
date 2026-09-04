# Inframe

Inframe is an infrastructure as code tool that's actually good, I hope. I'm
not a big fan of Pulumi's impurity or HCL's... everything. Inframe chooses a
functional approach in order to make composition, testing, and modularization
clear and easy to understand. It delegates the mechanics of resource creation
and state management to OpenTofu, and can generate PureScript adapters for
Terraform modules.

> Disclosure: LLMs were used heavily to develop this iteration of Inframe. While
it's mostly data plumbing, be wary and look at your plans before applying if you
use this tool. It's quite experimental.

## Example

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

## How to use it

### 1. Install and build

You need Rust 1.85+, OpenTofu 1.10+, PureScript 0.15.16, and Spago 1.x. From
this repository:

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

By convention the package above goes to
`<purescript.directory>/.generated/digitalocean`. Generated adapters are
gitignored build artifacts. Select one with `inframe provider generate
digitalocean`; `--source`, `--version`, `--module-root`, and `--output` are
available for ad hoc generation or overrides. `--schema-json` accepts a raw or
normalized schema fixture for reproducible offline builds.

Point a Spago `extraPackages` entry at the conventional directory and depend on
the generated package:

```yaml
workspace:
  extraPackages:
    generated-digitalocean:
      path: .generated/digitalocean
```

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

[stacks.platform.backend]
type = "local"
```

Each entry point prints one Graph IR document with `renderGraph`. Reusable
infrastructure is just ordinary pure functions called while constructing its
`Infra` value.

### 4. Build and inspect the graph

```bash
inframe build --stack platform
inframe graph inspect --stack platform
inframe graph validate --stack platform
```

The graph commands resolve the last built artifact from `inframe.toml`.
`inspect` prints a tree of provider pins, configured arguments, resources, data
sources, symbolic outputs, moves, and dependency edges. An explicit JSON path
or `-` for stdin remains available for debugging. `build` does not invoke
OpenTofu or contact the cloud.

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
```
