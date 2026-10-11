---
id: REQ-020
type: job
epic: unsorted
priority: must
status: done
updated: 2026-10-11
---

# Pre-commit checks validate exactly the staged snapshot

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- A staged regression cannot be hidden by an unstaged fix; a requirement ID present only in an unstaged file cannot validate a commit; the working tree is never modified
