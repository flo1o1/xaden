# Xaden — Threat model

The scaffold's own threat model, read by `/security` in this repository (REQ-055). Generated
projects get their own from `template/docs/threat-model.md`. Update this file when a change
adds an entry point, a downloaded tool or a new place the scripts write to.

**Last reviewed:** 2026-10-11, security review `docs/security-reviews/2026-10-11-scaffold-scripts.md`.

## System summary

Bash scripts and Markdown files. Maintainers and users run the scripts on their own machines
(Linux, macOS) to generate projects, update them and check them; the same scripts run in GitHub
Actions for the scaffold and for every generated project. No server, no network service, no
stored user data.

## Assets

- Integrity of generated projects: only reviewed template content, hooks that really check.
- Users' machines and CI runners: the scripts run with the user's rights on every commit.
- Secrets near the scaffold or a project (`.env`, keys) that must never be copied or committed.
- Trust in the gates: a green check, a valid `Refs:` trailer and a release tag mean what they say.

## Sensitive data

None stored by the scaffold. Scripts read git metadata (author names and emails in commits) and
may meet secrets in the working tree (`.env`, `inbox/`), which they must not copy, commit or print.

## Entry points

- CLI arguments: project name and target directory (`new-project.sh`), project directory and
  `--apply` (`update-scaffold.sh`), bump part (`release*.sh`), prompt names (`pack-context.sh`),
  requirement IDs, epics and titles (`req.sh`); command and arguments of `xaden`, target
  directory of `install.sh`.
- Files the scripts read: `template/` (exported to projects), requirement files, commit message
  files, `CHANGELOG.md`, `VERSION`, a project's `.scaffold/manifest` and `package.json` /
  `pyproject.toml` (which decide which tools run).
- Environment: `PROJECT_ROOT`, `RULES_FILE`, `STRICT`, `PATH`; in CI `EVENT_NAME`, `BASE_REF`,
  `BEFORE_SHA`, `DEFAULT_BRANCH`, filled from GitHub event data.
- Downloaded tools in CI: gitleaks archive, semgrep and ruff from PyPI, GitHub Actions, Homebrew.
- `inbox/`: files dropped by the user, untrusted by definition.

## Trust boundaries

- Untracked or ignored files in `template/` vs. the reviewed, tracked template content.
- A project's own files vs. the files the scaffold manages there (`update-scaffold.sh`).
- Pull-request and push data (branch names, commit messages) vs. the CI shell.
- Downloads from GitHub, PyPI and Homebrew vs. the CI runner.
- Content in `inbox/`, prompts' task input and tool output vs. instructions the assistant follows.

## Attackers and capabilities

- Contributor sending a pull request: controls branch names, commit messages and file contents.
- Contributor to a generated project, or the author of a project cloned from elsewhere: controls
  its tracked files, including symbolic links and `.scaffold/manifest`, which
  `update-scaffold.sh` reads and writes next to.
- Compromised upstream tool or action: code runs in CI with the job's permissions (read-only
  repository token).
- Malicious file in `inbox/` or pasted content: tries to make the assistant run commands or
  commit secrets (prompt injection).
- Careless use: a secret left in `template/`, a project name with shell or path characters.

## Deployment assumptions

Runs as the invoking user; no `sudo` except tool installation in CI. CI jobs use
`permissions: contents: read`. Nothing is pushed or published by the scripts. `scripts/install.sh` writes one symbolic link
(`~/.local/bin/xaden` by default) and nothing else outside the checkout.

## Security baseline

Verification standard: OWASP ASVS (what to build), OWASP WSTG (how to test it).

- ASVS level: L1, applied to input validation, secrets handling and build and dependency
  integrity.
- Not applicable areas: no web client, sessions, authentication or authorization of users;
  web-only WSTG items do not apply.

## Threats and mitigations

| Threat | Asset | Mitigation | Requirement / test |
|--------|-------|------------|--------------------|
| Project name with shell, `sed` or path characters | users' machines | `is_project_name` allows `[a-z][a-z0-9-]{1,50}` only | REQ-001, smoke "reject bad project name" |
| Secrets, dependencies or symlinks copied into a project | secrets, project integrity | only tracked template files exported; symlinks refused; failed runs cleaned up | REQ-018, smoke `test_generation_safety` |
| Secret committed | secrets | gitleaks in pre-commit and CI; a missing scanner fails `--strict` | REQ-004, REQ-019, smoke `test_missing_tools`; no test plants a secret yet |
| Unstaged fix hides a staged problem | trust in the gates | checks run on an export of the git index | REQ-020, smoke `test_staged_snapshot` |
| Commit cites invented requirements or slips past checks | trust in the gates | ID and trailer checks on every commit, re-run in CI | REQ-011, REQ-022, smoke `test_commit_bypasses` |
| Malicious `BASE_REF` in CI | CI runner | value validated before use | REQ-022, smoke "CI rejects a malformed base ref" |
| Update overwrites a project's own edits | project integrity | three-way comparison; conflicts written as `*.scaffold-new` | REQ-017, smoke `test_scaffold_update` |
| Symlink in a project redirects an update's writes outside the project | users' machines | writes refused when the path or a parent is a symlink (review 2026-10-11 #1) | REQ-017, smoke `test_update_safety` |
| Edited manifest makes an update delete project-owned files | project integrity | manifest paths outside `MANAGED_PATHS` ignored (review #2) | REQ-017, smoke `test_update_safety` |
| Repository token left in `.git/config` while CI runs project code | CI runner | `persist-credentials: false` on every checkout (review #3) | REQ-019, smoke `test_ci_credentials` |
| `install.sh` replaces a user's own `xaden` file, or `--uninstall` removes one | users' machines | never overwrites an existing name; removes only a link to this checkout | REQ-056, smoke `test_xaden_command` |
| `xaden` project commands run a malicious project's scripts | users' machines | same trust as running `scripts/*.sh` by hand; documented in GETTING-STARTED ("only in projects you trust"); commands are a fixed list | REQ-056 |
| Tampered gitleaks download in CI | CI runner | pinned version, SHA-256 verified | REQ-019 |
| Instructions hidden in `inbox/` or pasted content | users' machines, secrets | `inbox/` ignored by git; AGENTS.md §10 treats it as data | REQ-026, REQ-033 |

## Accepted risks

- The macOS CI job installs Homebrew's current shellcheck, semgrep, ruff and gitleaks without
  pinning; the Linux job is the pinned reference.
- semgrep and ruff are pinned by version from PyPI, not by hash.
