---
id: REQ-004
type: job
epic: unsorted
priority: must
status: done
updated: 2026-10-11
---

# Static code analysis on every commit and in CI

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- check.sh runs linters, shellcheck, secret scan, SAST; hooks and CI call it
