# Requirements — Vibe Coding Scaffold

Requirements of the scaffold itself (not of generated projects).
Priority: `must` · `should` · `could` · `wont` — Status: `draft` · `approved` · `in-progress` · `done` · `dropped`

| ID      | Requirement | Priority | Status | Acceptance criteria | Updated |
|---------|-------------|----------|--------|---------------------|---------|
| REQ-001 | Create a new project from the template with its own git repository and active hooks | must | done | `scripts/new-project.sh name` yields a repo with one commit and core.hooksPath set (smoke test) | 2026-10-11 |
| REQ-002 | One rule set usable by Claude Code, ChatGPT, other agents and local LLMs | must | done | AGENTS.md plus pointer files for Claude, Aider, Cline, Continue, Copilot; pack-context for chat UIs | 2026-10-11 |
| REQ-003 | Apply clean-code rules when generating code | must | done | Numbered CC rules in template AGENTS.md; review and refactor prompts cite them | 2026-10-11 |
| REQ-004 | Static code analysis on every commit and in CI | must | done | check.sh runs linters, shellcheck, secret scan, SAST; hooks and CI call it | 2026-10-11 |
| REQ-005 | Security review via alice-security-engineer skill with a tool-agnostic fallback | must | done | /security command plus prompts/security-review.md based on OWASP WSTG | 2026-10-11 |
| REQ-006 | Track requirements and update them when a session changes scope | must | done | REQUIREMENTS.md validated by script; AGENTS.md mandates update before code; /requirements prompt | 2026-10-11 |
| REQ-007 | Semantic versioning of projects | must | done | VERSION, CHANGELOG, Conventional Commits hook, release.sh bumps and tags | 2026-10-11 |
| REQ-008 | Review prompts in Obsidian | must | done | Template opens as a vault; prompts have frontmatter, wikilinks, template folder | 2026-10-11 |
| REQ-009 | Run on Linux and macOS; Windows optional | must | done | Bash 3.2 and POSIX tools only; smoke test passes on macOS and Linux CI | 2026-10-11 |
| REQ-010 | Generate user and admin documentation including installation and system requirements | must | done | Guide templates with required sections; /docs fills them; release blocked while TODOs remain | 2026-10-11 |
| REQ-011 | Prevent models from inventing rules or requirements | must | done | Imports, req.sh lookup, context fingerprint, commit hook rejects unknown IDs | 2026-10-11 |
| REQ-012 | Usable by people other than the author | must | done | setup.sh after clone, GETTING-STARTED, CI verifies commit messages | 2026-10-11 |
| REQ-013 | Separate scaffold maintenance files from the project template | must | done | Projects are copied from template/ only; scaffold has its own requirements, rules and checks | 2026-10-11 |
| REQ-014 | Fast, offline and reproducible pre-commit checks | must | done | Pre-commit checks only staged files, needs no network, uses pinned rules; full run in CI | 2026-10-11 |
| REQ-015 | Clean-code rules enforced by linters; a detected stack without checks fails | must | done | Stack presets map CC rules to linter settings; missing lint/type/test steps fail check.sh | 2026-10-11 |
| REQ-016 | Requirements traceable to tests | must | done | Every done requirement is referenced by a test; matrix script lists requirement to tests | 2026-10-11 |
| REQ-017 | Existing projects can adopt newer scaffold versions | should | done | Projects record scaffold version; update script shows and applies changes to managed files only | 2026-10-11 |
| REQ-018 | Project generation copies only reviewed template content | must | done | Only git-tracked template files (staged content) are copied; untracked, ignored and secret files never; symlinks and existing targets refused; partial output removed on failure; paths with spaces work | 2026-10-11 |
| REQ-019 | Required checks cannot be skipped silently | must | done | Every check reports passed, failed or skipped; any skip marks the run INCOMPLETE; CI and releases run strict so a missing scanner fails; CI provisions pinned tool versions | 2026-10-11 |
| REQ-020 | Pre-commit checks validate exactly the staged snapshot | must | done | A staged regression cannot be hidden by an unstaged fix; a requirement ID present only in an unstaged file cannot validate a commit; the working tree is never modified | 2026-10-11 |
| REQ-021 | Requirements need complete fields and an eligible status | must | done | Empty requirement text or acceptance criteria and invalid dates fail; template placeholders block releases; feat and fix may only reference approved, in-progress or done requirements | 2026-10-11 |
| REQ-022 | Commit reference checks cannot be bypassed | must | done | Special prefixes skip only the format check; Refs are parsed as git trailers; CI validates every commit of a first push | 2026-10-11 |
| REQ-023 | Context pack contains all mandatory guidance and is written safely | must | done | Pack includes the security checklist and the Unreleased changelog and lists its contents; an invalid prompt name keeps the previous pack; docs call the fingerprint a consistency aid, not proof | 2026-10-11 |
| REQ-024 | Releases never leave a partial state | must | done | An existing tag or failing check aborts before any file changes; a failing commit restores the files; a failing tag is reported with recovery steps | 2026-10-11 |
| REQ-025 | Scaffold tests are diagnosable and independent of user configuration | should | done | Failed assertions show the command output; tests ignore global git configuration; tool-dependent fixtures are mandatory in CI | 2026-10-11 |
| REQ-026 | Local drop zone for files that must never be committed | should | done | inbox/ exists in scaffold and projects; its contents are git-ignored, not copied into new projects, and treated as untrusted data by assistants | 2026-10-11 |

## Change log

- 2026-10-11 REQ-001..REQ-012 recorded retroactively from the initial build sessions.
- 2026-10-11 REQ-013..REQ-017 added: improvement plan (template split, fast hooks, linter presets, traceability, update path).
- 2026-10-11 REQ-014 done: staged/offline pre-commit, local semgrep rules.
- 2026-10-11 REQ-015 done: ruff/mypy and ESLint presets mapped to CC rules; detected stacks fail on missing setup.
- 2026-10-11 REQ-016 done: check-traceability.sh; scaffold smoke tests cite the requirements they verify.
- 2026-10-11 REQ-017 done: .scaffold manifest and update-scaffold.sh with three-way comparison.
- 2026-10-11 REQ-018..REQ-025 added from an external review (findings F01, F04-F08, release partial failure, test diagnostics). F02 and F03 were already fixed by REQ-015.
- 2026-10-11 REQ-025 done: smoke test shows output on failure, ignores global git config, CI requires tool fixtures
- 2026-10-11 REQ-026 added: user asked for a place to drop files that stay out of git.
- 2026-10-11 REQ-026 done: inbox/ in scaffold and template, contents git-ignored
- 2026-10-11 REQ-018 done: export_template copies tracked template files only, refuses symlinks, cleans up partial projects
- 2026-10-11 REQ-019 done: passed/failed/skipped summary, INCOMPLETE status, strict CI and release, pinned CI tools
- 2026-10-11 REQ-020 done: pre-commit checks run on an export of the git index; commit-msg reads requirements from the index
- 2026-10-11 REQ-021 done: field, date and placeholder validation; feat/fix only reference approved, in-progress or done
- 2026-10-11 REQ-022 done: prefixes skip only format check, trailers parsed by git, CI range covers whole first push
- 2026-10-11 REQ-023 done: pack includes security checklist and unreleased changes, validates before writing, atomic; fingerprint described as consistency aid
- 2026-10-11 REQ-024 done: tag checked before changes, failed commit restores files, failed tag reported with recovery steps
