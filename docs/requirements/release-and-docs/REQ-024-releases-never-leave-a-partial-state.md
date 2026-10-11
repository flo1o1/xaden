---
id: REQ-024
type: job
epic: release-and-docs
priority: must
status: done
updated: 2026-10-11
---

# Releases never leave a partial state

## Job

When a release step fails, I want no partial state left behind, so I can retry without manual repair.

## Acceptance criteria

- An existing tag or failing check aborts before any file changes
- a failing commit restores the files
- a failing tag is reported with recovery steps
