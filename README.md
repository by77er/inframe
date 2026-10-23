# Inframe

Inframe is an infrastructure-as-code interface that's actually nice to use, I hope. I'm
not a big fan of Pulumi's impurity or HCL's... everything. Inframe chooses a pure
functional approach in order to make composition, testing, and modularization
clear and easy to understand. It delegates the mechanics of resource creation
and state management to OpenTofu, and generates typed adapters for Terraform
providers in two frontend languages: Lean 4 and PureScript. Both provide a pure
functional interface, but Lean 4 allows more sophisticated validation and improved ergonomics.

Both frontends render the same intermediate representation.

## Example

This Lean 4 stack creates a private network (VPC), a Kubernetes cluster, a
storage bucket, and a PostgreSQL database on DigitalOcean:

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

`network.id` is a reference, not a copied string, so Inframe knows the cluster
and database depend on the VPC. The types come from the provider's schema: the
cluster needs exactly one node pool, so `nodePool` is a plain record, and the
bucket allows at most one `versioning` block, so it's an `Option`. Get either
wrong and it won't compile.

PureScript is also available as a simpler option. It produces the same output
for the same stack, but it can't check as much at compile time or do the proofs
below.

## Proofs

Policy tools like OPA and Sentinel check one plan at a time. If your stack takes
inputs, like an environment or a list of databases, the most they can tell you
is that today's inputs are fine.

With Lean, you can prove a rule holds for every input the stack could ever be
given. Take this rule, which says every database must be on the VPC:

```lean
def databaseRule (database : ResourceSpec) : Option String :=
  if database.argumentRefersTo DatabaseCluster.names.privateNetworkUuid
      (.res "digitalocean_vpc" "platform") [Vpc.names.id]
  then none
  else some "private_network_uuid must reference digitalocean_vpc.platform.id"

def databaseUsesManagedVpc : Policy :=
  Policy.resourcesOfType "database-uses-managed-vpc" "digitalocean_database_cluster" databaseRule
```

In this repository, the stack above is a function of an environment and a list
of databases. This theorem says the rule holds for every environment and every
list, including lists nobody has written yet:

```lean
theorem databases_use_managed_vpc (env : Environment) (databases : List Identifier) :
    databaseUsesManagedVpc.Holds (buildGraph (infrastructureFor env databases)) := by
  …
```

If a change would let even one possible input put a database off the VPC, the
proof stops compiling. Inframe checks it before every `plan` and `apply`, so
that change never reaches the cloud. The full proof is in
[`PlatformTest.lean`](lean/integration-digitalocean/Infra/PlatformTest.lean).

## Getting started

You'll need Rust 1.85+, OpenTofu 1.10+, and
[`elan`](https://github.com/leanprover/elan), which installs the Lean version
this project pins. For PureScript, you'll need PureScript 0.15.16 and Spago 1.x
instead.

Install the CLI and build the example stack. These commands don't run OpenTofu
or touch the cloud:

```bash
cargo install --path crates/cli        # installs `inframe`
inframe provider generate              # generate typed DigitalOcean bindings
inframe build --stack lean-example     # render the stack
inframe test --stack lean-example      # check its policies
```

To deploy it:

```bash
export DIGITALOCEAN_TOKEN='…'
inframe init --stack lean-example
inframe plan --stack lean-example
inframe apply --stack lean-example     # creates real, billable resources
inframe destroy --stack lean-example
```

For your own project, run `inframe project init` to create an `inframe.toml`,
then see the [guide](GUIDE.md).

## Documentation

- [GUIDE.md](GUIDE.md): project setup, generated bindings, remote state, and
  importing existing resources
- [inframe-design.md](inframe-design.md): the design

## Development

```bash
make check         # formatting, lints, and builds
make test          # all test suites
make conformance   # Lean and PureScript produce identical output
```

## License

[MIT](LICENSE-MIT) or [Apache 2.0](LICENSE-APACHE), at your option.
