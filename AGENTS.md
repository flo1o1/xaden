# AGENTS.md — {{PROJECT_NAME}}

Rules for any AI coding assistant (Claude Code, ChatGPT, Codex, Cursor, Aider,
Cline, Continue, local models). Read fully before changing anything.
Explicit user instructions in the current session override this file.

## 1. Session start

1. Read `docs/requirements/REQUIREMENTS.md` (source of truth for *what* to build).
2. Read the `Unreleased` section of `CHANGELOG.md` (what changed since last release).
3. If a request is ambiguous or conflicts with a requirement: **ask, do not guess**.

## 2. Requirements tracking (mandatory)

- Every behaviour the user asks for has a requirement `REQ-nnn` in
  `docs/requirements/REQUIREMENTS.md`.
- When the user adds, changes, or drops something during a session:
  **update the requirements file first, then write code.**
- IDs are stable. Never delete or renumber; set status `dropped` instead.
- Add one line to the `Change log` section of the requirements file per change.
- Run `scripts/check-requirements.sh` after editing; it validates the format.

## 3. Clean code

- One responsibility per class/function; functions small, one abstraction level.
- Intention-revealing names; no abbreviations, no magic numbers/strings.
- No duplication (DRY), no deep nesting (early return), no hidden dependencies
  (inject them), no commented-out code.
- Errors: raise specific exceptions, fail fast, never swallow, no `null` returns
  as error signal. Catch only what you can handle.
- Comments: short docstring per class/function (purpose, parameters, data format).
  No comments that repeat the code.
- Validate **all external input** at the system boundary (type, range, length, format).
- Details: `docs/clean-code.md`.

## 4. Tests

- Work in small Red → Green → Refactor steps. Test first when feasible.
- Tests are fast, isolated, repeatable, self-validating. Arrange–Act–Assert, one behaviour per test.
- Every requirement has acceptance criteria; tests should reference the `REQ-nnn`.

## 5. Static analysis (mandatory before "done")

- Run `scripts/check.sh`. Fix findings; never silence a rule without a one-line reason.
- Do not claim success unless the check passed. Report failures verbatim.

## 6. Security (mandatory)

- Follow `docs/security.md` while coding (secrets, injection, authz, crypto, deps).
- After finishing a feature that touches input, auth, data, files, network, or
  dependencies — and before every release — run a security review:
  - Claude Code: `/security` (uses the `alice-security-engineer` skill if installed).
  - Any other LLM: paste `prompts/security-review.md` plus the changed files.
- Never hardcode or print secrets. Never commit `.env`. Ask before adding dependencies.

## 7. Versioning and git

- Semantic Versioning in `VERSION` (`MAJOR.MINOR.PATCH`). Do not edit it by hand;
  `scripts/release.sh <major|minor|patch>` does it — only run when the user asks.
- Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`; `!` or
  `BREAKING CHANGE:` for breaking changes. Enforced by the commit-msg hook.
- Add a user-visible bullet to `CHANGELOG.md` → `Unreleased` for every `feat`/`fix`.
- Commit each coherent step. Never force-push, never rewrite published history.

## 8. Documentation (mandatory)

- Two guides are part of the product: `docs/user-guide.md` (end users) and
  `docs/admin-guide.md` (install, system requirements, configuration, security hardening,
  deployment, backup, monitoring, upgrade, uninstall).
- A feature is not done until the guides describe it. Update them in the same change.
- Fill the `<!-- TODO -->` markers with verified facts; ask if a fact is unknown. Never invent
  system requirements or commands. Prompt: `prompts/documentation.md` (`/docs` in Claude Code).
- `scripts/check-docs.sh` enforces the section structure; releases are blocked while TODO
  markers remain. `scripts/release.sh` stamps the version into both guides.

## 9. Working style

- Plan briefly, then change in small steps; keep the project runnable.
- Refactor before adding functionality when the change would be hard otherwise.
- Prefer boring, widely used libraries; justify every new dependency.
- Prompts live in `prompts/` (an Obsidian vault). Improve a prompt there instead of
  re-explaining the same thing in chat.
- Setup/commands for this project: see `README.md`.
