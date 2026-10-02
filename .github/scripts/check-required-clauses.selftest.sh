#!/usr/bin/env bash
# Proves the required-clause check can fail, and that it fails for the right
# reason.
#
# Every assertion is on the MESSAGE, and on the exact exit status beside it.
# This check has several separate ways of refusing — a clause gone from a file,
# a file gone from the tree, a file never tracked, an unreadable file, a
# manifest that is missing, empty or malformed — and one bit cannot tell them
# apart. A run where all but one of those branches works would otherwise be
# indistinguishable from a run where all of them work.
#
# The check resolves its manifest next to its own source, so every case below
# runs a COPY in a scratch directory. Writing the fixtures next to the real
# script would mean editing a tracked file in this repository and trusting a
# restore step to put it back.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source="$here/check-required-clauses.py"
[ -f "$source" ] || { echo "self-test FAILED: $source is missing" >&2; exit 1; }

work="$(mktemp -d "${TMPDIR:-/tmp}/required-clauses-selftest.XXXXXX")"
tools="$(mktemp -d "${TMPDIR:-/tmp}/required-clauses-tools.XXXXXX")"
cleanup() { chmod -R u+w "$work" "$tools" 2>/dev/null || true; rm -r -- "$work" "$tools"; }
trap cleanup EXIT

check="$tools/check-required-clauses.py"
manifest="$tools/required-clauses.txt"
cp "$source" "$check"

git -C "$work" init -q
git -C "$work" config user.email ci@example.invalid
git -C "$work" config user.name ci

fail() { echo "self-test FAILED: $1" >&2; exit 1; }

# Output first, status second: read `$?` after a pipe and you get the pipe's.
_out=""
_status=0
run() {
  # No `|| true`. Swallowed, a staging failure leaves every later case checking
  # the PREVIOUS index, and a suite that silently stopped advancing still passes.
  git -C "$work" add -A >/dev/null
  if _out="$(python3 "$check" "$work" 2>&1)"; then _status=0; else _status=$?; fi
}

expect_status() {
  [ "$_status" -eq "$2" ] || fail "$1
  expected exit status: $2
  actual exit status:   $_status
  actual output: $_out"
}

# A substring, not the whole line: these messages carry the clause itself, and
# a clause is prose that will be reworded. The reason and the manifest line
# number are the parts that distinguish the branches, and both are asserted.
expect_refusal() {
  local label="$1" want="$2"
  run
  printf '%s\n' "$_out" | grep -qF -- "$want" || fail "$label
  expected text: $want
  actual output: $_out"
  expect_status "$label: refused but exited wrong" 1
  printf '  ok  %s\n' "$label"
}

expect_clean() {
  local label="$1" want="$2"
  run
  printf '%s\n' "$_out" | grep -qxF -- "$want" || fail "$label
  expected line: $want
  actual output: $_out"
  # ...and that nothing was reported alongside it. A check printing both would
  # still have exited 0, so the status cannot separate these two.
  printf '%s\n' "$_out" | grep -q '::error' && fail "$label
  reported a finding on a compliant tree: $_out"
  expect_status "$label: said clean but exited wrong" 0
  printf '  ok  %s\n' "$label"
}

echo "required-clauses self-test"

# ── the clause is there, and the summary says what it looked at ─────────────
# Two clauses in ONE file, so a summary counting rows as files would be caught.
# The counts are also the only place the singular and the plural wording are
# exercised, which is why the fixtures below use two clauses and then one.
#
# The first clause contains `##`, deliberately: comments are recognised only at
# the start of a line, and a check stripping from the first `#` anywhere would
# truncate this clause to nothing and then match the truncation. The comment
# line above the clauses covers the converse — that a real comment is skipped.
printf '## Policy — hard rule\nNever do the thing.\n' > "$work/AGENTS.md"
# A comment and a blank line before the clauses, deliberately: they push the
# second clause to manifest line 4 while it stays the second ROW. Without that
# offset a reported line number and a row index are the same integer, and a
# check reporting the wrong one of the two reads as correct.
cat > "$manifest" <<'EOF'
# pinned deliberately

AGENTS.md :: ## Policy — hard rule
AGENTS.md :: Never do the thing.
EOF
expect_clean "present clauses read clean, counting clauses and files apart" \
  "2 required clauses present, across 1 file"

