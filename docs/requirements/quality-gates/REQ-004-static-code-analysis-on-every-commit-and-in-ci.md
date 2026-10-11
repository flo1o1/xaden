---
id: REQ-004
type: job
epic: quality-gates
priority: must
status: done
updated: 2026-10-11
---

# Static code analysis on every commit and in CI

## Job

When I commit or push, I want static analysis to run automatically, so I can find defects and insecure code before review.

## Acceptance criteria

- check.sh runs linters, shellcheck, secret scan, SAST
- hooks and CI call it
