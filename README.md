# Vibe Coding Scaffold

A tool-agnostic starter for AI-assisted ("vibe") coding that keeps quality, security and
traceability under control. Works with Claude Code, ChatGPT, Aider, Cline, Continue,
Cursor, Codex, Copilot and local models (Ollama, LM Studio).

Everything a new project receives lives in [`template/`](template/). Paths in the table are
relative to it.

## What you get

| Need | Solution |
|------|----------|
| One rule set for every LLM | `AGENTS.md` (+ `CLAUDE.md` imports it, other tools get pointer files) |
| Clean code | Rules in `AGENTS.md`, details in `docs/clean-code.md`, review/refactor prompts |
| Static analysis | `scripts/check.sh`: shellcheck, gitleaks, semgrep, per-stack linters/type/audit (Python, Node) |
| Security | `docs/security.md`, `/security` (alice-security-engineer skill), tool-agnostic `prompts/security-review.md` |
| Requirements tracking | `docs/requirements/REQUIREMENTS.md`, validated by `scripts/check-requirements.sh`; the AI must update it when scope changes |
| Semantic versioning | `VERSION`, `CHANGELOG.md`, Conventional Commits hook, `scripts/release.sh` |
| User + admin docs | `docs/user-guide.md`, `docs/admin-guide.md` (install, system requirements, config, hardening, upgrade); filled by `/docs`, checked by `scripts/check-docs.sh`, release blocked while incomplete |
| Model can't invent rules/requirements | Numbered rules (`CC-nn`) and requirements (`REQ-nnn`); Claude Code imports them into every session; `scripts/req.sh` and `scripts/context-status.sh` (fingerprint handshake); commit hook rejects unknown IDs and requires `Refs: REQ-nnn` on `feat`; `pack-context.sh` includes everything for chat UIs |
| Git | New projects get their own repo with hooks installed |
| Obsidian | Open the folder as a vault; prompts have frontmatter, wikilinks, a template folder |
| Chat UIs / small models | `scripts/pack-context.sh` builds one pasteable file |

New here? Read **[GETTING-STARTED.md](GETTING-STARTED.md)** — prerequisites to first release.

## Create a project

```bash
scripts/setup.sh                         # once after cloning: maintainer hooks + tool check
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

## Layout

```
template/             the product: copied 1:1 into every new project
  AGENTS.md CLAUDE.md .aider.conf.yml .clinerules .continue/ .github/ .claude/ .obsidian/
  prompts/            prompt library (open template/ or a project as Obsidian vault)
  docs/               user-guide, admin-guide, requirements, ADRs, clean-code, security, local-llm
  scripts/            setup, check, release, hooks, pack-context, req, context-status, stacks/
scripts/              scaffold tools: new-project, setup, check-scaffold, release-scaffold
docs/requirements/    requirements of the scaffold itself
tests/smoke.sh        end-to-end test: generates a project and exercises its tooling
AGENTS.md CLAUDE.md   rules for maintaining the scaffold
```

See `template/docs/local-llm.md` for non-Claude tools.

## Maintaining the scaffold

```bash
scripts/setup.sh              # maintainer hooks (.githooks/) + tool check
scripts/check-scaffold.sh     # full check incl. smoke test (pre-commit runs --quick)
scripts/release-scaffold.sh minor
```
