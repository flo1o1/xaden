# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Breaking
- Requirements are one file per requirement in epic folders (`docs/requirements/<epic>/REQ-nnn-<slug>.md` with an `EPIC.md` per epic and a generated `INDEX.md`) instead of one table. Functional requirements are Jobs To Be Done (*When …, I want to …, so I can …*), non-functional ones measurable quality goals. `scripts/req.sh new|show|list|index` manages them; `check-requirements.sh`, the commit hook, traceability, context fingerprint and packs read the new layout. Existing projects run `scripts/migrate-requirements.sh` after updating.

### Security
- `scripts/pack-context.sh` refuses symbolic links, so a committed link (for example in `docs/personas/`) can no longer copy a file from outside the project, such as a credentials file, into a context pack.
- A `fix` commit's trailer must be a requirement ID or exactly `Refs: none`; values that merely contain "none" (such as `Refs: nonexistent`) are rejected.
- `scripts/check-security-exceptions.sh` rejects expiry dates with an impossible month or day (such as `2026-13-01`), which used to be accepted and silently extended the exception.
- `scripts/migrate-requirements.sh` stops when a table row's ID is not `REQ-nnn`, so a crafted requirements table can no longer make the migration write files outside `docs/requirements/`.
- The full `scripts/check.sh` fails when a row in `docs/security-exceptions.md` has expired, has no owner or no `YYYY-MM-DD` expiry, so accepted risks are fixed or consciously renewed. The pre-commit hook skips this date-dependent check.
- Releases are refused while `SECURITY.md` or `docs/threat-model.md` still contain `<!-- TODO` markers, so no release ships without a vulnerability contact and a threat model.
- `scripts/update-scaffold.sh` refuses to write through a symbolic link in the project, so a committed symlink can no longer make an update overwrite files outside the project; paths in `.scaffold/manifest` outside the scaffold-managed files are ignored, so an edited manifest can no longer make an update delete project files.
- CI checkouts no longer keep the job token in `.git/config` (`persist-credentials: false`) while dependency installs and tests run.
- Dependency policy requires checking that a proposed package really exists in the official registry (source, maintainers, age, downloads) before it is added, against slopsquatting: malware registered under package names assistants invent.
- AGENTS.md §10 separates trusted instructions from untrusted content (code comments, issues, web pages, tool output, documents, `inbox/`) and lists actions that need explicit user approval: destructive changes, dependencies, production, sending data out, secrets, releases.
- Pre-commit checks run on an export of the git index, so a staged problem can no longer be hidden by an unstaged fix; commit messages are validated against the staged requirements.
- Skipped checks are reported as INCOMPLETE instead of success; CI and releases run `--strict`, so a missing scanner fails. CI installs pinned tool versions (gitleaks verified by SHA-256), sets up Python/Node automatically and requires a committed `package-lock.json`.
- Project generation copies only git-tracked template files; untracked or ignored files (`.env`, `node_modules/`, `inbox/` content) are never copied or committed. Symlinks are refused; failed runs remove the partial project.

### Fixed
- Shell lint failed on Linux CI: Ubuntu's shellcheck 0.9.0 rejects `A && B || C` in `scripts/pack-context.sh` and `scripts/install.sh`, which newer versions accept; both are now plain `if` statements.
- The full check chose the files for each checker with several processes per tracked file (about 12 s per checker for 5,000 files); it now filters the list in one pass.
- `scripts/context-status.sh` reads the rules from `RULES_FILE` when set, so maintainers get a complete `CONTEXT CHECK` at the scaffold root (command in the root AGENTS.md) instead of an error and an empty rule list.
- `xaden update` and `scripts/update-scaffold.sh` work in git worktrees and submodules, where `.git` is a file instead of a folder.
- The pre-commit hook copied every tracked file into its snapshot on each commit, so large tracked assets slowed every commit; files over 1 MiB that the commit does not change are now left out.
- `check-traceability.sh --matrix` listed tests that cite a requirement only on a `traceability: ignore` line, while the check did not count them; both now skip those lines.
- `scripts/release-scaffold.sh` released and tagged even when `CHANGELOG.md` had no `[Unreleased]` section, leaving the release without notes; the shared changelog stamp now refuses that for both release scripts.
- `check-docs.sh --release` counted every "TODO" word, so a guide mentioning TODO items (e.g. of a to-do app) blocked every release; only `<!-- TODO` markers count now.
- CI of a Python project without `requirements-dev.txt` (ruff configured in `pyproject.toml`) stopped at the install step with "No such file"; it now installs the file only when present, and `scripts/check.sh --strict` names any missing tool.
- Commits made with `git commit -v` were rejected when the appended diff mentioned an unknown `REQ-nnn`; the commit-msg check now reads the message as git stores it, without comments and diff.
- Obsidian per-user files (`appearance.json`, plugins, workspace, cache) were not ignored; projects now track only the shared vault config (`app.json`, `core-plugins.json`, `templates.json`), and the scaffold root ignores `.obsidian/` entirely.
- `/security`, AGENTS.md, CLAUDE.md and the docs referred to a personal security skill other users do not have; the review now runs the tool-agnostic prompt only, and a smoke test rejects skill references in generated projects.
- The feature prompt created requirements as `in-progress`, skipping the user's approval; new rows now start as `draft`. All prompts mark **Approval points** the same way and honour approval already given in the session; feature refactors first only when needed, bug fixes are regression-test first.
- Claude Code deny rules blocked `.env.example`, which `/docs` must read; they now list real env file names, cover `git push -f` and `--force-with-lease`, and `CLAUDE.md` states what they do not cover.
- Releases validate the tag before changing files, restore all files if the release commit fails, and print recovery steps if tagging fails.
- Context packs include the security checklist and unreleased changes, list what they leave out, and are written atomically (an invalid prompt name keeps the previous pack). Docs now describe the fingerprint as a consistency aid, not proof.
- Merge/Revert/fixup!/squash! commits no longer bypass ID checks; `Refs:` is parsed as a git trailer; CI checks every commit of a first push or pull request (`verify-commits.sh --ci`).
- Requirements validation rejects empty text or acceptance criteria, invalid dates and (for releases) template placeholders; `feat`/`fix` commits may only reference approved, in-progress or done requirements.
- Smoke test failures now show the command output; tests ignore global git config; tool fixtures are mandatory in CI and visibly skipped locally.
- Python projects were never detected unless pyproject.toml, setup.py and requirements*.txt all existed.

