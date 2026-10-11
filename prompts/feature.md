---
title: Build a feature
type: prompt
status: stable
version: 1.0.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, development]
---

# Build a feature

## Goal
Implement one capability, test-first, tracked in requirements.

## Inputs
- Feature: {{what the user can do afterwards}}
- Related requirement: {{REQ-nnn or "new"}}

## Steps
1. Read `AGENTS.md` and the requirements file.
2. If the feature has no `REQ-nnn`, add one (status `in-progress`) and a change-log line first.
   If it conflicts with an existing requirement, stop and ask me.
3. Plan in at most 5 small steps; show the plan; wait for my OK if it touches more than 2 files.
4. For each step: write a failing test, make it pass, refactor (Red → Green → Refactor).
5. Validate all external input at the boundary. Raise specific exceptions.
6. Run `scripts/check.sh`; fix all findings.
7. If the feature touches input, auth, data, files, network or dependencies: run the
   [[security-review]] prompt on the changed files.
8. Update `docs/user-guide.md` (usage) and, if config/ports/dependencies/deployment changed,
   `docs/admin-guide.md` — see [[documentation]].
9. Set requirement status to `done`, add a `CHANGELOG.md` → Unreleased bullet, commit
   `feat(<scope>): <summary>`.

## Done when
- [ ] Acceptance criteria met and tested
- [ ] `scripts/check.sh` passes
- [ ] Requirements, changelog, docs, security review handled
