#!/usr/bin/env python3
"""Offline editorial invariants. Python 3.11+, no third-party dependencies."""

import datetime as dt
import json
from pathlib import Path
import re
import sys
import tomllib

ROOT = Path(__file__).resolve().parents[1]
ENTRY = re.compile(r"^- ([🧠🌍🧪]) \[([^\]]+)\]\((https://[^\s)]+)\)(?: ⭐ (\d+)k\+)? – (.+)$")


def check_readme(text):
    errors, previous, seen = [], None, {}
    for number, line in enumerate(text.splitlines(), 1):
        if not re.match(r"^- [🧠🌍🧪] .*\[", line):
            previous = None
            continue
        match = ENTRY.fullmatch(line)
        if not match:
            errors.append(f"README.md:{number}: invalid resource format")
            continue
        marker, name, url, stars, description = match.groups()
        key = name.lstrip("@").casefold()
        if previous and key < previous:
            errors.append(f"README.md:{number}: {name} is out of alphabetical order")
        previous = key
        canonical = url.rstrip("/").casefold()
        if canonical in seen:
            errors.append(f"README.md:{number}: duplicate primary URL (line {seen[canonical]})")
        seen[canonical] = number
        if stars and int(stars) < 5:
            errors.append(f"README.md:{number}: stars are displayed only from 5k")
        if not description.endswith((".", ")*")):
            errors.append(f"README.md:{number}: description needs terminal punctuation")
        if marker == "🧠" and not re.match(
            r"https://(?:(?:[a-z0-9-]+\.)?mistral\.ai(?:/|$)|"
            r"(?:github\.com|huggingface\.co)/mistralai(?:/|$)|"
            r"www\.npmjs\.com/package/@mistralai/|arxiv\.org/abs/|"
            r"discord\.gg/mistralai$|x\.com/MistralAI$)", url
        ):
            errors.append(f"README.md:{number}: official marker needs ownership verification")
    return errors


def check_metadata(data, text, today):
    errors = []
    reviewed = dt.date.fromisoformat(data["last_reviewed"])
    age = (today - reviewed).days
    if not 0 <= age <= 31 or data["max_age_days"] != 31:
        errors.append(f"Editorial review is future-dated or older than 31 days ({age} days)")
    elif age > 7:
        print(f"WARNING: editorial review is {age} days old; weekly refresh is due")
    if f"Last editorial review: {reviewed.isoformat()}." not in text:
        errors.append("README review date does not match maintenance.json")
    if data["audit"] != f"audits/{reviewed.isoformat()}.md":
        errors.append("Audit path must match the editorial review date")
    for entry in data["link_exceptions"]:
        checked = dt.date.fromisoformat(entry["checked_at"])
        expires = dt.date.fromisoformat(entry["expires_on"])
        if not checked <= today <= expires or not 0 < (expires - checked).days <= 7:
            errors.append(f"Link exception expired, future-dated or longer than 7 days: {entry['url']}")
        if not entry["reason"] or not entry["evidence"].startswith("https://"):
            errors.append(f"Missing evidence for link exception: {entry['url']}")
    return errors


def main():
    text = (ROOT / "README.md").read_text()
    data = json.loads((ROOT / "maintenance.json").read_text())
    today = dt.datetime.now(dt.timezone.utc).date()
    errors = check_readme(text) + check_metadata(data, text, today)
    audit = ROOT / data["audit"]
    if not audit.is_file():
        errors.append(f"Missing audit: {data['audit']}")
    config = tomllib.loads((ROOT / "lychee.toml").read_text())
    expected = {"^" + re.escape(e["url"]) + "$" for e in data["link_exceptions"]}
    if set(config.get("exclude", [])) != expected:
        errors.append("Lychee exclusions must exactly match documented, dated URLs")
    # Pin every action, including any introduced by subsequent maintenance.
    for path in sorted((ROOT / ".github/workflows").glob("*.y*ml")):
        source = path.read_text()
        if "pull_request_target" in source:
            errors.append(f"{path.name}: privileged pull-request execution is forbidden")
        for action in re.findall(r"\buses:\s+(\S+)", source):
            if not re.fullmatch(r"[\w.-]+/[\w./-]+@[0-9a-f]{40}", action):
                errors.append(f"{path.name}: action must use a complete commit SHA: {action}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    print(f"Content checks: {len(errors)} error(s)")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
