---
title: Project kickoff
type: prompt
status: stable
version: 1.0.0
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
   REQ-001): small, testable, with priority and acceptance criteria. Run
   `scripts/check-requirements.sh`.
4. Propose a stack with 2 alternatives and a one-line trade-off each. Wait for my choice.
5. Record the decision in `docs/decisions/0001-stack.md` (copy `docs/decisions/0000-template.md`).
6. Create the minimal skeleton: source dir, one test, linter/formatter/type-checker config,
   dependency file. Keep it runnable. Run `scripts/check.sh`.
7. Update `README.md` (what it is, how to run, how to test) and `CHANGELOG.md`.
   Run [[documentation]] to fill installation and system requirements in both guides.
8. Commit: `chore: bootstrap <stack> skeleton`.

## Done when
- [ ] Requirements approved by me
- [ ] Skeleton runs; `scripts/check.sh` passes
- [ ] Decision record and README written
