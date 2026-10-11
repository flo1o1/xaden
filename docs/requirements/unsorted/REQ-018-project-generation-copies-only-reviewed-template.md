---
id: REQ-018
type: job
epic: unsorted
priority: must
status: done
updated: 2026-10-11
---

# Project generation copies only reviewed template content

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- Only git-tracked template files (staged content) are copied; untracked, ignored and secret files never; symlinks and existing targets refused; partial output removed on failure; paths with spaces work
