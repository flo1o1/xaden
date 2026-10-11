---
title: Project kickoff
type: prompt
status: stable
version: 1.1.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, planning]
---

# Project kickoff

## Goal
Turn my idea into tracked requirements, a stack decision, and a first runnable skeleton.

## Inputs
- Idea: {{describe what you want to build, who uses it, what "done" looks like}}

## Steps
1. Read `AGENTS.md`. Do not write code yet.
2. Ask me up to 7 questions that block decisions: users, platform, data, constraints,
   language/stack preference, hosting, security/privacy needs. Wait for answers.
3. Write requirements into `docs/requirements/REQUIREMENTS.md` (replace the placeholder
   REQ-001): small, testable, with priority and acceptance criteria, status `draft`. Run
   `scripts/check-requirements.sh`. **Approval point:** show me the table; set the rows I
   approve to `approved`.
4. Fill `docs/threat-model.md` from my answers: assets, sensitive data, entry points, trust
   boundaries, attackers, deployment assumptions. Propose an OWASP ASVS level with a one-line
   reason. Write "unknown" and ask me where you lack facts; never invent them.
5. Propose a stack with 2 alternatives and a one-line trade-off each. **Approval point:**
   wait for my choice.
6. Record the decision in `docs/decisions/0001-stack.md` (copy `docs/decisions/0000-template.md`).
   Fill `docs/architecture.md` for the chosen stack: layers, composition root, naming, rules for
   new code. Keep it as small as the project.
7. Create the minimal skeleton: source dir, one test, dependency file. Run
   `scripts/apply-preset.sh python|node` for the clean-code linter config (other stacks: create
   an equivalent config mapping CC-01…CC-08, see `docs/clean-code.md`). **Approval point**
   before installing the tools it lists. Keep it runnable. Run `scripts/check.sh`.
8. Update `README.md` (what it is, how to run, how to test) and `CHANGELOG.md`.
   Run [[documentation]] to fill installation and system requirements in both guides.
9. Commit: `chore: bootstrap <stack> skeleton`.

## Done when
- [ ] Requirements approved by me
- [ ] Threat model filled; open questions listed
- [ ] Skeleton runs; `scripts/check.sh` passes
- [ ] Decision record, architecture and README written
- [ ] Completion report given (AGENTS.md §5): checks run, checks skipped, unresolved findings, acceptance evidence
