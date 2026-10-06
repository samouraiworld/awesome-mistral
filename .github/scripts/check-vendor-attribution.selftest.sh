#!/usr/bin/env bash
# Proves the attribution check can fail, and that it fails for the right reason.
#
# Every assertion below is on the MESSAGE the check prints; all but the order
# check and the allowlist cases also assert the exact exit status beside it. An
# exit status is one bit, and this check has several separate ways of finding
# something: plain text, base64, an inflated compressed chunk, a forbidden chunk
# type, and the allowlist that can exempt any of them. One bit cannot tell those
# apart, so a run in which every branch but one still works is indistinguishable
# from a run in which all of them work. Each case here names the file it expects
# reported and the reason it expects given — the part that differs between
# branches — and matches the whole line, so an extra or a missing reason fails
# too.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$here/check-vendor-attribution.py"
[ -f "$check" ] || { echo "self-test FAILED: $check is missing" >&2; exit 1; }

# Assembled at runtime on purpose. Spelled as one word, this file would itself
# be a finding, and the check would flag the test that proves it works.
needle="cla""ude"

work="$(mktemp -d "${TMPDIR:-/tmp}/vendor-attribution-selftest.XXXXXX")"
spare="$(mktemp -d "${TMPDIR:-/tmp}/vendor-attribution-tools.XXXXXX")"
cleanup() { chmod -R u+w "$work" "$spare" 2>/dev/null || true; rm -rf -- "$work" "$spare"; }
trap cleanup EXIT

git -C "$work" init -q
git -C "$work" config user.email ci@example.invalid
git -C "$work" config user.name ci

fail() { echo "self-test FAILED: $1" >&2; exit 1; }

# Every case that passes says so through here, and the total is checked at the
# end against the number of cases this file holds. A case deleted by mistake,
# or a block skipped by a stray early exit, would otherwise leave a shorter run
# that still ends by saying it passed.
cases=0
ok() { cases=$((cases + 1)); printf '  %s  %s\n' ok "$1"; }

# Every run of the check is held to a wall clock. A change that makes it slow,
# or makes it block on something it should never have opened, then fails the
# case it belongs to, by name and with status 124, instead of holding CI until
# the job's own timeout. Standard input passes through, for the --text cases.
#
# `bounded SECONDS SCRIPT ARGS...` runs the Python SCRIPT under a timer in its
# own process, rather than under a second process that watches it: one start
# of the interpreter per run instead of two, which is most of what a case
# costs. The timer's signal is left at its default action, which ends the
# process even inside a call that blocks, such as opening a FIFO; the shell
# sees status 142 (128 + SIGALRM), which nothing else here can produce.
limit=60
bounded() {
  local code=0
  python3 -c '
import runpy, signal, sys
signal.setitimer(signal.ITIMER_REAL, float(sys.argv[1]))
sys.argv = sys.argv[2:]
runpy.run_path(sys.argv[0], run_name="__main__")' "$@" || code=$?
  if [ "$code" -eq 142 ]; then
    echo "TIMED OUT: still running after ${1}s, and stopped"
    code=124
  fi
  return "$code"
}

# The check a case runs: the one beside this file, except in the cases that
# run a copy with one bound lowered (see `patched` below).
use="$check"


# Stages whatever the fixture left behind, returns the check's output, and
# records the exit status for `expect_status`.
_out=""
_status=0
run() {
  git -C "$work" add -A
  if _out="$(bounded "$limit" "$use" "$work" 2>&1)"; then _status=0; else _status=$?; fi
  printf '%s\n' "$_out"
}

# The message tells the branches apart; the exit status is the only thing CI
# consumes. Asserting the message without the status lets a refusal flipped to
# a pass go unnoticed: message assertions alone all still pass with the
# checker's `return 1` changed to `return 0`.
#
# The EXACT status, not merely non-zero: a traceback also exits non-zero, and
# "could not look" must never read as "found something".
expect_status() {
  [ "$_status" -eq "$2" ] || fail "$1
  expected exit status: $2
  actual exit status:   $_status
  actual output: $_out"
}

# Output reaches grep as a here-string, never through a pipe: `grep -q` exits
# at the first match and closes the pipe, and under pipefail the writer's
# SIGPIPE then fails a case whose line did match.
#
# The whole line, matched literally. Substring-matching the reason alone would
# also accept a line that carried a second, unexpected reason beside it.
expect_line() {
  local label="$1" want="$2" out
  run; out="$_out"
  if ! grep -qxF -- "$want" <<<"$out"; then
    fail "$label
  expected line: $want
  actual output: $out"
  fi
  expect_status "$label: reported the finding but exited wrong" 1
  ok "$label"
}

expect_text() {
  local label="$1" want="$2" out
  run; out="$_out"
  if ! grep -qF -- "$want" <<<"$out"; then
    fail "$label
  expected text: $want
  actual output: $out"
  fi
  expect_status "$label: reported the finding but exited wrong" 1
  ok "$label"
}

expect_clean() {
  local label="$1" out
  run; out="$_out"
  if ! grep -qxF -- 'no tracked file carries assistant attribution' <<<"$out"; then
    fail "$label
  expected the clean-tree message
  actual output: $out"
  fi
  # ...and that it reported nothing alongside it. A check that printed both
  # would still have exited 0, so the exit status cannot separate these two.
  if grep -q '::error' <<<"$out"; then
    fail "$label
  reported a finding on a clean tree: $out"
  fi
  expect_status "$label: said clean but exited wrong" 0
  ok "$label"
}

echo "vendor-attribution self-test"

# The wall clock itself, proven before anything relies on it: a run that
# overruns is stopped, promptly, says so, and exits 124.
printf 'import time\ntime.sleep(30)\n' > "$spare/sleep.py"
started="$(date +%s)"
if _out="$(bounded 0.3 "$spare/sleep.py" 2>&1)"; then _status=0; else _status=$?; fi
[ $(( $(date +%s) - started )) -le 5 ] || fail "the wall clock let an overrunning run go on"
grep -qxF -- 'TIMED OUT: still running after 0.3s, and stopped' <<<"$_out" \
  || fail "the wall clock did not stop an overrunning run
  actual output: $_out"
expect_status "the wall clock stopped the run but exited wrong" 124
ok "the wall clock stops a run that overruns, and says so"

printf 'nothing to declare\n' > "$work/clean.txt"
expect_clean "a clean tree says so, and reports nothing"

# 1. Plain text — what a grep-based rule assumes, and the only one of these a
#    recursive grep would catch on its own.
printf 'produced with %s assistance\n' "$needle" > "$work/plain.txt"
expect_line "plain text names the file and the needle" \
  "::error file=plain.txt::carries $needle"
rm "$work/plain.txt"

# 2. Binary metadata — a NUL byte makes grep treat the file as binary: `grep -I`
#    skips it, and plain grep reports only a one-line "binary file matches"
#    notice. One of the ways attribution arrives unseen.
printf 'PNG\000metadata\000%s\000' "$needle" > "$work/blob.bin"
expect_line "attribution inside binary metadata is caught" \
  "::error file=blob.bin::carries $needle"
rm "$work/blob.bin"

# 3. Base64 — another. The name is not text anywhere in the file, and the
#    reported reason has to say so: matching the whole line proves the decoding
#    branch is what caught it, rather than a stray plain-text match that would
#    leave the base64 path untested.
payload="$(printf 'padding%.0s' $(seq 1 40))$needle"
encoded="$(printf '%s' "$payload" | base64 | tr -d '\n')"
printf '<svg><metadata>%s</metadata></svg>\n' "$encoded" > "$work/hidden.svg"
if grep -qi "$needle" "$work/hidden.svg"; then
  fail "the base64 fixture is not actually hidden"
fi
expect_line "base64 is caught, and reported as base64" \
  "::error file=hidden.svg::carries $needle (base64)"
rm "$work/hidden.svg"

# 4. The decoding threshold. The fixture above is long enough to be decoded
#    under a much higher minimum, such as 120 characters, so on its own it
#    proves nothing about how short an encoded name the check still decodes.
short="$(printf '%s' "$(printf 'x%.0s' $(seq 1 24))$needle" | base64 | tr -d '\n')"
if [ "${#short}" -lt 40 ] || [ "${#short}" -gt 50 ]; then
  fail "threshold fixture is ${#short} chars, wanted 40 to 50"
fi
printf '<svg><desc>%s</desc></svg>\n' "$short" > "$work/short.svg"
expect_line "a ${#short}-character base64 run is still decoded" \
  "::error file=short.svg::carries $needle (base64)"
rm "$work/short.svg"

# 5. A compressed chunk, built deliberately on a colour profile. That chunk
#    type is PERMITTED, so the file cannot be caught on its type — only
#    inflation can catch it, and the reason reported has to say "compressed
#    chunk", or something other than the inflation branch is what ran.
NEEDLE="$needle" python3 - "$work/compressed.png" <<'PY'
import os, struct, sys, zlib

def chunk(kind, body):
    return (struct.pack(">I", len(body)) + kind + body
            + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF))

text = ("Profile produced with " + os.environ["NEEDLE"]).encode()
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
       + chunk(b"iCCP", b"ICC profile\x00\x00" + zlib.compress(text))
       + chunk(b"IDAT", zlib.compress(b"\x00\x00"))
       + chunk(b"IEND", b""))
open(sys.argv[1], "wb").write(png)
PY
if grep -qi "$needle" "$work/compressed.png"; then
  fail "the compressed fixture is not actually hidden"
fi
expect_line "a permitted compressed chunk is inflated and reported as such" \
  "::error file=compressed.png::carries $needle (compressed chunk)"
rm "$work/compressed.png"

# 6. The converse: a forbidden chunk type is a finding on its own, carrying
#    nothing incriminating at all. The reason is what separates this branch
#    from the one above — by exit status the two fixtures are identical.
python3 - "$work/bare.png" <<'PY'
import struct, sys, zlib

def chunk(kind, body):
    return (struct.pack(">I", len(body)) + kind + body
            + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF))

