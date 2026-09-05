#!/usr/bin/env sh
# Round-trip fixtures/graph-ir/template-escapes.json through OpenTofu and compare the values it
# resolves with the literals the graph wrote. The graph has outputs only, so applying it needs
# no provider, credentials, or cloud contact: state lands in a temporary workspace.
#
# This is the cross-layer check the Lean kernel cannot make: a literal that reaches OpenTofu
# must denote exactly the value the frontend wrote, however many `${` and `%{` it contains.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
inframe=${INFRAME:-"cargo run -q -p inframe-cli --"}
workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT

graph="$root/fixtures/graph-ir/template-escapes.json"
expected="$root/fixtures/tofu-output/template-escapes.json"

$inframe init --stack template-escapes --graph "$graph" --workspace "$workspace" -- -input=false -no-color >/dev/null
$inframe apply --stack template-escapes --graph "$graph" --workspace "$workspace" -- -input=false -no-color -auto-approve >/dev/null
$inframe output --stack template-escapes --workspace "$workspace" > "$workspace/actual.json"

python3 - "$workspace/actual.json" "$expected" <<'PY'
import json
import sys

actual = {name: entry["value"] for name, entry in json.load(open(sys.argv[1])).items()}
expected = json.load(open(sys.argv[2]))
if actual != expected:
    print("OpenTofu resolved different values than the graph wrote", file=sys.stderr)
    print(json.dumps({"expected": expected, "actual": actual}, indent=2, sort_keys=True), file=sys.stderr)
    sys.exit(1)
print(f"template escapes round-trip through OpenTofu: {len(actual)} outputs unchanged")
PY
