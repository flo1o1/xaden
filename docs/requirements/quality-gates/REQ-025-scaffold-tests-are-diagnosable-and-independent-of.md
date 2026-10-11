---
id: REQ-025
type: quality
epic: quality-gates
priority: should
status: done
updated: 2026-10-11
---

# Scaffold tests are diagnosable and independent of user configuration

## Quality goal

Scaffold tests show the failing command's output, ignore the user's global git configuration, and require tool-dependent fixtures in CI.

## Acceptance criteria

- Failed assertions show the command output
- tests ignore global git configuration
- tool-dependent fixtures are mandatory in CI