### Added
- Every change happens on its own branch in its own git worktree and reaches `main` through a pull request (AGENTS.md §7), so several changes can be worked on in parallel without touching each other. The pre-commit hook refuses commits on `main`/`master`; project generation, releases and concluding a merge are allowed, `ALLOW_MAIN_COMMIT=1` overrides.
- User personas: `scripts/persona.sh new "<name>"` (or `/persona <description>` in Claude Code) creates a prefilled `docs/personas/<name>.md`. AGENTS.md, kickoff, feature and code review check every solution against the project's 3 to 5 personas and name the one it fails; context packs include them.
- `xaden` command: `scripts/install.sh` links it into `~/.local/bin`; `xaden new my-app` creates `./my-app` from any directory, `xaden update` updates the project you are in, and `xaden setup|check|req|pack|release` run that project's own scripts from any of its subdirectories.
- Caveman (shorter assistant replies) is documented as an optional add-on next to Ponytail, with the rule that project files stay in normal prose.
- Token Optimizer (context and tool-output compression) is documented as an optional add-on, with its noncommercial license and the rule that completion reports quote failing lines from the full, uncompressed output.
- Maintainers can run `/bugfix`, `/refactor`, `/review` and `/security` on the scaffold itself: root commands include the template prompts unchanged, `AGENTS.md` maps their project paths, and `docs/threat-model.md` describes the scaffold's own attack surface.
- `/review` in Claude Code offers Ponytail's `/ponytail-review` as an optional second pass when the plugin is installed; the project's review prompt and completion report stay authoritative.
- "Look before you build" rule (AGENTS.md §9, feature prompt): before writing something others have likely solved, assistants search for mature existing solutions and offer them as options with name, summary, license, website and maturity; adopting one follows the dependency approval and registry check.
- Optional tools, suggested where they fit: the full `scripts/check.sh` prints `TIP:` lines for actionlint and zizmor (GitHub workflows), jscpd (duplication), vulture or knip (dead code), Hypothesis or fast-check (property-based tests) and mutmut or StrykerJS (mutation testing), depending on the project's language. Adopted tools run in the check; tips never change the result. `docs/optional-tools.md` also lists Claude Code plugins for deeper reviews (Anthropic `code-review`/`security-guidance`, Trail of Bits, Ponytail).
- GETTING-STARTED documents [Ponytail](https://github.com/DietrichGebert/ponytail) as an optional add-on rule set (install per tool, trusted sources); nothing is installed automatically. AGENTS.md §10 states that add-on rule sets never override the project rules.
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
- CI workflows (scaffold and generated projects) pin `actions/checkout` v7.0.1 instead of v4.2.2, which ran on the deprecated Node 20. Self-hosted runners need runner version 2.327.1 or newer.
- `.claude/settings.json` is now updated by `scripts/update-scaffold.sh`, so existing projects receive corrected Claude Code permissions; a project that edited the file keeps it and gets `.claude/settings.json.scaffold-new` to merge.
- The scaffold is now called Xaden (formerly Vibe Coding Scaffold). New projects name it in their README, first CHANGELOG entry and first commit; script names and the `.scaffold/` state folder are unchanged, so existing projects update as before.
- Commit hooks are faster with many requirements: the traceability check reads each test file once, and the commit-msg check exports the staged requirements in one step.
- Loosening a linter or type-checker rule, raising a threshold or adding a suppression is an approval point (AGENTS.md §5); when adopting linters on existing code, violations go into a baseline that may only shrink.
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
