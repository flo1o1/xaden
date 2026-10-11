---
id: REQ-011
type: job
epic: assistant-guidance
priority: must
status: done
updated: 2026-10-11
---

# Prevent models from inventing rules or requirements

## Job

When an assistant cites rules or requirements, I want it to look them up instead of inventing them, so I can rely on what it says.

## Acceptance criteria

- Imports, req.sh lookup, context fingerprint, commit hook rejects unknown IDs
