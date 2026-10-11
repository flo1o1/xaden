---
id: REQ-019
type: job
epic: unsorted
priority: must
status: done
updated: 2026-10-11
---

# Required checks cannot be skipped silently

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- Every check reports passed, failed or skipped; any skip marks the run INCOMPLETE; CI and releases run strict so a missing scanner fails; CI provisions pinned tool versions
