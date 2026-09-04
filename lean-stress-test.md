# Lean emitter stress test

The Lean emitter was exercised against three provider schemas by generating a
package and running `lake build` on every module. Numbers are from a 20-core
machine; the two large providers were built with `LEAN_NUM_THREADS=10`.

| Provider | Modules | Generate | Package | `lake build`, clean | Peak memory |
| --- | --- | --- | --- | --- | --- |
| `digitalocean/digitalocean` 2.100.0 | 156 | < 1 s | 2 MB | 7 s | n/a |
| `hashicorp/google` 8.1.0 | 1,797 | 1.6 s | 23 MB | 2 min 13 s | 4.1 GB |
| `hashicorp/aws` 6.63.0 | 2,394 | 13 s | 24 MB | 2 min 27 s | 4.1 GB |

Every module of all three providers compiles.

## What the runs found

**Reserved words.** Six provider attribute names collide with Lean tokens and
are now escaped with a trailing underscore: `continue`, `from`, `prefix`,
`public`, `meta`, and `matches`. The list lives in `lean_reserved` in
`crates/emit-lean/src/lib.rs`; new providers may extend it.

**Unrolled recursive blocks.** Six AWS resources (the WAF rule, rule group, and
web ACL resources and the QuickSight dashboard, template, and analysis
resources) unroll recursive nested blocks to 8,000 to 21,000 block paths each.
Emitted as one type per path, they were 19 to 59 MB of Lean apiece, the AWS
package was 213 MB, and the smallest of them could not be elaborated within
15 GB; building the package with Lake's default parallelism exhausted a 23 GB
machine. Those paths have only 49 to 424 structurally distinct shapes, so the
emitter now keys every nested object by its field list and declares each shape
once, named after the first path where it occurs. The worst module is 244 KB and
compiles in two seconds, and the package fits in 24 MB. `emit-purescript` does
not share shapes yet.

**Per-shape structures.** Even after sharing, one Lean `structure` per builder
generates a dozen auxiliary declarations each. `Args` and block builders are
therefore `abbrev`s of one phantom-tagged core type, `Block "<qualified name>"`,
which keeps shapes distinct at the type level at no per-shape cost.

## Reproducing

```bash
cargo build -p inframe-cli
inframe provider inspect --source hashicorp/aws --version 6.63.0 --output aws.json
inframe provider generate --source hashicorp/aws --version 6.63.0 \
  --schema-json aws.json --frontend lean --module-root Aws --output aws-lean
cd aws-lean && LEAN_NUM_THREADS=10 lake build
```

Lake has no jobs flag; `LEAN_NUM_THREADS` bounds its parallelism. The generated
package requires the `inframe` core library from this repository by git unless
the project's `[lean.core]` points at a checkout.
