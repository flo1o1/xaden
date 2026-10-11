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
| REQ-014 | Fast, offline and reproducible pre-commit checks | must | approved | Pre-commit checks only staged files, needs no network, uses pinned rules; full run in CI | 2026-10-11 |
| REQ-015 | Clean-code rules enforced by linters; a detected stack without checks fails | must | approved | Stack presets map CC rules to linter settings; missing lint/type/test steps fail check.sh | 2026-10-11 |
| REQ-016 | Requirements traceable to tests | must | approved | Every done requirement is referenced by a test; matrix script lists requirement to tests | 2026-10-11 |
| REQ-017 | Existing projects can adopt newer scaffold versions | should | approved | Projects record scaffold version; update script shows and applies changes to managed files only | 2026-10-11 |

## Change log

- 2026-10-11 REQ-001..REQ-012 recorded retroactively from the initial build sessions.
- 2026-10-11 REQ-013..REQ-017 added: improvement plan (template split, fast hooks, linter presets, traceability, update path).
