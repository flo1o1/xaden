---
id: REQ-069
type: job
epic: project-setup
priority: should
status: draft
updated: 2026-10-14
---

# Xaden reuses the repository's tests, linters, hooks and CI instead of replacing them

## Job

When my repository already has working tooling, I want to run Xaden's checks through that tooling, so I can keep one toolchain and no second set of rules fights the first.

## Acceptance criteria

- Given the scan found `npm test` and `make lint`, when `xaden/xaden.conf` maps checks to those commands, then `check.sh` runs them and Xaden's own presets stay unused.
- Given an existing hook manager (husky, pre-commit, lefthook or plain `.git/hooks`), when Xaden installs its hooks, then it chains into that manager and does not set `core.hooksPath` over it.
- Given existing CI workflows, then adoption adds a separate job or a documented step and edits no existing workflow file.
- Given a hook manager or CI system outside the supported list, then adoption stops with a clear error and a manual step; it does not guess.
