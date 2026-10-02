#!/usr/bin/env python3
"""Decide whether the aggregate gate passes, given the `needs` context.

Branch protection points at a single required check. That check is only worth
anything if it goes red when a gate does, so the decision lives here — in a
file a self-test can exercise — rather than inline in the workflow where
nothing can prove it.

Reads the JSON `needs` object on stdin. Exits non-zero, with a GitHub error
annotation per offending job, unless every gate passed.

A skipped job is NOT a pass by default. `always()` keeps this job itself from
being skipped and read as satisfied; without the rule below, the jobs it gates
would reintroduce exactly that — add an `if:` or a path filter to a gate and
the required check reports success when the gate never ran.

Some gates are legitimately conditional: a job that guards code which does not
exist yet should skip, not fail. Those are declared per repository, by name,
in the SKIP_OK environment variable set on the step:

    env:
      SKIP_OK: typecheck,migrations-check,policy

Declaring a job skippable does not weaken the rest: a declared job that fails
still fails, and the job those conditions derive from (a `detect`-style setup
job) belongs in `needs:` so that its own failure is caught rather than being
laundered into a skip of everything downstream.
"""

import json
import os
import sys

SKIP_OK_ENV = "SKIP_OK"

# The job this script decides the result of. Named here so its messages can
# point at the right place in the workflow.
AGGREGATE = "ci-ok"


def declared_skippable():
    """Job names this repository allows to skip, from the workflow."""
    raw = os.environ.get(SKIP_OK_ENV, "")
    return {name.strip() for name in raw.split(",") if name.strip()}


def problems(needs, skippable):
    """Return [(job, result, why)] for every job that does not pass."""
    found = []
    for name, job in sorted(needs.items()):
        result = (job or {}).get("result")
        if result == "success":
            continue
        if result == "skipped":
            if name not in skippable:
                why = f"was skipped but is not listed in {SKIP_OK_ENV}"
                found.append((name, result, why))
            continue
        if result is None:
            # A dependency with no result at all is not a pass. It means the
            # needs context was malformed, not that the job was fine.
            found.append((name, "no result", "reported nothing at all"))
            continue
        found.append((name, result, "did not succeed"))
    return found


def main():
    try:
        needs = json.load(sys.stdin)
    except ValueError as exc:
        print(f"::error::the needs context was not valid JSON: {exc}")
        return 1

    if not isinstance(needs, dict):
        print("::error::the needs context was not an object")
        return 1

    # An empty object means this job depended on nothing. Reporting "all 0
    # gates passed" would let a deleted `needs:` list turn the required check
    # green while every gate went unread.
    if not needs:
        print(
            f"::error::the needs context was empty, so this gate read no "
            f"results: check that the {AGGREGATE} job still declares `needs:`"
        )
        return 1

    skippable = declared_skippable()

    # A name here that is not a real dependency is stale configuration: the
    # job was renamed or removed and the exemption outlived it. Not fatal on
    # its own, but it is how an exemption quietly starts covering nothing.
    for stale in sorted(skippable - set(needs)):
        print(f"::warning::{SKIP_OK_ENV} names '{stale}', not a dependency")

    found = problems(needs, skippable)
    for name, result, why in found:
        print(f"::error::{name} concluded {result}: it {why}")

    if found:
        print(f"{len(found)} of {len(needs)} gates did not pass")
        return 1

    skipped = sum(1 for job in needs.values() if (job or {}).get("result") == "skipped")
    if skipped:
        print(f"all {len(needs)} gates passed ({skipped} skipped by declaration)")
    else:
        print(f"all {len(needs)} gates succeeded")
    return 0


if __name__ == "__main__":
    sys.exit(main())
