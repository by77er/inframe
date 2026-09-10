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
status; the test library and structure remain the project's choice.

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
`test` entry point, `init`, `validate`, `plan`, `apply`, `destroy`, and `tofu`
run it after building and stop if it fails, so a policy suite kept in its own
executable gates deployment and not only `inframe test`. `--skip-tests`
overrides that and says so on stderr, and a stack without a test entry point is
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
