#!/usr/bin/env sh
# Every file in this directory must fail to compile with the error named on its first line
# (`-- expect: <text>`). These are the type-level guarantees of the core library, stated as
# programs the compiler has to reject; `lake env lean` gives them the package's search path.
set -eu
cd "$(dirname -- "$0")/.."
status=0
for file in Negative/*.lean; do
  expected=$(sed -n '1s/^-- expect: //p' "$file")
  if [ -z "$expected" ]; then
    echo "FAIL $file: first line must be '-- expect: <error text>'" >&2
    status=1
    continue
  fi
  output=$(lake env lean "$file" 2>&1 || true)
  if printf '%s\n' "$output" | grep -qF -- "$expected"; then
    echo "rejected $file: $expected"
  else
    echo "FAIL $file: expected an error containing '$expected', got:" >&2
    printf '%s\n' "$output" >&2
    status=1
  fi
done
exit $status