png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
       + chunk(b"tEXt", b"Comment\x00nothing incriminating here")
       + chunk(b"IDAT", zlib.compress(b"\x00\x00"))
       + chunk(b"IEND", b""))
open(sys.argv[1], "wb").write(png)
PY
expect_line "a forbidden chunk type is reported as the chunk, with no name in it" \
  "::error file=bare.png::carries tEXt chunk"
rm "$work/bare.png"

# 7. The summary counts files, and the listing is sorted. A caller reads both,
#    and neither is visible in the exit status. Checking the order needs an
#    ordered read: two findings whose sorted order is known in advance.
printf 'a %s\n' "$needle" > "$work/a-first.txt"
printf 'z %s\n' "$needle" > "$work/z-last.txt"
expect_text "the summary counts the files it found" \
  "2 tracked files carry attribution"
run; ordered="$_out"
first="$(printf '%s\n' "$ordered" | grep -n 'a-first.txt' | cut -d: -f1)"
last="$(printf '%s\n' "$ordered" | grep -n 'z-last.txt' | cut -d: -f1)"
if [ -z "$first" ] || [ -z "$last" ] || [ "$first" -ge "$last" ]; then
  fail "findings are not listed in sorted order
  actual output: $ordered"
fi
ok "findings are listed in sorted order"
rm "$work/a-first.txt" "$work/z-last.txt"

expect_clean "the tree is clean again once every fixture is removed"

# 8. The allowlist, exercised against a COPY of the check in a scratch
#    directory. It resolves its allowlist next to its own source, so testing
#    it in place would mean writing to a tracked file in this repository and
#    trusting a restore step to put it back. The copy makes the exemption
#    impossible to leak into the repository at all.
cp "$check" "$spare/check-vendor-attribution.py"
printf 'exempt %s\n' "$needle" > "$work/exempt.txt"
git -C "$work" add -A

before="$(bounded "$limit" "$spare/check-vendor-attribution.py" "$work" 2>&1 || true)"
if ! grep -qxF -- "::error file=exempt.txt::carries $needle" <<<"$before"; then
  fail "with no allowlist, the file should have been reported
  actual output: $before"
fi
ok "with no allowlist the file is reported"

printf 'exempt.txt\n' > "$spare/vendor-attribution-allowlist.txt"
after="$(bounded "$limit" "$spare/check-vendor-attribution.py" "$work" 2>&1 || true)"
if ! grep -qxF -- 'no tracked file carries assistant attribution' <<<"$after"; then
  fail "an allowlisted file should have been exempt
  actual output: $after"
fi
ok "an allowlisted path is exempt, and the tree reads clean"

# The comment syntax the allowlist file documents, proven rather than assumed:
# commented out, the same entry must stop exempting anything.
printf '# exempt.txt\n' > "$spare/vendor-attribution-allowlist.txt"
commented="$(bounded "$limit" "$spare/check-vendor-attribution.py" "$work" 2>&1 || true)"
if ! grep -qxF -- "::error file=exempt.txt::carries $needle" <<<"$commented"; then
  fail "a commented-out allowlist entry should not exempt anything
  actual output: $commented"
fi
ok "a commented-out allowlist entry exempts nothing"

