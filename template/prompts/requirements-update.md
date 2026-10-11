---
title: Update requirements
type: prompt
status: stable
version: 1.1.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, requirements]
---

# Update requirements

## Goal
Keep the requirement files in `docs/requirements/` true after scope changed in this session.

## Inputs
- Change: {{what I now want differently, in my words}}

## Steps
1. Read `docs/requirements/INDEX.md` and re-read the session for every statement that adds,
   changes or removes behaviour.
2. For each: create a requirement (`scripts/req.sh new <epic> <job|quality> "<title>"`), edit
   its file, move it to another epic (keep the ID, update `epic:`), or set status `dropped`.
   Write functional needs as jobs (*When …, I want to …, so I can …*), not as features.
   Never delete, reuse or renumber IDs. Update `updated:`. New requirements are `draft`; use
   `approved` only for what I explicitly asked for in this session.
3. Append one line per change to the `Change log` in `docs/requirements/README.md` (date, ID,
   what, why).
4. Run `scripts/req.sh index`, then `scripts/check-requirements.sh`.
5. **Approval point:** show me a summary diff and list code or tests that are now outdated.
   Do not change code yet.
6. Commit `docs(requirements): <summary>`.

## Done when
- [ ] Validation passes
- [ ] I confirmed the summary
- [ ] Completion report given (AGENTS.md §5): checks run, checks skipped, unresolved findings, acceptance evidence
