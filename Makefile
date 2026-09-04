.PHONY: test check generate validate-fixture

test:
	cargo test --workspace
	cd purescript && spago test -p inframe-graph-core

check:
	cargo fmt --all -- --check
	cargo clippy --workspace --all-targets -- -D warnings
	cd purescript && spago build -p integration-digitalocean

generate:
	cargo run -q -p inframe-cli -- provider generate

validate-fixture:
	cargo run -q -p inframe-cli -- init --stack smoke --graph fixtures/graph-ir/digitalocean-tag.json -- -backend=false -input=false
	cargo run -q -p inframe-cli -- validate --stack smoke --graph fixtures/graph-ir/digitalocean-tag.json
