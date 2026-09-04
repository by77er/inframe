# Contributing

Keep changes inside the representation boundary that owns them. Provider schema
semantics belong in `provider-schema`, frontend API semantics in
`binding-model`, language syntax in an emitter, graph semantics in `graph-ir`,
and process behavior in `opentofu`.

Before submitting a change, run the commands in the README's **Build and test**
section. Generated provider changes should be reproducible by rerunning the
documented `provider generate` command and should include a reviewed manifest
diff.

Use `jj` for local change management. A typical change starts with `jj new` and
ends with `jj describe -m "..."` after all checks pass.

