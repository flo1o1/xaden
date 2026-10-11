# Requirements — Vibe Coding Scaffold

Requirements of the scaffold itself (not of generated projects).
Priority: `must` · `should` · `could` · `wont` — Status: `draft` · `approved` · `in-progress` · `done` · `dropped`

| ID      | Requirement | Priority | Status | Acceptance criteria | Updated |
|---------|-------------|----------|--------|---------------------|---------|
| REQ-001 | Create a new project from the template with its own git repository and active hooks | must | done | `scripts/new-project.sh name` yields a repo with one commit and core.hooksPath set (smoke test) | 2026-10-11 |
| REQ-002 | One rule set usable by Claude Code, ChatGPT, other agents and local LLMs | must | done | AGENTS.md plus pointer files for Claude, Aider, Cline, Continue, Copilot; pack-context for chat UIs | 2026-10-11 |
| REQ-003 | Apply clean-code rules when generating code | must | done | Numbered CC rules in template AGENTS.md; review and refactor prompts cite them | 2026-10-11 |
| REQ-004 | Static code analysis on every commit and in CI | must | done | check.sh runs linters, shellcheck, secret scan, SAST; hooks and CI call it | 2026-10-11 |
| REQ-005 | Security review that works with any assistant | must | done | /security command and prompts/security-review.md based on OWASP WSTG; no personal or optional add-on required | 2026-10-11 |
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
| REQ-027 | Clean-code rules are proportional and language-appropriate | should | done | CC-06 documents contracts instead of every function; CC-05 accepts exceptions, result or option types; CC-03 and CC-09 warn against premature abstraction and purposeless refactoring; CC-04 covers dependency direction and explicit side effects; every CC ID in AGENTS.md is explained in clean-code.md; IDs stay stable | 2026-10-11 |
| REQ-028 | Projects capture a threat model at kickoff | should | done | Template has docs/threat-model.md (assets, sensitive data, entry points, trust boundaries, attackers, deployment assumptions, ASVS level); kickoff fills it; security review reads it; context pack includes it | 2026-10-11 |
| REQ-029 | Security checklist covers common gaps precisely | should | done | security.md covers CSRF beyond SameSite, SSRF redirects and private ranges, archive and symlink traversal, upload limits, object and tenant authorization tests, session expiry and revocation, password reset, rate and resource limits, safe parsing, data retention and logging; web-only items marked | 2026-10-11 |
| REQ-030 | Dependency policy with accountable exceptions | should | done | security.md states update, lockfile, license and install-script rules; docs/security-exceptions.md records accepted vulnerabilities with owner and expiry | 2026-10-11 |
| REQ-031 | Projects ship a vulnerability reporting and incident policy | should | done | Template SECURITY.md covers reporting, secret rotation and incident basics; SBOM and provenance are optional guidance without tooling | 2026-10-11 |
| REQ-032 | Security reviews produce a recorded report with evidence | should | done | Review prompt output has scope, evidence, limitations, findings and remediation status; reports are stored from docs/security-reviews/0000-template.md; a checklist is not presented as proof | 2026-10-11 |
| REQ-033 | Assistants distinguish trusted instructions from untrusted content and ask before risky actions | must | done | AGENTS.md names untrusted sources that never authorise commands, policy changes or secret access, and lists actions needing explicit user approval | 2026-10-11 |
| REQ-034 | Claude Code permission rules are accurate and documented with their limits | should | done | Deny rules block real env files but not .env.example; docs say which patterns are covered and that they are not a security boundary | 2026-10-11 |
| REQ-035 | Prompts follow one consistent workflow and approval model | should | done | Bugfix is regression-test first, feature refactors only when needed; approval points are named the same way across prompts and respect authorisation already given | 2026-10-11 |
| REQ-036 | Assistants end work with a truthful completion report | must | done | AGENTS.md defines the report (checks run, checks skipped, unresolved findings, acceptance evidence); prompts reference it; skipped checks are never reported as passed | 2026-10-11 |
| REQ-037 | Documentation guidance is honest about checks and covers operations | should | done | Docs state check-docs.sh validates structure only; documentation prompt and admin guide ask for timeouts, retries, cancellation, health checks, safe logs, migrations with rollback and tested restores where they apply | 2026-10-11 |
| REQ-038 | The scaffold is published under the MIT license | should | done | Root LICENSE holds the MIT text; generated projects do not inherit it | 2026-10-11 |
| REQ-039 | Security checklist and review cover the WSTG test areas missing so far | should | done | security.md and the review prompt cover open redirect, parameter pollution, header injection and smuggling, further injection types, file inclusion, vertical privilege escalation, user enumeration, default credentials, session scope and URL tokens, HSTS, exposed files and methods, client-side secrets, encryption at rest, upload origin and counts, automation and wildcard DoS, ReDoS, audit trail, segregation of duties, postMessage and web storage, payments via a provider; obsolete technologies left out | 2026-10-11 |
| REQ-040 | Local semgrep rules catch more insecure patterns | should | done | Rules for open redirect, insecure randomness for secrets, weak password hashing, cookies without security flags, unsafe XML parsing and regular expressions built from input, each proven by fixtures in tests/semgrep for Python and JS where applicable | 2026-10-11 |
| REQ-041 | Clean-code guide covers proven design, test and refactoring practices | should | done | clean-code.md adds composition root, do-or-know, polymorphism over repeated switches, temporal coupling, Law of Demeter, conditionals, size heuristics, test practices and test doubles, comment upkeep and language, refactoring techniques; ESLint preset forbids var; CC IDs unchanged; nothing project-specific | 2026-10-11 |
| REQ-042 | Projects document their architecture with rules for new code | should | done | Template docs/architecture.md (goals, layers and dependency direction, composition root, interaction, naming, rules for new code, persisted data); kickoff fills it after the stack decision; feature prompt follows it; context pack includes it | 2026-10-11 |
| REQ-043 | Persisted data formats are versioned and migrated without data loss | should | done | Architecture template and clean-code.md state versioned formats, automatic migration, partial failure isolated with a message, tests per old version; release prompt counts incompatible data, file, API or config format changes as major | 2026-10-11 |
| REQ-044 | Linter configuration only gets stricter without user approval | should | done | AGENTS.md: loosening rules or thresholds is an approval point; adopting linters on existing code uses a baseline that may only shrink | 2026-10-11 |
| REQ-045 | The scaffold depends on no personal tools, skills or accounts | must | done | Scaffold and generated projects name no personal skills, plugins or private tools; features work with what the README lists as prerequisites; a smoke test rejects named skills in the template | 2026-10-11 |
| REQ-046 | Functional requirements are written as Jobs To Be Done; quality requirements as measurable goals | should | approved | type job needs a job story (When, I want to, so I can); type quality needs a quality goal; both need acceptance criteria; validated by check-requirements.sh; TODO text warns and blocks releases | 2026-10-11 |
| REQ-047 | One file per requirement, grouped in epic folders | should | approved | docs/requirements/<epic>/REQ-nnn-<slug>.md with front matter (id, type, epic, priority, status, updated) and an EPIC.md per folder; IDs stay global REQ-nnn; a generated INDEX.md must be current; req.sh lists, shows and creates requirements; all tools and the commit hook read the new layout | 2026-10-11 |
| REQ-048 | Projects with a requirements table can migrate to the per-file format | should | approved | scripts/migrate-requirements.sh converts every table row into a requirement file without losing ID, status, priority, date, text or acceptance criteria, moves the change log, writes the index and refuses to overwrite existing files | 2026-10-11 |
| REQ-049 | The scaffold documents its own requirements in the per-file JTBD format | should | approved | Every scaffold requirement is a job or quality file in a topic epic; no TODO job text remains; scaffold checks validate it | 2026-10-11 |

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
- 2026-10-11 REQ-027..REQ-038 added from the external review's wider recommendations; user chose MIT and SBOM as guidance only.
- 2026-10-11 REQ-027 done: CC-03/04/05/06/09 reworded; clean-code.md explains every rule and what tools cannot check
- 2026-10-11 REQ-028 done: threat-model.md template, kickoff and security review use it, pack includes it
- 2026-10-11 REQ-029 done: security.md and the review prompt cover the listed gaps; web-only items marked
- 2026-10-11 REQ-030 done: dependency policy in security.md, security-exceptions.md with owner and expiry, release prompt checks expiry
- 2026-10-11 REQ-031 done: template SECURITY.md (reporting, rotation, incidents); SBOM as guidance only, per user decision
- 2026-10-11 REQ-032 done: review report template, prompt writes reports with evidence and limitations
- 2026-10-11 REQ-033 done: AGENTS.md section 10: untrusted sources and actions needing approval
- 2026-10-11 REQ-034 done: deny rules list env files, keep .env.example readable, limits documented in CLAUDE.md
- 2026-10-11 REQ-035 done: approval points marked uniformly; order of work defined in AGENTS.md section 9
- 2026-10-11 REQ-036 done: completion report defined in AGENTS.md section 5, required by every working prompt
- 2026-10-11 REQ-037 done: check-docs reports structure only; documentation prompt and admin guide cover operations
- 2026-10-11 REQ-038 done: MIT LICENSE at the root, chosen by the user; not copied into projects
- 2026-10-11 REQ-039..REQ-040 added: gaps found by comparing a community WSTG checklist (inbox, untrusted, not copied) with security.md and the semgrep rules.
- 2026-10-11 REQ-039 done: security.md and review prompt extended with the missing WSTG areas; obsolete items left out
- 2026-10-11 REQ-040 done: 12 semgrep rules with fixtures; smoke proves an open redirect blocks the pre-commit check
- 2026-10-11 REQ-041..REQ-044 added: general practices extracted from another project's guidelines (inbox, untrusted); project-specific content excluded.
- 2026-10-11 REQ-041 done: clean-code.md extended with general practices; ESLint preset adds no-var
- 2026-10-11 REQ-042 done: architecture.md template; kickoff, feature, review and pack use it
- 2026-10-11 REQ-043 done: migration rules in architecture.md, clean-code.md points to them, release prompt counts format changes as major
- 2026-10-11 REQ-044 done: AGENTS.md section 5 and presets: loosening needs approval, baselines only shrink
- 2026-10-11 REQ-005 changed: the review no longer refers to a personal skill (user: keep the scaffold generic).
- 2026-10-11 REQ-045 added: user asked that the scaffold never depend on personal skills or tools.
- 2026-10-11 REQ-045 done: skill references removed from template and docs; maintainer rule added; smoke test guards it
- 2026-10-11 REQ-046..REQ-049 added: user wants Jobs To Be Done for functional requirements, one file per requirement, grouped by epic; global IDs, quality type for non-functional, migration script and scaffold migration chosen by the user.
