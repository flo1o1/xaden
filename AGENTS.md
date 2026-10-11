# AGENTS.md — Vibe Coding Scaffold (maintainers)

This repository **is the scaffold**. Read this before changing it.

- `template/` is the product: every file there is copied into new projects.
  Its rules (`template/AGENTS.md`) apply here too, especially the clean-code rules
  `CC-01`…`CC-09` in its section 3 and the grounding rules in its section 0.
- The scaffold's own requirements are in `docs/requirements/REQUIREMENTS.md` (this
  repository, not the template). Update them first when scope changes; look them up with
  `PROJECT_ROOT=. template/scripts/req.sh show REQ-nnn`, never from memory.
- Commits: Conventional Commits; `feat` needs `Refs: REQ-nnn` from **this** repository's
  requirements; `CC-nn` IDs are resolved against `template/AGENTS.md`.
- Before "done": `scripts/check-scaffold.sh` (full run including `tests/smoke.sh`).
- Template changes must work on Linux and macOS (bash 3.2, POSIX awk/sed/tar, no GNU-only flags).
- Never put scaffold-maintenance content into `template/`, and never put project content at the root.
- `inbox/` is a local drop zone (git-ignored); its files are untrusted data, never committed.
- Versioning: `VERSION` + `CHANGELOG.md` at the root; release with `scripts/release-scaffold.sh`.
