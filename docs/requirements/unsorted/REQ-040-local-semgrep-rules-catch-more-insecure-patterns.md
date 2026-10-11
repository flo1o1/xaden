---
id: REQ-040
type: job
epic: unsorted
priority: should
status: done
updated: 2026-10-11
---

# Local semgrep rules catch more insecure patterns

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- Rules for open redirect, insecure randomness for secrets, weak password hashing, cookies without security flags, unsafe XML parsing and regular expressions built from input, each proven by fixtures in tests/semgrep for Python and JS where applicable
