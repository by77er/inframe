# Inframe guide

The reference for everything the [README](README.md) quick start leaves out.
The reasoning behind the design is in [inframe-design.md](inframe-design.md).

- [Project configuration](#project-configuration)
- [Generating providers](#generating-providers)
- [Wiring a frontend package](#wiring-a-frontend-package)
- [Reading a generated Lean module](#reading-a-generated-lean-module)
- [Stack entry points](#stack-entry-points)
- [Build, test, and inspect](#build-test-and-inspect)
- [Plan, apply, and the rest of the lifecycle](#plan-apply-and-the-rest-of-the-lifecycle)
- [Adopting existing infrastructure](#adopting-existing-infrastructure)
- [Remote state](#remote-state)
- [Composing stacks through remote state](#composing-stacks-through-remote-state)
- [Proofs versus assertions](#proofs-versus-assertions)

## Project configuration

`inframe project init` creates a starter `inframe.toml` without overwriting an
existing one. A project connects frontend packages and their entry points to
named OpenTofu stacks. This repository configures both frontends:

```toml
[purescript]
directory = "purescript"
package = "integration-digitalocean"
main = "Infra.Main"

[lean]
directory = "lean/integration-digitalocean"
main = "infra"
core = { path = "lean" }   # or { git = "https://github.com/by77er/inframe", rev = "…", subdir = "lean" }

[providers.digitalocean]
source = "digitalocean/digitalocean"
version = "2.100.0"
module_root = "DigitalOcean"

[workspace]
directory = ".inframe"
graph_directory = ".inframe/graphs"

[stacks.example]
frontend = "purescript"
main = "Infra.Platform"
test = "Infra.PlatformTest"

[stacks.example.backend]
type = "local"

[stacks.lean-example]
frontend = "lean"
main = "platform"
test = "platform-test"

[stacks.lean-example.gate]
module = "Infra.PlatformTest"
program = "infrastructure"
policy = "policies"
proof = "platform_gate"

[stacks.lean-example.backend]
type = "local"
```

- `[purescript]`: the Spago workspace `directory`, the `package` that holds the
  stacks, and the default `main` module.
- `[lean]`: the Lake package `directory`, the default `main` and optional `test`
  executables (`lake exe <name>`), and `core`, which is where the generated
  package finds the core library: a `path` for a checkout of this repository, or
  a `git` source with `rev` and `subdir = "lean"`.
- `[providers.<name>]`: `source` and `version` pin the provider; `module_root`
  names the generated top-level module; `strip_prefix` overrides the inferred
  resource-type prefix (see below).
- `[workspace]`: where prepared OpenTofu configurations and built graphs go.
- `[stacks.<name>]`: `main` and `test` override the frontend defaults; when
  both frontends are configured, `frontend` picks one. The `backend` table is
  OpenTofu's backend for that stack (see [Remote state](#remote-state)).
- `[stacks.<name>.gate]` (Lean only): the statement that gates deployment.
  `program` and `policy` are Lean names visible from `module`, and `proof`
  names a theorem of `Inframe.Gated policy program`. See
  [The deployment gate](#the-deployment-gate).

The `example` stack here is PureScript and `lean-example` is Lean, and
`make conformance` checks that they build byte-identical Graph IR.

## Generating providers

```bash
inframe provider generate                                  # every configured provider and frontend
inframe provider generate digitalocean --frontend lean     # one provider, one frontend
```

Each run emits one package per configured frontend. By convention the
PureScript package goes to `<purescript.directory>/.generated/<provider>` and
the Lean package to `<lean.directory>/.generated/<provider>`. Generated adapters
are build artifacts; gitignore them.

Module names drop the provider's type prefix, so `google_compute_instance`
becomes `ComputeInstance`. The prefix is inferred from the provider name and
its resource types, so a `google-beta` provider strips `google_` rather than
stuttering; `strip_prefix = "google_"` in the provider table (or
`--strip-prefix`) pins it explicitly.

`--source`, `--version`, `--module-root`, and `--output` cover ad hoc generation
or one-off overrides without touching `inframe.toml`.

If a provider's schema does not decode, `--schema-json` is the escape hatch:
acquire the raw document yourself (`tofu providers schema -json` in a temporary
directory whose configuration pins the provider in `required_providers`, or
`inframe provider inspect --source … --version … --output schema.json`), fix or
trim it, and pass it in. Raw and normalized documents are both accepted, which
also makes offline builds reproducible.

## Wiring a frontend package

### Lean

A Lean project requires the generated package and the core library from its
`lakefile.toml`. The generated package's own lakefile already points at the core
configured in `[lean.core]`, so the two must agree:

```toml
[[require]]
name = "inframe"
path = ".."                              # a checkout of this repository

[[require]]
name = "generated-digitalocean"
path = ".generated/digitalocean"
```

A project that points `[lean.core]` at the repository instead writes the core
dependency as

```toml
[[require]]
name = "inframe"
git = "https://github.com/by77er/inframe"
rev = "…"
subDir = "lean"
```

Its `lean-toolchain` must pin the toolchain the core is built with (the one in
`lean/lean-toolchain`); `inframe build` warns when it does not.

The stack executables are ordinary `[[lean_exe]]` entries whose root modules
print the graph and check the policies:

```toml
[[lean_exe]]
name = "platform"
root = "Infra.PlatformMain"

[[lean_exe]]
name = "platform-test"
root = "Infra.PlatformTest"
```

### PureScript

Point a Spago `extraPackages` entry at the conventional directory and depend on
the generated package from the stack package:

```yaml
workspace:
  extraPackages:
    generated-digitalocean:
      path: .generated/digitalocean
```

```yaml
package:
  name: integration-digitalocean
  dependencies:
    - generated-digitalocean
    - inframe-graph-core
    - …
  test:
    main: Infra.PlatformTest
```

### Editor support

Generated adapters are ordinary PureScript source, so the PureScript language
server provides completion, inferred signatures, hover types, and navigation
after `spago build`. Open the configured `purescript` directory as the editor
workspace (or add it as a workspace folder) so the language server finds its
`spago.yaml`. Provider attribute descriptions are emitted as PureScript `-- |`
documentation on generated setters and as field catalogs on `Required` and
symbolic handle types. Those declarations appear in language-server hovers and
generated compiler documentation; direct record-field hovers may show only the
field type, depending on editor support.

## Reading a generated Lean module

Each resource is one module (`Cloudflare.Resource.Zone`) that is a namespace, so
`open Cloudflare.Resource` and then `Zone.create`; `open Cloudflare.Resource (Zone)`
does not work because `Zone` is a namespace, not a declaration. Resources have
`create`/`createWith`, data sources `read`/`readWith`, and the provider
`configure`/`configureAs`. The `Args` record follows the schema:

| Schema | `Args` field |
| --- | --- |
| required attribute | `Input T` |
| optional attribute | `Option (Input T) := none` |
| nested block, exactly once | `XArgs` |
| nested block, at most once | `Option XArgs := none` |
| nested block, list | `List XArgs := []`, and an empty list is not written |
| nested attribute (plugin-framework providers), single | `Option XArgs := none` |
| nested attribute, list or set | `Option (List XArgs) := none`: `none` leaves it unset, `some []` writes `[]` |
| nested attribute, map | `Option (List (String × XArgs)) := none` |
| `dynamic` or tuple | `Input Value`, written with `value% { team: "core", tags: ["a"] }` |

A block list with a minimum or maximum count carries that bound as a proof
obligation on `create`, discharged automatically whenever the number of blocks
is a literal, even when their values are symbolic references. An empty `rule`
list on a resource that requires one is a compile error.

Known values coerce, so `type := "full"` and `paused := spec.paused` are enough;
an `if` expression does not coerce inside an optional field, so write
`some (lit (if … then "a" else "b"))`. `Number` is `Lean.JsonNumber`: numerals
elaborate directly, and a `Nat` variable becomes one with
`Lean.JsonNumber.fromNat`. A field whose name is a Lean keyword gets a trailing
underscore (`include_`, `private_`, `meta_`, `end_`).

A handle is `Attributes Input Resolved`, so every attribute is a symbolic input
(`zone.id : Input String`), and handles of different resource types are
different types: a function that accepts several kinds of resource takes the
`Input String` it needs rather than a handle. The same structure at
`Resolved Option` is the resolved state (`Zone.State`, decoded from `inframe show`)
and at `Option Resolved` a fully tolerant view. Elements of computed nested
blocks are traversed with the schema's types
(`instance.networkInterface[1].fields.networkIp`,
`instance.networkInterface.splat (·.networkIp)`).

Argument and attribute names are available as `names` records
(`DatabaseCluster.names.privateNetworkUuid`, `Vpc.names.id`), so a policy that
refers to a schema name by string is a compile error after a rename rather than
a rule that silently matches nothing.

Names come from data as easily as from literals: an `Identifier` is accepted
wherever a literal name is and its proof is reused, so
`Zone.create (site.indexed 3) { … }` and `Record.create (zone.slug host) { … }`
need no proof at the call site (`Identifier.mk "…"` itself needs a literal;
`slug` maps anything an identifier cannot contain, such as `.` or `/`, to `-`).

When a generated argument record cannot express what the provider needs, the
graph primitives are the supported escape hatch: build the record's
`toInputObject`, `insert` the extra argument as an `ExprNode`, and call
`addResource` with the resource's phantom type:

```lean
let values := args.toInputObject |>.insert "extra" (.literal (.string "value"))
let _ ← addResource (r := Zone.ZoneResource) resourceOptions (Identifier.mk "cloudflare_zone") name values
```

## Stack entry points

Each stack `main` prints one Graph IR document: in PureScript
`log (renderGraph infrastructure)`, in Lean `def main : IO Unit := emitGraph infrastructure`.
`emitGraph` renders compact JSON and writes it with `putStr`; it is the one
printing path the core's scale test exercises, and it is the whole of a stack's
`main`. The optional `test` entry point runs assertions over the same pure
infrastructure value. Reusable infrastructure is just ordinary pure functions
called while constructing the `Infra` value.

For Lean stacks `main` and `test` name Lake executables (`lake exe <name>`)
whose root modules print the graph and check policies. The policy theorems in
the test executable's modules are checked by the compiler before the executable
runs, so a violated policy fails the build.

## Build, test, and inspect

```bash
inframe build --stack platform
inframe test --stack platform
inframe graph inspect --stack platform
inframe graph validate --stack platform
```

Every command that takes `--stack` builds the stack first, so `inspect`,
`validate`, `plan`, and `apply` always reflect the current source. Pass
`--no-build` to the graph commands to look at the last built artifact instead;
it warns when any source under the stack's package changed after the artifact
was written. An explicit JSON path, or `-` for stdin, remains available for
debugging.

`build` does not invoke OpenTofu or contact the cloud. For a Lean stack it runs
`lake -q exe <main>`, which compiles only that executable's import tree: a
broken test module does not break `build`, and the first `inframe test` after a
run of builds compiles the rest. A frontend tool that fails is reported with its
command line, exit status, and stderr verbatim, and a tool that is missing from
`PATH` is named along with how to install it.

`inspect` prints a tree of provider pins, configured arguments, resources, data
sources, symbolic outputs, moves, imports, and dependency edges. `graph schema`
prints the Graph IR JSON Schema, the reference for the wire format (references
serialize as `resource_attr`, secrets as `secret_env`, whatever the frontend
constructors are called).

`test` runs the stack's configured test entry point and preserves its exit
status; the test library and structure remain the project's choice. Then, for
a stack with a gate, it runs [the deployment gate](#the-deployment-gate). A Lean
stack without a gate gets a note on every run, because a test executable that
exits 0 says nothing about a `sorry` in the theorems beside it.

## Plan, apply, and the rest of the lifecycle

```bash
inframe init --stack platform -- -input=false
inframe validate --stack platform

export DIGITALOCEAN_TOKEN='…'
inframe plan --stack platform
inframe apply --stack platform
inframe output --stack platform
inframe destroy --stack platform
```

Lifecycle commands rebuild the configured entry point and write deterministic
OpenTofu JSON into `.inframe/stacks/<stack>/`. When the stack configures a
`test` entry point or a gate, `init`, `validate`, `plan`, `apply`, `destroy`,
and `tofu` run them after building and stop if either fails, so a policy suite
kept in its own executable gates deployment and not only `inframe test`.
`--skip-tests` overrides both and says so on stderr, and a stack without a test entry point is
pointed out every time (`--quiet` silences those notes and the build line,
never errors). A graph passed with `--graph` bypasses the project and only the
reference validator runs on it.

Secrets referenced with `secretEnv` are required only for the subcommands that
contact providers (`plan`, `apply`, `destroy`, and `refresh`, `import`, and
`console` through `inframe tofu`); Inframe passes them to OpenTofu as sensitive
variables without writing their values to Graph IR or OpenTofu configuration.

Anything else OpenTofu can do in the workspace goes through the same prepared
configuration with `inframe tofu --stack <name> -- <subcommand>`, for example
`-- state list`, `-- import digitalocean_droplet.web 12345`, or
`-- force-unlock <id>`. `inframe show --stack <name>` runs `tofu show -json` and
`inframe output --stack <name>` runs `tofu output -json` in an existing stack.

## Adopting existing infrastructure

Objects that already exist are adopted from the program, not one command at a
time: `adopt handle "<id>"` (the id in the provider's import syntax, the string
`tofu import` takes) records an `import` block for the handle's resource, so the
next `inframe plan` shows every adoption at once and `apply` performs them in
one run. Delete the `adopt` calls once the state holds the objects.

```lean
let zone ← Zone.create "example" { account := { id := accountId }, name := "example.com" }
adopt zone "023e105f4ecef8ad9ca31a8372d0c353"
```

`inframe tofu --stack <name> -- import <address> <id>` still works for a single
object; it rebuilds and re-runs the tests on every call, so a loop over many of
them wants `--skip-tests --quiet`.

## Remote state

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

Supply credentials through that backend's standard environment variables, for
example `TF_HTTP_USERNAME` and `TF_HTTP_PASSWORD`. Inframe rejects
secret-looking backend keys because OpenTofu may persist backend configuration
in its working directory.

## Composing stacks through remote state

A stack's public interface is a structure of inputs. The producing program
returns it and every field becomes a root output, named after the field in
snake case. A consuming stack gets the same structure back with each field
pointing into the producer's state. Consumers are ordinary functions of the
exports:

```lean
structure Platform where
  clusterEndpoint : Input String          -- output `cluster_endpoint`
  vpcId : Input String
  adminToken : Sensitive String           -- published with `sensitiveOutput`
  deriving StackExports

def platform : Stack Platform :=
  .define "platform" do                   -- the project's [stacks.platform]
    let network ← Vpc.create "platform" { name := "platform", region := "nyc3" }
    …
    pure { clusterEndpoint := cluster.endpoint, vpcId := network.id, adminToken := ⟨token⟩ }

def apps (p : Platform) : Infra Unit := do
  let database ← DatabaseCluster.create "apps" { …, privateNetworkUuid := p.vpcId }
  output "endpoint" (p.clusterEndpoint.orDefault "https://fallback.example")   -- `try`

def appsStack : Infra Unit := do
  apps (← platform.read)                  -- data.terraform_remote_state.platform
```

The producer's `main` is `platform.emit`. If the producer renames or retypes a
field, the consumer stops compiling instead of failing at plan time. Because
`apps` doesn't care where its argument comes from, a test passes literals,
`platform.program >>= apps` builds both stacks as one graph, and a theorem over
`∀ p : Platform, … (buildGraph (apps p))` holds however the stacks are deployed.

The consumer's graph records a stack reference, not a backend. The producer's
`[stacks.platform.backend]` table is the only place the backend is written:
`inframe plan`/`apply` fill it in when they prepare the consumer, and for a
`local` backend they point at the producer's state file in the workspace. A
build fails if the consumer reads a stack that `inframe.toml` doesn't declare.

One stack is one state. A stack deployed per environment is one project stack
per environment, and the `Stack` value can be a function of the environment.
A name computed at run time must be an `Identifier`, so its validity is already
proved:

```lean
def Environment.platformStack : Environment → Identifier    -- `platform-dev`, `platform-prod`
  | .dev => Identifier.mk "platform-dev"
  | .prod => Identifier.mk "platform-prod"

def platform (env : Environment) : Stack Platform := .define env.platformStack.raw (platformFor env)
def apps (env : Environment) : Infra Unit := do appsFor env (← (platform env).read)
```

`deriving StackExports` accepts structures, with or without parameters, whose
fields are `Input α` or `Sensitive α`. Two fields that map to the same output
name, or a field whose snake-case name isn't an OpenTofu identifier, are
compile errors.

### Building and ordering every stack

`inframe build --stack <name>` compiles only that stack, so a change to a
producer's exports doesn't show the consumers it breaks. `inframe build --all`
builds every declared stack, which compiles every consumer against the current
exports, and prints the order to apply them in, producers first:

```text
$ inframe build --all
built stack `apps` to .inframe/graphs/apps.json
built stack `platform` to .inframe/graphs/platform.json
apply order: platform, apps
```

Stacks that read each other in a cycle can't be deployed in any order, and
`build --all` rejects them. `inframe test --all` runs the tests of every stack
that has a test entry point. CI
should run both.

The type says what the producer's code exports, not what its state holds yet.
When a consumer starts reading a new field, apply the producer first or use
`orDefault` until it has been applied. When a field is removed, apply the
consumers before the producer.

### Producers outside the project

For a producer that isn't an Inframe stack of this project,
`RemoteState.read` adds the `terraform_remote_state` data source with an
explicit backend and exposes the outputs by name:

```lean
def infrastructure : Infra Unit := do
  let legacy ← RemoteState.read "legacy" (.gcs "acme-state" (prefix_ := "legacy"))
  let cluster : Input String := legacy.output "cluster_endpoint"
  let region : Input String := legacy.outputOr "region" "nyc3"   -- `try` with a default
  …
```

`RemoteBackend` has constructors for `localFile`, `gcs`, `s3`, `azurerm`,
`http`, `kubernetes`, and `consul`, and `other` for any backend with its
configuration as known values. The type of each output is the consumer's
claim, so nothing checks it before plan.

## Proofs versus assertions

A policy is a decidable proposition over the graph, so
`theorem valid : (buildGraph infrastructure).Valid := by decide` refuses to
compile for an invalid configuration before it reaches OpenTofu.

Kernel `decide` is a proof, and its cost grows with the graph: forty instances
each carrying a four-kilobyte startup script take about nine seconds to
validate. For deployed graphs beyond that, `#assert_policy policy graph` and
`#assert_valid graph` evaluate the same checks with the compiled evaluator while
the module compiles and fail the build with the report. That is a check rather
than a proof, but it is the same gate: keep theorems for statements over every
input of a parameterized stack, and the assertions for the concrete instance.
`lean/integration-digitalocean/Infra/PlatformTest.lean` shows both side by
side, including a proof by induction over an arbitrary database list.

### The deployment gate

A theorem in a test module proves what its author wrote, about whichever
program they wrote it for, and Lean builds a module with a `sorry` in it with
only a warning. A test executable passing is therefore not enough to deploy on.
A Lean stack's gate names the statement in `inframe.toml` instead:

```toml
[stacks.lean-example.gate]
module = "Infra.PlatformTest"   # imports everything below
program = "infrastructure"      # the Infra program `main` emits
policy = "policies"             # the Policy its graph must satisfy
proof = "platform_gate"         # optional: a theorem of `Gated policies infrastructure`
```

```lean
theorem platform_gate : Gated policies infrastructure :=
  ⟨platform_valid, platform_policies .prod⟩
```

`inframe test`, `plan`, and `apply` write a module of their own to
`.inframe/gates/<stack>/Gate.lean` and elaborate it with `lake env lean`. It:

1. states `Inframe.Gated policy program`, meaning the program's graph passes
   the validator and the policy, and checks that `proof` proves exactly that.
   Without `proof` it evaluates the validator and the policy with
   `#assert_valid` and `#assert_policy`, which scales past kernel `decide` but
   is a check rather than a proof.
2. runs `#assert_standard_axioms`. Every declaration imported from outside the
   Lean toolchain (the stack, its bindings, and the core), and the gate's own
   theorem, may depend only on `propext`, `Classical.choice`, and `Quot.sound`.
   The gate fails, naming the declaration, on a `sorry` (`sorryAx`) anywhere,
   including in a universal theorem the gate does not state, on
   `native_decide` (an axiom trusting the compiler), and on an `axiom` the
   stack declares.
3. runs `#assert_compiled_as_proved`, which refuses a definition there with
   `@[implemented_by]` or `@[extern]`. The kernel proves facts about a
   definition's body, but compiled code, `main` included, would run the
   replacement.
4. writes the program's graph, and Inframe requires it to equal the graph the
   stack's `main` printed. A `main` that emits a different program fails the
   gate.

The gate trusts the Lean toolchain and the kernel. It does not defend against
a stack that runs metaprograms to tamper with the environment; `leanchecker`,
which ships with the toolchain, re-checks compiled modules from scratch.

A policy sees the graph, not the plan: a value read from a data source or
another resource is a reference until OpenTofu plans. A rule over values has to
say so rather than skip it, and `Policy.argumentValues` does: it hands the rule
the literal values of one argument and reports every other one as unknown at
its resource. Nothing evaluates unknowns against the plan yet, so an unknown
fails the policy like a violation and the report names it apart:

```text
policy `platform` cannot be decided from the graph:
  [single-region] digitalocean_spaces_bucket.assets: unknown until plan: region is data.digitalocean_region.here.slug
```

Programs extend the graph only through the builder primitives: `Infra`'s
constructor is private, so a stack cannot write a step that reads or replaces
the graph, and the `run` lemmas the proofs use cover everything a stack can do.

### What a proof covers, and what it does not

- **Graph structure.** `Graph.Valid` is the reference validator as a theorem:
  names, references, provider selection, replacement triggers, moves, and
  acyclicity. The Rust validator re-checks the same rules on the emitted
  document. `Graph.Valid` also requires that no object repeat a key. A policy
  reads the first entry and the encoder keeps the last, and the duplicate never
  reaches the document Rust sees.
- **What gates a deployment.** The statement in `[stacks.<name>.gate]`, which
  Inframe states itself, and only with proofs free of `sorry`, `native_decide`,
  and stack-declared axioms, about definitions whose compiled code is their
  body (see [The deployment gate](#the-deployment-gate)).
  Other theorems in the stack are checked for the same axioms but are about
  whatever they state; review their statements like the policies.
- **The provider schema, as far as it is in the types.** Required arguments,
  attribute types, and how many entries a nested block may have are in the
  generated records. Value-level rules (allowed strings, formats, "exactly one
  of these") are not; `inframe validate` runs OpenTofu's own validation with the
  provider installed and no credentials.
- **Policies.** A theorem proves the properties you stated about the graphs
  your program can produce, for the inputs you quantified over, and nothing
  else. A value only the plan knows is not proved either way; a policy built
  on `Policy.argumentValues` fails on it as unknown. It says nothing about the
  account: quotas, permissions, drift, and what the provider does at apply
  time are what `plan` and `apply` are for.
- **Serialization.** Lowering Graph IR to OpenTofu JSON is Rust code outside
  the kernel, covered by golden files and by a round trip
  (`scripts/check-template-escapes.sh`) that applies a graph with OpenTofu and
  compares the resolved values with the literals the graph wrote.

A green proof plus a green plan is the evidence; neither is enough on its own.
