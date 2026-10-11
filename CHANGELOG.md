# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Security
- AGENTS.md §10 separates trusted instructions from untrusted content (code comments, issues, web pages, tool output, documents, `inbox/`) and lists actions that need explicit user approval: destructive changes, dependencies, production, sending data out, secrets, releases.
- Pre-commit checks run on an export of the git index, so a staged problem can no longer be hidden by an unstaged fix; commit messages are validated against the staged requirements.
- Skipped checks are reported as INCOMPLETE instead of success; CI and releases run `--strict`, so a missing scanner fails. CI installs pinned tool versions (gitleaks verified by SHA-256), sets up Python/Node automatically and requires a committed `package-lock.json`.
- Project generation copies only git-tracked template files; untracked or ignored files (`.env`, `node_modules/`, `inbox/` content) are never copied or committed. Symlinks are refused; failed runs remove the partial project.

### Fixed
- The feature prompt created requirements as `in-progress`, skipping the user's approval; new rows now start as `draft`. All prompts mark **Approval points** the same way and honour approval already given in the session; feature refactors first only when needed, bug fixes are regression-test first.
- Claude Code deny rules blocked `.env.example`, which `/docs` must read; they now list real env file names, cover `git push -f` and `--force-with-lease`, and `CLAUDE.md` states what they do not cover.
- Releases validate the tag before changing files, restore all files if the release commit fails, and print recovery steps if tagging fails.
- Context packs include the security checklist and unreleased changes, list what they leave out, and are written atomically (an invalid prompt name keeps the previous pack). Docs now describe the fingerprint as a consistency aid, not proof.
- Merge/Revert/fixup!/squash! commits no longer bypass ID checks; `Refs:` is parsed as a git trailer; CI checks every commit of a first push or pull request (`verify-commits.sh --ci`).
- Requirements validation rejects empty text or acceptance criteria, invalid dates and (for releases) template placeholders; `feat`/`fix` commits may only reference approved, in-progress or done requirements.
- Smoke test failures now show the command output; tests ignore global git config; tool fixtures are mandatory in CI and visibly skipped locally.
- Python projects were never detected unless pyproject.toml, setup.py and requirements*.txt all existed.

### Added
- Migration rules for persisted data in `docs/architecture.md`: versioned formats, automatic migration, isolated failures with a message, old data kept until migrated, a test per old version. The release prompt treats incompatible data, API and configuration format changes as major.
- Architecture template (`docs/architecture.md`): goals, layers and dependency direction, composition root, interaction, naming, rules for new code, third-party code. Kickoff fills it, the feature and review prompts follow it, context packs include it.
- Twelve local semgrep rules (Python and JS/TS): open redirect, regular expressions built from request data, `random`/`Math.random` for secrets, fast hashes on passwords, cookies without `secure`/`httpOnly`, unsafe XML parsing (stdlib parsers, entity expansion). Each is proven by fixtures; `docs/security.md` says what the rules cover and what they miss.
- The scaffold is published under the MIT License (`LICENSE`); generated projects do not inherit it.
- Completion report format in AGENTS.md §5 (checks run, checks skipped, unresolved findings, acceptance evidence); every working prompt ends with it, and skipped checks are never reported as passed.
- Security reviews are saved as reports (`docs/security-reviews/`, template managed by the scaffold) with scope, evidence, limitations, findings and remediation status; reviews look at callers, configuration and dependencies, not only changed lines.
- `SECURITY.md` in new projects: vulnerability reporting, secret rotation, incident response basics; SBOM/provenance stays optional guidance without tooling.
- Dependency policy in `docs/security.md` (approval, lockfiles, licenses, install scripts, update cadence, optional SBOM/provenance) and `docs/security-exceptions.md` for accepted vulnerabilities with owner and expiry; the release prompt blocks on expired exceptions.
- Threat model template (`docs/threat-model.md`): assets, sensitive data, entry points, trust boundaries, attackers, deployment assumptions, OWASP ASVS level. Kickoff fills it, security reviews read it, context packs include it.
- `inbox/` drop zone in scaffold and projects: contents are git-ignored; assistants treat them as untrusted data.
- Initial scaffold: AGENTS.md rules for any LLM, Claude Code commands, Obsidian prompt vault.
- Static analysis runner (`scripts/check.sh`), requirements tracking and validation.
- SemVer release script, Conventional Commits hook, changelog.
- User and admin guide templates with release gating (`/docs`).
- Grounding: numbered rules (CC-nn), `req.sh`, context fingerprint, ID verification in commits.
- `scripts/setup.sh` for fresh clones, commit-message checks in CI, GETTING-STARTED guide.

### Changed
- `docs/clean-code.md` adds design heuristics (composition root, do-or-coordinate, polymorphism over repeated switches, visible order dependencies, Law of Demeter, size heuristics), naming by scope, comment upkeep and language, refactoring techniques, and test practices (state over interaction, no logic in tests, flaky tests, test doubles, pyramid, Given/When/Then). The ESLint preset forbids `var`.
- Security checklist and review prompt cover more OWASP WSTG test areas: open redirect, parameter pollution, header injection and request smuggling, NoSQL/LDAP/XPath/template injection, file inclusion, vertical privilege escalation, user enumeration, default accounts, session scope and tokens in URLs, HSTS, exposed files and methods, client-side secrets, encryption at rest, upload origin and limits, anti-automation, `LIKE` wildcards, ReDoS, audit trail, segregation of duties, `postMessage` and web storage, card payments via a provider.
- `check-docs.sh` and the docs say it checks structure only, not content. The documentation prompt and admin guide ask generated apps to document timeouts, bounded retries, graceful shutdown, health checks, safe logs, migrations with rollback and tested restores where they apply.
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
