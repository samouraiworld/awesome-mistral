# Repository conventions

This file applies to every contributor and every automated agent working in
this repository. [MAINTENANCE.md](MAINTENANCE.md) is the editorial procedure,
and [CONTRIBUTING.md](CONTRIBUTING.md) sets the inclusion criteria.

## Assistant attribution — hard rule

- Never name an AI assistant, its vendor, or a model anywhere in this repository: not in a tracked file, a filename, a commit message, a commit author or committer identity, a PR title or body, a branch name, a tag, or a release note. No vendor-named instruction file — conventions live in `AGENTS.md` — no `Co-Authored-By:` trailer, no "generated with" footer or badge, no link to a vendor's site.
- **It covers binary and encoded content too.** Attribution has reached repositories in this org inside PNG text chunks and base64-encoded provenance manifests, where a recursive grep cannot see it. A grep is not sufficient evidence.
- **Verify before pushing:** `python3 .github/scripts/check-vendor-attribution.py .` for tracked files, and `git log --format='%an <%ae>%n%cn <%ce>%n%B' origin/main..HEAD | python3 .github/scripts/check-vendor-attribution.py --text "commits on this branch"` for commit metadata. The `Vendor attribution` check enforces both on every pull request.
- Naming a Mistral model, or a *third-party* tool listed in the directory, is the point of this repository. What is forbidden is attribution of the assistant used to produce the work.
- This is a hard rule, not a style preference. It is not waivable in review.

## Git workflow

- Never commit to `main` or `master`. Work on a dated `docs/`, `fix/` or `chore/` branch and open a pull request; a maintainer merges it.
- Commit as the maintainer identity configured for this repository. A hosted automation must set `git config user.name` and `user.email` before its first commit, because its default identity is not acceptable here.
- Commit messages explain why, in one concise line with an optional short body, and carry no trailers.
- Reuse the open maintenance pull request instead of opening a competing one.

## Checks before pushing

Run the reproducible checks listed in [MAINTENANCE.md](MAINTENANCE.md#reproducible-checks)
and the attribution commands above. Never weaken a check, add a link exception
or accept an HTTP error class to make a pull request pass; record the evidence
and fix the cause instead.
