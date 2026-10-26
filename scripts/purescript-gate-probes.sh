#!/usr/bin/env sh
# The deployment gate of the PureScript `example` stack must refuse the ways a green test can
# lie: a `main` that prints a graph other than the one checked, a test module that checks
# something other than the deployed program, and a `proof`, which PureScript cannot give. Each
# probe edits the example in place, expects `inframe test` to fail with the error named, and
# restores the sources. Run from the repository root after the bindings are generated.
set -eu
inframe=${INFRAME:-"cargo run -q -p inframe-cli --"}
src=purescript/integration-digitalocean/src/Infra
test=purescript/integration-digitalocean/test/Infra
backup=$(mktemp -d)
cp "$src/Platform.purs" "$test/PlatformTest.purs" "$backup/"
probe_project=inframe.gate-probe.toml
restore() {
  cp "$backup/Platform.purs" "$src/"
  cp "$backup/PlatformTest.purs" "$test/"
  rm -rf "$backup" "$probe_project"
}
trap restore EXIT

status=0
expect_refusal() {
  name=$1
  expected=$2
  shift 2
  output=$($inframe "$@" test --stack example 2>&1 || true)
  if printf '%s\n' "$output" | grep -qF -- "$expected"; then
    echo "refused $name: $expected"
  else
    echo "FAIL $name: expected an error containing '$expected', got:" >&2
    printf '%s\n' "$output" >&2
    status=1
  fi
  cp "$backup/Platform.purs" "$src/"
  cp "$backup/PlatformTest.purs" "$test/"
}

sed 's/^main = log (renderGraph infrastructure)$/main = log (renderGraph (infrastructure <* output "extra" (lit "x")))/' \
  "$backup/Platform.purs" > "$src/Platform.purs"
expect_refusal "a main that prints another graph" "prints a different graph"

# The database leaves the VPC and the test module stops checking anything; the gate still
# checks the deployed program against `policies`.
sed 's/# Database.privateNetworkUuid (computed network.id)/# Database.privateNetworkUuid (lit "00000000-not-the-vpc")/' \
  "$backup/Platform.purs" > "$src/Platform.purs"
sed 's/^main = Policy.enforce policies (buildGraph infrastructure)$/main = pure unit/' \
  "$backup/PlatformTest.purs" > "$test/PlatformTest.purs"
expect_refusal "a test that checks nothing" \
  "[database-uses-managed-vpc] digitalocean_database_cluster.postgres: private_network_uuid must reference"

sed 's/^program = "Infra.Platform.infrastructure"$/&\nproof = "platform_gate"/' inframe.toml > "$probe_project"
expect_refusal "a proof in a PureScript gate" "which has no proofs" --project "$probe_project"

exit $status
