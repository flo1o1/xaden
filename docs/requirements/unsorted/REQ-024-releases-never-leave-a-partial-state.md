---
id: REQ-024
type: job
epic: unsorted
priority: must
status: done
updated: 2026-10-11
---

# Releases never leave a partial state

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- An existing tag or failing check aborts before any file changes; a failing commit restores the files; a failing tag is reported with recovery steps
