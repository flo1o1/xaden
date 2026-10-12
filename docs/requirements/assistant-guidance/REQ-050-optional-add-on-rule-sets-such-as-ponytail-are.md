---
id: REQ-050
type: job
epic: assistant-guidance
priority: should
status: done
updated: 2026-10-12
---

# Optional add-on rule sets such as Ponytail are documented and never override the project rules

## Job

When my AI tool supports add-on rule sets such as Ponytail (leaner code, reuse before writing), I want to know how to install one and how it relates to the project rules, so I can use it without weakening the requirements, checks and reports the scaffold enforces.

## Acceptance criteria

- Given the getting-started guide, when I read the prerequisites, then Ponytail is listed as optional, with its install commands for Claude Code and the AGENTS.md route for other tools.
- Given a new project, when it is generated, then nothing installs or enables Ponytail automatically and no plugin is configured in `.claude/settings.json`.
- Given a generated project's AGENTS.md, when an add-on rule set conflicts with it, then AGENTS.md wins (for example, the completion report replaces a shorter end-of-reply note).
- Given the getting-started guide, when I read the optional add-ons, then Caveman (terser replies) is listed as optional with its install command and source, and the guide says that project files (rule files, requirements, guides) stay in normal prose and are never compressed or extended by it.
- Given the getting-started guide and `docs/optional-tools.md`, when I read the optional add-ons, then Token Optimizer (context and output compression) is listed as optional with its install command and source, they state its license (PolyForm Noncommercial with a small-business permission, not open source), and they warn that compressed tool output must not replace the verbatim failing lines the completion report quotes, and that it keeps full tool output on disk in the home directory (credentials removed by pattern only).
- Given the getting-started guide and `docs/optional-tools.md`, when I read the optional add-ons, then claude-mem (memory across sessions) is listed as optional with its install command and source, and they warn that it stores sessions in the home directory, that its hosted memory service receives session content, and that injected memories never replace looking up rules and requirements in the files.
