#!/usr/bin/env python3
"""Fail if anything published from this repository carries assistant-vendor
attribution.

The policy this enforces: the name of the assistant that helped build a
repository never appears in anything that repository publishes. The obvious
check, a recursive case-insensitive grep, misses two ways such attribution can
arrive:

  1. Binary metadata. `grep -I` skips binaries, and without it a match in one
     is reported only as a one-line "binary file matches" notice. PNG
     provenance lives in an ancillary chunk, and when that chunk is compressed
     no grep sees the name at all, so a whole icon set can carry attribution
     unnoticed.
  2. Base64. A provenance manifest embedded in an SVG holds the name encoded,
     so it is not present as text at all and no plain grep can see it.

So this reads every tracked file as bytes, decodes base64 runs in either
alphabet, whether on one line, wrapped across several or split across quoted
strings, reads UTF-16 text, and inflates what is compressed: the chunks of a
PNG wherever it sits in a file, a gzip file, the members of a zip file and the
streams of a PDF. What it decodes or inflates is read again the same way,
because a data URI is a file inside a file: a PNG in an SVG carries its chunks
as surely as the PNG does on its own.

Every limit it keeps fails closed. Content nested deeper than it opens, a
compressed stream larger than it inflates, a compressed chunk that does not
inflate, and a file that runs through its decoding or inflation budget are
each reported, never passed: "could not look" is not "clean". That has a cost:
legitimate content past a limit is refused too, and needs the allowlist. A PDF
holding a Flate image that inflates to 40 MiB, or a gzip file that inflates
past 32 MiB, is refused as too large; a few such images in one PDF run through
the budget. So is any tracked icon or archive whose PNGs carry a text or EXIF
chunk.

The limits fail closed; the formats it does not open do not. What it does not
read is passed as it stands, searched only as plain bytes:
  - a bare zlib stream inside base64, and wrapped URL-safe base64;
  - zip members that are encrypted or compressed with bzip2 or LZMA, and a zip
    with anything before its first member, such as a self-extracting archive;
  - every gzip member after the first, and xz and bzip2 files;
  - PDF streams behind an ASCII85 or hex filter or a predictor, a PDF with
    anything before its header, and PDF strings written in hex or octal
    escapes, UTF-16 Info strings among them;
  - fonts (WOFF, WOFF2), and version-1 provenance manifest labels;
  - a name broken up by invisible characters or markup, or written with
    entities, percent-encoding or look-alike letters.

It uses git to enumerate tracked paths, reading their working-tree contents,
not staged index blobs. A clean checkout is required to verify a commit. A tracked symlink
publishes the path it holds, so that path is what is scanned, and the link is
never followed. A submodule publishes a commit id: its path is scanned, and
nothing else. Anything else that is not a regular file is reported as
unreadable.

It also fails on the metadata containers themselves, whoever wrote them: a
design asset has no reason to carry a text or provenance chunk, and checking
only for today's vendor name would miss tomorrow's. Competitor product names
are NOT flagged — naming a competing product in a comparison or a benchmark is
legitimate research. What is forbidden is attribution of the assistant used to
produce the work.

Tracked files are only the surface `git ls-files` can see. At least five more
published surfaces are invisible to it: commit messages, branch names,
pull-request titles and bodies, tags and release notes. None of those is a
file, so `--text LABEL` takes one of them on stdin and applies the same needles
to it. The caller, normally a CI step, supplies the text, because most of these
live in the event payload rather than in git.

An empty surface is refused rather than passed. A step whose input silently
came out empty — a range that resolved to nothing, an expression that named a
field the event does not carry — would otherwise report the surface clean
without having looked at it. `--allow-empty` marks the surfaces that are
legitimately absent most of the time, and only those.
"""

import base64
import binascii
import hashlib
import os
import re
import stat
import subprocess
import sys
import zlib

# The needles are hex-encoded rather than written out, because this file is
# itself a tracked file: spelled plainly, the check would flag its own source
# and could never pass. Decoded, they read as the assistant vendor names.
VENDOR = tuple(
    bytes.fromhex(h)
    for h in (
        "616e7468726f706963",  # the company
        "636c61756465",  # the assistant
    )
)

# The provenance manifest namespace, searched as text anywhere in a file —
# that is how it appears in an SVG.
NAMESPACE = tuple(
    bytes.fromhex(h)
    for h in (
        "63327061",  # manifest namespace
    )
)

