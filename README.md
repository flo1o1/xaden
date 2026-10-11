# Xaden

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

**Start here: [GETTING-STARTED.md](GETTING-STARTED.md)** — prerequisites, creating a project,
kickoff, features, release, and updating existing projects.

## Layout

```
template/             the product: copied 1:1 into every new project
  AGENTS.md CLAUDE.md .aider.conf.yml .clinerules .continue/ .github/ .claude/ .obsidian/
  prompts/            prompt library (open template/ or a project as Obsidian vault)
  docs/               user-guide, admin-guide, requirements, ADRs, clean-code, security, local-llm
  scripts/            setup, check, release, hooks, pack-context, req, context-status, stacks/
scripts/              scaffold tools: xaden + install, new-project, update-scaffold, setup, check-scaffold, release-scaffold
docs/requirements/    requirements of the scaffold itself
inbox/                local drop zone (git-ignored contents)
tests/smoke.sh        end-to-end test: generates a project and exercises its tooling
AGENTS.md CLAUDE.md   rules for maintaining the scaffold
```

## Maintaining the scaffold

```bash
scripts/setup.sh              # maintainer hooks (.githooks/) + tool check
scripts/check-scaffold.sh     # full check incl. smoke test (pre-commit runs --staged)
scripts/release-scaffold.sh minor
```

## License

The scaffold is released under the [MIT License](LICENSE). Projects you generate do not
inherit it: `template/` contains no license file, so choose one for each project.
