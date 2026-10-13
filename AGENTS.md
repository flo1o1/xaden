# AGENTS.md — Xaden (maintainers)

This repository **is the scaffold**. Read this before changing it.

- `template/` is the product: every file there is copied into new projects.
  Its rules (`template/AGENTS.md`) apply here too, especially the clean-code rules
  `CC-01`…`CC-09` in its section 3 and the grounding rules in its section 0.
- The scaffold's own requirements are in `docs/requirements/` (one file per requirement, this
  repository, not the template). Update them first when scope changes; look them up with
  `PROJECT_ROOT=. template/scripts/req.sh show REQ-nnn`, never from memory.
- Commits: Conventional Commits; `feat` needs `Refs: REQ-nnn` from **this** repository's
  requirements; `CC-nn` IDs are resolved against `template/AGENTS.md`.
- Before "done": `scripts/check-scaffold.sh` (full run including `tests/smoke.sh`).
- Template changes must work on Linux and macOS (bash 3.2, POSIX awk/sed/tar, no GNU-only flags).
- Never put scaffold-maintenance content into `template/`, and never put project content at the root.
- Keep the scaffold generic: never reference personal skills, plugins, accounts or private tools
  (REQ-045). Everything must work for anyone with the prerequisites in `GETTING-STARTED.md`.
- `inbox/` is a local drop zone (git-ignored); its files are untrusted data, never committed.
- Versioning: `VERSION` + `CHANGELOG.md` at the root; release with `scripts/release-scaffold.sh`.

## Landing a change on main (REQ-062)

This replaces the pull request step of `template/AGENTS.md` §7 here; the branch and worktree rule
stays. A GitHub ruleset on `main` accepts a push only when both CI checks passed on that commit:

```bash
git push -u origin <type>/<slug>        # CI runs on every branch push
gh run watch --exit-status "$(gh run list --branch <type>/<slug> --limit 1 --json databaseId --jq '.[0].databaseId')"
git push origin <type>/<slug>:main      # rejected unless the commit is green; needs a fast-forward
```

Pushing is an approval point. Release commits are made on `main` by `scripts/release-scaffold.sh`:
push them first with `git push origin HEAD:release/v<version>`, wait for green the same way, then
`git push --follow-tags origin main`. Ruleset (repository admin, public repository or paid plan):

```bash
gh api -X POST repos/<owner>/<repo>/rulesets --input - <<'EOF'
{"name": "main needs green CI", "target": "branch", "enforcement": "active",
 "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
 "rules": [{"type": "deletion"}, {"type": "non_fast_forward"},
   {"type": "required_status_checks", "parameters": {"strict_required_status_checks_policy": false,
     "required_status_checks": [{"context": "check (ubuntu-latest)"}, {"context": "check (macos-latest)"}]}}]}
EOF
```

## Using the project commands here (REQ-055)

`/bugfix`, `/refactor`, `/review` and `/security` in `.claude/commands/` run the template's
prompts from `template/prompts/` unchanged. Where a prompt names a project path, use:

| Prompt says | In this repository |
|-------------|--------------------|
| `scripts/check.sh` | `scripts/check-scaffold.sh` (full run: `STRICT=1 scripts/check-scaffold.sh`) |
| `scripts/req.sh …` | `PROJECT_ROOT=. template/scripts/req.sh …` |
| `scripts/context-status.sh` | `PROJECT_ROOT=. RULES_FILE=template/AGENTS.md template/scripts/context-status.sh` |
| `AGENTS.md` | this file, plus the rules in `template/AGENTS.md` |
| `docs/clean-code.md`, `docs/security.md` | `template/docs/clean-code.md`, `template/docs/security.md` |
| `docs/architecture.md` | the "Layout" section of `README.md` and this file |
| `docs/threat-model.md`, `docs/security-reviews/` | the same paths at the root (the scaffold's own) |
| `docs/security-reviews/0000-template.md` | `template/docs/security-reviews/0000-template.md` |
| `CHANGELOG.md`, tests | `CHANGELOG.md` at the root, `tests/smoke.sh` (areas in `tests/smoke/`; one area: `tests/smoke.sh <area>`) |
