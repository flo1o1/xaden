# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Security
- Pre-commit checks run on an export of the git index, so a staged problem can no longer be hidden by an unstaged fix; commit messages are validated against the staged requirements.
- Skipped checks are reported as INCOMPLETE instead of success; CI and releases run `--strict`, so a missing scanner fails. CI installs pinned tool versions (gitleaks verified by SHA-256), sets up Python/Node automatically and requires a committed `package-lock.json`.
- Project generation copies only git-tracked template files; untracked or ignored files (`.env`, `node_modules/`, `inbox/` content) are never copied or committed. Symlinks are refused; failed runs remove the partial project.

### Fixed
- Releases validate the tag before changing files, restore all files if the release commit fails, and print recovery steps if tagging fails.
- Context packs include the security checklist and unreleased changes, list what they leave out, and are written atomically (an invalid prompt name keeps the previous pack). Docs now describe the fingerprint as a consistency aid, not proof.
- Merge/Revert/fixup!/squash! commits no longer bypass ID checks; `Refs:` is parsed as a git trailer; CI checks every commit of a first push or pull request (`verify-commits.sh --ci`).
- Requirements validation rejects empty text or acceptance criteria, invalid dates and (for releases) template placeholders; `feat`/`fix` commits may only reference approved, in-progress or done requirements.
- Smoke test failures now show the command output; tests ignore global git config; tool fixtures are mandatory in CI and visibly skipped locally.
- Python projects were never detected unless pyproject.toml, setup.py and requirements*.txt all existed.

### Added
- Threat model template (`docs/threat-model.md`): assets, sensitive data, entry points, trust boundaries, attackers, deployment assumptions, OWASP ASVS level. Kickoff fills it, security reviews read it, context packs include it.
- `inbox/` drop zone in scaffold and projects: contents are git-ignored; assistants treat them as untrusted data.
- Initial scaffold: AGENTS.md rules for any LLM, Claude Code commands, Obsidian prompt vault.
- Static analysis runner (`scripts/check.sh`), requirements tracking and validation.
- SemVer release script, Conventional Commits hook, changelog.
- User and admin guide templates with release gating (`/docs`).
- Grounding: numbered rules (CC-nn), `req.sh`, context fingerprint, ID verification in commits.
- `scripts/setup.sh` for fresh clones, commit-message checks in CI, GETTING-STARTED guide.

### Changed
- Security checklist (`docs/security.md`) is anchored to OWASP ASVS and covers CSRF precisely (SameSite is defence in depth), SSRF with redirects and DNS rebinding, archive and symlink traversal, upload limits, object- and tenant-level authorization tests, session revocation, password reset, rate and resource limits, safe parsing and data retention; web-only items are marked.
- Clean-code rules are proportional and language-appropriate: CC-05 accepts exceptions, result or option types; CC-06 documents public APIs and contracts instead of every function; CC-03 warns against premature abstraction; CC-04 covers dependency direction and explicit side effects; CC-09 forbids unrelated refactoring. `docs/clean-code.md` says what tools cannot check.
- Projects record their scaffold version and a manifest of managed files (`.scaffold/`);
  `scripts/update-scaffold.sh <project> [--apply]` brings them to a newer scaffold with a
  three-way comparison, never overwriting local edits (`*.scaffold-new` instead).
- New projects receive only tracked, non-ignored template files (no `.DS_Store` etc.).
- Requirement traceability (`check-traceability.sh`): `done` requirements must be cited by a test,
  tests must not cite unknown IDs; `--matrix` prints requirement → tests → commits.
- Clean-code linter presets (`template/presets/`, `scripts/apply-preset.sh python|node`) map
  CC rules to ruff/mypy and ESLint settings; a detected stack with missing config, tools,
  scripts or tests now fails instead of passing silently.
- Pre-commit checks are fast and offline: staged files only, versioned local semgrep rules
  (`template/.semgrep/rules.yml`, tested by fixtures), `gitleaks --staged`. Types, tests, audits
  and semgrep registry rules run in the full check and CI.
- Project files moved to `template/`; the scaffold has its own requirements, rules,
  maintainer hooks (`.githooks/`), `check-scaffold.sh`, `release-scaffold.sh` and CI (Linux + macOS).
