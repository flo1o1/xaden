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
| Optional: [Ponytail](https://github.com/DietrichGebert/ponytail) | Third-party rule set (MIT) that pushes assistants towards less new code; see the add-ons note below |
| Optional: [Caveman](https://github.com/JuliusBrussee/caveman) | Third-party rule set (Apache-2.0) that makes assistant replies shorter; see the add-ons note below |
| Optional: [Token Optimizer](https://github.com/alexgreensh/token-optimizer) | Third-party plugin (PolyForm Noncommercial, not open source) that compresses context and tool output; see the add-ons note below |
| Optional: [claude-mem](https://github.com/thedotmack/claude-mem) | Third-party plugin (Apache-2.0) that carries memory of past sessions into new ones; see the add-ons note below |
| Optional: [obsidian-skills](https://github.com/kepano/obsidian-skills) | Third-party plugin (MIT) that teaches assistants Obsidian's Markdown, Bases and Canvas formats; see the add-ons note below |
| Optional: [impeccable](https://github.com/pbakaus/impeccable) | Third-party plugin (Apache-2.0) for projects with a web UI: design guidance and 59 deterministic checks for generated frontend design; see the add-ons note below |

### Optional: assistant add-ons

The add-ons in the table above are third-party; the scaffold installs none of them, and your
project's `AGENTS.md` takes precedence over each (§10). Install commands, sources, licenses and
the risks to know before installing are in `template/docs/optional-tools.md` → "Assistant
plugins" (in a generated project: `docs/optional-tools.md`).

### Optional: the `xaden` command

`scripts/install.sh` links `xaden` into `~/.local/bin` (or the directory you pass) so you can
use the scaffold from any directory. It writes nothing else; `git pull` in the checkout updates
the command, and `scripts/install.sh --uninstall` removes the link. If the directory is not on
your `PATH`, the script prints the line to add to your shell profile. Keep the checkout where it
is: the link points into it.

| Command | Does |
|---------|------|
| `xaden new my-app [dir]` | `scripts/new-project.sh`, creating `./my-app` (or `dir`) |
| `xaden new --autopilot --stack python my-app` | a new project with the recommended setup after one confirmation (see "Autopilot for a new project") |
| `xaden adopt`, `xaden remove` | add Xaden to the repository you are in, or take it out again (see "Adding Xaden to an existing repository") |
| `xaden update [--apply]` | `scripts/update-scaffold.sh` for a project created by `xaden new` |
| `xaden doctor`, `fetch`, `upgrade` | compare the installed and the pinned version, install the pinned one, move a project to a newer one (see "One Xaden version per project") |
| `xaden setup`, `check`, `req`, `pack`, `release` | the project's own `scripts/setup.sh`, `check.sh`, `req.sh`, `pack-context.sh`, `release.sh`, from anywhere inside it; in an adopted repository the installed Xaden's scripts |
| `xaden prompt <name>`, `doc <name>`, `context`, `persona`, `rules`, `ignore-list` | adopted repositories: print a task prompt or guide, the context fingerprint, create a persona, regenerate `xaden/RULES.md`, list the paths Xaden owns |
| `xaden version`, `xaden help` | scaffold version, command list |

Project commands run that project's scripts, just as typing them would: use them only in
projects you trust.

## 2. Get Xaden

Two ways, same files. Below, `<xaden-repo-url>` is the address of the Xaden repository you found
this guide in. Both need git, because new projects get their own git repository.

### Download the release (zip)

1. Download the release archive: `<xaden-repo-url>/archive/refs/tags/v<version>.zip`
   (`<version>` as in `CHANGELOG.md`, for example `0.2.2`).
2. Extract it somewhere permanent, for example `unzip xaden-<version>.zip -d ~/tools`. The optional
   `xaden` command links into this folder, so do not move it afterwards.
3. `cd ~/tools/xaden-<version>`, then continue with section 3 (`scripts/new-project.sh my-app`) or install the
   `xaden` command (`scripts/install.sh`, below).

Verify: Xaden publishes no checksums or signatures. Download only from the repository address over
HTTPS, check that `scripts/xaden.sh version` prints the version in the file name, and read the scripts
you are about to run: they are plain shell.

Update: download the new release and extract it next to the old one. Remove the old command link
with `old-folder/scripts/install.sh --uninstall`, run `new-folder/scripts/install.sh`, then delete the
old folder. `install.sh` never replaces a link that points somewhere else.

### Clone the repository

```bash
git clone <xaden-repo-url> xaden && cd xaden
```

Update: `git pull` in the clone; the `xaden` command keeps working. To use a fixed release instead of
`main`, run `git tag -l` and `git checkout v<version>`; return with `git checkout main` before the
next `git pull`.

### When to choose which

- Zip: you only want to use Xaden, need no git history, and are happy to download updates yourself.
- Clone: you want `git pull` updates, a choice of release tags, or to read the history and contribute.

### Linux

git, bash, awk, sed, tar, grep and cksum are normally preinstalled; install a missing one with your
distribution's package manager. If `~/.local/bin` is not on your `PATH`, `scripts/install.sh` prints the
line to add, usually to `~/.bashrc` (bash) or `~/.zshrc` (zsh).

### macOS

bash 3.2, the version macOS ships, is supported. If `git` is missing, running it once offers to install
Apple's command line tools. The default shell is zsh: put the `PATH` line that `scripts/install.sh`
prints into `~/.zshrc`.

### Windows

Untested: nobody has run these steps on Windows yet, so expect to adapt them. WSL is recommended: open a
WSL shell and follow the Linux steps, keeping Xaden and your projects in the Linux file system (your
WSL home directory) rather than under `/mnt/c`. Git Bash is also possible but untested.
Native PowerShell is not supported, because the scripts are bash.

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

## Adding Xaden to an existing repository

Your repository keeps its build, its tests, its documentation and its CI. Xaden goes beneath it in
one pull request that your team reviews. Run these in a clone of the repository:

```bash
xaden adopt --scan     # read-only report of what the repository has
xaden adopt --plan     # the exact diff and file list; changes nothing
xaden adopt            # asks once, then works on a branch in its own folder
```

`xaden adopt` reports the stack, test runner, linters, type checker, CI system, hook manager,
commit convention and any existing `AGENTS.md`, `CLAUDE.md` and `.claude/`. It lists rules in an
existing `AGENTS.md` or `CLAUDE.md` that contradict `xaden/RULES.md` with file and line, and leaves
the decision to you. What it cannot recognise it says so; it never guesses a command (name one with
`--check test="make verify"`). Without a terminal it stops after the plan and prints the command that
applies it, `xaden adopt --yes`.

It creates the branch `chore/adopt-xaden` in a folder next to the repository
(`<repo>-adopt-xaden`) and commits there. Nothing lands on the default branch. The commits add only:

- `xaden/`: `xaden.conf` (the pinned Xaden version and checksum, the mode of the checks, the commands
  Xaden runs), `RULES.md` (generated from the pinned version, do not edit), `requirements/`, `personas/`,
  `security-reviews/`, `baselines/`, optional `prompts/`, and `footprint.txt`. Plain Markdown, no
  editor-specific files, and none of Xaden's scripts.
- a short marked block in `AGENTS.md`. Text outside the block is never changed.
- for Claude Code users (`--assistants claude`, pre-selected when the scan finds `CLAUDE.md` or
  `.claude/`, and confirmed by you): `CLAUDE.md` with the one line `@AGENTS.md`, or that line added to
  an existing file that lacks it.
- a separate workflow `.github/workflows/xaden.yml` (its own commit; `--skip-ci` leaves it out). Existing
  workflows are not edited. It installs the pinned Xaden version and verifies its checksum.
- Xaden's hooks, chained into the hook manager you have: husky (a tracked change, its own commit),
  or plain git hooks, pre-commit and lefthook (inside `.git`, each teammate runs `xaden setup`).
  Existing hooks keep their content, and `core.hooksPath` is never set over a manager.

Your own commands are reused: the scan maps `npm test`, `make lint`, `pytest`, `ruff check .` and
similar to `check.test`, `check.lint` and `check.typecheck` in `xaden.conf`, and `xaden check` runs
them. Violations that exist today are recorded in `xaden/baselines/` while the plan is applied (this runs your
check commands once). The baseline only shrinks: fixing a violation removes it, a new one fails the check.

The mode in `xaden/xaden.conf` decides how strict the checks are:

| Mode | A new violation |
|------|-----------------|
| `advisory` | warns and passes |
| `changed-files` (default for existing repositories) | fails if it is in a file the change touches |
| `strict` | fails in any file |

Changing the mode, or letting a baseline grow, is an approval point. With another commit convention
than Conventional Commits, the `Refs:` checks only advise until the team opts in with
`commit-convention = conventional`.

If the repository lacks tests, linters or a type checker for its stack, the scan lists each gap. The
plan can offer Xaden's preset for Python or Node as a separate commit (`--preset`, or the question when a
terminal is attached): its configuration goes to the repository root where the tools expect it, and you
install the tools yourself, the command is printed. Files you already have are never overwritten; the
difference is shown. Without the preset, `xaden check` reports the gap: a warning in `advisory` and
`changed-files`, an error in `strict`.

An unsupported hook manager or CI system stops the run (exit code 4) with a manual step; adopt without it
using `--skip-hooks` or `--skip-ci`. When you applied the plan, push the branch and open the pull request.

`xaden remove` deletes `xaden/` and undoes exactly the paths in `xaden/footprint.txt`; review the result
with `git status`. `xaden ignore-list` prints `xaden/`, `AGENTS.md` and `CLAUDE.md` (when present), one per
line, for `.dockerignore`, `.npmignore` and archive excludes.

A project created by `xaden new` (it has `.scaffold/`) can move to this layout with the same command: its
requirements, personas and reviews move into `xaden/`, the copied tooling you did not edit is removed, and
what you edited stays and is listed.

In an adopted repository assistants have no slash commands. They run `xaden prompt kickoff`, `xaden prompt
feature` and so on; a prompt of the same name in `xaden/prompts/` replaces the default.

## One Xaden version per project

An adopted repository pins the Xaden version it uses, with a checksum, in `xaden/xaden.conf`. A newer
Xaden on one machine changes nothing in the repository.

```bash
xaden doctor          # installed X, project pinned Y; reads two files, no network
xaden fetch 0.3.0     # installs the pinned version when it is missing
xaden upgrade 0.3.0   # a branch that bumps version and checksum and regenerates xaden/RULES.md
xaden upgrade --check # asks, then looks for a newer release
```

Xaden never downloads anything without your yes. When the pinned version is not installed, the question
shows the version, the source and the checksum, ends the output with `Download and install Xaden <version>
now? [y/N]`, and anything but yes means no. A download is installed only if its checksum equals the one in
`xaden.conf`; the yes is not remembered. Without a terminal (an IDE git client, a script, an assistant) nothing
downloads: the command exits with code 3 and prints the `xaden fetch <version>` to run yourself. Assistants
show the question to you and never answer it. Other installed versions live in `~/.local/share/xaden/versions`
(`XADEN_HOME` changes the place). If `xaden/RULES.md` does not match the pinned version, the check fails
and names `xaden rules`. `xaden upgrade` shows the diff and the changelog entries between the versions;
your team reviews it as one pull request.

## Autopilot for a new project

```bash
xaden new --autopilot --stack python my-app    # or --stack node
```

It prints one plan and asks once. A yes creates the folder, `git init` on `main`, the `xaden/` layout, the
stack's preset, mode `strict`, hooks, the CI workflow and a first commit. It prints the exact install commands
for the development tools (pinned versions) and never runs them, never pushes and never downloads. It ends with
the checks: tools that are not installed yet are reported as skipped, and a run with skipped checks ends with a
warning, never a success sign. A folder that already has code, a build file or history stops with a pointer to
`xaden adopt`.

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
