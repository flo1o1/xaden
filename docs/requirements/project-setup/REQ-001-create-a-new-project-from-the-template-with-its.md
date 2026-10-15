---
id: REQ-001
type: job
epic: project-setup
priority: must
status: done
updated: 2026-10-11
---

# Create a new project from the template with its own git repository and active hooks

## Job

When I start a new project, I want one command that creates a repository from the template with active hooks, so I can begin coding under the scaffold's rules immediately.

## Acceptance criteria

- `scripts/new-project.sh name` yields a repo with one commit and core.hooksPath set (smoke test)
- Given `PROJECT_ROOT` set in the caller's environment to another repository, when `scripts/new-project.sh` runs, then the new project gets its hooks and the other repository's git configuration stays unchanged
