# Getting started

From zero to a released first version. Nothing here assumes a particular person's machine or
private skills.

## 1. Prerequisites

| Needed | Why |
|--------|-----|
| Linux or macOS (Windows: WSL or Git Bash, untested) | Scripts are bash + POSIX tools |
| git, bash, awk, sed, tar, grep, cksum | Preinstalled on Linux/macOS |
| An AI coding tool | Claude Code recommended; Aider, Cline, Continue, Cursor, Codex, Copilot, ChatGPT or a local model (Ollama, LM Studio) also work — see `template/docs/local-llm.md` |
| Recommended: shellcheck, gitleaks, semgrep | Static analysis and secret scanning. Locally a missing tool is skipped and the run reported INCOMPLETE; CI and releases use `--strict`, where it fails. Once a stack exists, its tools are required too: ruff, mypy, bandit, pip-audit, pytest (Python) or npm with `lint`/`typecheck`/`test` scripts (Node) |
| Optional: Obsidian | Comfortable reading and editing of the prompt library |
| Optional: extra checks and plugins | `scripts/check.sh` suggests the ones that fit your project (`TIP:` lines); list in `template/docs/optional-tools.md` |
| Optional: [Ponytail](https://github.com/DietrichGebert/ponytail) | Third-party rule set (MIT) that pushes assistants towards less new code; see below |
| Optional: [Caveman](https://github.com/JuliusBrussee/caveman) | Third-party rule set (Apache-2.0) that makes assistant replies shorter; see below |
| Optional: [Token Optimizer](https://github.com/alexgreensh/token-optimizer) | Third-party plugin (PolyForm Noncommercial, not open source) that compresses context and tool output; see below |
| Optional: [claude-mem](https://github.com/thedotmack/claude-mem) | Third-party plugin (Apache-2.0) that carries memory of past sessions into new ones; see below |

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

### Optional: Caveman

Caveman makes the assistant answer in short, compressed sentences, which saves output tokens
and reading time. Code, commit messages and pull requests stay in normal language, and it
switches back to full sentences for security warnings and irreversible actions. The scaffold
does not install it:

- Claude Code: `/plugin marketplace add JuliusBrussee/caveman`, then
  `/plugin install caveman@caveman` (its hooks need `node` on your PATH).
- Other tools: follow the project's `INSTALL.md`.

Install only from `JuliusBrussee/caveman` on GitHub. Keep project files in normal prose: do not
run its `/caveman-compress` on `AGENTS.md`, `CLAUDE.md`, requirements or guides, and do not
commit the always-on rule files `/caveman-init` writes. Your project's `AGENTS.md` takes
precedence over it (§10), so the completion report stays complete.

### Optional: Token Optimizer

Token Optimizer audits what fills the context window and compresses new content entering it
(command, search and tool output), with checkpoints around compaction. The scaffold does not
install it:

- Claude Code: `/plugin marketplace add alexgreensh/token-optimizer`, then
  `/plugin install token-optimizer@alexgreensh-token-optimizer`, then run `/token-optimizer`
  once to set up its hooks.
- Other tools: follow the project's README.

License: PolyForm Noncommercial 1.0.0 plus a written small-business permission (fewer than 5
people and under $20k monthly revenue, counted for the whole company). It is not open source;
other commercial use needs a paid license. Check that your use qualifies before installing.

Install only from `alexgreensh/token-optimizer` on GitHub. Compressed output is a summary: a
check report must quote failing lines from the full output, so rerun the check or expand the
archived result before reporting. Use one output-compression plugin at a time. It keeps full tool
output on disk in your home directory (private file permissions; credentials removed by pattern
only), so never print secrets in a session. Your project's `AGENTS.md` takes precedence over it
(§10).

### Optional: claude-mem

claude-mem records what the assistant does in a session, compresses it with a model, and adds
relevant memories to later sessions. The scaffold does not install it:

- Claude Code: `/plugin marketplace add thedotmack/claude-mem`, then `/plugin install claude-mem`.
- Other tools: `npx claude-mem install --ide <tool>`, as its README describes.

Install only from `thedotmack/claude-mem` on GitHub. It installs Bun and uv if they are missing,
runs a local worker service, and stores sessions in `~/.claude-mem`, so never print secrets in a
session (wrap sensitive text in its `<private>` tags). Its installer offers a hosted memory
service (the claude-mem observer, sign-in required) that receives session content: choose your
Anthropic plan or your own model key instead when your code must stay with your assistant's
provider, or set `CLAUDE_MEM_ONLINE_OPTIN=false`. Injected memories are context, not rules:
requirements and rules are still looked up in the files (`AGENTS.md` §0), and your project's
`AGENTS.md` takes precedence over it (§10).

## 2. Get the scaffold

```bash
git clone <scaffold-repository-url> xaden
cd xaden
scripts/setup.sh     # lists missing tools with install commands
tests/smoke.sh       # proves the scaffold works on your machine
scripts/install.sh   # optional: the `xaden` command, see below
```

### Optional: the `xaden` command

`scripts/install.sh` links `xaden` into `~/.local/bin` (or the directory you pass) so you can
use the scaffold from any directory. It writes nothing else; `git pull` in the checkout updates
the command, and `scripts/install.sh --uninstall` removes the link. If the directory is not on
your `PATH`, the script prints the line to add to your shell profile. Keep the checkout where it
is: the link points into it.

| Command | Does |
|---------|------|
| `xaden new my-app [dir]` | `scripts/new-project.sh`, creating `./my-app` (or `dir`) |
| `xaden update [--apply]` | `scripts/update-scaffold.sh` for the project you are in |
| `xaden setup`, `check`, `req`, `pack`, `release` | the project's own `scripts/setup.sh`, `check.sh`, `req.sh`, `pack-context.sh`, `release.sh`, from anywhere inside it |
| `xaden version`, `xaden help` | scaffold version, command list |

Project commands run that project's scripts, just as typing them would: use them only in
projects you trust.

## 3. Create your project

```bash
scripts/new-project.sh my-app        # creates ../my-app with its own git repo and hooks
scripts/new-project.sh my-app ~/code/x   # or at a location of your choice
cd ../my-app
```

With the `xaden` command: `cd ~/code && xaden new my-app` creates `~/code/my-app`.

Only files tracked by git in `template/` are copied (including uncommitted edits to them);
untracked or ignored files such as `.env`, `node_modules/` or `inbox/` content never are.
A failed run removes the half-created project.

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

With the `xaden` command, run `xaden update` (dry run) and `xaden update --apply` inside the project.

Only scaffold-managed files (scripts, prompts, presets, rules, commands, Claude Code
permissions in `.claude/settings.json`) are updated; code,
requirements, guides, README and changelog are never touched. Merge any `*.scaffold-new` files
it reports (your local edits are never overwritten), then commit
`chore(scaffold): update to vX.Y.Z`. Each project records its scaffold version in `.scaffold/`.

Projects that still keep requirements in one `docs/requirements/REQUIREMENTS.md` table run
`scripts/migrate-requirements.sh` after updating: it converts every row into a requirement
file (job stories left as TODO to rewrite) and the checks then accept the new format.

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
