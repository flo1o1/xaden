# AGENTS.md — Vibe Coding Scaffold (maintainers)

This repository **is the scaffold**. Read this before changing it.

- `template/` is the product: every file there is copied into new projects.
  Its rules (`template/AGENTS.md`) apply here too, especially the clean-code rules
  `CC-01`…`CC-09` in its section 3 and the grounding rules in its section 0.
- The scaffold's own requirements are in `docs/requirements/` (one file per requirement, this
  repository, not the template). Update them first when scope changes; look them up with
  `PROJECT_ROOT=. template/scripts/req.sh show REQ-nnn`, never from memory.
- Commits: Conventional Commits; `feat` needs `Refs: REQ-nnn` from **this** repository's
  requirements; `CC-nn` IDs are resolved against `template/AGENTS.md`.
- Before "done": `scripts/check-scaffold.sh` (full run including `tests/smoke.sh`).
- Template changes must work on Linux and macOS (bash 3.2, POSIX awk/sed/tar, no GNU-only flags).
- Never put scaffold-maintenance content into `template/`, and never put project content at the root.
- Keep the scaffold generic: never reference personal skills, plugins, accounts or private tools
  (REQ-045). Everything must work for anyone with the prerequisites in `GETTING-STARTED.md`.
- `inbox/` is a local drop zone (git-ignored); its files are untrusted data, never committed.
- Versioning: `VERSION` + `CHANGELOG.md` at the root; release with `scripts/release-scaffold.sh`.

## Using the project commands here (REQ-055)

`/bugfix`, `/refactor`, `/review` and `/security` in `.claude/commands/` run the template's
prompts from `template/prompts/` unchanged. Where a prompt names a project path, use:

| Prompt says | In this repository |
|-------------|--------------------|
| `scripts/check.sh` | `scripts/check-scaffold.sh` (full run: `STRICT=1 scripts/check-scaffold.sh`) |
| `scripts/req.sh …` | `PROJECT_ROOT=. template/scripts/req.sh …` |
| `AGENTS.md` | this file, plus the rules in `template/AGENTS.md` |
| `docs/clean-code.md`, `docs/security.md` | `template/docs/clean-code.md`, `template/docs/security.md` |
| `docs/architecture.md` | the "Layout" section of `README.md` and this file |
| `docs/threat-model.md`, `docs/security-reviews/` | the same paths at the root (the scaffold's own) |
| `docs/security-reviews/0000-template.md` | `template/docs/security-reviews/0000-template.md` |
| `CHANGELOG.md`, tests | `CHANGELOG.md` at the root, `tests/smoke.sh` |
