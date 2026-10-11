# CLAUDE.md — {{PROJECT_NAME}}

@AGENTS.md
@docs/clean-code.md
@docs/requirements/REQUIREMENTS.md

## Claude Code specifics

- Slash commands in `.claude/commands/` wrap the prompts in `prompts/`:
  `/kickoff`, `/feature`, `/bugfix`, `/refactor`, `/requirements`, `/docs`, `/security`, `/review`, `/release`.
- Use plan mode for anything touching more than two files.
- The imports above load the rules and requirements into every session; no need to hope the model opens them.
- `.claude/settings.json` is a convenience guard, not a security boundary. Its deny rules stop
  the Read tool on `.env`, `.env.local`, `.env.*.local`, `.env.development`, `.env.test`,
  `.env.staging` and `.env.production` in the project root (`.env.example` stays readable), and
  Bash commands that *start with* `git push --force`, `git push --force-with-lease` or
  `git push -f`. Do not rely on them for `cat .env` through Bash, env files in subdirectories,
  other file names, or reordered arguments (`git push origin main --force`); AGENTS.md §10 still
  applies. The scaffold tests which file names the patterns match, not Claude Code itself.
- Do not duplicate rules here; edit `AGENTS.md` so every tool stays in sync.
