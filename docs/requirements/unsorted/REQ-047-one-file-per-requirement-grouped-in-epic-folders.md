---
id: REQ-047
type: job
epic: unsorted
priority: should
status: done
updated: 2026-10-11
---

# One file per requirement, grouped in epic folders

## Job

TODO: rewrite as "When <situation>, I want to <motivation>, so I can <expected outcome>.", or change the type to quality and use a "## Quality goal" section.

## Acceptance criteria

- docs/requirements/<epic>/REQ-nnn-<slug>.md with front matter (id, type, epic, priority, status, updated) and an EPIC.md per folder; IDs stay global REQ-nnn; a generated INDEX.md must be current; req.sh lists, shows and creates requirements; all tools and the commit hook read the new layout
