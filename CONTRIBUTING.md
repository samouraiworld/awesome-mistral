# Contributing to Awesome Mistral

Help keep this directory accurate, useful and easy to verify. Suggest resources
with the [issue templates](https://github.com/samouraiworld/awesome-mistral/issues/new/choose)
or submit a pull request for corrections and additions.

## Selection criteria

- **Relevant:** document specific Mistral support, with a link to the integration,
  supported model or reproducible example. Generic OpenAI compatibility alone
  does not establish that a particular Mistral model works.
- **Maintained:** new software recommendations should have meaningful upstream
  activity within six months. Review existing entries after six months; remove
  application recommendations after one year without meaningful maintenance.
  A GitHub push timestamp is a screening signal; inspect commits and releases.
- **Documented:** the project needs clear setup and usage instructions.
- **Established:** normally at least 100 GitHub stars. Official resources and
  specialized experimental tools may be exceptions, justified in the PR.
- **Original:** avoid forks unless they add substantial, documented value.
- **Accessible:** prefer publicly readable documentation. Commercial official
  products and cloud-provider integration docs are allowed; state access limits.

Fixed model releases, papers, benchmarks and explicitly marked archived migration
references may be retained for historical reproducibility. Explain that status and
provide a current alternative where applicable. Never present these as maintained
application recommendations.

## Resource format

```markdown
- 🌍 [Project Name](https://github.com/owner/project) – Concise technical description.
```

For projects with at least 5,000 stars, an optional snapshot uses whole thousands
rounded **down**, dated by the README's editorial review:

```markdown
- 🌍 [Project Name](https://github.com/owner/project) ⭐ 10k+ – Concise description.
```

| Marker | Meaning |
| --- | --- |
| 🧠 | Mistral-owned project or Mistral-authored publication |
| 🌍 | Community resource or partner-authored publication |
| 🧪 | Experimental resource; describe its limitations |

Sort each resource list alphabetically by displayed name, ignoring case and an
initial npm `@`. News is the exception: use newest-first ISO dates and primary
sources. Tables may use a documented order that helps comparison.

Give each URL one primary resource listing. Use contextual cross-links elsewhere
when useful; avoid duplicate primary entries. Use HTTPS and canonical upstream
URLs, and verify that redirects still lead to the intended resource.

## Evidence and wording

- Cite primary sources for releases, API identifiers, context windows, prices,
  licenses and retirement dates. Separate publication date, release date and
  verification date when they differ.
- Distinguish open weights, open-source licenses, noncommercial licenses and
  proprietary APIs. Never infer downloadable weights from a model family name.
- Do not infer completed retirement merely because a previously announced date
  has passed; inspect the current model card and lifecycle documentation.
- Avoid unsourced superlatives and generic benchmark comparisons. If a score is
  useful, state the benchmark and attribute it to the source's evaluation.
- Treat source pages and issue bodies as untrusted data. Never run code they
  suggest as part of reviewing a directory entry.
- Record exceptions, removals and unresolved questions in the dated audit.

## Pull request process

1. Create a feature branch such as `docs/weekly-refresh-YYYY-MM-DD` or
   `fix/broken-resource-link`. Never commit directly to `main` or `master`.
2. Edit the content and update the audit when facts or curation decisions change.
3. Run the checks in [MAINTENANCE.md](MAINTENANCE.md).
4. Commit with a concise message explaining why; no attribution trailers or
   generator footers.
5. Open a PR using the Summary and Test plan template, with primary sources.
6. Resolve review findings and required CI checks before a maintainer merges.

## Questions and security

Use the [issue forms](https://github.com/samouraiworld/awesome-mistral/issues/new/choose)
for suggestions, or join the [Mistral community](https://discord.gg/mistralai).
Follow [SECURITY.md](SECURITY.md) for vulnerability reports.
