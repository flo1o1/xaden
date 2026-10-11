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
| Security | `docs/security.md`, `/security` and tool-agnostic `prompts/security-review.md` (OWASP WSTG based) |
| Requirements tracking | `docs/requirements/`: one file per requirement in epic folders, functional ones as Jobs To Be Done, quality ones as measurable goals; validated by `scripts/check-requirements.sh`; the AI must update them when scope changes |
| Semantic versioning | `VERSION`, `CHANGELOG.md`, Conventional Commits hook, `scripts/release.sh` |
| User + admin docs | `docs/user-guide.md`, `docs/admin-guide.md` (install, system requirements, config, hardening, upgrade); filled by `/docs`, structure checked by `scripts/check-docs.sh` (not content), release blocked while incomplete |
| Fewer invented rules/requirements | Numbered rules (`CC-nn`) and requirements (`REQ-nnn`); Claude Code imports them into every session; `scripts/req.sh` lookup; commit hook and traceability check reject unknown IDs. `scripts/context-status.sh` fingerprints the files the assistant started from: a consistency aid, not proof it read or followed them |
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

Only files tracked by git in `template/` are copied (including uncommitted edits to them);
untracked or ignored files such as `.env`, `node_modules/` or `inbox/` content never are.
A failed run removes the half-created project.

Then open `my-app` in your tool and run the kickoff prompt (`/kickoff` in Claude Code).

## Requirements on your machine

bash, git, tar, awk, sed (Linux and macOS). Locally, a missing analysis tool is skipped and
the run is reported as INCOMPLETE; CI and releases use `--strict`, where it fails: shellcheck, gitleaks, semgrep, and ruff, mypy,
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
scripts/              scaffold tools: new-project, update-scaffold, setup, check-scaffold, release-scaffold
docs/requirements/    requirements of the scaffold itself
inbox/                local drop zone (git-ignored contents)
tests/smoke.sh        end-to-end test: generates a project and exercises its tooling
AGENTS.md CLAUDE.md   rules for maintaining the scaffold
```

See `template/docs/local-llm.md` for non-Claude tools.

## Updating existing projects

```bash
scripts/update-scaffold.sh ../my-app          # dry run: what would change
scripts/update-scaffold.sh ../my-app --apply  # apply and stage; review, then commit
```

Only scaffold-managed files (scripts, prompts, presets, rules, commands) are updated. Files you
changed locally are never overwritten: the new version is written next to them as
`<file>.scaffold-new` for you to merge. Code, requirements, guides, README and changelog are
never touched. Each project records its scaffold version in `.scaffold/`.

Projects that still keep requirements in one `docs/requirements/REQUIREMENTS.md` table run
`scripts/migrate-requirements.sh` after updating: it converts every row into a requirement
file (job stories left as TODO to rewrite) and the checks then accept the new format.

## Maintaining the scaffold

```bash
scripts/setup.sh              # maintainer hooks (.githooks/) + tool check
scripts/check-scaffold.sh     # full check incl. smoke test (pre-commit runs --staged)
scripts/release-scaffold.sh minor
```

## License

The scaffold is released under the [MIT License](LICENSE). Projects you generate do not
inherit it: `template/` contains no license file, so choose one for each project.
