---
id: REQ-017
type: job
epic: project-setup
priority: should
status: done
updated: 2026-10-11
---

# Existing projects can adopt newer scaffold versions

## Job

When a newer scaffold version is released, I want to update my existing project without losing local changes, so I can benefit from improvements.

## Acceptance criteria

- Projects record scaffold version
- update script shows and applies changes to managed files only
- Given a project checked out as a git worktree or submodule (`.git` is a file), when the update script runs, then it plans and applies the update like in a normal checkout
