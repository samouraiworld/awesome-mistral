#!/usr/bin/env python3
"""Fail if a clause this repository has decided it must carry has gone missing.

The attribution gate scans tracked files for the vendor name. It has no opinion
about the *policy that mandates it* being deleted, and that gap is not
hypothetical: a stale branch merged as the two-dot residue of `main..branch`
silently reverts everything `main` gained since the branch was cut, which can
be a policy section of `AGENTS.md`, a Dependabot `update-types` cap or a
`CODEOWNERS` entry. Every other check stays green, because none of them is
watching for an absence.

Looking for a net deletion in those files after a merge is a rule someone has
to remember to apply. This is that rule as a gate.

The clauses are declared in `required-clauses.txt` beside this script, one per
line:

    path/to/file :: text that must appear somewhere in it

The text is matched verbatim as a substring, because a clause worth pinning is
a sentence someone wrote, not a pattern. Pin the shortest fragment that cannot
survive the deletion you are guarding against: pin a whole paragraph and an
innocent rewording reddens the branch, pin one common word and nothing is
guarded.

The file must also be TRACKED. A clause in an untracked file passes locally and
is absent for everyone else, which is the same trap `git add`-before-scanning
exists to close.
"""

import os
import re
import subprocess
import sys

SEPARATOR = " :: "
MANIFEST = os.path.join(os.path.dirname(__file__), "required-clauses.txt")
WHITESPACE = re.compile(r"\s+")


def flatten(text):
    """Collapse every run of whitespace to one space.

    A clause is a fragment of prose, and prose gets rewrapped. Matched
    literally, a clause that fits on one line at 100 columns can break when the
    paragraph is rewrapped at 80 -- a tripwire that reddens a branch for a
    reformatting nobody meant as a policy change, and formatters do reflow
    files that something else reads as text. Collapsing whitespace on both
    sides also lets a clause match across a line break, which is the same thing
    from the other direction.

    It does not cover prefixed prose. When a comment (`# `) or a quotation
    (`> `) is rewrapped, the prefix lands between two words, and a pinned clause
    spanning that line break no longer matches.
    """
    return WHITESPACE.sub(" ", text)


def plural(count, noun):
    return f"{count} {noun}" if count == 1 else f"{count} {noun}s"


def declared(manifest):
    """Parse the manifest into [(lineno, path, clause)], or raise on a bad line.

    A line this cannot parse is an error rather than a line to skip: a typo in
    the separator would otherwise silently retire the clause it was meant to
    add, and a gate that quietly guards fewer things than its file lists is
    worse than no gate.
    """
    rows = []
    with open(manifest, encoding="utf-8") as handle:
        for lineno, raw in enumerate(handle, start=1):
            # `#` comments only at the start of a line. A clause is a fragment of
            # prose and routinely contains one -- every markdown heading does --
            # so stripping from the first `#` anywhere would truncate the clause
            # and then match the truncation, which passes while guarding nothing.
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if SEPARATOR not in line:
                raise ValueError(
                    f"line {lineno} has no '{SEPARATOR.strip()}' separator: {line.strip()}"
                )
            path, _, clause = line.partition(SEPARATOR)
            path, clause = path.strip(), clause.strip()
            if not path or not clause:
                raise ValueError(f"line {lineno} names an empty path or clause: {line.strip()}")
            # `git ls-files` never emits a leading `./`, so a path spelled that
            # way would be reported "not tracked" for a file that is tracked --
            # a true refusal with a false reason, which sends the reader to the
            # wrong repair.
            if path.startswith("./") or path.startswith("/"):
                raise ValueError(
                    f"line {lineno} must spell the path as git does, without a "
                    f"leading './' or '/': {path}"
                )
            # A duplicate row inflates the summary count, and that count is what
            # a reader takes as evidence of how much is guarded.
            if any(path == p and clause == c for _, p, c in rows):
                raise ValueError(f"line {lineno} repeats a clause already declared")
            rows.append((lineno, path, clause))
    return rows


def tracked(root):
    # S603/S607: a fixed argv, no shell, and `root` is this script's own
    # argument. Resolving an absolute path for `git` would break every runner
    # and developer machine that relies on PATH.
    listing = subprocess.run(  # noqa: S603
        ["git", "-C", root, "ls-files", "-z"],  # noqa: S607
        capture_output=True,
        check=True,
    ).stdout
    return {blob.decode("utf-8", "surrogateescape") for blob in listing.split(b"\0") if blob}


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    name = os.path.basename(MANIFEST)

    if not os.path.exists(MANIFEST):
        print(f"::error::{name} is missing, so this gate had nothing to check")
        return 1

    try:
        rows = declared(MANIFEST)
    except ValueError as exc:
        print(f"::error file={name}::{exc}")
        return 1

    # An empty manifest is the vacuous pass this gate exists to refuse. Emptied
    # by the same kind of merge that deletes a clause, it would report success
    # for every clause it no longer names.
    if not rows:
        print(f"::error::{name} declares no clauses, so this gate checked nothing")
        return 1

    in_tree = tracked(root)
    missing = []
    for lineno, path, clause in rows:
        if path not in in_tree:
            missing.append((path, lineno, "is not tracked, so the clause cannot be in it"))
            continue
        full = os.path.join(root, path)
        # A symlink is refused rather than followed. This manifest quotes every
        # clause verbatim, so it is itself a file that satisfies all of them:
        # pointing a policy file at the manifest would delete the policy and
        # leave every gate green. A policy file has no reason to be a symlink.
        if os.path.islink(full):
            missing.append((path, lineno, "is a symlink, so what it contains is another file's"))
            continue
        try:
            with open(full, encoding="utf-8") as handle:
                body = handle.read()
        except (OSError, UnicodeDecodeError) as exc:
            # Both are "could not look", and both must leave here the same way:
            # left uncaught, a decoding error escapes as a traceback with no
            # annotation naming the file.
            reason = exc.strerror if isinstance(exc, OSError) else "not valid UTF-8"
            missing.append((path, lineno, f"could not be read ({reason})"))
            continue
        if flatten(clause) not in flatten(body):
            missing.append((path, lineno, f"no longer contains: {clause}"))

    for path, lineno, why in missing:
        print(f"::error file={path}::{why} ({name} line {lineno})")

    if missing:
        print(
            f"\nmissing {plural(len(missing), 'required clause')}, of {len(rows)} "
            f"declared. Each one was decided deliberately; restore it, or retire it "
            f"from {name} in its own commit so the decision is visible."
        )
        return 1

    files = len({path for _, path, _ in rows})
    print(
        f"{plural(len(rows), 'required clause')} present, "
        f"across {plural(files, 'file')}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