# Ancillary PNG chunks that can hold arbitrary text, including a manifest
# re-added under another name. These are recognised only at a real chunk
# boundary inside a real PNG, never as a substring: their four letters are
# ordinary words in prose (and in this file), and matching them loosely would
# flag every document that discusses image internals.
#
# Rollout note: the stock create-next-app `favicon.ico` carries an exif chunk,
# so a repository scaffolded from it fails this policy until the icon is
# re-exported without it. That failure is by design: the chunk is metadata a
# design asset has no reason to publish.
FORBIDDEN_CHUNKS = tuple(
    bytes.fromhex(h)
    for h in (
        "63614258",  # provenance
        "69545874",  # international text
        "74455874",  # text
        "7a545874",  # compressed text
        "65584966",  # exif
        "64534947",  # signature
    )
)

# 40 characters decode to 30 bytes — short enough to catch a name tucked into a
# small blob. A much higher threshold, such as 120, would let a short encoded
# name through.
B64_FLOOR = 40

# The URL-safe alphabet (RFC 4648 section 5) writes `-` and `_` where the
# standard one writes `+` and `/`: tokens, JWT segments, data in a URL. A run is
# taken over both alphabets at once, one search rather than two, and then cut
# into the pieces of each: the standard pieces are exactly the runs a search
# over the standard alphabet alone would find.
B64_RUN = re.compile(rb"[A-Za-z0-9+/_=-]{%d,}" % B64_FLOOR)
B64_STD_PIECES = re.compile(rb"[-_]+")
B64_URL_PIECES = re.compile(rb"[+/]+")
B64URL_TO_STD = bytes.maketrans(b"-_", b"+/")

# What encoders and source code put between the pieces of one blob. Removed
# before B64_RUN looks, so that a wrapped blob is one run again.
#
#   - A line break: LF, CRLF or a lone CR, escaped with a backslash (a YAML
#     double-quoted scalar, a shell command continued) or not; the escaped
#     `\n` or `\r\n` of a JSON string; any number of them, so a blank line
#     inside a blob does not cut it; blanks on either side, which covers YAML
#     indentation and Markdown's two-blank hard break; and after the break one
#     line prefix: the `>` of a quote, or the `#`, ` * ` or `// ` of a comment.
#     The slashes are in the alphabet, so they count as a prefix only when a
#     blank follows them, which no line of base64 contains.
#   - A string boundary: a closing quote, then an optional `+` (JavaScript) or
#     `,` (an array), line breaks or none (Python joins adjacent literals), and
#     the next opening quote.
#
# Removed only between two characters of the alphabet: whatever it joins is
# then one run, and a run's own first and last pieces may be prose. Joining a
# word to a blob puts the blob out of step with base64's four-character groups,
# which is why every run is decoded at all four alignments (`b64decode`), and
# why nothing here tries to tell a word from a blob. Other prefixes (`--`, `;`,
# `%`) are not joined: that is a known limit, not an oversight.
#
# Linear time, whatever the input. The lookbehinds mean only a position right
# after the alphabet is tried, and not one right after the letter of an escaped
# `\r` or `\n`, so each stretch of blanks and breaks is read from its start
# once. Without the second, every escape in a long run of them would start a
# read to the end of the run: 20,000 of them took longer than 20 seconds.
# Inside the pattern no two parts can match the same characters: every
# repetition starts with a break character, and a lone CR is one only when no
# LF follows it, so a failed match gives back one character at a time without
# trying a second way to read the ones before.
_EOL = rb"(?:\\?(?:\r\n|\r(?!\n)|\n)|(?:\\r)?\\n)"
B64_BREAK = re.compile(
    rb"(?<=[A-Za-z0-9+/=])(?<!\\[rn])(?:"
    rb"[ \t]*(?:" + _EOL + rb"[ \t]*)+(?:(?:>|\*|#|//(?=[ \t]))[ \t]*)?"
    rb"|[\"'][ \t]*(?:[+,][ \t]*)?(?:" + _EOL + rb"[ \t]*)*(?:[+,][ \t]*)?[\"']"
    rb")(?=[A-Za-z0-9+/=])"
)

# Where one run of the alphabet holds more than one encoding: after the `=` of
# a `key=value` prefix, or after the padding of one blob with another written
# straight after it. B64_RUN takes `=` as part of the alphabet, so it keeps
# such a run whole, and decoding it whole puts everything after the `=` out of
# step with base64's four-character groups.
#
# Only from the first `=` of a run. Without the lookbehind, a long run of `=`
# that nothing follows is tried again from each of its characters, and each try
# reads to its end before failing: 80,000 of them held one file for half a
# minute. Anchored, each run is tried once, and the splits are the same.
B64_PADDING = re.compile(rb"(?<!=)=+(?=[A-Za-z0-9+/])")

