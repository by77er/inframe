#!/usr/bin/env sh
# The deployment gate of the `lean-example` stack must refuse the ways a green build can lie:
# a `sorry` beside a passing test executable, a `main` that prints a graph other than the one
# proved, a program whose compiled code is swapped with `implemented_by`, and a proof of a
# weaker statement than the gate's. Each probe edits the example in
# place, expects `inframe test` to fail with the error named, and restores the sources.
# Run from the repository root after the bindings are generated.
set -eu
inframe=${INFRAME:-"cargo run -q -p inframe-cli --"}
package=lean/integration-digitalocean/Infra
backup=$(mktemp -d)
cp "$package/Platform.lean" "$package/PlatformTest.lean" "$package/PlatformMain.lean" "$backup/"
probe_project=inframe.gate-probe.toml
restore() {
  cp "$backup/Platform.lean" "$backup/PlatformTest.lean" "$backup/PlatformMain.lean" "$package/"
  rm -rf "$backup" "$probe_project"
}
trap restore EXIT

status=0
expect_refusal() {
  name=$1
  expected=$2
  shift 2
  output=$($inframe "$@" test --stack lean-example 2>&1 || true)
  if printf '%s\n' "$output" | grep -qF -- "$expected"; then
    echo "refused $name: $expected"
  else
    echo "FAIL $name: expected an error containing '$expected', got:" >&2
    printf '%s\n' "$output" >&2
    status=1
  fi
  cp "$backup/Platform.lean" "$backup/PlatformTest.lean" "$backup/PlatformMain.lean" "$package/"
}

cat >> "$package/PlatformTest.lean" <<'EOF'

theorem probe_every_graph_valid (env : Environment) (databases : List Identifier) :
    (buildGraph (infrastructureFor env databases)).Valid := by
  sorry
EOF
expect_refusal "a sorry beside a passing test" "probe_every_graph_valid depends on \`sorryAx\`"

sed 's/emitGraph infrastructure/emitGraph (infrastructureFor .dev [Identifier.mk "postgres"])/' \
  "$backup/PlatformMain.lean" > "$package/PlatformMain.lean"
expect_refusal "a main that prints another graph" "prints a different graph"

sed 's/^def infrastructure : Infra Unit :=$/def rogue : Infra Unit := infrastructureFor .dev []\n\n@[implemented_by rogue]\ndef infrastructure : Infra Unit :=/' \
  "$backup/Platform.lean" > "$package/Platform.lean"
expect_refusal "a program compiled from other code" "infrastructure is implemented by rogue"

sed 's/^proof = "platform_gate"$/proof = "platform_valid"/' inframe.toml > "$probe_project"
expect_refusal "a proof of a weaker statement" "but is expected to have type" --project "$probe_project"

exit $status
