# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Fixed
- Python projects were never detected unless pyproject.toml, setup.py and requirements*.txt all existed.

### Added
- Initial scaffold: AGENTS.md rules for any LLM, Claude Code commands, Obsidian prompt vault.
- Static analysis runner (`scripts/check.sh`), requirements tracking and validation.
- SemVer release script, Conventional Commits hook, changelog.
- User and admin guide templates with release gating (`/docs`).
- Grounding: numbered rules (CC-nn), `req.sh`, context fingerprint, ID verification in commits.
- `scripts/setup.sh` for fresh clones, commit-message checks in CI, GETTING-STARTED guide.

### Changed
- Clean-code linter presets (`template/presets/`, `scripts/apply-preset.sh python|node`) map
  CC rules to ruff/mypy and ESLint settings; a detected stack with missing config, tools,
  scripts or tests now fails instead of passing silently.
- Pre-commit checks are fast and offline: staged files only, versioned local semgrep rules
  (`template/.semgrep/rules.yml`, tested by fixtures), `gitleaks --staged`. Types, tests, audits
  and semgrep registry rules run in the full check and CI.
- Project files moved to `template/`; the scaffold has its own requirements, rules,
  maintainer hooks (`.githooks/`), `check-scaffold.sh`, `release-scaffold.sh` and CI (Linux + macOS).
