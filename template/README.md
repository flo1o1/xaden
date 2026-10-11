# {{PROJECT_NAME}}

> Describe the project in one sentence here.

Built with the vibe-coding scaffold: AI-assisted, requirements-tracked, statically
analysed, security-reviewed, SemVer-versioned.

## Quick start

```bash
scripts/setup.sh   # once after every clone: activates git hooks, lists missing tools
scripts/check.sh   # static analysis, requirements and docs checks
```

Start an AI session by pointing the tool at this folder, then run the kickoff prompt:
`prompts/kickoff.md` (Claude Code: `/kickoff`).
Tools without file access: `scripts/pack-context.sh kickoff` and paste `context-pack.md`.

## Where things are

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Rules for every AI assistant (`CLAUDE.md` imports it) |
| `docs/requirements/REQUIREMENTS.md` | Tracked requirements, updated every session |
| `docs/user-guide.md`, `docs/admin-guide.md` | End-user and operator documentation (install, system requirements, config, upgrade) |
| `prompts/` | Reusable prompts; open the folder in Obsidian |
| `scripts/` | check, release, hooks, context packing |
| `CHANGELOG.md`, `VERSION` | SemVer history |
| `inbox/` | Local drop zone for your files; contents are git-ignored and never committed |
| `.scaffold/` | Scaffold version and managed-file manifest (used by the scaffold's `update-scaffold.sh`) |

## Release

```bash
scripts/release.sh patch   # or minor / major
```

## Optional tools (checks skip missing ones; `scripts/check.sh --strict` requires them)

shellcheck, gitleaks, semgrep, plus per stack: ruff, mypy, bandit, pip-audit, pytest (Python)
or npm scripts `lint` / `typecheck` / `test` (Node/TypeScript).