# ── the PATH is published as loudly as the contents ──────────────────────────
# A filename is published as surely as a file's contents, and a scan of contents
# alone cannot see one. Each fixture below is innocuous INSIDE, so only the path
# scan can catch it.
rm -f "$work"/*.txt "$work"/*.md 2>/dev/null || true
git -C "$work" add -A >/dev/null 2>&1 || true

printf 'nothing to declare\n' > "$work/$needle.md"
expect_line "the marker in a filename is caught" \
  "::error file=$needle.md::carries $needle (in the path)"
rm "$work/$needle.md"

mkdir -p "$work/docs/$needle-assets"
printf 'nothing to declare\n' > "$work/docs/$needle-assets/readme.txt"
expect_line "the marker in a directory component is caught" \
  "::error file=docs/$needle-assets/readme.txt::carries $needle (in the path)"
rm -r "$work/docs"

upper="$(printf '%s' "$needle" | tr '[:lower:]' '[:upper:]')"
printf 'nothing to declare\n' > "$work/$upper.md"
expect_line "an uppercase filename is caught, and reported lower-cased" \
  "::error file=$upper.md::carries $needle (in the path)"
rm "$work/$upper.md"

# ...and the path scan must not MASK the content scan: a clean path with dirty
# contents still reports the content reason, with no "(in the path)" suffix.
printf 'x %s\n' "$needle" > "$work/plain.txt"
expect_line "a clean path with dirty contents reports only the content reason" \
  "::error file=plain.txt::carries $needle"
rm "$work/plain.txt"
expect_clean "the tree is clean once the path fixtures are removed"

# ── "could not look" must not read as "clean" ────────────────────────────────
# Skipped rather than reported, both of these would read as a clean tree and
# exit 0.
# `chmod 000` does not stop root reading a file, so under a root container this
# case would read the file, find nothing, exit 0 and fail the suite for an
# environment reason. Skipped audibly instead: a silent skip is the thing this
# file exists to refuse.
skipped=0
if [ "$(id -u)" = 0 ]; then
  printf '  SKIP  %s\n' "unreadable-file cases: running as root, where chmod 000 is inert"
  skipped=1
else
printf 'readable for now\n' > "$work/locked.txt"
git -C "$work" add -A >/dev/null
chmod 000 "$work/locked.txt"
# Invoked directly rather than through run(): run() re-stages, and `git add`
# itself fails on a mode-000 file, so the harness would never reach the checker.
# The file is already tracked, which is the only precondition that matters here.
if _out="$(bounded "$limit" "$check" "$work" 2>&1)"; then _status=0; else _status=$?; fi
if ! grep -q 'locked.txt.*could not be read' <<<"$_out"; then
  chmod 644 "$work/locked.txt"; rm -f "$work/locked.txt"
  fail "an unreadable tracked file was not reported
  actual output: $_out"
fi
expect_status "an unreadable tracked file is reported, not skipped" 1
ok "an unreadable tracked file is reported, not skipped"
chmod 644 "$work/locked.txt"; rm "$work/locked.txt"
fi

# A tracked path that is not a regular file where one is tracked. A FIFO is
# the sharpest case: opened the ordinary way, the read blocks forever, so this
# also proves the check does not open it that way.
printf 'a file for now\n' > "$work/pipe.txt"
git -C "$work" add -A >/dev/null
rm "$work/pipe.txt"
mkfifo "$work/pipe.txt"
# Direct, like the mode-000 case: `git add` refuses a FIFO.
if _out="$(bounded "$limit" "$check" "$work" 2>&1)"; then _status=0; else _status=$?; fi
rm -f "$work/pipe.txt"
if ! grep -qxF -- '::error file=pipe.txt::carries could not be read (not a regular file)' <<<"$_out"; then
  fail "a FIFO where a file is tracked was not reported
  actual output: $_out"
fi
expect_status "a FIFO where a file is tracked is reported" 1
ok "a FIFO where a file is tracked is reported as not a regular file, without blocking"

# A symlink where a regular file is tracked: the working tree no longer holds
# what git would publish, and the link is not followed to find out.
printf 'written by %s\n' "$needle" > "$spare/elsewhere.txt"
printf 'a file for now\n' > "$work/swapped.txt"
git -C "$work" add -A >/dev/null
rm "$work/swapped.txt"
ln -s "$spare/elsewhere.txt" "$work/swapped.txt"
if _out="$(bounded "$limit" "$check" "$work" 2>&1)"; then _status=0; else _status=$?; fi
rm -f "$work/swapped.txt"
git -C "$work" add -A >/dev/null
grep -qE -- '^::error file=swapped\.txt::carries could not be read \([^)]+\)$' <<<"$_out" \
  || fail "a symlink where a file is tracked was followed, or not reported
  actual output: $_out"
expect_status "a symlink where a file is tracked is reported" 1
ok "a symlink where a file is tracked is reported, not followed"
expect_clean "the tree is clean once the unreadable fixtures are removed"

# ── a symlink publishes the path it holds, and only that ────────────────────
# Git stores a symlink as the text of its target, so that text is what the
# repository publishes, and what is read. What the link leads to is not
# published, and following it can read a device or a FIFO without end. Every
# target here is relative, so that no temporary directory's name ends up in
# the text that is read.
ln -s "notes/$needle-notes.txt" "$work/ghost.txt"
expect_line "a symlink is read as the path it holds, dangling or not" \
  "::error file=ghost.txt::carries $needle (in the link target)"
rm "$work/ghost.txt"

outside="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$spare" "$work")"
printf 'written by %s\n' "$needle" > "$spare/outside.txt"
ln -s "$outside/outside.txt" "$work/outside.txt"
expect_clean "a symlink is not followed: what it leads to is not what the repository publishes"
rm "$work/outside.txt"

mkfifo "$spare/fifo"
ln -s "$outside/fifo" "$work/fifo-link.txt"
expect_clean "a symlink to a FIFO is read as its path, and does not block"
rm "$work/fifo-link.txt"
git -C "$work" add -A
expect_clean "the tree is clean once the link fixtures are removed"

# ── a submodule is a commit id, not a file ───────────────────────────────────
# Its contents belong to another repository and are checked there. Opened as a
# file, the submodule's directory would be reported as unreadable, failing
# every tree that has one. Its PATH is still published here, so a marker in the
# path must still be caught.
nested="$work/vendored"
git -C "$work" config advice.addEmbeddedRepo false
git init -q "$nested"
git -C "$nested" config user.email ci@example.invalid
git -C "$nested" config user.name ci
printf 'made with %s\n' "$needle" > "$nested/inside.txt"
git -C "$nested" add -A
git -C "$nested" commit -q -m fixture
expect_clean "a submodule's contents are not this tree's files"
git -C "$work" rm -q -f --cached vendored
mv "$nested" "$work/$needle-vendored"
expect_line "a marker in a submodule's path is still caught" \
  "::error file=$needle-vendored::carries $needle (in the path)"
git -C "$work" rm -q -f --cached "$needle-vendored"
mv "$work/$needle-vendored" "$spare/"
expect_clean "the tree is clean once the submodule fixtures are removed"

# ── the manifest namespace, in both directions ─────────────────────────────
# It is FOUR bytes. Matched as a bare substring it collides with base64: it
# can refuse an npm lockfile whose only crime is an integrity hash containing
# those four characters. Both directions are asserted, because an anchor that
# is too tight stops catching real manifests and no existing case would notice.
ns="$(printf '\x63\x32\x70\x61')"
printf '<svg xmlns:%s="http://example.invalid/ns"><g/></svg>\n' "$ns" > "$work/manifest.svg"
expect_line "a declared manifest namespace is caught" \
  "::error file=manifest.svg::carries $ns"
rm "$work/manifest.svg"

printf '<x><%s:claim/></x>\n' "$ns" > "$work/qualified.xml"
expect_line "a namespace-qualified name is caught" \
  "::error file=qualified.xml::carries $ns"
rm "$work/qualified.xml"

# The negative, which is the collision real trees produce: the four characters
# inside a base64 integrity hash, with no manifest anywhere.
printf '{"integrity":"sha512-R8gLRTZeyp03ymzP6Lil28tGeGEzhx1q2k703KGWRAI1VdvPIXdG70VJ%sMw3NA6JKL5hhFu1sJX0Mnn"}\n' "$ns" > "$work/package-lock.json"
expect_clean "four characters inside an integrity hash are not a manifest"
rm "$work/package-lock.json"

# ── base64 as encoders actually emit it: wrapped ────────────────────────────
# `base64` wraps at 76 columns by default, PEM and MIME at 64 or 76, often with
# CRLF, and YAML indents the block. Read line by line, a name in a short last
# line falls under the 40-character floor, and a name across a line break is
# split between two decodes. Every earlier base64 fixture strips its newlines,
# so none of them can show it. The fixtures fold explicitly rather than
# trusting `base64` to wrap: BSD `base64` does not.

# Prints the lines of the base64 in $1 that a single-line decode would catch: at
# least the 40-character floor, and carrying the name once decoded alone. A
# wrapped fixture must print nothing, or a single-line decode could be what
# catches it and the wrapped path would go untested.
lines_alone_carry() {
  NEEDLE="$needle" python3 - "$1" <<'PY'
import base64, os, re, sys
needle = os.environ["NEEDLE"].encode()
for line in re.split(rb"\r?\n|\\n", open(sys.argv[1], "rb").read()):
    run = re.sub(rb"[^A-Za-z0-9+/=]", b"", line)
    if len(run) < 40:
        continue
    run += b"=" * (-len(run) % 4)
    try:
        if needle in base64.b64decode(run).lower():
            print(line.decode())
    except Exception:
        pass
PY
}

printf '%060d%s' 0 "$needle" | base64 | tr -d '\n' | fold -w 76 > "$spare/tail.b64"
if [ "$(awk 'END { print length($0) }' "$spare/tail.b64")" -ge 40 ]; then
  fail "the short-last-line fixture's last line is not short"
fi
[ -z "$(lines_alone_carry "$spare/tail.b64")" ] || fail "the short-last-line fixture is caught line by line"
printf '<svg><desc>\n%s\n</desc></svg>\n' "$(cat "$spare/tail.b64")" > "$work/wrapped-tail.svg"
expect_line "wrapped at 76, a name in a short last line is decoded" \
  "::error file=wrapped-tail.svg::carries $needle (base64)"
rm "$work/wrapped-tail.svg"

# Both lines here are well over the floor, so it is the split, not the length,
# that the single-line decode misses.
printf '%055d%s%040d' 0 "$needle" 0 | base64 | tr -d '\n' | fold -w 76 > "$spare/split.b64"
[ -z "$(lines_alone_carry "$spare/split.b64")" ] || fail "the line-break fixture is caught line by line"
printf '<svg><desc>\n%s\n</desc></svg>\n' "$(cat "$spare/split.b64")" > "$work/wrapped-split.svg"
expect_line "wrapped at 76, a name across the line break is decoded" \
  "::error file=wrapped-split.svg::carries $needle (base64)"
rm "$work/wrapped-split.svg"

# PEM shape: 64 columns, CRLF, and the indentation of a YAML block scalar.
printf '%046d%s%040d' 0 "$needle" 0 | base64 | tr -d '\n' | fold -w 64 \
  | awk '{ printf "  %s\r\n", $0 }' > "$spare/pem.b64"
[ -z "$(lines_alone_carry "$spare/pem.b64")" ] || fail "the CRLF fixture is caught line by line"
{ printf 'blob: |\r\n'; cat "$spare/pem.b64"; } > "$work/wrapped.yaml"
expect_line "wrapped at 64 with CRLF and indentation, the name is decoded" \
  "::error file=wrapped.yaml::carries $needle (base64)"
rm "$work/wrapped.yaml"

# Inside a JSON string a line break is the two characters backslash and n.
printf '%046d%s%040d' 0 "$needle" 0 | base64 | tr -d '\n' | fold -w 64 \
  | awk '{ printf "%s\\n", $0 }' > "$spare/json.b64"
[ -z "$(lines_alone_carry "$spare/json.b64")" ] || fail "the JSON fixture is caught line by line"
printf '{"blob": "%s"}\n' "$(cat "$spare/json.b64")" > "$work/wrapped.json"
expect_line "wrapped inside a JSON string, the name is decoded" \
  "::error file=wrapped.json::carries $needle (base64)"
rm "$work/wrapped.json"

# A block after a line of prose: the join takes the last word of that line as
# its first piece, three characters that put every later line out of step with
# base64's four-character groups, so the block is decoded again from its first
# whole line.
printf '%055d%s%040d' 0 "$needle" 0 | base64 | tr -d '\n' | fold -w 76 > "$spare/prose.b64"
[ -z "$(lines_alone_carry "$spare/prose.b64")" ] || fail "the prose fixture is caught line by line"
printf 'the signing key\n%s\n' "$(cat "$spare/prose.b64")" > "$work/after-prose.txt"
expect_line "a wrapped block after a line of prose is decoded in step" \
  "::error file=after-prose.txt::carries $needle (base64)"
rm "$work/after-prose.txt"

# The converse, because joining lines is exactly how a check starts reading
# prose as base64: a wrapped block of clean bytes, and a column of words each
# on a line of its own, which joins into one long run of the alphabet.
printf '%0200d' 0 | base64 | tr -d '\n' | fold -w 76 > "$work/clean-wrapped.txt"
seq 1 200 | awk '{ printf "word%s\n", $0 }' > "$work/column.txt"
expect_clean "clean wrapped base64 and a column of words read clean"
rm "$work/clean-wrapped.txt" "$work/column.txt"

# ── what sits next to a blob must not cost the blob ─────────────────────────
# Each of these is the whole blob, readable as it stands, lost only to what is
# written beside it.

# The join takes the first word of the line after a block as its last piece.
# With no padding at the end of the block, a word one character past a
# four-character group ("Hello", five) fails the decode, and the whole joined
# block with it, so the block is decoded again short of that word.
printf '%055d%s%053d' 0 "$needle" 0 | base64 | tr -d '\n' | fold -w 76 > "$spare/unpadded.b64"
if grep -q '=' "$spare/unpadded.b64"; then fail "the short-word fixture is padded"; fi
[ -z "$(lines_alone_carry "$spare/unpadded.b64")" ] || fail "the short-word fixture is caught line by line"
{ cat "$spare/unpadded.b64"; printf '\nHello world\n'; } > "$work/short-word.txt"
expect_line "a wrapped block followed by a short word is decoded short of the word" \
  "::error file=short-word.txt::carries $needle (base64)"
rm "$work/short-word.txt"

# More than one line of a single word after the block: each is joined on as a
# piece of its own, so dropping only the last still leaves "Hello" glued on,
# five characters, one past a four-character group.
{ cat "$spare/unpadded.b64"; printf '\nHello\nabcd\n'; } > "$work/short-words.txt"
expect_line "a wrapped block followed by two one-word lines is decoded short of both" \
  "::error file=short-words.txt::carries $needle (base64)"
rm "$work/short-words.txt"

# Blanks before the line break: two of them are a hard line break in Markdown.
printf '%055d%s%040d' 0 "$needle" 0 | base64 | tr -d '\n' | fold -w 76 \
  | awk '{ printf "%s  \n", $0 }' > "$spare/blanks.b64"
[ -z "$(lines_alone_carry "$spare/blanks.b64")" ] || fail "the trailing-blanks fixture is caught line by line"
cp "$spare/blanks.b64" "$work/hard-breaks.md"
expect_line "wrapped with trailing blanks before each break, the name is decoded" \
  "::error file=hard-breaks.md::carries $needle (base64)"
rm "$work/hard-breaks.md"

# The same trouble at the other end: more than one line of a single word before
# the block, each joined on in front of it.
{ printf 'the\nsigning\n'; cat "$spare/unpadded.b64"; printf '\n'; } > "$work/words-before.txt"
expect_line "a wrapped block after two one-word lines is decoded in step" \
  "::error file=words-before.txt::carries $needle (base64)"
rm "$work/words-before.txt"

# A blank line inside a blob, and a lone CR as the line end.
{ head -n 1 "$spare/split.b64"; printf '\n'; tail -n +2 "$spare/split.b64"; } > "$work/blank-line.txt"
expect_line "a blank line inside a wrapped blob does not cut it" \
  "::error file=blank-line.txt::carries $needle (base64)"
rm "$work/blank-line.txt"
tr '\n' '\r' < "$spare/split.b64" > "$work/lone-cr.txt"
expect_line "wrapped with a lone CR at each line end, the name is decoded" \
  "::error file=lone-cr.txt::carries $needle (base64)"
rm "$work/lone-cr.txt"

# A blob kept in a quote carries a prefix on every line. The comment prefixes
# have cases of their own below, at another width.
sed 's|^|> |' "$spare/split.b64" > "$work/prefixed.txt"
[ -z "$(lines_alone_carry "$work/prefixed.txt")" ] || fail "the '> ' fixture is caught line by line"
expect_line "wrapped behind a '> ' line prefix, the name is decoded" \
  "::error file=prefixed.txt::carries $needle (base64)"
rm "$work/prefixed.txt"

# A blob in source code, split across string literals: joined with `+` in
# JavaScript, by adjacency in Python, as the elements of a JSON array.
awk 'NR > 1 { printf " +\n" } { printf "  \"%s\"", $0 } END { print ";" }' "$spare/split.b64" > "$work/concat.js"
[ -z "$(lines_alone_carry "$work/concat.js")" ] || fail "the concatenation fixture is caught line by line"
expect_line "a blob split across concatenated string literals is joined" \
  "::error file=concat.js::carries $needle (base64)"
rm "$work/concat.js"
{ printf 'BLOB = (\n'; sed 's/.*/    "&"/' "$spare/split.b64"; printf ')\n'; } > "$work/adjacent.py"
expect_line "a blob split across adjacent string literals is joined" \
  "::error file=adjacent.py::carries $needle (base64)"