# A run of UTF-16 text in the ASCII range: each character a printable byte and
# a NUL. The match starts at a NUL rather than at the character before it,
# which lets the search skip straight from one NUL to the next: started at a
# character class, it is twenty times slower on a binary, and binaries are
# where NULs are. Three characters after the NUL, and the one before it, is no
# longer than the shortest needle, and long enough that a binary seldom holds
# such a run by chance, so what is read again is text and not noise.
UTF16_RUN = re.compile(rb"\x00(?:[\t\n\r\x20-\x7e]\x00){3,}[\t\n\r\x20-\x7e]?")
UTF16_CHARS = frozenset(b"\t\n\r" + bytes(range(0x20, 0x7F)))

# Containers opened one inside another, and no deeper: an HTML page holding an
# SVG as a data URI, holding a PNG as a data URI, whose profile is compressed,
# is three. What sits deeper is still searched for the names, and if it holds
# anything that would be opened, the file is reported as nested too deep:
# left unopened and passed, it would be a place to hide a name.
MAX_DEPTH = 3

# Decoding is the step that multiplies: every run is decoded four ways, and
# every decode is read again. Each file may decode this much, counted once per
# distinct payload, and a file that needs more is reported, for the same reason
# as content nested too deep. Measured across every tree this check guards, the
# most any one file needed was under a megabyte, a lockfile.
DECODE_BUDGET = 128 << 20

# Inflation is the one step that makes a payload larger than the file it came
# from, so it is the one step that is capped. A chunk that inflates past the
# cap is reported: read in part and passed, it would be a place to hide a name.
MAX_INFLATE = 32 << 20

# ...and capped per file as well. A PNG may hold any number of chunks under
# the cap, and a zip any number of members, so a small crafted file could
# otherwise hold CI for minutes. Every byte read into a stream or inflated out
# of one counts, whether it is kept or not, and a file that runs out is
# reported, for the same reason as a stream over the cap.
INFLATE_BUDGET = 64 << 20

# Inflated a slice at a time, at most this much, so that a stream abandoned
# partway, because it raised or stopped short of its end, is still charged for
# what it read and produced.
INFLATE_STEP = 1 << 20

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

# Chunks whose payload is zlib-compressed. The third is an embedded colour
# profile: a legitimate chunk type, which is exactly why it is here. The other
# two are forbidden outright, so inflating them can never be the only reason a
# file is caught — without a permitted compressed chunk in this list, the
# inflation path could break and no test would notice.
COMPRESSED_CHUNKS = (
    bytes.fromhex("7a545874"),  # compressed text
    bytes.fromhex("69545874"),  # international text
    bytes.fromhex("69434350"),  # colour profile
)

# Of those, the two whose payload is always compressed. One that does not
# inflate at all hides whatever it holds, so it is reported. International text
# may be stored uncompressed, and is forbidden in any case.
MUST_INFLATE = (
    bytes.fromhex("7a545874"),  # compressed text
    bytes.fromhex("69434350"),  # colour profile
)

# Every other chunk, private ones included, is inflated too if it holds a zlib
# stream, at the start of its payload or after a keyword, because a private
# chunk is a place to put anything. Except the image data: it is compressed as
# a matter of course, and inflated it would spend a large image's whole budget
# on pixels.
IMAGE_DATA = (
    bytes.fromhex("49444154"),  # image data
    bytes.fromhex("66644154"),  # animation frame data
)

# Registered chunk types that never hold a zlib stream. Any other chunk that
# begins with a valid zlib header and gives nothing when inflated is reported,
# as a profile that does not inflate is; these are exempt because their first
# bytes are numbers, a palette colour for one, and two of them form a valid
# header by chance about once in two thousand. A private chunk is also read as
# a bare deflate stream, with no zlib header at all; these are not.
PLAIN_CHUNKS = (
    b"IHDR",
    b"PLTE",
    b"IEND",
    b"tRNS",
    b"cHRM",
    b"gAMA",
    b"sBIT",
    b"sRGB",
    b"cICP",
    b"mDCV",
    b"cLLI",
    b"bKGD",
    b"hIST",
    b"pHYs",
    b"sPLT",
    b"tIME",
    b"acTL",
    b"fcTL",
    b"oFFs",
    b"pCAL",
    b"sCAL",
    b"sTER",
    b"gIFg",
    b"gIFx",
    *FORBIDDEN_CHUNKS,
)