# ── a clause deleted from a file that is still there ───────────────────────
# The defect this gate exists for: the file survives the merge, the rule in it
# does not, and every other check stays green.
printf '## Policy — hard rule\n' > "$work/AGENTS.md"
expect_refusal "a deleted clause is reported with its text and its manifest line" \
  "::error file=AGENTS.md::no longer contains: Never do the thing. (required-clauses.txt line 4)"

# ── the file itself gone: a different reason, the same exit status ──────────
git -C "$work" rm -q -f AGENTS.md
expect_refusal "a clause whose file left the tree is reported as untracked" \
  "::error file=AGENTS.md::is not tracked, so the clause cannot be in it"

# ── present on disk but never tracked ──────────────────────────────────────
# Passes locally and is absent for everyone else. The same trap that makes a
# tracked-file scan pass vacuously before `git add`.
printf '## Policy — hard rule\nNever do the thing.\n' > "$work/AGENTS.md"
printf 'AGENTS.md\n' > "$work/.gitignore"
expect_refusal "a clause in an untracked file is refused, not passed" \
  "::error file=AGENTS.md::is not tracked, so the clause cannot be in it"
rm "$work/.gitignore"
run  # re-track it
expect_clean "tracking the file again satisfies the gate" \
  "2 required clauses present, across 1 file"

# ── the summary counts what is missing against what was declared ───────────
printf '## Policy — hard rule\n' > "$work/AGENTS.md"
expect_refusal "the summary counts the missing clauses against the declared ones" \
  "missing 1 required clause, of 2 declared"

printf '## Policy — hard rule\nNever do the thing.\n' > "$work/AGENTS.md"

# ── "nothing declared" must not read as "nothing missing" ──────────────────
# Emptied by the same kind of merge that deletes a clause, a manifest that
# declares nothing would report success for every clause it no longer names.
: > "$manifest"
expect_refusal "an empty manifest is refused, not read as compliant" \
  "required-clauses.txt declares no clauses, so this gate checked nothing"

printf '# only comments\n\n' > "$manifest"
expect_refusal "a comments-only manifest is empty too" \
  "declares no clauses, so this gate checked nothing"

mv "$manifest" "$tools/stashed.txt"
expect_refusal "a missing manifest is refused, not read as compliant" \
  "required-clauses.txt is missing, so this gate had nothing to check"
mv "$tools/stashed.txt" "$manifest"

# ── a malformed line is an error, never a line to skip ─────────────────────
# Skipped, a typo in the separator silently retires the clause it was meant to
# add. The line number is the only thing that makes it findable.
printf 'AGENTS.md : ## Policy — hard rule\n' > "$manifest"
expect_refusal "a line with no separator is refused, naming the line" \
  "line 1 has no '::' separator"

printf '\nAGENTS.md :: \n' > "$manifest"
expect_refusal "a line with an empty clause is refused, naming the line" \
  "line 2 names an empty path or clause"

printf ' :: Never do the thing.\n' > "$manifest"
expect_refusal "a line with an empty path is refused too" \
  "line 1 names an empty path or clause"

# ── a rewrap is not a policy change ────────────────────────────────────────
# Matched literally, a pinned clause survives at 100 columns and can break when
# rewrapped at 80: a tripwire that reddens a branch for a reformatting nobody
# meant as a change of policy. Whitespace is collapsed on both sides.
printf '## Policy — hard rule\nNever do\n   the thing.\n' > "$work/AGENTS.md"
printf 'AGENTS.md :: Never do the thing.\n' > "$manifest"
expect_clean "a clause still matches across a line break and a re-indent" \
  "1 required clause present, across 1 file"

# ...and collapsing whitespace must not collapse the words. A clause whose
# TEXT changed is still missing however it is wrapped.
printf '## Policy — hard rule\nNever do that thing.\n' > "$work/AGENTS.md"
expect_refusal "a reworded clause is still missing, wrapping notwithstanding" \
  "no longer contains: Never do the thing."

