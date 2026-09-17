# Maintenance playbook

Run the editorial review **every Sunday at 09:00 Europe/Paris**. Address a major
release, material factual error or security advisory sooner when discovered.
An editorial review must never be more than **31 days** old. CI warns after
seven days and fails after 31; unresolved link exceptions expire after at most 14 days.
A successful link check alone does not constitute an editorial review.

## Weekly procedure

1. Fetch the default branch and inspect local changes and open PRs. Reuse an
   existing maintenance PR when appropriate; otherwise create a dated `docs/`,
   `fix/` or `chore/` feature branch from the latest remote default branch.
   Preserve unrelated work and never commit to `main` or `master`.
2. Read the previous audit and inspect the sources below from its verification
   date through today. Follow each candidate to its primary source, even when
   discovered through a search engine or social media.
3. Check every model family against current model cards: exact IDs, weights,
   license, context, modalities, API stage, aliases, prices and retirement dates.
   Treat announced retirement dates and confirmed retirement as distinct facts.
4. Check official SDK and Vibe releases, new official repositories, products,
   regional availability and security advisories. Include material developments
   with their actual dates; never fabricate an update in a quiet week.
5. Run all link and content checks below. Inspect redirects for semantic changes.
   Retry transient errors; distinguish missing pages from login requirements or
   rate limiting. Never broadly accept 401, 403, 429, 5xx or redirect loops.
6. Review GitHub metadata, archived/stale repositories, compatibility evidence,
   alphabetical order, duplicate entries, markers, license wording and stars.
   Apply the historical-resource exceptions in CONTRIBUTING.md explicitly.
7. Check workflow permissions, SHA pins, Dependabot updates, CODEOWNERS validity,
   branch protections, secret scanning and private vulnerability reporting.
   Audit this repository's executable maintenance code; do not install, execute
   or claim to security-audit every third-party project listed here.
8. Write `audits/YYYY-MM-DD.md` with scope, sources, changes, measured checks,
   limitations and next actions. Preserve older audits. Update `maintenance.json`
   and the README review date/audit link only after completing the review.
9. Commit and open/update a PR with **Summary** and **Test plan**, without
   attribution trailers. Inspect its CI and fix failures. Leave merging to a
   maintainer; report the PR and any unresolved blockers in the scheduled task.

## Sources of record

| Area | Sources |
| --- | --- |
| Announcements | [Mistral News](https://mistral.ai/news/) |
| Models and lifecycle | [Catalog](https://docs.mistral.ai/models), [lifecycle policy](https://docs.mistral.ai/inference/model-lifecycle), individual model cards |
| API changes and pricing | [Changelog](https://docs.mistral.ai/resources/changelogs), [pricing](https://docs.mistral.ai/inference/pricing) |
| Product availability | [Release notes](https://docs.mistral.ai/resources/release-notes) |
| Model specifications | [Model schemas](https://github.com/mistralai/platform-docs-public/tree/main/src/schema/models/models) behind the catalog; compare against the previous review's commit |
| Model weights | [Mistral on Hugging Face](https://huggingface.co/mistralai), individual model cards and licenses |
| SDKs | [Python releases](https://github.com/mistralai/client-python/releases), [TypeScript releases](https://github.com/mistralai/client-ts/releases) |
| Coding agent and CLI | [Vibe releases](https://github.com/mistralai/mistral-vibe/releases), [Mistral CLI releases](https://github.com/mistralai/cli/releases) |
| Official repositories | [Mistral GitHub](https://github.com/mistralai) |
| Security | [Mistral advisories](https://docs.mistral.ai/resources/security-advisories), [GitHub advisory database](https://github.com/advisories), upstream repository advisories and Security settings |

When sources conflict, prefer the version-specific model card/schema for model
specifications, the current pricing page for prices, and the changelog for API
release dates. Document the conflict instead of silently guessing. An API probe
is only evidence when performed with authorized access; do not spend API credits
to establish a model's status during routine maintenance.

## Reproducible checks

Prerequisites: Python 3.11+, authenticated GitHub CLI, Lychee **0.24.2**, and
markdownlint-cli2 **0.23.2** (the version bundled by the pinned CI action). CI pins
the action wrappers separately by commit SHA.
Use published tools from their upstreams; check downloaded release checksums.

```sh
python3 scripts/check_content.py
python3 -m unittest discover -s scripts -p 'test_*.py'
npx --yes markdownlint-cli2@0.23.2
mkdir -p audit-output
git ls-files -- '*.md' '.github/ISSUE_TEMPLATE/*.yml' > audit-output/link-inputs.txt
lychee --config lychee.toml --no-progress --verbose --format json --output audit-output/links.json --files-from audit-output/link-inputs.txt
python3 scripts/audit_github.py --output audit-output/github.json
git diff --check
```

Stage new documentation before creating the tracked-file inventory, or explicitly
include it in the local check. The CI checks every tracked Markdown file and URLs
in issue templates, including historical audit source links. Code examples are
not executed. Local and remote anchors are checked by Lychee.

Review HTTP redirects using `curl --head --location` and the verbose link-check
output; an HTTP 200 alone cannot establish relevance. Inspect the destination's
content, particularly for moved repositories, rebrands and cloud catalogs.

## Access restrictions and evidence

`maintenance.json` records exact-URL exceptions with a reason, primary evidence,
verification date and expiry. `scripts/check_content.py` requires a one-to-one
match with the anchored exclusions in `lychee.toml`. Review each exception every
week; max validity is 14 days, so a review PR awaiting merge does not break the
default branch. A primary-source reference confirms ownership,
but does not prove that an authenticated destination is accessible. State that
limitation in the report. Never report excluded links as HTTP-verified successes.

Store raw check outputs in ignored `audit-output/`; summarize useful results in
the dated audit. GitHub Actions preserves `quality-evidence` artifacts for 90 days.
Keep failed and retried outcomes distinguishable rather than replacing evidence
with an unsupported claim that everything passed.

CI also probes each excluded destination separately with a bounded HTTPS GET and
records its status, destination and transport error in `link-exceptions.json`.
These measurements do not count as Lychee successes or renew an exception.
Inspect the artifact when deciding whether an exclusion is still necessary;
a 200 response may still be a login or anti-bot page.

## Scheduling and failure handling

The scheduled editorial task performs research, edits and a reviewable PR in this
repository every Sunday at 07:00 UTC (09:00 Europe/Paris in summer time). It runs
in a hosted automation environment and depends on that account's usage limits,
network access and repository permissions; a run that stops before research is a
missed review, not a quiet week. On its next run after a missed review, cover
the entire gap since the last successful editorial review.

GitHub Actions independently checks the default branch every Sunday at 07:17 UTC,
on pushes and on PRs. GitHub may delay schedules, and disables scheduled workflows
in public repositories [after 60 days without repository activity](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule); monitor the last
actual run, not just the presence of a cron expression. Trigger a manual run after
restoring a missed schedule. This CI does not perform editorial research or merge.
Push, scheduled and manual runs have separate concurrency groups so a manual
check cannot cancel the checks attached to a merge. Only superseded PR runs are
cancelled automatically.
The issue-reporting job remains serialized across triggers to avoid duplicate
failure issues when scheduled and manual runs finish together.

A separate scheduled reporting job opens or updates one bot-owned failure issue
and closes it after a successful scheduled/manual check. PR checks never receive
issue-write permissions. A failed review, overdue audit, broken link or unavailable
source must be reported with a concrete next action. Do not silently advance the
review date or accumulate duplicate maintenance PRs.
