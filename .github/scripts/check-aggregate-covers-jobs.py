#!/usr/bin/env python3
"""Fail if the aggregate job does not depend on every other job.

The aggregate is the one required status check. It can only speak for the
gates named in its `needs:`, so a gate added later and not wired in is
invisible to branch protection: the new job can fail while the required check
stays green. That is the same silent hole as a skipped gate counting as a
pass, arriving through a different door.

Parsed with a small scanner rather than a YAML library so the check has no
dependency beyond the interpreter already present on the runner.
"""

import re
import sys

# YAML permits a quoted key, and a job the scanner cannot see is a job this
# check silently declares covered. Accept both quoting styles, and treat any
# other line at job indentation as a parse failure rather than skipping it.
# A name may be bare, double-quoted or single-quoted.
NAME = r"""(?:"([^"]*)"|'([^']*)'|([A-Za-z0-9_.\-]+))"""
COMMENT = r"\s*(?:#.*)?$"

JOB_KEY = re.compile(rf"^  {NAME}:{COMMENT}")
JOB_LINE = re.compile(r"^  [^#\s].*:")
SECTION = re.compile(r"^([A-Za-z0-9_.\-]+):")
NEEDS_BLOCK = re.compile(rf"^    needs:{COMMENT}")
NEEDS_FLOW = re.compile(rf"^    needs:\s*\[(.*)\]{COMMENT}")
NEEDS_ITEM = re.compile(rf"^      -\s*{NAME}{COMMENT}")

AGGREGATE = "ci-ok"


class UnparsedError(Exception):
    """A line at job indentation the scanner could not read."""


def first(match):
    """The one populated group of an alternation."""
    return next(g for g in match.groups() if g is not None)


def parse(path):
    """Return (all job keys, the aggregate's needs)."""
    jobs, needs, in_jobs, current, collecting = [], [], False, None, False

    lines = open(path, encoding="utf-8").read().splitlines()
    for number, line in enumerate(lines, start=1):
        if SECTION.match(line):
            in_jobs = line.startswith("jobs:")
            continue
        if not in_jobs:
            continue

        key = JOB_KEY.match(line)
        if key:
            current = first(key)
            jobs.append(current)
            collecting = False
            continue

        # Looks like a job key but did not parse. Guessing here is how a job
        # ends up uncounted and therefore reported as covered.
        if JOB_LINE.match(line):
            key = line.strip()
            raise UnparsedError(f"{path}:{number}: cannot read this job key: {key}")

        if current != AGGREGATE:
            continue

        flow = NEEDS_FLOW.match(line)
        if flow:
            needs = [n.strip() for n in flow.group(1).split(",") if n.strip()]
            continue
        if NEEDS_BLOCK.match(line):
            collecting = True
            continue
        if collecting:
            item = NEEDS_ITEM.match(line)
            if item:
                needs.append(first(item))
            elif line.strip() and not line.startswith("      "):
                collecting = False

    return jobs, needs


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else ".github/workflows/ci.yml"
    try:
        jobs, needs = parse(path)
    except UnparsedError as exc:
        print(f"::error file={path}::{exc}")
        return 1

    if AGGREGATE not in jobs:
        print(f"::error file={path}::no `{AGGREGATE}` job found")
        return 1

    expected = {j for j in jobs if j != AGGREGATE}
    declared = set(needs)

    missing = sorted(expected - declared)
    unknown = sorted(declared - expected)

    for job in missing:
        print(
            f"::error file={path}::job '{job}' is not in `{AGGREGATE}` "
            f"needs:, so the required check cannot see whether it passed"
        )
    for job in unknown:
        print(
            f"::error file={path}::`{AGGREGATE}` needs: names '{job}', "
            f"which is not a job in this workflow"
        )

    if missing or unknown:
        return 1

    print(f"`{AGGREGATE}` depends on all {len(expected)} other jobs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