# Runs of whitespace collapse to ONE space, not to none. Collapsed to nothing,
# the separation between words is gone and a clause starts matching a
# concatenation that does not contain it: "do not" would be satisfied by
# "donotice". Every other case here passes either way, so this is the only thing
# standing between the normalisation and a looser match than anyone asked for.
printf 'donotice the difference\n' > "$work/AGENTS.md"
printf 'AGENTS.md :: do not\n' > "$manifest"
expect_refusal "a clause is not satisfied by a word that merely contains it unspaced" \
  "no longer contains: do not"

# ── the manifest is itself a file that satisfies every clause it quotes ─────
# Pointing the policy file at the manifest would delete the policy and leave
# the gate green, because the manifest quotes each clause verbatim.
printf '## Policy — hard rule\nNever do the thing.\n' > "$work/AGENTS.md"
printf 'AGENTS.md :: Never do the thing.\n' > "$manifest"
run
rm "$work/AGENTS.md"
mkdir -p "$work/.github/scripts"
printf 'AGENTS.md :: Never do the thing.\n' > "$work/.github/scripts/required-clauses.txt"
ln -s .github/scripts/required-clauses.txt "$work/AGENTS.md"
expect_refusal "a clause satisfied through a symlink is refused" \
  "::error file=AGENTS.md::is a symlink, so what it contains is another file's"
rm "$work/AGENTS.md"
rm -r "$work/.github"
printf '## Policy — hard rule\nNever do the thing.\n' > "$work/AGENTS.md"
run
expect_status "the tree is compliant again once the symlink is replaced by a file" 0
printf '  ok  %s\n' "the tree is compliant again once the symlink is replaced by a file"

# ── the summary count is evidence, so it must not be inflatable ────────────
printf 'AGENTS.md :: Never do the thing.\nAGENTS.md :: Never do the thing.\n' > "$manifest"
expect_refusal "a repeated clause is refused rather than counted twice" \
  "line 2 repeats a clause already declared"

# ── a path spelled in a way git never emits ────────────────────────────────
# `git ls-files` has no leading `./`, so if accepted this would report "is not
# tracked" for a file that is tracked: a true refusal with a false reason.
printf './AGENTS.md :: Never do the thing.\n' > "$manifest"
expect_refusal "a './'-prefixed path is refused, naming the real problem" \
  "must spell the path as git does"

# ── "could not look" covers a decoding failure too ─────────────────────────
# Uncaught, this escapes as a traceback with no annotation naming the file: the
# status is right and the reader is given nothing to act on.
printf 'AGENTS.md :: Never do the thing.\n' > "$manifest"
printf 'policy \351 latin-1\n' > "$work/AGENTS.md"
expect_refusal "a file that is not UTF-8 is reported, not raised" \
  "::error file=AGENTS.md::could not be read (not valid UTF-8)"
printf '## Policy — hard rule\nNever do the thing.\n' > "$work/AGENTS.md"

# ── "could not look" must not read as "clause present" ─────────────────────
printf '## Policy — hard rule\n' > "$work/AGENTS.md"
printf 'AGENTS.md :: ## Policy — hard rule\n' > "$manifest"
git -C "$work" add -A >/dev/null
if [ "$(id -u)" = 0 ]; then
  printf '  SKIP  %s\n' "unreadable-file case: running as root, where chmod 000 is inert"
else
chmod 000 "$work/AGENTS.md"
# Invoked directly: run() re-stages, and `git add` itself fails on a mode-000
# file, so the harness would never reach the check. The file is already
# tracked, which is the only precondition that matters here.
if _out="$(python3 "$check" "$work" 2>&1)"; then _status=0; else _status=$?; fi
chmod 644 "$work/AGENTS.md"
printf '%s\n' "$_out" | grep -qF -- "::error file=AGENTS.md::could not be read" || fail \
  "an unreadable file was not reported
  actual output: $_out"
expect_status "an unreadable file is reported, not skipped" 1
printf '  ok  %s\n' "an unreadable file is reported, not skipped"
fi

expect_clean "the tree is compliant again once every fixture is restored" \
  "1 required clause present, across 1 file"

echo "self-test passed: a present clause, a deleted clause, a file that left"
echo "the tree, a file never tracked, the missing-count summary, a rewrap and a"
echo "rewording, a symlink, a repeated clause, a './' path, a non-UTF-8 file, an"
echo "empty manifest, a comments-only manifest, a missing manifest, three"
echo "malformed lines and an unreadable file each proved by their own message"
echo "AND their own exit status"
