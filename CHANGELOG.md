# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Initial scaffold: AGENTS.md rules for any LLM, Claude Code commands, Obsidian prompt vault.
- Static analysis runner (`scripts/check.sh`), requirements tracking and validation.
- SemVer release script, Conventional Commits hook, changelog.
- User and admin guide templates with release gating (`/docs`).
- Grounding: numbered rules (CC-nn), `req.sh`, context fingerprint, ID verification in commits.
- `scripts/setup.sh` for fresh clones, commit-message checks in CI, GETTING-STARTED guide.

### Changed
- Project files moved to `template/`; the scaffold has its own requirements, rules,
  maintainer hooks (`.githooks/`), `check-scaffold.sh`, `release-scaffold.sh` and CI (Linux + macOS).
