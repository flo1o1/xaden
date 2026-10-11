---
id: REQ-050
type: job
epic: assistant-guidance
priority: should
status: done
updated: 2026-10-11
---

# Optional add-on rule sets such as Ponytail are documented and never override the project rules

## Job

When my AI tool supports add-on rule sets such as Ponytail (leaner code, reuse before writing), I want to know how to install one and how it relates to the project rules, so I can use it without weakening the requirements, checks and reports the scaffold enforces.

## Acceptance criteria

- Given the getting-started guide, when I read the prerequisites, then Ponytail is listed as optional, with its install commands for Claude Code and the AGENTS.md route for other tools.
- Given a new project, when it is generated, then nothing installs or enables Ponytail automatically and no plugin is configured in `.claude/settings.json`.
- Given a generated project's AGENTS.md, when an add-on rule set conflicts with it, then AGENTS.md wins (for example, the completion report replaces a shorter end-of-reply note).
