# {{PROJECT_NAME}}

> Describe the project in one sentence here.

Built with the vibe-coding scaffold: AI-assisted, requirements-tracked, statically
analysed, security-reviewed, SemVer-versioned.

## Quick start

```bash
git config core.hooksPath scripts/hooks   # already set by the scaffold
scripts/check.sh                          # static analysis + requirements check
```

Start an AI session by pointing the tool at this folder, then run the kickoff prompt:
`prompts/kickoff.md` (Claude Code: `/kickoff`).
Tools without file access: `scripts/pack-context.sh kickoff` and paste `context-pack.md`.

## Where things are

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Rules for every AI assistant (`CLAUDE.md` imports it) |
| `docs/requirements/REQUIREMENTS.md` | Tracked requirements, updated every session |
| `prompts/` | Reusable prompts; open the folder in Obsidian |
| `scripts/` | check, release, hooks, context packing |
| `CHANGELOG.md`, `VERSION` | SemVer history |

## Release

```bash
scripts/release.sh patch   # or minor / major
```

## Optional tools (checks skip missing ones; `scripts/check.sh --strict` requires them)

shellcheck, gitleaks, semgrep, plus per stack: ruff, mypy, bandit, pip-audit, pytest (Python)
or npm scripts `lint` / `typecheck` / `test` (Node/TypeScript).