rm "$work/adjacent.py"
{ printf '{"lines": ['; paste -sd '|' "$spare/split.b64" | sed 's/|/", "/g; s/^/"/; s/$/"/'; printf ']}\n'; } > "$work/lines.json"
expect_line "a blob split across the strings of a JSON array is joined" \
  "::error file=lines.json::carries $needle (base64)"
rm "$work/lines.json"

# A JSON encoder may escape every slash, and base64 of high bytes is full of
# them. Each escape cuts the run, and no piece between two of them is long
# enough to decode.
NEEDLE="$needle" python3 - "$work/escaped.json" <<'PY'
import base64, os, sys
text = (bytes(range(250, 256)) * 8 + b" by " + os.environ["NEEDLE"].encode()
        + b" " + bytes((255, 254, 253)) * 20)
encoded = base64.b64encode(text)
assert encoded.count(b"/") > 5
open(sys.argv[1], "wb").write(b'{"u": "' + encoded.replace(b"/", b"\\/") + b'"}\n')
PY
if grep -qi "$needle" "$work/escaped.json"; then fail "the escaped-slash fixture is not hidden"; fi
expect_line "base64 with every slash escaped, as JSON may write it, is decoded" \
  "::error file=escaped.json::carries $needle (base64)"
rm "$work/escaped.json"

# A `key=` prefix: `=` is in the alphabet, so the key and the blob are one run,
# and the key's five characters put the blob out of step when it is decoded.
encoded="$(printf 'a note written by %s and kept here for later reference ok' "$needle" | base64 | tr -d '\n')"
printf 'token=%s\n' "$encoded" > "$work/prefixed.env"
if grep -qi "$needle" "$work/prefixed.env"; then fail "the key-prefix fixture is not hidden"; fi
expect_line "base64 behind a key= prefix is decoded from after the =" \
  "::error file=prefixed.env::carries $needle (base64)"
rm "$work/prefixed.env"

# Fixtures too fiddly for a one-liner, all built at once and then copied into
# place by name: `built NAME PATH`.
cat > "$spare/fx.py" <<'PY'
import base64, functools, gzip, hashlib, io, os, struct, sys, zipfile, zlib

N = os.environ["NEEDLE"].encode()
SIG = b"\x89PNG\r\n\x1a\n"


def chunk(kind, body):
    crc = zlib.crc32(kind + body) & 0xFFFFFFFF
    return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", crc)


def png(*extra):
    return (SIG + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
            + b"".join(extra) + chunk(b"IDAT", zlib.compress(b"\x00\x00")) + chunk(b"IEND", b""))


def profile(data):
    return chunk(b"iCCP", b"p\x00\x00" + data)


def noise(seed, size):
    out = b""
    while len(out) < size:
        out += hashlib.sha256(b"%d/%d" % (seed, len(out))).digest()
    return out[:size]


def b64(data, times=1):
    for _ in range(times):
        data = base64.b64encode(data)
    return data


def raw_deflate(data):
    packer = zlib.compressobj(9, zlib.DEFLATED, -15)
    return packer.compress(data) + packer.flush()



def sprites(distinct):
    # Fifty small SVGs as data URIs, each holding an image as a data URI of its
    # own: the same image in every one, or a different one in each.
    rows = []
    for i in range(50):
        inner = b64(noise(i if distinct else 0, 3000))
        svg = b'<svg id="%d"><image href="data:image/png;base64,' % i + inner + b'"/></svg>'
        rows.append(b"icon%d: data:image/svg+xml;base64," % i + b64(svg) + b";")
    return b"\n".join(rows) + b"\n"



def zipped(*members):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for number, member in enumerate(members):
            archive.writestr("part%d.bin" % number, member)
    return buffer.getvalue()


def docx(properties, first=None):
    buffer = io.BytesIO()
    member = zipfile.ZipInfo("docProps/app.xml")
    member.compress_type = zipfile.ZIP_DEFLATED
    # An extended-timestamp field, which moves the member's data along.
    member.extra = b"\x55\x54\x05\x00\x01\x00\x00\x00\x00"
    with zipfile.ZipFile(buffer, "w") as archive:
        if first is not None:
            archive.writestr(zipfile.ZipInfo("[Content_Types].xml"), first,
                             compress_type=zipfile.ZIP_DEFLATED)
        archive.writestr(member, properties)
    return buffer.getvalue()


named = b"made with " + N
# Sized for a copy of the check whose cap is 64 KiB and whose budget is 128.
CAP = 1 << 16
decoy = profile(zlib.compress(bytes(CAP), 9))
stored_empty = b"\x00\x00\x00\xff\xff"

build = {
    # The file's inflation budget spent exactly by two profiles at the cap,
    # then a third profile naming the assistant.
    "spent": lambda: png(decoy, decoy, profile(zlib.compress(named))),
    # A profile past the cap that names the assistant before the cap.
    "bomb": lambda: png(profile(zlib.compress(named + bytes(CAP + 1), 9))),
    # Three profiles each under the cap, which together pass the budget.
    # ...and ending right after them, so that nothing after the third reaches
    # the budget check a chunk meets before it is inflated.
    "budget": lambda: (SIG + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
                       + profile(zlib.compress(bytes(60000), 9)) * 3),
    # A gzip file that names the assistant, then runs past the cap.
    "gzip-cap": lambda: gzip.compress(named + bytes(CAP + 1)),
    # A zip whose three members together pass the budget.
    "zip-budget": lambda: zipped(*[bytes(60000)] * 3),
    # A gzip file three containers deep.
    "deep-gzip": lambda: b64(gzip.compress(named), 3) + b"\n",
    # A profile whose keyword runs past the 79 bytes PNG allows.
    "long-keyword": lambda: png(chunk(b"iCCP", b"K" * 100 + b"\x00\x00" + zlib.compress(named))),
    # Base64 inside a profile inside a data URI.
    "profile-b64": lambda: png(profile(zlib.compress(
        b"desc " + b64(b"a profile written with " + N + b" and nothing else")))),
    # Four and three containers deep, the innermost holding something to open.
    "deep-text": lambda: b64(b"a note written by " + N + b" and kept here", 4) + b"\n",
    "deep-png": lambda: b64(png(profile(zlib.compress(named))), 3) + b"\n",
    "sprites-same": lambda: sprites(False),
    "sprites-distinct": lambda: sprites(True),
    # gzip with every optional header field, each of which moves the data.
    "gzip-fields": lambda: (b"\x1f\x8b\x08\x1e" + b"\x00" * 4 + b"\x02\xff"
                            + struct.pack("<H", 6) + b"ab\x02\x00xy" + b"drawing.svg\x00"
                            + b"a comment\x00" + b"\x00\x00" + raw_deflate(named)
                            + struct.pack("<II", zlib.crc32(named), len(named))),
    "gzip-uri": lambda: b'<a href="data:application/gzip;base64,' + b64(gzip.compress(named)) + b'">x</a>\n',
    "docx": lambda: docx(b"<Properties><Application>" + named + b"</Application></Properties>"),
    # The metadata as the second member, where a real document keeps it.
    "docx-second": lambda: docx(b"<Properties><Application>" + named + b"</Application></Properties>",
                                first=b"<Types>" + b"x" * 300 + b"</Types>"),
    "pdf-crlf": lambda: (b"%PDF-1.7\r\n1 0 obj <</Filter /FlateDecode>> stream\r\n"
                         + zlib.compress(b"<</Producer (" + named + b")>>") + b"\r\nendstream\r\n"),
    "pdf": lambda: (b"%PDF-1.7\n1 0 obj <</Length 99 /Filter /FlateDecode>> stream\n"
                    + zlib.compress(b"<x:xmpmeta><xmp:CreatorTool>" + named + b"</xmp:CreatorTool></x:xmpmeta>")
                    + b"\nendstream endobj\n%%EOF\n"),
    # Floods: shapes that once cost time in the square of their size.
    "flood-escapes": lambda: b"A" + b"\\r\\n" * 30000 + b".",
    # Signatures, each followed by a profile chunk that claims to run to the
    # end of the file and holds no NUL to end its keyword.
    "flood-signatures": lambda: (SIG + struct.pack(">I", 0x7FFFFFFF) + b"iCCP" + b"." * 20) * 20000,
    # PNGs nested 300 deep, each in a chunk of the one outside it, then half
    # a megabyte of zeros, which read as empty chunks from wherever a walk
    # lands.
    "flood-nest": lambda: functools.reduce(
        lambda inner, _: SIG + struct.pack(">I", len(inner)) + b"zzzz" + inner + b"\x00" * 4,
        range(300), b"") + b"\x00" * (1 << 19),
}
# Every fixture is built once, into the directory given, each under its name.
os.makedirs(sys.argv[1], exist_ok=True)
for name, make in build.items():
    data = make()
    # A fixture that shows the name as it stands proves nothing about the
    # container it is hidden in, whichever branch then catches it.
    if N in data.lower():
        sys.exit("self-test FAILED: the %s fixture is not actually hidden" % name)
    open(os.path.join(sys.argv[1], name), "wb").write(data)
