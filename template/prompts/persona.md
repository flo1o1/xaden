---
title: Create a user persona
type: prompt
status: stable
version: 1.0.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, planning, personas]
---

# Create a user persona

## Goal
Add one user persona to `docs/personas/` that assistants check solutions against (AGENTS.md §9).

## Inputs
- Persona: {{name and a short description: who they are, what they need}}

## Steps
1. Read `AGENTS.md`, `docs/requirements/INDEX.md` and the existing files in `docs/personas/`.
   If the new persona overlaps an existing one, say which and ask whether to merge instead.
2. Run `scripts/persona.sh new "<name>"` (no shell: copy `docs/personas/0000-template.md`).
3. Fill every section from my description and the requirements; link the jobs it hires the
   software for (`REQ-nnn`). Keep `basis: assumption` and mark each fact you inferred
   "(assumption)"; never invent research, numbers or quotes as if observed.
4. Write 3 to 5 concrete, checkable red flags under "A solution fails this persona when".
5. **Approval point:** show me the file and the open assumptions; edit until I agree.
6. If the project now has fewer than 3 or more than 5 personas, tell me.

## Done when
- [ ] No `TODO:` text left in the persona file
- [ ] Assumptions marked; red flags checkable
- [ ] Completion report given (AGENTS.md §5): checks run, checks skipped, unresolved findings, acceptance evidence
