.PHONY: test check generate validate-fixture conformance conformance-tofu

test:
	cargo test --workspace
	cd purescript && spago test -p inframe-graph-core
	cd lean && lake -q exe inframe-test
	cd lean && lake -q exe inframe-scale-test | cargo run -q -p inframe-cli -- graph validate -
	scripts/lean-negative.sh lean
	scripts/lean-negative.sh lean/integration-digitalocean

check:
	cargo fmt --all -- --check
	cargo clippy --workspace --all-targets -- -D warnings
	cd purescript && spago build -p integration-digitalocean
	cd lean/integration-digitalocean && lake build

generate:
	cargo run -q -p inframe-cli -- provider generate

# Both frontends must render byte-identical Graph IR for the platform stack.
conformance:
	cargo run -q -p inframe-cli -- build --stack example
	cargo run -q -p inframe-cli -- build --stack lean-example
	diff .inframe/graphs/example.json .inframe/graphs/lean-example.json

validate-fixture:
	cargo run -q -p inframe-cli -- init --stack smoke --graph fixtures/graph-ir/digitalocean-tag.json -- -backend=false -input=false
	cargo run -q -p inframe-cli -- validate --stack smoke --graph fixtures/graph-ir/digitalocean-tag.json

# Literals with template markers must come back from OpenTofu exactly as written.
conformance-tofu:
	scripts/check-template-escapes.sh
