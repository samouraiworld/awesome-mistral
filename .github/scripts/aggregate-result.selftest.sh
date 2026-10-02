#!/usr/bin/env bash
# Proves the aggregate gate can fail.
#
# A required status check that has never been observed failing is a decoration,
# not a gate. This runs immediately before the real evaluation, so every
# pipeline re-proves that a gate going red turns the aggregate red — the
# mutation is the point, not the passing case.
#
# The skip cases are the ones with history: counting every skip as a pass let
# the aggregate report success when a gate never ran, which is the failure
# this script now pins shut in both directions.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/aggregate-result.py"

[ -f "$script" ] || { echo "self-test FAILED: $script is missing" >&2; exit 1; }

# $1 expected exit, $2 label, $3 payload, $4 optional SKIP_OK value
expect() {
  local want="$1" label="$2" payload="$3" allow="${4-}" got=0
  printf '%s' "$payload" | SKIP_OK="$allow" python3 "$script" >/dev/null 2>&1 || got=$?
  if [ "$got" -ne "$want" ]; then
    echo "self-test FAILED: '$label' expected exit $want, got $got" >&2
    exit 1
  fi
  printf '  ok  %-42s exit %s\n' "$label" "$got"
}

echo "aggregate-result self-test"

expect 0 "all succeeded" \
  '{"a":{"result":"success"},"b":{"result":"success"}}'

expect 1 "one failure" \
  '{"a":{"result":"success"},"b":{"result":"failure"}}'

expect 1 "one cancellation" \
  '{"a":{"result":"success"},"b":{"result":"cancelled"}}'

expect 1 "every gate failed" \
  '{"a":{"result":"failure"},"b":{"result":"failure"}}'

expect 1 "a missing result" \
  '{"a":{}}'

# The hole this contract closes: a gate that gains an `if:` or a path filter
# skips, and the aggregate must not call that satisfied.
expect 1 "an undeclared skip" \
  '{"a":{"result":"success"},"b":{"result":"skipped"}}'

# ...while a gate the repository has declared conditional may skip.
expect 0 "a declared skip" \
  '{"a":{"result":"success"},"b":{"result":"skipped"}}' "b"

expect 1 "a declared skip alongside a failure" \
  '{"a":{"result":"failure"},"b":{"result":"skipped"}}' "b"

expect 1 "a skip declared under some other name" \
  '{"a":{"result":"success"},"b":{"result":"skipped"}}' "c"

# Deleting the `needs:` list must not make the gate pass vacuously.
expect 1 "an empty needs object" '{}'

expect 1 "a needs context that is not an object" '[]'

expect 1 "malformed JSON" 'not json at all'

echo "self-test passed: the aggregate fails on failure, cancellation and any"
echo "skip the repository has not declared"