PY
NEEDLE="$needle" python3 "$spare/fx.py" "$spare/fixtures"
built() { cp "$spare/fixtures/$1" "$2"; }

# A copy of the check with some bounds lowered: `patched NAME VALUE...`. The
# cases that reach a bound would otherwise need tens or hundreds of megabytes
# of input, and the self-test runs twice in every CI run of every repository
# that carries it. Each bound is a constant in the check, and only this copy
# changes it: nothing lets the check CI runs be told a different one. That the
# check ships with its real bounds is a case of its own, below.
patched() {
  mkdir -p "$spare/patched"
  python3 - "$check" "$spare/patched/check-vendor-attribution.py" "$@" <<'PY'
import re, sys
source, target, *pairs = sys.argv[1:]
text = open(source).read()
for name, value in zip(pairs[::2], pairs[1::2]):
    line = re.compile(r"^%s = .*$" % re.escape(name), re.M)
    if len(line.findall(text)) != 1:
        sys.exit("self-test FAILED: %s is not assigned exactly once in the check" % name)
    text = line.sub("%s = %s" % (name, value), text)
open(target, "w").write(text)
PY
  use="$spare/patched/check-vendor-attribution.py"
}

# The bounds the check ships with. The cases that reach a bound run a patched
# copy, so without this a bound raised in the check itself, even to no bound at
# all, would leave every one of them passing.
python3 - "$check" <<'PY' || fail "the check does not ship with the bounds this self-test was written for"
import re, sys
text = open(sys.argv[1]).read()
want = {
    "MAX_DEPTH": "3",
    "DECODE_BUDGET": "128 << 20",
    "MAX_INFLATE": "32 << 20",
    "INFLATE_BUDGET": "64 << 20",
    "INFLATE_STEP": "1 << 20",
}
for name, value in want.items():
    found = re.findall(r"^%s = (.*)$" % name, text, re.M)
    if found != [value]:
        sys.exit("self-test FAILED: %s is %s in the check, wanted %s" % (name, found, value))
PY
ok "the check ships with its real bounds: depth 3, 128 MiB decoded, 32 MiB a stream, 64 MiB a file"

# A long run of `=` that nothing in the alphabet follows. Splitting at padding
# once tried such a run again from each of its characters, reading to its end
# every time: 80,000 of them took half a minute, and this file would take
# minutes. Fixed, it takes a fraction of a second; the bound is generous so a
# slow runner cannot fail it. The blob before the run, behind a key= prefix,
# proves the split still happens.
printf 'token=%s' "$encoded" > "$work/padding-run.env"
python3 -c 'import sys; open(sys.argv[1], "ab").write(b"=" * 200000 + b"\n")' "$work/padding-run.env"
if grep -qi "$needle" "$work/padding-run.env"; then fail "the padding-run fixture is not hidden"; fi
started="$(date +%s)"
expect_line "a 200,000-character run of padding is split, and the blob before it decoded" \
  "::error file=padding-run.env::carries $needle (base64)"
elapsed=$(( $(date +%s) - started ))
[ "$elapsed" -le 5 ] || fail "a 200,000-character run of padding took ${elapsed}s to scan, wanted 5s at most"
ok "...and in ${elapsed}s, under the 5s bound"
rm "$work/padding-run.env"

# Three more shapes that each once cost time in the square of their size, fixed
# the same way and bounded the same way. Stopped at 20 seconds on the wall
# clock, and held to 5 once they finish.
limit=20
for flood in escapes nest; do
  built "flood-$flood" "$work/flood.bin"
  started="$(date +%s)"
  expect_clean "a flood of $flood reads clean"
  elapsed=$(( $(date +%s) - started ))
  [ "$elapsed" -le 5 ] || fail "a flood of $flood took ${elapsed}s to scan, wanted 5s at most"
  ok "...and in ${elapsed}s, under the 5s bound"
  rm "$work/flood.bin"
done
# Signatures, each followed by a profile chunk that claims to run to the end
# of the file and never ends its keyword: each is refused as a chunk that does
# not inflate, and quickly.
built flood-signatures "$work/flood.bin"
started="$(date +%s)"
expect_line "a flood of signatures is refused, and quickly" \
  "::error file=flood.bin::carries compressed chunk does not inflate"
elapsed=$(( $(date +%s) - started ))
[ "$elapsed" -le 5 ] || fail "a flood of signatures took ${elapsed}s to scan, wanted 5s at most"
ok "...and in ${elapsed}s, under the 5s bound"
rm "$work/flood.bin"
limit=60

# ── what base64 carries is read like a file ─────────────────────────────────
# A PNG in a `data:` URI is the same bytes as the PNG file. Read as nothing but
# text, a text chunk that fails as a file would pass inside an SVG, and so would
# a name in a compressed chunk. So the decoded bytes go through the same reading
# a file gets, and the reason says which container they came out of, innermost
# first.

# Writes a one-pixel PNG to $1, carrying the chunk named by $2: a text chunk
# with nothing incriminating in it, a compressed text chunk or a colour profile
# naming the assistant, or no extra chunk at all.
make_png() {
  NEEDLE="$needle" python3 - "$1" "$2" <<'PY'
import os, struct, sys, zlib

def chunk(kind, body):
    return (struct.pack(">I", len(body)) + kind + body
            + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF))

named = ("made with " + os.environ["NEEDLE"]).encode()
extra = {
    "none": b"",
    "tEXt": chunk(b"tEXt", b"Comment\x00nothing incriminating here"),
    "zTXt": chunk(b"zTXt", b"Comment\x00\x00" + zlib.compress(named)),
    "iCCP": chunk(b"iCCP", b"ICC profile\x00\x00" + zlib.compress(named)),
    "iCCP-clean": chunk(b"iCCP", b"ICC profile\x00\x00" + zlib.compress(b"sRGB")),
}[sys.argv[2]]
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
       + extra
       + chunk(b"IDAT", zlib.compress(b"\x00\x00"))
       + chunk(b"IEND", b""))
open(sys.argv[1], "wb").write(png)
PY
}

data_uri() { printf 'data:image/png;base64,%s' "$(base64 < "$1" | tr -d '\n')"; }

make_png "$spare/text.png" tEXt
printf '<svg><image href="%s"/></svg>\n' "$(data_uri "$spare/text.png")" > "$work/icon.svg"
expect_line "a text chunk in a data URI is reported as the chunk, from base64" \
  "::error file=icon.svg::carries tEXt chunk (base64)"
rm "$work/icon.svg"

make_png "$spare/ztxt.png" zTXt
printf '<svg><image href="%s"/></svg>\n' "$(data_uri "$spare/ztxt.png")" > "$work/note.svg"
if grep -qi "$needle" "$work/note.svg"; then fail "the compressed-text data URI is not hidden"; fi
expect_line "a compressed text chunk in a data URI is inflated as well as refused" \
  "::error file=note.svg::carries $needle (compressed chunk in base64), zTXt chunk (base64)"
rm "$work/note.svg"

# The permitted chunk type, so that inflation is the only thing that can catch
# it, as in case 5.
make_png "$spare/iccp.png" iCCP
printf '<svg><image href="%s"/></svg>\n' "$(data_uri "$spare/iccp.png")" > "$work/profile.svg"
expect_line "a colour profile in a data URI is inflated and reported as such" \
  "::error file=profile.svg::carries $needle (compressed chunk in base64)"
rm "$work/profile.svg"

# Both gaps at once: the data URI wrapped and indented inside an HTML
# attribute. The compressed chunk runs past the first line, so only the joined
# block can be inflated; the chunk type alone is in the first line.
{
  printf '<img src="data:image/png;base64,\n'
  base64 < "$spare/ztxt.png" | tr -d '\n' | fold -w 76 | sed 's/^/    /'
  printf '\n">\n'
} > "$work/page.html"
expect_line "a wrapped data URI is joined, decoded and read as a PNG" \
  "::error file=page.html::carries $needle (compressed chunk in base64), zTXt chunk (base64)"
rm "$work/page.html"

# Nesting, to the depth the check follows: an HTML page holding an SVG as a
# data URI, which holds a PNG as a data URI, whose colour profile names the
# assistant. Three containers, each opened in turn.
printf '<svg><image href="%s"/></svg>' "$(data_uri "$spare/iccp.png")" \
  | base64 | tr -d '\n' > "$spare/svg.b64"
printf '<object data="data:image/svg+xml;base64,%s"/>\n' "$(cat "$spare/svg.b64")" > "$work/nested.html"
expect_line "three containers deep, each is opened and named, innermost first" \
  "::error file=nested.html::carries $needle (compressed chunk in base64 in base64)"
rm "$work/nested.html"

# A clean PNG stays clean as a data URI, including one with a permitted
# profile that inflates to nothing forbidden.
make_png "$spare/plain.png" none
make_png "$spare/srgb.png" iCCP-clean
printf '<svg><image href="%s"/><image href="%s"/></svg>\n' \
  "$(data_uri "$spare/plain.png")" "$(data_uri "$spare/srgb.png")" > "$work/clean.svg"
expect_clean "clean PNGs in data URIs read clean"
rm "$work/clean.svg"

# Inflation is the one step that makes a payload larger than the file it came
# from, so it is capped, and a chunk over the cap is reported rather than read
# in part and passed. What it produced up to the cap is read all the same, so
# a name there is reported beside it. These cases run a copy of the check with
# the cap at 64 KiB and the budget at 128 KiB.
patched MAX_INFLATE "1 << 16" INFLATE_BUDGET "1 << 17"
built bomb "$work/bomb.png"
expect_line "a chunk past the cap is reported, and what came before the cap is read" \
  "::error file=bomb.png::carries $needle (compressed chunk), compressed chunk too large to inflate"
rm "$work/bomb.png"

