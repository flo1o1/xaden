---
title: Build a feature
type: prompt
status: stable
version: 1.1.0
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
1. Run `scripts/context-status.sh`; read `AGENTS.md` and the requirements file. Look requirements up with `scripts/req.sh show REQ-nnn`; never from memory.
2. If the feature has no `REQ-nnn`, add one (status `draft`) and a change-log line.
   **Approval point:** show me the row; after my OK set it to `in-progress`.
   If it conflicts with an existing requirement, stop and ask me.
3. Plan in at most 5 small steps, placing code as `docs/architecture.md` → "Rules for new code"
   says; if the feature changes the structure, update that file in the same change.
   **Approval point** if the plan touches more than 2 files or adds a dependency.
4. If the code is hard to change for this feature, refactor first ([[refactor]], separate
   commit, tests green). Otherwise leave unrelated code alone (CC-09).
5. For each step: write a failing test that cites the `REQ-nnn`, make it pass, refactor
   (Red → Green → Refactor). Validate all external input at the boundary (CC-07); make errors
   explicit (CC-05).
6. Run `scripts/check.sh`; fix all findings.
7. If the feature touches input, auth, data, files, network or dependencies: run the
   [[security-review]] prompt on the changed files.
8. Update `docs/user-guide.md` (usage) and, if config/ports/dependencies/deployment changed,
   `docs/admin-guide.md` — see [[documentation]].
9. Set requirement status to `done`, add a `CHANGELOG.md` → Unreleased bullet, commit
   `feat(<scope>): <summary>` with the trailer `Refs: REQ-nnn` (the hook rejects unknown IDs).

## Done when
- [ ] Acceptance criteria met and tested
- [ ] `scripts/check.sh` passes
- [ ] Requirements, changelog, docs, security review handled
- [ ] Completion report given (AGENTS.md §5): checks run, checks skipped, unresolved findings, acceptance evidence
