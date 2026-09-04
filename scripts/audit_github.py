#!/usr/bin/env python3
"""Read public GitHub metadata; never install or execute listed repositories.

Requires authenticated `gh`. Writes evidence even when some requests fail.
An unresolved request fails the command; inactivity is a review signal, not
proof of abandonment. Run: python3 scripts/audit_github.py --output audit-output/github.json
"""

import argparse
from concurrent.futures import ThreadPoolExecutor
import datetime as dt
import json
from pathlib import Path
import re
import subprocess
import sys


def fetch(name):
    try:
        result = subprocess.run(
            ["gh", "api", f"repos/{name}"], text=True, capture_output=True, timeout=45
        )
        if result.returncode:
            return {"requested": name, "error": result.stderr.strip()}
        data = json.loads(result.stdout)
        keys = ("full_name", "html_url", "archived", "disabled", "pushed_at",
                "stargazers_count", "default_branch", "fork")
        return {"requested": name, **{key: data[key] for key in keys}}
    except (subprocess.TimeoutExpired, OSError, ValueError, KeyError) as exc:
        return {"requested": name, "error": str(exc)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("audit-output/github.json"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    text = (root / "README.md").read_text()
    names = set(re.findall(r"https://github.com/([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)", text))
    # Ollama's primary listing links to its product website.
    if "https://ollama.com" in text:
        names.add("ollama/ollama")
    with ThreadPoolExecutor(max_workers=4) as pool:
        repositories = list(pool.map(fetch, sorted(names, key=str.casefold)))
    now = dt.datetime.now(dt.timezone.utc)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({"checked_at": now.isoformat(), "repositories": repositories}, indent=2) + "\n")
    failures = 0
    for repo in repositories:
        if "error" in repo:
            failures += 1
            print(f"ERROR: {repo['requested']}: {repo['error']}")
            continue
        pushed = dt.datetime.fromisoformat(repo["pushed_at"].replace("Z", "+00:00"))
        age = (now - pushed).days
        flags = []
        if repo["archived"]:
            flags.append("archived")
        if repo["disabled"]:
            flags.append("disabled")
        if age > 183:
            flags.append(f"last push {age} days ago")
        if repo["requested"] != repo["full_name"]:
            flags.append(f"canonical name: {repo['full_name']}")
        if flags:
            print(f"REVIEW: {repo['requested']}: {', '.join(flags)}")
    print(f"Checked {len(repositories)} repositories; {failures} request failure(s). Evidence: {args.output}")
    return bool(failures)


if __name__ == "__main__":
    sys.exit(main())