# Input is fed to zlib in slices that start small and double, so a stream that
# fails early costs little, and a stream that fails late loses only the slice
# the fault is in -- which is then replayed in halves, to keep every byte of
# output the stream gave before its fault.
INFLATE_FIRST_SLICE = 64

# Compressed files that announce themselves, besides a PNG. Only a gzip file at
# the start of a payload, the members of a payload that starts as a zip file,
# and the streams of one that starts as a PDF are opened: a bare zlib stream
# announces itself with two bytes, which noise matches too often to act on.
GZIP_MAGIC = b"\x1f\x8b\x08"
ZIP_MEMBER = b"PK\x03\x04"
PDF_MAGIC = b"%PDF-"
PDF_STREAM = re.compile(rb"(?<!end)stream(?:\r\n|\n|\r)")

ALLOWLIST = os.path.join(os.path.dirname(__file__), "vendor-attribution-allowlist.txt")


def load_allowlist():
    if not os.path.exists(ALLOWLIST):
        return set()
    keep = set()
    for line in open(ALLOWLIST, encoding="utf-8"):
        line = line.split("#", 1)[0].strip()
        if line:
            keep.add(line)
    return keep


def png_chunks(raw):
    """Yield (type, start, end) for each chunk of every PNG anywhere in RAW.

    A PNG is found by its signature wherever it sits: at the start of a file,
    as an image in an icon, an .icns or a cursor, appended to another file, or
    inside another PNG's chunk. Each is walked to its end over the whole buffer
    rather than over a slice a directory declared, so a directory entry cannot
    cut an image short. A chunk offset already walked is not walked again: two
    walks that reach the same offset go the same way from there, so every
    offset is visited once however the signatures overlap.
    """
    walked = set()
    at = raw.find(PNG_SIGNATURE)
    while at >= 0:
        offset = at + len(PNG_SIGNATURE)
        while offset + 8 <= len(raw) and offset not in walked:
            walked.add(offset)
            length = int.from_bytes(raw[offset : offset + 4], "big")
            kind = raw[offset + 4 : offset + 8]
            # A chunk type is four ASCII letters. Anything else is not a PNG,
            # or a walk that has left one: a copy of the signature in prose
            # or in a binary, which is not worth reading as chunks.
            if not kind.isalpha():
                break
            yield kind, offset + 8, min(offset + 8 + length, len(raw))
            if kind == b"IEND":
                break
            offset += 12 + length
        at = raw.find(PNG_SIGNATURE, at + 1)


def utf16_texts(payload):
    """Every run of UTF-16 text in PAYLOAD, with its NULs taken out.

    Whichever the byte order, and with or without a byte-order mark: read one
    byte in, big-endian text is little-endian text, so one pattern finds both.
    Wherever in a file the text sits, too: a font's name table, a resource in
    an executable, a script saved by an editor that writes UTF-16.
    """
    for match in UTF16_RUN.finditer(payload):
        start = match.start()
        # The character before the first NUL, when there is one: little-endian
        # text puts its first character there.
        lead = payload[start - 1 : start] if start else b""
        if lead and lead[0] not in UTF16_CHARS:
            lead = b""
        yield lead + match.group()[1::2]


def zlib_header(view, at):
    """Whether VIEW holds a valid zlib header at AT: deflate, with no preset
    dictionary, and a check value that divides as the format requires."""
    if at + 2 > len(view):
        return False
    method, flags = view[at], view[at + 1]
    return (
        method & 0x0F == 8
        and method >> 4 <= 7
        and not flags & 0x20
        and ((method << 8 | flags) % 31 == 0)
    )


def deflate_start(view, at):
    """Whether a bare deflate stream can begin at AT: its first block is not
    of the reserved type, and a stored block's length matches its complement.
    Half of all bytes fail this at once, and a run of anything else, a PNG
    signature among them, is not worth decompressing to find that out."""
    if at + 5 > len(view):
        return at < len(view)
    block = view[at] >> 1 & 3
    if block == 3:
        return False
    return block != 0 or (
        view[at + 1] ^ view[at + 3] == 0xFF and view[at + 2] ^ view[at + 4] == 0xFF
    )


