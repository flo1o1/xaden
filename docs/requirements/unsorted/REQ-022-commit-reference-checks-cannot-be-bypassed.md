---
id: REQ-022
type: job
epic: unsorted
priority: must
status: done
updated: 2026-10-11
---

# Commit reference checks cannot be bypassed

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- Special prefixes skip only the format check; Refs are parsed as git trailers; CI validates every commit of a first push
