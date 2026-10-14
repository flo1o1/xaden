---
id: REQ-073
type: quality
epic: project-setup
priority: should
status: done
updated: 2026-10-14
---

# The tracked Xaden footprint in an adopting repository is small and predictable

## Quality goal

An adopted repository tracks Xaden content in at most `xaden/` plus `AGENTS.md` and, for Claude users, `CLAUDE.md`; no other path is created or changed.

## Acceptance criteria

- Given `xaden adopt` on a repository, when the plan is applied, then the files it creates or changes are all under `xaden/` or are `AGENTS.md` (marked block) or `CLAUDE.md` (one line, Claude users only).
- Given the changed paths, then a smoke test fails if any other path appears, including `.gitignore`, CI workflows and hook manager files, except where REQ-069 says a step is added and documented, or where the team accepted a preset (its configuration files at the root are listed in the plan and committed separately).
- Given `xaden remove`, then exactly those paths are removed or reverted and `git status` shows nothing else.
