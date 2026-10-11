---
title: Refactor
type: prompt
status: stable
version: 1.0.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, development, clean-code]
---

# Refactor

## Goal
Improve structure without changing behaviour.

## Inputs
- Target: {{files / module}}
- Pain: {{what is hard to read or change}}

## Steps
1. Read `AGENTS.md` and `docs/clean-code.md`.
2. Ensure tests cover current behaviour; add characterization tests if missing. Run them: green.
3. List the smells found (name each: duplication, long method, god class, …) with file:line.
4. Fix one smell per step; tests green after every step. Keep the project runnable.
5. Run `scripts/check.sh`.
6. Commit `refactor(<scope>): <summary>`. No behaviour change → no requirement change.

## Done when
- [ ] Behaviour unchanged (tests identical or only added)
- [ ] Smell list resolved or consciously deferred (note in commit body)
