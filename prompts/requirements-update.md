---
title: Update requirements
type: prompt
status: stable
version: 1.0.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, requirements]
---

# Update requirements

## Goal
Keep `docs/requirements/REQUIREMENTS.md` true after scope changed in this session.

## Inputs
- Change: {{what I now want differently, in my words}}

## Steps
1. Read the requirements file and re-read the session for every statement that adds, changes
   or removes behaviour.
2. For each: add a new `REQ-nnn` (next free number), edit the row, or set status `dropped`.
   Never delete or renumber. Update the `Updated` column.
3. Append one line per change to the `Change log` section (date, ID, what, why).
4. Run `scripts/check-requirements.sh`.
5. Show me a summary diff and list code or tests that are now outdated. Do not change code yet.
6. Commit `docs(requirements): <summary>`.

## Done when
- [ ] Validation passes
- [ ] I confirmed the summary
