# tofu-dag

`tofu-dag` is a typed, pure frontend for OpenTofu. Frontend programs build an
immutable infrastructure graph; the Rust CLI validates that graph, lowers it to
deterministic `.tofu.json`, and delegates planning, state, and provider execution
to OpenTofu.

This repository is an MVP of the architecture in
[tofu-dag-design.md](tofu-dag-design.md). It includes a working end-to-end slice
for `digitalocean/digitalocean` `2.100.0`.

```text
PureScript program -> Graph IR JSON -> Rust validation/lowering -> OpenTofu
```

## What works

- Provider schemas are acquired with `tofu providers schema -json` and
  normalized deterministically.
- A language-neutral binding model drives generated PureScript bindings.
- The checked-in DigitalOcean package contains 79 resources and 77 data sources.
- The PureScript `Infra` builder is pure: resource creation only appends to a
  graph value.
- Graph IR validates versions, identifiers, addresses, references, moves, and
  explicit dependencies.
- Dependencies are derived by walking symbolic expressions; no duplicate DAG is
  stored.
- The lowerer emits sorted OpenTofu JSON and supports literals, references,
  arrays, objects, indexing, conditionals, functions, templates, outputs,
  providers, lifecycle settings, moves, and explicit `depends_on`.
- The CLI wraps `init`, `validate`, `plan`, `apply`, `destroy`, `show`, and
  `output` in isolated stack workspaces.

The MVP intentionally does not implement its own state engine, remote state
service, module generation, `for_each`/`count`, or remote execution.

## Repository map

| Path | Responsibility |
| --- | --- |
| `crates/provider-schema` | OpenTofu schema acquisition and normalization |
| `crates/binding-model` | Provider schema to language-neutral API model |
| `crates/emit-purescript` | Deterministic PureScript package generation |
| `crates/graph-ir` | Canonical graph model, validation, JSON Schema, dependencies |
| `crates/opentofu` | Pure lowering, stack workspaces, and process execution |
| `crates/cli` | `tofu-dag` command-line orchestration |
| `purescript` | Pure graph core, generated provider, and integration program |
| `fixtures` | Real/synthetic schema, graph, and lowering fixtures |

## Prerequisites

- Rust 1.85 or newer
- OpenTofu 1.10 or newer
- PureScript 0.15.16
- Spago 1.x

## Build and test

```bash
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
cargo fmt --all -- --check

cd purescript
spago test -p tofu-dag-graph-core
spago build -p generated-digitalocean
spago run -p integration-digitalocean --main Infra.Main --quiet \
  | cargo run -q -p tofu-dag-cli -- graph validate -
```

To exercise the real lowerer and provider without cloud credentials:

```bash
cargo run -q -p tofu-dag-cli -- init \
  --stack smoke \
  --graph fixtures/graph-ir/digitalocean-tag.json \
  -- -backend=false -input=false

cargo run -q -p tofu-dag-cli -- validate \
  --stack smoke \
  --graph fixtures/graph-ir/digitalocean-tag.json
```

## Generate provider bindings

The normal path acquires the schema through a temporary OpenTofu workspace:

```bash
cargo run -q -p tofu-dag-cli -- provider generate \
  --source digitalocean/digitalocean \
  --version 2.100.0 \
  --module-root DigitalOcean \
  --output purescript/generated-digitalocean
```

`--schema-json` accepts raw `tofu providers schema -json` output for offline
fixture tests. It is not used by the production generation path.

## Author a graph

The integration program is a complete small example:

```purescript
infrastructure :: Infra Unit
infrastructure = do
  requireProvider "digitalocean" "digitalocean/digitalocean" "= 2.100.0"
  DigitalOcean.configure (DigitalOcean.args {})
  tag <- Tag.create "mvp" (Tag.args { name: lit "tofu-dag-mvp" })
  output "tag_id" tag.id
```

`Tag.create` performs no I/O. `main` is the small outer effect that renders the
resulting graph to stdout.

## CLI examples

```bash
tofu-dag graph validate graph.json
tofu-dag graph inspect graph.json
tofu-dag graph schema --output graph-ir.schema.json
tofu-dag render --graph graph.json --output main.tofu.json

tofu-dag plan --stack dev --graph graph.json -- -out=plan.bin
tofu-dag apply --stack dev --graph graph.json -- -auto-approve
tofu-dag output --stack dev
tofu-dag destroy --stack dev --graph graph.json -- -auto-approve
```

Stack workspaces live under `.tofu-dag/stacks/<stack>/` by default. Provider and
backend credentials should be supplied through environment variables, never as
checked-in graph literals.

## MVP boundaries

The generated API models provider types faithfully enough to compile the entire
pinned DigitalOcean schema. Nested attributes and blocks are accepted as typed
whole values; dedicated nested builder modules are a post-MVP ergonomic
improvement. Tuple, map, and dynamic provider values currently use `Json` as the
safe lossless fallback. Unsafe raw expressions exist in Graph IR but are
deliberately not exposed by the PureScript core.

