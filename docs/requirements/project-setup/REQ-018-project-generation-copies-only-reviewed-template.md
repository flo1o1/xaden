---
id: REQ-018
type: job
epic: project-setup
priority: must
status: done
updated: 2026-10-11
---

# Project generation copies only reviewed template content

## Job

When I generate a project, I want only reviewed, tracked template files copied, so I can never leak secrets or private files into a new repository.

## Acceptance criteria

- Only git-tracked template files (staged content) are copied
- untracked, ignored and secret files never
- symlinks and existing targets refused
- partial output removed on failure
- paths with spaces work
