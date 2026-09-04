# Lean emitter stress test

Bindings were generated for three providers and every module was compiled with
`lake build` on a 20-core machine (the two large providers with
`LEAN_NUM_THREADS=10`).

| Provider | Modules | Generate | Package | `lake build`, clean | Peak memory |
| --- | --- | --- | --- | --- | --- |
| `digitalocean/digitalocean` 2.100.0 | 156 | < 1 s | 2 MB | 7 s | n/a |
| `hashicorp/google` 8.1.0 | 1,797 | 1.6 s | 23 MB | 2 min 13 s | 4.1 GB |
| `hashicorp/aws` 6.63.0 | 2,394 | 13 s | 24 MB | 2 min 27 s | 4.1 GB |

Every module of all three providers compiles.

## Findings

- Six provider attribute names collide with Lean tokens (`continue`, `from`,
  `prefix`, `public`, `meta`, `matches`); the emitter escapes them.
- Six AWS resources (WAF rules and QuickSight) unroll recursive blocks to up to
  21,000 nested block paths with only a few hundred distinct shapes. Emitted one
  type per path they were up to 59 MB each and could not be compiled within
  15 GB; the emitter now shares one type per shape, and the largest module is
  1 MB.

## Reproducing

```bash
inframe provider inspect --source hashicorp/aws --version 6.63.0 --output aws.json
inframe provider generate --source hashicorp/aws --version 6.63.0 \
  --schema-json aws.json --frontend lean --module-root Aws --output aws-lean
cd aws-lean && LEAN_NUM_THREADS=10 lake build
```
