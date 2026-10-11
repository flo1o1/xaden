---
title: Prompt index
type: index
tags: [prompts, index]
---

# Prompt library

Open this repository folder as an **Obsidian vault**; review and edit prompts here.
Every prompt has frontmatter (`status`, `version`, `works-with`) visible in Obsidian's Properties panel.

| Prompt | Use when | Claude Code |
|--------|----------|-------------|
| [[kickoff]] | New project: capture goals, requirements, stack | `/kickoff` |
| [[feature]] | Build a new capability | `/feature` |
| [[bugfix]] | Fix a defect | `/bugfix` |
| [[refactor]] | Improve structure, same behaviour | `/refactor` |
| [[requirements-update]] | Scope changed mid-session | `/requirements` |
| [[code-review]] | Review a diff against clean-code rules | `/review` |
| [[security-review]] | Security audit (OWASP WSTG based) | `/security` |
| [[documentation]] | Write/update user and admin guides | `/docs` |
| [[release]] | Cut a SemVer release | `/release` |

Related: [[prompt-template]] · rules in `AGENTS.md` · requirements in `docs/requirements/REQUIREMENTS.md`

## How to use with each tool

- **Claude Code**: slash command above; it loads `AGENTS.md` through `CLAUDE.md`.
- **Aider / Cline / Continue / Cursor / Codex**: they read `AGENTS.md` (Aider via `.aider.conf.yml`);
  paste or reference the prompt file.
- **ChatGPT / web UIs / small local models**: `scripts/pack-context.sh <prompt-name>`, paste `context-pack.md`.

## Conventions

- One prompt = one job. Keep each under ~60 lines so small models cope.
- Variables are written `{{like_this}}`; fill them before sending.
- Bump `version` when you change the wording; set `status: draft | stable`.