# The cap is per chunk, so a file is held to a total as well: three chunks each
# under the cap, which together inflate past the per-file budget. Reported, for
# the same reason as a chunk over the cap, rather than read in part and passed.
built budget "$work/budget.png"
expect_line "chunks under the cap that together pass the file's budget are reported" \
  "::error file=budget.png::carries inflate budget exceeded"
rm "$work/budget.png"

# The budget spent to the byte by two profiles, then a third that names the
# assistant: nothing is left to inflate it with, and the file is refused for
# that, not passed because the third was never read. Every byte read counts as
# well as every byte inflated, and how many bytes a profile's stream takes
# depends on the zlib that compressed it, so the budget is set here to exactly
# what two of them cost, measured with the check itself.
charge="$(python3 - "$check" "$spare/fixtures/spent" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("check", sys.argv[1])
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)
data = open(sys.argv[2], "rb").read()
kind, start, end = next(c for c in check.png_chunks(data) if c[0] == b"iCCP")
print(check.inflate(kind, memoryview(data)[start:end], 1 << 17)[2])
PY
)" || fail "could not measure what a profile costs"
patched MAX_INFLATE "1 << 17" INFLATE_BUDGET "$(( 2 * charge ))"
built spent "$work/spent.png"
expect_line "a chunk after the budget is spent is refused, not skipped" \
  "::error file=spent.png::carries inflate budget exceeded"
rm "$work/spent.png"
use="$check"

# A compressed chunk whose keyword never ends within the 79 bytes allowed is
# not a valid chunk, but zlib still reads what it holds.
built long-keyword "$work/long-keyword.png"
expect_line "a compressed chunk with an overlong keyword is refused, not skipped" \
  "::error file=long-keyword.png::carries compressed chunk does not inflate"
rm "$work/long-keyword.png"

# What is inflated is read like everything else, base64 included.
built profile-b64 "$spare/profile-b64.png"
printf '<svg><image href="%s"/></svg>\n' "$(data_uri "$spare/profile-b64.png")" > "$work/profile-b64.svg"
expect_line "base64 inside an inflated chunk inside a data URI is decoded" \
  "::error file=profile-b64.svg::carries $needle (base64 in compressed chunk in base64)"
rm "$work/profile-b64.svg"

# ── past the depth limit is "could not look", not "clean" ───────────────────
# Content is opened three containers deep. Deeper than that it is still
# searched, and if it holds something that would be opened, the file is
# refused: left shut and passed, it would be a place to hide a name. Once for
# base64, once for a compressed chunk, so each is proven on its own.
built deep-text "$work/deep-text.txt"
expect_line "base64 past the depth limit is refused as nested too deep" \
  "::error file=deep-text.txt::carries nested too deep to open (base64 in base64 in base64)"
rm "$work/deep-text.txt"
built deep-png "$work/deep-png.txt"
expect_line "a compressed chunk past the depth limit is refused as nested too deep" \
  "::error file=deep-png.txt::carries nested too deep to open (base64 in base64 in base64)"
rm "$work/deep-png.txt"

# Private raw deflate is supported on main even though it does not claim a zlib header.
python3 - "$work/deep-private.txt" <<'PYFIXTURE'
import base64, struct, sys, zlib
named = b"profile by " + bytes.fromhex("636c61756465")
raw = zlib.compressobj(wbits=-15)
body = raw.compress(named) + raw.flush()
def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
data = b"\x89PNG\r\n\x1a\n" + chunk(b"zzzz", body) + chunk(b"IEND", b"")
for _ in range(3):
    data = base64.b64encode(data)
open(sys.argv[1], "wb").write(data)
PYFIXTURE
expect_line "a private raw-deflate chunk past the depth limit is refused" \
  "::error file=deep-private.txt::carries nested too deep to open (base64 in base64 in base64)"
rm "$work/deep-private.txt"

# Split a compressed payload where deleting a comment-like prefix corrupts the stream.
# Plain-text fixtures can accidentally pass because the remaining bytes still contain the name.
python3 - "$spare" <<'PYFIXTURE'
import base64, random, struct, sys, zlib
from pathlib import Path
rng = random.Random(1)
noise = bytes(rng.choice(b"abcdefg0123456789") for _ in range(5000))
body = zlib.compress(noise + b" profile by " + bytes.fromhex("636c61756465"))
def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
png = b"\x89PNG\r\n\x1a\n" + chunk(b"iCCP", b"profile\0\0" + body) + chunk(b"IEND", b"")
encoded = base64.b64encode(png)
split = encoded.find(b"//", 100)
assert 100 < split < len(encoded) - 200
for name, separator in [("slash", b"\n"), ("star", b"\n* "), ("hash", b"\n# "), ("comment", b"\n// "), ("continuation", b"\\\n")]:
    Path(sys.argv[1], "wrapped-" + name).write_bytes(encoded[:split] + separator + encoded[split:])
PYFIXTURE
for shape in slash star hash comment continuation; do
  cp "$spare/wrapped-$shape" "$work/wrapped-$shape.txt"
  expect_line "a wrapped compressed payload preserves its $shape boundary" \
    "::error file=wrapped-$shape.txt::carries $needle (compressed chunk in base64)"
  rm "$work/wrapped-$shape.txt"
done

# Several PNG signatures converge on shared chunks: visit each offset only once.
if python3 - "$check" <<'PYFIXTURE'
import importlib.util, struct, sys
spec = importlib.util.spec_from_file_location("checker", sys.argv[1])
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)
sig = b"\x89PNG\r\n\x1a\n"
count = 10
tail = count * 20
raw = b"".join(sig + struct.pack(">I", tail - i * 20 - 20) + b"zzzz" + b"...." for i in range(count))
raw += b"\0\0\0\0PLTE\0\0\0\0" * 20 + b"\0\0\0\0IEND\0\0\0\0"
chunks = list(checker.png_chunks(raw))
assert len(chunks) == 31 and len({start for _, start, _ in chunks}) == 31
PYFIXTURE
then
  ok "PNG walks visit each chunk offset once"
else
  fail "PNG walks visit each chunk offset once"
fi

# ── the decoding budget ─────────────────────────────────────────────────────
# Reaching the real budget takes more input than a self-test should build, so
# these run a copy with the budget lowered to 900,000 bytes. Fifty SVG icons,
# each holding an image as a data URI: the same image in all of them is decoded
# once and fits; a different image in each does not.
built sprites-distinct "$work/sprites.txt"
expect_clean "fifty icons with different images fit the real budget"
patched DECODE_BUDGET 900000
expect_line "a file that needs more decoding than its budget is refused" \
  "::error file=sprites.txt::carries decode budget exceeded"
built sprites-same "$work/sprites.txt"
expect_clean "the same image in fifty icons is decoded once, and fits"
use="$check"
rm "$work/sprites.txt"

# ── compressed files besides a PNG ─────────────────────────────────────────
built gzip-fields "$work/drawing.svgz"
expect_line "a gzip file is inflated, past every optional header field" \
  "::error file=drawing.svgz::carries $needle (gzip)"
rm "$work/drawing.svgz"
built gzip-uri "$work/link.html"
expect_line "gzip inside a data URI is inflated" \
  "::error file=link.html::carries $needle (gzip in base64)"
rm "$work/link.html"
built docx "$work/report.docx"
expect_line "a deflated zip member is inflated" \
  "::error file=report.docx::carries $needle (zip member)"
rm "$work/report.docx"
built docx-second "$work/report.docx"
expect_line "every zip member is inflated, not only the first" \
  "::error file=report.docx::carries $needle (zip member)"
rm "$work/report.docx"
built pdf "$work/report.pdf"
expect_line "a compressed PDF stream is inflated" \
  "::error file=report.pdf::carries $needle (PDF stream)"
built pdf-crlf "$work/report.pdf"
expect_line "a PDF stream after a CRLF is inflated" \
  "::error file=report.pdf::carries $needle (PDF stream)"
rm "$work/report.pdf"
expect_clean "the tree is clean once the base64 fixtures are removed"


# The limits hold for these files as for a PNG, on the same copy of the check
# with the cap at 64 KiB and the budget at 128 KiB.
patched MAX_INFLATE "1 << 16" INFLATE_BUDGET "1 << 17"
built gzip-cap "$work/big.svgz"
expect_line "a gzip file past the cap is reported, and what came before the cap is read" \
  "::error file=big.svgz::carries $needle (gzip), gzip too large to inflate"
rm "$work/big.svgz"
built zip-budget "$work/parts.zip"
expect_line "zip members that together pass the file's budget are reported" \
  "::error file=parts.zip::carries inflate budget exceeded"
rm "$work/parts.zip"
use="$check"
built deep-gzip "$work/deep-gzip.txt"
expect_line "a gzip file past the depth limit is refused as nested too deep" \
  "::error file=deep-gzip.txt::carries nested too deep to open (base64 in base64 in base64)"
rm "$work/deep-gzip.txt"
expect_clean "the tree is clean once the base64 fixtures are removed"

# ── the encodings, containers and chunks a name can still hide in ───────────
# Each fixture below reads clean to a check that only knows the shapes above,
# and each is caught for the reason its line names.

# Builds a PNG, an icon or a chunk for the fixtures that follow. The name is
# passed in, as everywhere in this file, never written out.
cat > "$spare/fixture.py" <<'PY'
import base64, os, struct, sys, zlib

NAMED = b"made with " + os.environ["NEEDLE"].encode()

def chunk(kind, body):
    return (struct.pack(">I", len(body)) + kind + body
            + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF))

def png(*extra):
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
            + b"".join(extra)
            + chunk(b"IDAT", zlib.compress(b"\x00\x00"))
            + chunk(b"IEND", b""))

def ico(*images):
    # An icon directory: a header, one 16-byte entry per image, then the
    # images, each stored whole.
    offset = 6 + 16 * len(images)
    head = struct.pack("<HHH", 0, 1, len(images))
    for image in images:
        head += struct.pack("<BBBBHHII", 1, 1, 0, 0, 1, 32, len(image), offset)
        offset += len(image)
    return head + b"".join(images)

def write(data):
    open(sys.argv[1], "wb").write(data)
