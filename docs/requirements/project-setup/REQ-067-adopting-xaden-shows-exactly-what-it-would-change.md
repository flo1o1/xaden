---
id: REQ-067
type: job
epic: project-setup
priority: should
status: done
updated: 2026-10-14
---

# Adopting Xaden shows exactly what it would change before it changes anything

## Job

When I consider adding Xaden to a repository I do not know well, I want a read-only report and an exact plan first, so I can decide with the team without risk.

## Acceptance criteria

- Given an existing repository, when `xaden adopt --scan` runs, then it reports stack, test runner, linters, type checker, CI system, hook manager, commit convention, existing `AGENTS.md`, `CLAUDE.md` and `.claude/`, and changes no file.
- Given the scan finds rules in an existing `AGENTS.md` or `CLAUDE.md` that contradict `xaden/RULES.md`, then it lists each contradiction with file and line and leaves the decision to a human.
- Given `xaden adopt --plan`, then it prints the exact diff and the list of files that would be created or touched, and writes nothing.
- Given a tool or setup the scan cannot recognise, then it says so and asks; it never guesses a command.