def inflate_starts(kind, view):
    """Where a stream may begin in a chunk's payload: (offset, wbits, claimed).

    A zlib stream is tried only where a valid zlib header is, past up to four
    bytes of flags and empty fields after the keyword, and for a chunk other
    than the compressed ones, at the start of the payload too: a private chunk
    need not have a keyword. CLAIMED marks the two places where a header means
    the chunk holds a stream, so that nothing coming out of it is a finding:
    the start of the payload, and past a keyword and a method byte, as in a
    compressed text chunk. A private chunk is also tried as bare deflate.
    """
    # A keyword is 1 to 79 bytes, so its NUL is in the first 80: looking no
    # further keeps this constant however long the payload.
    nul = bytes(view[:80]).find(b"\0")
    tail = [] if nul < 0 else [nul + 1 + skip for skip in range(5)]
    private = kind not in PLAIN_CHUNKS and kind not in COMPRESSED_CHUNKS
    places = tail if kind in COMPRESSED_CHUNKS else [*range(5), *tail]
    starts = []
    for at in dict.fromkeys(places):
        if zlib_header(view, at):
            claimed = private and (at == 0 or tail[1:2] == [at])
            starts.append((at, zlib.MAX_WBITS, claimed))
    if private and deflate_start(view, 0):
        starts.append((0, -zlib.MAX_WBITS, False))
    return starts