PY
fixture() { NEEDLE="$needle" PYTHONPATH="$spare" python3 - "$@"; }
hidden() { if grep -qi "$needle" "$1"; then fail "the $2 fixture is not actually hidden"; fi; }

# URL-safe base64 writes `-` and `_` for `+` and `/`, and each cuts a
# standard-alphabet run. Glued behind a word joined by a dash, five characters
# long, the blob is also out of step from the start of its run.
fixture "$work/token.txt" <<'PY'
from fixture import *
blob = base64.urlsafe_b64encode(b"??>" * 8 + b" written by " + NAMED + b" " + b"\xff\xfe\xfd" * 10)
assert b"-" in blob and b"_" in blob
write(b"session: sess-" + blob.rstrip(b"=") + b"\n")
PY
hidden "$work/token.txt" "URL-safe"
expect_line "URL-safe base64 behind a word is decoded" \
  "::error file=token.txt::carries $needle (base64)"
rm "$work/token.txt"

# UTF-16 writes a NUL beside every character of the name. Little-endian with
# a byte-order mark, as Windows editors save it...
fixture "$work/notes-le.txt" <<'PY'
from fixture import *
write(("﻿release notes, " + NAMED.decode() + ", fin\r\n").encode("utf-16-le"))
PY
hidden "$work/notes-le.txt" "UTF-16LE"
expect_line "UTF-16 little-endian text with a byte-order mark is read as text" \
  "::error file=notes-le.txt::carries $needle (UTF-16)"
rm "$work/notes-le.txt"

# ...and big-endian with none, the name its very last character, which is the
# one character a big-endian run read one byte in has no NUL after.
fixture "$work/notes-be.txt" <<'PY'
from fixture import *
write(("release notes, " + NAMED.decode()).encode("utf-16-be"))
PY
hidden "$work/notes-be.txt" "UTF-16BE"
expect_line "UTF-16 big-endian text with no mark is read to its last character" \
  "::error file=notes-be.txt::carries $needle (UTF-16)"
rm "$work/notes-be.txt"

# An icon is a directory of images, each of which may be a whole PNG: this one
# holds two, a text chunk in the first and a profile naming the assistant in
# the second. Both are read as a PNG file would be.
fixture "$work/favicon.ico" <<'PY'
from fixture import *
write(ico(png(chunk(b"tEXt", b"Comment\x00nothing incriminating here")),
          png(chunk(b"iCCP", b"ICC profile\x00\x00" + zlib.compress(NAMED)))))
PY
hidden "$work/favicon.ico" "icon"
expect_line "each PNG in an icon is held to the chunk policy and inflated" \
  "::error file=favicon.ico::carries $needle (compressed chunk), tEXt chunk"
rm "$work/favicon.ico"

# A private chunk type, which no list names, holding a bare zlib stream with no
# keyword before it.
fixture "$work/private.png" <<'PY'
from fixture import *
write(png(chunk(b"prVt", zlib.compress(NAMED))))
PY
hidden "$work/private.png" "private-chunk"
expect_line "a private chunk holding a zlib stream is inflated" \
  "::error file=private.png::carries $needle (compressed chunk)"
rm "$work/private.png"

