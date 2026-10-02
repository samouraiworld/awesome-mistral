#!/usr/bin/env bash
# Proves the coverage check can fail.
#
# The case that matters is the third one: a gate present in the workflow but
# absent from the aggregate's `needs:`. That job can fail while the required
# check stays green, which is exactly what this check exists to prevent — so a
# version of it that cannot detect that is worse than none.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/check-aggregate-covers-jobs.py"

[ -f "$script" ] || { echo "self-test FAILED: $script is missing" >&2; exit 1; }

work="$(mktemp -d "${TMPDIR:-/tmp}/aggregate-covers-selftest.XXXXXX")"
trap 'rm -rf "$work"' EXIT

fixture() { printf '%s\n' "$2" > "$work/$1.yml"; }

expect() {
  local want="$1" label="$2" got=0
  python3 "$script" "$work/$2.yml" >/dev/null 2>&1 || got=$?
  if [ "$got" -ne "$want" ]; then
    echo "self-test FAILED: '$label' expected exit $want, got $got" >&2
    exit 1
  fi
  printf '  ok  %-38s exit %s\n' "$label" "$got"
}

echo "aggregate-covers-jobs self-test"

fixture complete 'name: CI
jobs:
  build:
    runs-on: ubuntu-latest
  lint:
    runs-on: ubuntu-latest
  ci-ok:
    name: ci-ok
    needs:
      - build
      - lint'
expect 0 complete

fixture flow 'name: CI
jobs:
  build:
    runs-on: ubuntu-latest
  ci-ok:
    name: ci-ok
    needs: [build]'
expect 0 flow

fixture uncovered 'name: CI
jobs:
  build:
    runs-on: ubuntu-latest
  lint:
    runs-on: ubuntu-latest
  ci-ok:
    name: ci-ok
    needs:
      - build'
expect 1 uncovered

fixture phantom 'name: CI
jobs:
  build:
    runs-on: ubuntu-latest
  ci-ok:
    name: ci-ok
    needs:
      - build
      - a-job-that-was-renamed'
expect 1 phantom

fixture missing 'name: CI
jobs:
  build:
    runs-on: ubuntu-latest'
expect 1 missing

# YAML allows a quoted key. If the scanner cannot see it, the job is not
# counted and its absence from needs: is reported as full coverage.
fixture quoted 'name: CI
jobs:
  "build":
    runs-on: ubuntu-latest
  ci-ok:
    name: ci-ok
    needs:
      - build'
expect 0 quoted

fixture quoted-uncovered 'name: CI
jobs:
  "build":
    runs-on: ubuntu-latest
  '"'"'lint'"'"':
    runs-on: ubuntu-latest
  ci-ok:
    name: ci-ok
    needs:
      - build'
expect 1 quoted-uncovered

# Anything else at job indentation is a parse failure, never a skip: guessing
# is what let an unreadable key count as covered in the first place.
#
# The key below carries a space, which YAML accepts and this scanner cannot
# read — so the offending line is the one that trips the check, and the error
# names it. An earlier fixture used explicit-key syntax and was caught one line
# later, on the `:` line, which proved the behaviour while reporting the wrong
# place.
fixture unreadable 'name: CI
jobs:
  build:
    runs-on: ubuntu-latest
  end to end:
    runs-on: ubuntu-latest
  ci-ok:
    name: ci-ok
    needs:
      - build'
expect 1 unreadable

echo "self-test passed: an unwired gate, a stale dependency, a missing"
echo "aggregate and a key the scanner cannot read are all caught"