def replay(state, piece, room):
    """The output STATE gives from PIECE before the byte where it fails.

    Halving the piece, the half that fails is narrowed and the half that does
    not is kept, so at most twice the piece is decompressed.
    """
    out = bytearray()
    while piece and room > 0:
        trial = state.copy()
        half = piece[: max(1, len(piece) // 2)]
        try:
            got = trial.decompress(half, room)
        except zlib.error:
            if len(half) == len(piece):
                break
            piece = half
            continue
        out += got
        room -= len(got)
        state = trial
        piece = piece[len(half) :]
        if trial.eof:
            break
    return bytes(out)


def stream(view, at, wbits, room):
    """Inflate one stream from AT: (bytes, reached its end, bytes charged).

    Every byte in and out is charged, input as well as output: a run of empty
    blocks gives nothing and yet takes time to read. Stops once the charge
    passes ROOM.
    """
    state = zlib.decompressobj(wbits)
    blob, spent, size = bytearray(), 0, INFLATE_FIRST_SLICE
    while at < len(view) and not state.eof and spent <= room:
        piece = view[at : at + size]
        left = room + 1 - spent
        saved = state.copy() if blob or spent else None
        try:
            step = state.decompress(piece, left)
        except zlib.error:
            got = replay(saved or zlib.decompressobj(wbits), piece, left)
            blob += got
            spent += len(piece) + len(got)
            break
        used = len(piece) - len(state.unconsumed_tail)
        blob += step
        spent += used + len(step)
        if not used and not step:
            break
        at += used
        size = min(size * 2, INFLATE_STEP)
    return bytes(blob), state.eof, spent


def inflate(kind, view, limit=MAX_INFLATE):
    """Decompress a chunk payload: (bytes, state, spent, claimed).

    A name inside one of these is neither readable text nor base64, so it
    would otherwise pass both of the other scans. The first stream to inflate
    to its end wins: STATE is "whole". A charge past LIMIT makes the state
    "over", with what came out by then. When no stream reaches its end,
    because it is cut short or corrupt, the longest output any of them gave is
    returned as "partial": what a stream holds before it breaks is still
    published. A zlib stream that fails is tried again as the bare deflate
    inside it, two bytes in, which reads past a bad checksum at its end. With
    no output at all, the bytes are None, and CLAIMED says whether a header
    promised some. `spent` counts every byte read and inflated, from abandoned
    streams too, so that a caller can hold every chunk in a file to one budget.
    """
    spent, longest, claimed = 0, b"", kind in MUST_INFLATE
    for at, wbits, claims in inflate_starts(kind, view):
        claimed = claimed or claims
        tries = [(at, wbits)]
        if wbits > 0 and deflate_start(view, at + 2):
            tries.append((at + 2, -zlib.MAX_WBITS))
        for start, bits in tries:
            blob, whole, cost = stream(view, start, bits, limit - spent)
            spent += cost
            if spent > limit:
                return max(blob, longest, key=len), "over", spent, claimed
            if whole:
                return blob, "whole", spent, claimed
            if len(blob) > len(longest):
                longest = blob
    if longest:
        return longest, "partial", spent, claimed
    return None, None, spent, claimed


def gzip_start(data):
    """Where the deflate data of a gzip member at offset 0 begins, or None."""
    if len(data) < 10 or not data.startswith(GZIP_MAGIC):
        return None
    flags, at = data[3], 10
    if flags & 4:
        at += 2 + int.from_bytes(data[10:12], "little")
    for field in (8, 16):
        if flags & field:
            end = data.find(b"\0", at)
            if end < 0:
                return None
            at = end + 1
    if flags & 2:
        at += 2
    return at if at < len(data) else None


def compressed_files(payload):
    """Yield (label, start) for each deflate stream a compressed file holds.

    START is where its raw deflate data begins, past any header, so that a
    stream whose checksum is wrong still yields what it holds. A stream ends
    where its own data says it does.
    """
    at = gzip_start(payload)
    if at is not None:
        yield "gzip", at
    if payload.startswith(ZIP_MEMBER):
        member = 0
        while member >= 0:
            header = payload[member : member + 30]
            if len(header) == 30 and int.from_bytes(header[8:10], "little") == 8:
                names = int.from_bytes(header[26:28], "little")
                extra = int.from_bytes(header[28:30], "little")
                yield "zip member", member + 30 + names + extra
            member = payload.find(ZIP_MEMBER, member + 4)
    if payload.startswith(PDF_MAGIC):
        for match in PDF_STREAM.finditer(payload):
            if zlib_header(payload, match.end()):
                yield "PDF stream", match.end() + 2


def b64decode(run):
    """Decode RUN at each of base64's four alignments, and yield what decodes.

    A run may start with the tail of a word or a prefix glued to the blob, and
    no rule can tell which characters those are, so every start is tried: one
    of the four is in step with the blob. A single character left past the last
    whole group cannot be decoded and is dropped; two or three are an unpadded
    tail, and are padded.
    """
    for k in range(4):
        body = run[k:]
        body = body[:-1] if len(body) % 4 == 1 else body + b"=" * (-len(body) % 4)
        try:
            out = base64.b64decode(body, validate=False)
        except binascii.Error:
            # A run that will not decode at this alignment is simply not
            # base64 there. That is the common case, not an error worth
            # logging: every long alphanumeric token in the tree reaches it.
            continue
        if out:
            yield out


def b64_runs(payload):
    """Every run of base64 worth decoding in PAYLOAD, one line or wrapped.

    Each is given once: a run decoded twice is only time spent twice. URL-safe
    runs are given rewritten in the standard alphabet.
    """
    # A JSON string may escape every slash, and a backslash is outside the
    # alphabet: left in, it cuts the run at each slash the encoding contains.
    payload = payload.replace(b"\\/", b"/")
    # Joined a break at a time rather than by `re.sub`, which holds every
    # piece between two breaks as an object of its own until it joins them:
    # ten megabytes of one-character lines took 850 MiB that way.
    joined, last = bytearray(), 0
    for match in B64_BREAK.finditer(payload):
        joined += payload[last : match.start()]
        last = match.end()
    joined += payload[last:]
    runs, urlsafe = [], []
    for match in B64_RUN.finditer(joined):
        run = bytes(match.group())
        if b"-" in run or b"_" in run:
            runs += B64_STD_PIECES.split(run)
            urlsafe += (p for p in B64_URL_PIECES.split(run) if b"-" in p or b"_" in p)
        else:
            runs.append(run)
    # URL-safe runs are rewritten before the split, not after: B64_PADDING
    # looks for the standard alphabet after a `key=`, and a URL-safe value that
    # starts with `-` or `_` would otherwise stay glued to its key.
    runs += (run.translate(B64URL_TO_STD) for run in urlsafe)
    seen = set()
    for run in runs:
        for part in (run, *B64_PADDING.split(run)[1:]):
            if len(part) >= B64_FLOOR and part not in seen:
                seen.add(part)
                yield part


def tracked_bytes(path, link):
    """The bytes git publishes for the tracked PATH.

    A symlink publishes the path it holds, never what that path leads to:
    following it would read a file that is not published, and a link to a
    FIFO or a device would hang the check or exhaust its memory. Anything that
    is not a regular file where one is tracked raises, and is reported.
    """
    if link and stat.S_ISLNK(os.lstat(path).st_mode):
        return os.fsencode(os.readlink(path))
    # A symlink checked out where links are not supported is a regular file
    # holding the path, and reads as one. Anything else is opened without
    # following a link and without blocking, and read only if what was opened
    # is a regular file: a FIFO opened the ordinary way blocks for ever.
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, "rb") as handle:
        if not stat.S_ISREG(os.fstat(handle.fileno()).st_mode):
            raise OSError(0, "not a regular file")
        return handle.read()


def findings_in(raw):
    """Every reason these bytes should not be published, sorted.

    Split out from reading a file so the same needles reach the surfaces that
    are not files: a commit message, a branch name, a pull-request body.
    """
    hits = []
    budget = [INFLATE_BUDGET]
    decode = [DECODE_BUDGET]
    # The shallowest depth each decoded payload was read at. The same bytes
    # read again no shallower cannot turn up anything new.
    read_at = {}

    def note(label):
        if label not in hits:
            hits.append(label)

    def scan(payload, suffix=""):
        # Matched case-insensitively: these are words, and capitalisation
        # carries no meaning in them.
        low = payload.lower()
        for needle in VENDOR:
            if needle in low:
                note(needle.decode() + suffix)
        # The namespace needle is FOUR bytes, and four bytes over base64's
        # alphabet collide by chance: matched as a bare substring, it can refuse
        # an npm lockfile whose only crime is a sha512- integrity hash
        # containing those four characters. Each sha512 hash offers about 85
        # positions, so a lockfile with a few hundred hashes collides from under
        # one to about three percent of the time: rare in one tree, a rate
        # across many.
        #
        # So it is recognised only where a manifest actually puts it: as a
        # declared XML namespace, or as a namespace-qualified name. This is the
        # same treatment the PNG chunk types already get, and for the same
        # stated reason -- their four letters are ordinary words, so they are
        # matched at a real boundary rather than anywhere in the bytes.
        for needle in NAMESPACE:
            if b"xmlns:" + needle in low or needle + b":" in low:
                note(needle.decode() + suffix)

    def examine(payload, via):
        # VIA names the containers PAYLOAD came out of, innermost first, and
        # every reason found in it says so: "(base64)", "(compressed chunk)",
        # "(compressed chunk in base64)" for a PNG profile in a data URI.
        suffix = f" ({' in '.join(via)})" if via else ""
        scan(payload, suffix)
        opened = len(via) < MAX_DEPTH

        for run in b64_runs(payload):
            if not opened:
                note("nested too deep to open" + suffix)
                break
            for decoded in b64decode(run):
                key = hashlib.blake2b(decoded, digest_size=16).digest()
                if read_at.get(key, MAX_DEPTH + 1) <= len(via) + 1:
                    continue
                read_at[key] = len(via) + 1
                if len(decoded) > decode[0]:
                    note("decode budget exceeded")
                    return
                decode[0] -= len(decoded)
                examine(decoded, ("base64", *via))

        # UTF-16 writes each character of a name as two bytes, one of them
        # NUL, so no needle matches it as it stands. Without a NUL there is
        # no UTF-16 to read.
        if b"\0" in payload:
            for text in utf16_texts(payload):
                examine(text, ("UTF-16", *via))

        view = memoryview(payload)
        for kind, start, end in png_chunks(payload):
            chunk(kind, view[start:end], suffix, via, opened)

        for label, start in compressed_files(payload):
            if not opened:
                note("nested too deep to open" + suffix)
                break
            # A budget already spent leaves no room: the stream is stopped at
            # once, which reports the budget, as running out partway does.
            limit = min(MAX_INFLATE, budget[0])
            blob, _, spent = stream(view, start, -zlib.MAX_WBITS, limit)
            budget[0] -= spent
            if spent > limit:
                if limit < MAX_INFLATE:
                    note("inflate budget exceeded")
                else:
                    note(label + " too large to inflate" + suffix)
            if blob:
                examine(blob, (label, *via))

    def chunk(kind, body, suffix, via, opened):
        if kind in FORBIDDEN_CHUNKS:
            note(kind.decode() + " chunk" + suffix)
        if kind in IMAGE_DATA:
            return
        if not opened:
            # A chunk that would be inflated, left shut, is a place to hide
            # a name: refuse every candidate we would otherwise open, including
            # private raw deflate without a zlib header. At the bound this can
            # also refuse clean private bytes resembling a deflate candidate.
            if kind in MUST_INFLATE or inflate_starts(kind, body):
                note("nested too deep to open" + suffix)
            return
        if budget[0] <= 0:
            note("inflate budget exceeded")
            return
        limit = min(MAX_INFLATE, budget[0])
        blob, state, spent, claimed = inflate(kind, body, limit)
        budget[0] -= spent
        if blob is None:
            if claimed:
                note("compressed chunk does not inflate" + suffix)
            return
        if state == "over":
            if limit < MAX_INFLATE:
                note("inflate budget exceeded")
            else:
                note("compressed chunk too large to inflate" + suffix)
        examine(blob, ("compressed chunk", *via))

    examine(raw, ())

    return sorted(set(hits))


def path_findings(rel):
    """Findings in the repo-relative PATH itself, directory components included.

    A file whose NAME is the marker publishes it as loudly as one whose contents
    do, and a scan of contents alone cannot see it -- an instructions file named
    after the assistant, for instance.
    """
    low = rel.lower().encode("utf-8", "surrogateescape")
    return [n.decode() + " (in the path)" for n in VENDOR if n in low]


USAGE = (
    "usage: check-vendor-attribution.py [ROOT]\n"
    "       check-vendor-attribution.py --text LABEL [--allow-empty] < surface"
)


def scan_text(label, allow_empty):
    """Check one non-file surface, read as bytes from stdin.

    The LABEL is the only thing in the output that says which surface failed,
    so the caller names it: nothing here can work out whether these bytes were
    a branch name or a release note.
    """
    raw = sys.stdin.buffer.read().strip()

    # Every message below puts the label in a prepositional phrase rather than
    # making it the subject. Labels are both singular and plural -- "branch
    # name", "commit messages on this branch" -- and a sentence built around
    # one of them disagrees with the other half of the time.
    if not raw:
        if allow_empty:
            # Declared absent-by-default, so this is the ordinary case and not
            # a result worth dressing up as a pass. Said out loud all the same,
            # because a surface that is empty EVERY time is a broken expression
            # and the log is where that shows.
            print(f"nothing to scan: no {label} on this event")
            return 0
        print(
            f"::error::nothing was scanned: the {label} arrived empty. This "
            f"surface is never legitimately empty, so the step that produced "
            f"it is wrong"
        )
        return 1

    hits = findings_in(raw)
    for hit in hits:
        print(f"::error::{hit} appears in the {label}")
    if hits:
        print(
            f"\nThis must not be published. Unlike a file, a surface cannot be "
            f"allowlisted: rewrite the {label}."
        )
        return 1
    print(f"no assistant attribution in the {label} ({len(raw)} bytes scanned)")
    return 0


def scan_tracked(root):
    allow = load_allowlist()
    # S603/S607 are suppressed rather than fixed, with reason: the argv is a
    # fixed list with no shell, and `root` is this script's own argument, not
    # untrusted input. Resolving an absolute path for `git` would break the
    # runners and developer machines that rely on PATH, which is every one.
    listing = subprocess.run(  # noqa: S603
        ["git", "-C", root, "ls-files", "-z", "--stage"],  # noqa: S607
        capture_output=True,
        check=True,
    ).stdout
    bad = {}
    for entry in listing.split(b"\0"):
        if not entry:
            continue
        meta, _, blob = entry.partition(b"\t")
        rel = blob.decode("utf-8", "surrogateescape")
        if rel in allow:
            continue
        hits = path_findings(rel)
        # A submodule is a commit id in this tree, not a file: its contents are
        # published by its own repository, which runs its own check. Its path
        # is still a name this repository publishes, so it is scanned above.
        if meta.startswith(b"160000 "):
            if hits:
                bad[rel] = sorted(set(hits))
            continue
        link = meta.startswith(b"120000 ")
        try:
            raw = tracked_bytes(os.path.join(root, rel), link)
        except OSError as exc:
            # A tracked path that could not be read is not a path known to be
            # clean. Skipping it here would report a clean tree and exit 0 for a
            # file at mode 000 and for a FIFO alike.
            hits.append(f"could not be read ({exc.strerror})")
        else:
            found = findings_in(raw)
            hits += [f"{hit} (in the link target)" for hit in found] if link else found
        if hits:
            bad[rel] = sorted(set(hits))

    for rel, hits in sorted(bad.items()):
        print(f"::error file={rel}::carries {', '.join(hits)}")
    if bad:
        print(
            f"\n{len(bad)} tracked files carry attribution or metadata that "
            f"should not be published."
        )
        print(
            "Strip it. The allowlist exempts a whole file from every needle, "
            "so it is a last resort, not a fix."
        )
        return 1
    print("no tracked file carries assistant attribution")
    return 0


def main():
    argv = sys.argv[1:]
    if "--text" not in argv:
        return scan_tracked(argv[0] if argv else ".")
    rest = [arg for arg in argv if arg not in ("--text", "--allow-empty")]
    if argv[0] != "--text" or len(rest) != 1:
        # A mangled invocation must not be able to read as a pass. The status
        # is distinct from a finding's, because "this step is miswired" and
        # "this surface is dirty" call for different repairs.
        print(USAGE)
        return 2
    return scan_text(rest[0], "--allow-empty" in argv)


if __name__ == "__main__":
    sys.exit(main())
