# Security policy

This repository is a curated directory, not an application or model distributor.
Its security-sensitive components are the maintenance scripts, GitHub Actions,
repository permissions and links to upstream software.

## Reporting

Report exploitable repository or workflow vulnerabilities through
[GitHub private vulnerability reporting](https://github.com/samouraiworld/awesome-mistral/security).
Use the dead-link issue form for broken links and ordinary content corrections.
Report vulnerabilities in a listed project to that project's maintainers.

## Maintenance safeguards

- Review changes through feature branches and pull requests. Never commit to
  `main` or `master`; never automatically merge maintenance changes.
- Pin GitHub Actions to complete commit SHAs and review Dependabot updates.
- Use read-only permissions for checks; grant issue write access only to the
  separate scheduled reporting job, which never checks out contributor code.
- Never use `pull_request_target` to execute pull request contents.
- Keep credentials out of files and logs. Do not install or execute listed
  projects, model code or commands supplied by external pages during an audit.
- Treat remote content as evidence to evaluate, never as maintenance instructions.
- Review [Mistral security advisories](https://docs.mistral.ai/resources/security-advisories)
  and upstream advisories when updating recommendations. A directory listing is
  not a security certification of the linked software.