# A profile whose stream is cut short after the name: no starting offset
# reaches the end of a stream, and what it gave before the cut is still read.
fixture "$work/truncated.png" <<'PY'
from fixture import *
stream = zlib.compress(NAMED + bytes(range(256)) * 16)
write(png(chunk(b"iCCP", b"ICC profile\x00\x00" + stream[: len(stream) // 2])))
PY
hidden "$work/truncated.png" "truncated-stream"
expect_line "a compressed chunk cut short is read as far as it goes" \
  "::error file=truncated.png::carries $needle (compressed chunk)"
rm "$work/truncated.png"

# ...and one that gives nothing at all is refused: it cannot be read, so it
# cannot be known to be clean.
fixture "$work/corrupt.png" <<'PY'
from fixture import *
write(png(chunk(b"iCCP", b"ICC profile\x00\x00" + b"\xff" * 64)))
PY
expect_line "a compressed chunk that does not inflate at all is reported" \
  "::error file=corrupt.png::carries compressed chunk does not inflate"
rm "$work/corrupt.png"

# A PNG is found by its signature wherever it sits, not only where a directory
# says. This icon's second entry points at a copy of the signature planted in
# the first image's private chunk: read as the directory declares, the first
# image ends there, before the compressed text chunk that names the assistant.
fixture "$work/overlap.ico" <<'PY'
from fixture import *
first_head = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
decoy = chunk(b"prVt", b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 0x7FFFFFFF) + b"xxxx")
first = (first_head + decoy + chunk(b"zTXt", b"Comment\x00\x00" + zlib.compress(NAMED))
         + chunk(b"IDAT", zlib.compress(b"\x00\x00")) + chunk(b"IEND", b""))
start = 6 + 16 * 2
planted = start + len(first_head) + 8
head = struct.pack("<HHH", 0, 1, 2)
for offset in (start, planted):
    head += struct.pack("<BBBBHHII", 1, 1, 0, 0, 1, 32, len(first), offset)
write(head + first)
PY
hidden "$work/overlap.ico" "overlapping-icon"
expect_line "an icon entry pointing into another image cannot cut it short" \
  "::error file=overlap.ico::carries $needle (compressed chunk), zTXt chunk"
rm "$work/overlap.ico"

# ...and with no directory at all: a PNG appended to another file.
fixture "$work/appended.gif" <<'PY'
from fixture import *
write(b"GIF89a" + bytes(20) + png(chunk(b"iCCP", b"ICC profile\x00\x00" + zlib.compress(NAMED))))
PY
hidden "$work/appended.gif" "appended-PNG"
expect_line "a PNG appended to another file is read as a PNG" \
  "::error file=appended.gif::carries $needle (compressed chunk)"
rm "$work/appended.gif"

# A key= before a URL-safe value that starts with `-`: the split after the
# `=` has to know the URL-safe alphabet, or the value stays glued to its key.
fixture "$work/keyed.env" <<'PY'
from fixture import *
blob = base64.urlsafe_b64encode(b"\xf8" + b" a note " + NAMED + b" kept here for later")
assert blob.startswith(b"-") and len(blob.rstrip(b"=")) >= 40
write(b"token=" + blob + b"\n")
PY
hidden "$work/keyed.env" "keyed URL-safe"
expect_line "URL-safe base64 after key= that starts with - is decoded" \
  "::error file=keyed.env::carries $needle (base64)"
rm "$work/keyed.env"

# A stream whose checksum is wrong still holds every byte before it: read
# again as the bare deflate inside the zlib wrapper, it inflates to its end.
fixture "$work/badsum.png" <<'PY'
from fixture import *
stream = zlib.compress(NAMED)
write(png(chunk(b"prVt", stream[:-4] + b"\x00\x00\x00\x00")))
PY
hidden "$work/badsum.png" "bad-checksum"
expect_line "a zlib stream with a bad checksum is read past it" \
  "::error file=badsum.png::carries $needle (compressed chunk)"
rm "$work/badsum.png"

# A stream that gives the name and then a corrupt block: the output before
# the fault is kept, to the byte, not dropped with the call that raised.
fixture "$work/fault.png" <<'PY'
from fixture import *
deflate = zlib.compressobj(9)
write(png(chunk(b"prVt", deflate.compress(NAMED + b" ") + deflate.flush(zlib.Z_FULL_FLUSH) + b"\xff\xff\xff")))
PY
hidden "$work/fault.png" "corrupt-block"
expect_line "what a stream gives before a corrupt block is read" \
  "::error file=fault.png::carries $needle (compressed chunk)"
rm "$work/fault.png"

# Bare deflate with no zlib header at all, in a private chunk.
fixture "$work/bare-deflate.png" <<'PY'
from fixture import *
deflate = zlib.compressobj(9, zlib.DEFLATED, -15)
write(png(chunk(b"prVt", deflate.compress(NAMED) + deflate.flush())))
PY
hidden "$work/bare-deflate.png" "bare-deflate"
expect_line "a private chunk holding bare deflate is inflated" \
  "::error file=bare-deflate.png::carries $needle (compressed chunk)"
rm "$work/bare-deflate.png"

# A private chunk that opens with a valid zlib header and gives nothing is a
# chunk that cannot be read, reported as a profile that does not inflate is.
fixture "$work/claimed.png" <<'PY'
from fixture import *
write(png(chunk(b"prVt", b"\x78\x9c" + b"\xff" * 30)))
PY
expect_line "a private chunk with a zlib header that gives nothing is reported" \
  "::error file=claimed.png::carries compressed chunk does not inflate"
rm "$work/claimed.png"

# Base64 in a comment block, wrapped at 70: not a multiple of four, so read
# line by line, every line after the first is out of step. The name is in the
# second line.
printf '%060d%s%060d' 0 "$needle" 0 | base64 | tr -d '\n' | fold -w 70 > "$spare/c70.b64"
[ -z "$(lines_alone_carry "$spare/c70.b64")" ] || fail "the comment fixture is caught line by line"
sed 's/^/# /' "$spare/c70.b64" > "$work/hash-comment.py"
expect_line "base64 wrapped at 70 in # comments is joined" \
  "::error file=hash-comment.py::carries $needle (base64)"
rm "$work/hash-comment.py"

{ printf '/**\n'; sed 's/^/ * /' "$spare/c70.b64"; printf ' */\n'; } > "$work/block-comment.ts"
expect_line "base64 wrapped at 70 in a block comment is joined" \
  "::error file=block-comment.ts::carries $needle (base64)"
rm "$work/block-comment.ts"

sed 's|^|// |' "$spare/c70.b64" > "$work/line-comment.go"
expect_line "base64 wrapped at 70 in // comments is joined" \
  "::error file=line-comment.go::carries $needle (base64)"
rm "$work/line-comment.go"

# A YAML double-quoted scalar continued with a backslash at each line end.
{ printf 'blob: "'; sed -e '$!s/$/\\/' -e '2,$s/^/  /' "$spare/c70.b64"; printf '"\n'; } > "$work/continued.yaml"
expect_line "base64 continued with backslashes in YAML is joined" \
  "::error file=continued.yaml::carries $needle (base64)"
rm "$work/continued.yaml"

# `//` is also two characters of the alphabet, so it is a marker only with a
# blank after it. A wrapped line that merely starts with `//` must still join.
fixture "$spare/slashes.b64" <<'PY'
from fixture import *
data = b"\x00" * 57 + b"\xff\xff" + b"\x00" * 38 + b" by " + NAMED + b"\x00" * 40
text = base64.b64encode(data)
lines = [text[i : i + 76] for i in range(0, len(text), 76)]
assert lines[1].startswith(b"//")
write(b"\n".join(lines))
PY
[ -z "$(lines_alone_carry "$spare/slashes.b64")" ] || fail "the slash fixture is caught line by line"
cp "$spare/slashes.b64" "$work/slashes.txt"
expect_line "a wrapped line that starts with // is base64, not a comment" \
  "::error file=slashes.txt::carries $needle (base64)"
rm "$work/slashes.txt"

# The converse, because every one of these reads more than it used to: prose in
# comments, a clean UTF-16 file, a clean icon and kebab-case identifiers.
seq 1 200 | awk '{ printf "# word%s\n// word%s\n * word%s\n", $0, $0, $0 }' > "$work/comments.txt"
fixture "$work/clean16.txt" <<'PY'
from fixture import *
write("﻿nothing to declare here at all\r\n".encode("utf-16-le"))
PY
fixture "$work/clean.ico" <<'PY'
from fixture import *
write(ico(png(), png(chunk(b"iCCP", b"ICC profile\x00\x00" + zlib.compress(b"sRGB")),
                    chunk(b"prVt", bytes(range(64))))))
PY
seq 1 200 | awk '{ printf "some-long-kebab-case-identifier_with_parts-%s\n", $0 }' > "$work/idents.txt"
expect_clean "comment prose, clean UTF-16, a clean icon with a private chunk and identifiers read clean"
rm "$work/comments.txt" "$work/clean16.txt" "$work/clean.ico" "$work/idents.txt"

# ── the surfaces that are not files ─────────────────────────────────────────
# Five of them are what this mode is built for — commit messages, branch names,
# pull-request titles and bodies, tags and release notes — and `git ls-files`
# can see none. `--text LABEL` takes one on stdin. These cases are the only
# thing standing between that mode and a step that pipes the wrong expression
# into it, so the label and the byte count are asserted as well as the finding.

# Output first, status second. Reading `$?` after a pipe gives the pipe's
# status, which is the writer's, not the checker's.
run_text() {
  local input="$1"; shift
  if _out="$(printf '%s' "$input" | bounded "$limit" "$check" --text "$@" 2>&1)"; then
    _status=0
  else
    _status=$?
  fi
}

expect_text_line() {
  local label="$1" want="$2" input="$3"; shift 3
  run_text "$input" "$@"
  if ! grep -qxF -- "$want" <<<"$_out"; then
    fail "$label
  expected line: $want
  actual output: $_out"
  fi
  expect_status "$label: reported the finding but exited wrong" 1
  ok "$label"
}

# A clean surface says so AND says how much it looked at. The byte count is the
# only evidence in the log that the step's input arrived at all — a step whose
# expression produced the wrong field has no other tell when the wrong field is
# also clean. Two fixtures of different lengths, so a hard-coded number in the
# message could not satisfy both.
expect_clean_surface() {
  local label="$1" input="$2" surface="$3"
  run_text "$input" "$surface"
  # Bytes, not characters. `${#input}` counts characters, and the checker counts
  # bytes; the two agree only while every fixture is ASCII, which is not a
  # property anyone adding the next fixture would think to preserve.
  local size
  size="$(printf '%s' "$input" | wc -c | tr -d ' ')"
  local want="no assistant attribution in the $surface ($size bytes scanned)"
  if ! grep -qxF -- "$want" <<<"$_out"; then
    fail "$label
  expected line: $want
  actual output: $_out"
  fi
  expect_status "$label: said clean but exited wrong" 0
  ok "$label"
}

expect_clean_surface "a clean surface reads clean and reports how much it scanned" \
  'docs/state-the-attribution-rule' 'branch name'
expect_clean_surface "and the size it reports is the size it was given" \
  'fix/range' 'branch name'

# The finding names the surface. Two different labels, because a message that
# hard-coded one of them would pass a single-label test.
expect_text_line "a commit message is caught, and the message names the surface" \
  "::error::$needle appears in the commit messages on this branch" \
  "feat: a change

Co-Authored-By: $needle <noreply@example.invalid>" \
  "commit messages on this branch"

expect_text_line "a pull-request title is caught under its own label" \
  "::error::$needle appears in the pull request title" \
  "chore: generated with $needle" \
  "pull request title"

# Case, because a branch name is often capitalised differently than prose.
expect_text_line "an uppercase name in a branch is caught" \
  "::error::$needle appears in the branch name" \
  "feat/$(printf '%s' "$needle" | tr '[:lower:]' '[:upper:]')-review" \
  "branch name"

# Base64 reaches a text surface too: a footer can arrive encoded in a body.
body_payload="$(printf 'padding%.0s' $(seq 1 40))$needle"
body_encoded="$(printf '%s' "$body_payload" | base64 | tr -d '\n')"
if grep -qi "$needle" <<<"$body_encoded"; then
  fail "the base64 body fixture is not actually hidden"
fi
expect_text_line "base64 inside a body is decoded, and reported as base64" \
  "::error::$needle (base64) appears in the pull request body" \
  "see the attached manifest: $body_encoded" \
  "pull request body"

# ── an empty surface is "could not look", not "clean" ────────────────────────
# This is the whole reason the mode refuses by default. A range that resolved
# to nothing, or an expression naming a field the event does not carry, arrives
# here as empty — and reporting it clean is how a gate becomes a comment.
run_text '' 'commit messages on this branch'
if ! grep -qF -- 'nothing was scanned: the commit messages on this branch arrived empty' <<<"$_out"; then
  fail "an empty surface should be refused, not passed
  actual output: $_out"
fi
expect_status "an empty surface was refused but exited wrong" 1
ok "an empty surface is refused, and says the step is wrong"

# Whitespace is empty. A step whose expression produced only a newline is the
# same defect, and would otherwise slip past as a one-byte scan.
run_text '
   
' 'commit messages on this branch'
if ! grep -qF -- 'arrived empty. This surface is never legitimately empty' <<<"$_out"; then
  fail "a whitespace-only surface should be refused
  actual output: $_out"
fi
expect_status "a whitespace-only surface was refused but exited wrong" 1
ok "a whitespace-only surface counts as empty"

# ...and the opt-out works, for the surfaces that really are absent most runs.
run_text '' 'release notes' --allow-empty
if ! grep -qxF -- 'nothing to scan: no release notes on this event' <<<"$_out"; then
  fail "a declared-empty surface should pass and say so
  actual output: $_out"
fi
expect_status "a declared-empty surface said so but exited wrong" 0
ok "--allow-empty lets a legitimately absent surface pass, audibly"

# The flag must affect EMPTINESS only. Spelled as "ignore this surface" it
# would silently exempt every release note ever published, and no case above
# would notice — both exit 0.
expect_text_line "--allow-empty does not exempt a surface that carries the name" \
  "::error::$needle appears in the release notes" \
  "published with help from $needle" \
  "release notes" --allow-empty

# ── a miswired step must not read as a pass ─────────────────────────────────
# `--text` with no label, the shape a workflow typo actually takes. Status 2,
# distinct from a finding's 1: "this step is wrong" and "this surface is dirty"
# are repaired differently, and one bit cannot tell them apart.
expect_usage() {
  local label="$1"; shift
  if _out="$(bounded "$limit" "$check" "$@" 2>&1 <<<'x')"; then _status=0; else _status=$?; fi
  grep -qF -- '--text LABEL' <<<"$_out" || fail "$label
  expected the usage text
  actual output: $_out"
  expect_status "$label: printed usage but exited wrong" 2
  ok "$label"
}

expect_usage "--text with no label exits 2 with usage, not 0" --text
# The dispatch is two clauses -- `--text` must be FIRST and there must be
# exactly one label -- and each was unprovable on its own: mutating either one
# away left every case above passing. These two kill them separately.
expect_usage "a label after a root argument is not a surface scan" . --text
expect_usage "two labels are refused rather than one being picked" --text a b

# Every case above that can run, and no fewer. Update this number when a case
# is added or removed; that is the point of it.
expected=$(( 127 - skipped ))
[ "$cases" -eq "$expected" ] || fail "ran $cases cases, expected $expected: a case was skipped or lost"

echo "self-test passed: $cases cases. Plain text, binary metadata, base64 long and short, a"
echo "permitted compressed chunk, a forbidden chunk type, the summary count,"
echo "the listing order, the allowlist, the path scan, the unreadable-file"
echo "report, a submodule, the manifest namespace, wrapped base64 in seven"
echo "shapes, base64 behind escaped slashes and behind a key= prefix, a long run"
echo "of padding in bounded time, the PNG inside a data URI, three containers of"
echo "nesting, the inflation cap and the per-file inflation budget, URL-safe"
echo "base64 with and without a key=, UTF-16 in either byte order, a PNG"
echo "wherever it sits in a file, a private compressed chunk, a stream cut short,"
echo "one with a bad checksum, one with a corrupt block, bare deflate, and streams"
echo "that do not inflate, base64 wrapped in comments, quotes, YAML continuations"
echo "and string literals, symlinks and other non-files, floods in bounded time,"
echo "gzip, zip and PDF streams, the refusal past the depth limit, and both"
echo "per-file budgets each"
echo "proved by their own message AND their own exit status — and, for the"
echo "surfaces that are not files, the label, the scanned size, base64, the"
echo "refusal of an empty surface, the narrowness of --allow-empty and the usage"
echo "status of a miswired step"
