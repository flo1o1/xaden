# CLAUDE.md — {{PROJECT_NAME}}

@AGENTS.md

## Claude Code specifics

- Slash commands in `.claude/commands/` wrap the prompts in `prompts/`:
  `/kickoff`, `/feature`, `/bugfix`, `/refactor`, `/requirements`, `/docs`, `/security`, `/review`, `/release`.
- `/security` uses the `alice-security-engineer` skill when available.
- Use plan mode for anything touching more than two files.
- Do not duplicate rules here; edit `AGENTS.md` so every tool stays in sync.
