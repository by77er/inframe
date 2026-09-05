#!/usr/bin/env sh
# Every file in <package>/Negative must fail to compile with the error named on its first line
# (`-- expect: <text>`). These are guarantees the type checker gives, stated as programs it has
# to reject; `lake env lean` gives each file the package's search path, so run this after the
# package (and, for generated bindings, its dependencies) has been built.
set -eu
if [ $# -ne 1 ]; then
  echo "usage: $0 <lake package directory>" >&2
  exit 2
fi
cd "$1"
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
