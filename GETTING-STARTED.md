# Getting started

From zero to a released first version. Nothing here assumes a particular person's machine or
private skills.

## 1. Prerequisites

| Needed | Why |
|--------|-----|
| Linux or macOS (Windows: WSL or Git Bash, untested) | Scripts are bash + POSIX tools |
| git, bash, awk, sed, tar, grep, cksum | Preinstalled on Linux/macOS |
| An AI coding tool | Claude Code recommended; Aider, Cline, Continue, Cursor, Codex, Copilot, ChatGPT or a local model (Ollama, LM Studio) also work — see `template/docs/local-llm.md` |
| Recommended: shellcheck, gitleaks, semgrep | Static analysis and secret scanning; without them checks only warn |
| Optional: Obsidian | Comfortable reading and editing of the prompt library |
| Optional: [Ponytail](https://github.com/DietrichGebert/ponytail) | Third-party rule set (MIT) that pushes assistants towards less new code; see below |

### Optional: Ponytail

Ponytail asks the assistant to reuse what exists (codebase, standard library, platform,
installed dependencies) before writing code, and to leave a small test for risky logic. The
scaffold does not install it; add it to your own tool if you want it:

- Claude Code: `/plugin marketplace add DietrichGebert/ponytail`, then
  `/plugin install ponytail@ponytail` (its hooks need `node` on your PATH).
- Codex, Copilot CLI, Cursor and others: follow the project's `INSTALL.md`; tools that only
  read a rules file can use its `AGENTS.md`. Do not replace your project's `AGENTS.md` with it.

Install only from `DietrichGebert/ponytail` on GitHub or `@dietrichgebert/ponytail` on npm.
Your project's `AGENTS.md` takes precedence over it (§10), so requirements, checks and the
completion report stay mandatory.

## 2. Get the scaffold

```bash
git clone <scaffold-repository-url> vibe-scaffold
cd vibe-scaffold
scripts/setup.sh     # lists missing tools with install commands
tests/smoke.sh       # proves the scaffold works on your machine
```

## 3. Create your project

```bash
scripts/new-project.sh my-app        # creates ../my-app with its own git repo and hooks
cd ../my-app
```

Prefer GitHub's "Use this template" button? Then clone your copy and run
`scripts/new-project.sh my-app` from it the same way. Never develop your project inside the
scaffold: everything a project gets comes from `template/`.

## 4. Kickoff

- Claude Code: start `claude` in `my-app`, run `/kickoff <your idea>`.
- Other tools: open the folder; ask the tool to follow `prompts/kickoff.md`.
- Chat without file access: `scripts/pack-context.sh kickoff`, paste `context-pack.md`.

The assistant's first reply must start with `CONTEXT CHECK <number>`. Compare it with your own
`scripts/context-status.sh`: a mismatch means it started from stale or missing files. A match
is a consistency aid only; it does not prove the rules were read or followed, so still review its work.

You answer its questions, approve the requirements, and choose the stack. It then builds a
minimal runnable skeleton and fills installation details in the guides.

## 5. Build features (repeat)

`/feature <what users can do afterwards>` (or `prompts/feature.md`). The assistant links the work
to a requirement, plans, works test-first, runs `scripts/check.sh`, runs a security review when
input/auth/data/network are touched, updates guides and changelog, and commits with
`Refs: REQ-nnn`. Changed your mind? Say it, or run `/requirements`.

Also available: `/bugfix`, `/refactor`, `/review`, `/security`, `/docs`.

## 6. Release

`/release` proposes a SemVer bump; you confirm; `scripts/release.sh` checks everything, refuses
while the guides are incomplete, stamps versions, and tags locally. Push when you want:
`git push --follow-tags`.

## Getting scaffold improvements into your project

Pull the newest scaffold, then from the scaffold directory:

```bash
scripts/update-scaffold.sh ../my-app            # dry run
scripts/update-scaffold.sh ../my-app --apply    # stage changes; review with git diff --cached
```

Merge any `*.scaffold-new` files it reports (your local edits are never overwritten), then
commit `chore(scaffold): update to vX.Y.Z`.

## Joining an existing project

```bash
git clone <project-url> && cd <project>
scripts/setup.sh     # git hooks are not cloned; this turns them on
```

CI re-runs the static analysis and commit-message checks, so skipped hooks are caught there.

## Security review quality

`/security` follows `prompts/security-review.md` (OWASP WSTG based), which works with any model.
Claude Code users can additionally run the built-in `/security-review`. Use a strong model for
reviews before releases.
