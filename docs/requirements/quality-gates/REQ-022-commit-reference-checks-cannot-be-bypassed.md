---
id: REQ-022
type: job
epic: quality-gates
priority: must
status: done
updated: 2026-10-11
---

# Commit reference checks cannot be bypassed

## Job

When commits reference requirements, I want reference checks that special prefixes and prose cannot bypass, so I can trust the commit history's traceability.

## Acceptance criteria

- Special prefixes skip only the format check
- Refs are parsed as git trailers
- CI validates every commit of a first push
- IDs in comment lines and in the diff that `git commit -v` appends are not checked
