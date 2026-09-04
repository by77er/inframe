.PHONY: test check generate validate-fixture

test:
	cargo test --workspace
	cd purescript && spago test -p tofu-dag-graph-core

check:
	cargo fmt --all -- --check
	cargo clippy --workspace --all-targets -- -D warnings
	cd purescript && spago build -p generated-digitalocean

generate:
	cargo run -q -p tofu-dag-cli -- provider generate --source digitalocean/digitalocean --version 2.100.0 --module-root DigitalOcean --output purescript/generated-digitalocean

validate-fixture:
	cargo run -q -p tofu-dag-cli -- init --stack smoke --graph fixtures/graph-ir/digitalocean-tag.json -- -backend=false -input=false
	cargo run -q -p tofu-dag-cli -- validate --stack smoke --graph fixtures/graph-ir/digitalocean-tag.json

