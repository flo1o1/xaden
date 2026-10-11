---
id: REQ-048
type: job
epic: unsorted
priority: should
status: done
updated: 2026-10-11
---

# Projects with a requirements table can migrate to the per-file format

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- scripts/migrate-requirements.sh converts every table row into a requirement file without losing ID, status, priority, date, text or acceptance criteria, moves the change log, writes the index and refuses to overwrite existing files
