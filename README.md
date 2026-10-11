# Vibe Coding Scaffold

A tool-agnostic starter for AI-assisted ("vibe") coding that keeps quality, security and
traceability under control. Works with Claude Code, ChatGPT, Aider, Cline, Continue,
Cursor, Codex, Copilot and local models (Ollama, LM Studio).

## What you get

| Need | Solution |
|------|----------|
| One rule set for every LLM | `AGENTS.md` (+ `CLAUDE.md` imports it, other tools get pointer files) |
| Clean code | Rules in `AGENTS.md`, details in `docs/clean-code.md`, review/refactor prompts |
| Static analysis | `scripts/check.sh`: shellcheck, gitleaks, semgrep, per-stack linters/type/audit (Python, Node) |
| Security | `docs/security.md`, `/security` (alice-security-engineer skill), tool-agnostic `prompts/security-review.md` |
| Requirements tracking | `docs/requirements/REQUIREMENTS.md`, validated by `scripts/check-requirements.sh`; the AI must update it when scope changes |
| Semantic versioning | `VERSION`, `CHANGELOG.md`, Conventional Commits hook, `scripts/release.sh` |
| Git | New projects get their own repo with hooks installed |
| Obsidian | Open the folder as a vault; prompts have frontmatter, wikilinks, a template folder |
| Chat UIs / small models | `scripts/pack-context.sh` builds one pasteable file |

## Create a project

```bash
scripts/new-project.sh my-app            # creates ../my-app with git, hooks, first commit
scripts/new-project.sh my-app ~/code/x   # custom location
```

Then open `my-app` in your tool and run the kickoff prompt (`/kickoff` in Claude Code).

## Requirements on your machine

bash, git, tar, awk, sed (Linux and macOS). Optional, checks skip what is missing
(`scripts/check.sh --strict` demands them): shellcheck, gitleaks, semgrep, and ruff, mypy,
bandit, pip-audit, pytest (Python) or npm with `lint`/`typecheck`/`test` scripts (Node).
Windows: use WSL or Git Bash (optional, untested).

```bash
brew install shellcheck gitleaks semgrep      # macOS
```

## Test the scaffold itself

```bash
tests/smoke.sh
```

## Layout

```
AGENTS.md  CLAUDE.md  .aider.conf.yml  .clinerules  .continue/  .github/
.claude/commands/     slash commands wrapping prompts/
prompts/              Obsidian vault content (open repo root as vault)
docs/                 requirements, decisions (ADR), clean-code, security, local-llm
scripts/              check, release, hooks, new-project, pack-context
```

See `docs/local-llm.md` for non-Claude tools.
