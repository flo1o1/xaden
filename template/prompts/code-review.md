---
title: Code review
type: prompt
status: stable
version: 1.0.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, review, clean-code]
---

# Code review

## Goal
Review the change against clean-code rules and requirements. Report, do not rewrite.

## Inputs
- Scope: {{diff, branch, or files}}

## Steps
1. Read `AGENTS.md`, `docs/clean-code.md`, requirements.
2. Check: does the change satisfy its `REQ-nnn` and nothing more? Naming, function size, SRP,
   duplication, error handling, input validation, tests (FIRST), comments.
3. Output one line per finding: `file:line — severity (high|medium|low) — CC-nn — problem — fix`.
   Cite only rule IDs that exist in `AGENTS.md` section 3.
   Skip style nits a formatter handles.
4. End with a verdict: approve / changes requested, and the single most important fix.

## Done when
- [ ] Every finding has a location and a concrete fix
