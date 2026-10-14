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

Two shortcuts: "Autopilot for a new project" (below) sets up the recommended checks after one confirmation, and
"Adding Xaden to an existing repository" (below) is the way in for a repository you already have.

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

## Adding Xaden to an existing repository

Your repository keeps its build, its tests, its documentation and its CI. Xaden goes beneath it in
one pull request that your team reviews.

### The short path

```bash
cd ~/code/shop
xaden adopt
```

`xaden adopt` reads the repository and reports its stack, test runner, linters, CI system and git
hooks. Then it prints exactly which files it would create or touch and asks once. On a yes it works
on a new branch, `chore/adopt-xaden`, in its own folder next to the repository (`shop-adopt-xaden`),
so nothing lands on your default branch. When it is done, push the branch and open the pull request.

### Look first, change nothing

```bash
xaden adopt --scan
xaden adopt --plan
```

- `xaden adopt --scan`: reports what the repository has and changes no file. It also lists rules in an existing `AGENTS.md` or `CLAUDE.md` that contradict `xaden/RULES.md`, with file and line; you decide what to do about them.
- `xaden adopt --plan`: prints the exact diff and the list of files that would be created or changed, and writes nothing.

What Xaden cannot recognise it says so; it never guesses a command. Name one yourself with
`--check test="make verify"`. Without a terminal (a script, a CI job) `xaden adopt` stops after the plan and
prints the command that applies it: `xaden adopt --yes`.

### What it adds, and nothing else

- A visible folder `xaden/`. It holds `xaden.conf` (the pinned Xaden version and checksum, the mode of the
  checks and the commands Xaden runs), `RULES.md` (the rules for assistants, generated from the pinned
  version: do not edit), `requirements/`, `personas/`, `security-reviews/`, `baselines/`, an optional
  `prompts/` and `footprint.txt`. It is plain Markdown plus one settings file, no editor-specific files, and
  none of Xaden's scripts.
- A short marked block in `AGENTS.md`. Text you wrote there stays untouched.
- For Claude Code users, `CLAUDE.md` with the single line `@AGENTS.md`, or that line added to an existing
  `CLAUDE.md` that lacks it. Use `--assistants claude` to choose; by default Xaden pre-selects Claude when
  it finds `CLAUDE.md` or `.claude/`, and asks you to confirm.
- A separate workflow, `.github/workflows/xaden.yml`, in its own commit (`--skip-ci` leaves it out). It
  installs the pinned Xaden version and verifies its checksum. Your existing workflows are not edited.
- Xaden's checks in your git hooks, chained into the manager you have (see "Hooks and CI that do not fit").

Your `README.md`, `docs/`, `scripts/`, `CHANGELOG.md` and build files are never changed.

### Your own tools keep running

The scan maps the commands it finds (`npm test`, `make lint`, `pytest`, `ruff check .` and similar) to
`check.test`, `check.lint` and `check.typecheck` in `xaden.conf`, and `xaden check` runs them. Xaden's own
language presets stay unused.

### How strict the checks are

Existing findings never block a team. When the plan is applied, Xaden runs your check commands once and
records what they report in `xaden/baselines/`. A baseline only shrinks: fixing a violation removes it from
the list, a new violation is never added to it. The mode in `xaden.conf` decides what a new violation does:

| Mode | A new violation |
|------|-----------------|
| `advisory` | warns and passes |
| `changed-files` (default for existing repositories) | fails if it is in a file the change touches |
| `strict` | fails in any file |

Changing the mode, or letting a baseline grow, is an approval point. If your repository does not use
Conventional Commits, the `Refs:` checks only advise until you set `commit-convention = conventional`.

### No tests or linters yet

If the repository lacks tests, linters or a type checker for its stack, the scan lists each gap. The plan can
offer Xaden's preset for Python or Node as a separate step and a separate commit (`--preset`, or a question
when a terminal is attached). The preset's configuration goes to the repository root where its tools expect
it; you install the tools yourself, the command is printed. A file you already have is never overwritten: the
difference is shown. Without the preset no configuration file is added, and `xaden check` reports the gap: a
warning in `advisory` and `changed-files`, an error in `strict`.

### Hooks and CI that do not fit

Xaden chains into husky, plain git hooks, pre-commit and lefthook, and keeps what your hooks already do.
It never sets `core.hooksPath` over a manager. husky hooks are files in the repository, so that step is its
own commit; the others live inside `.git`, so each teammate runs `xaden setup` once. A hook manager or CI
system outside this list stops the run with exit code 4 and a manual step. Adopt without it with
`--skip-hooks` or `--skip-ci`.

### Finish, or take it out again

Push the branch and open the pull request your team reviews. To undo the adoption in a working tree:

```bash
xaden remove
```

- `xaden remove`: deletes `xaden/` and undoes exactly the paths listed in `xaden/footprint.txt`. Review the result with `git status`, then commit.

`xaden ignore-list` prints `xaden/`, `AGENTS.md` and, when present, `CLAUDE.md`, one per line, for
`.dockerignore`, `.npmignore` and archive excludes.

### A project created with `xaden new`

A project that keeps its own copy of the tooling (it has a `.scaffold/` folder) moves to this layout with the
same command. Its requirements, personas and reviews move into `xaden/`, the copied files you did not edit
are removed, and the ones you edited stay and are listed.

### Working with assistants in an adopted repository

There are no slash commands. Assistants run `xaden prompt kickoff`, `xaden prompt feature` and so on to print
the task prompt. A prompt of the same name in `xaden/prompts/` replaces the default.

## One Xaden version per project

An adopted repository pins the Xaden version it uses, with a checksum, in `xaden/xaden.conf`. A newer Xaden
installed on one machine changes nothing in the repository, and the rules for assistants never change
underneath anyone.

### See which version a project uses

```bash
xaden doctor
```

- `xaden doctor`: prints `installed X, project pinned Y` and checks the checksum. It reads two files and uses no network.

If `xaden/RULES.md` does not match the pinned version, `xaden check` fails and names the fix, `xaden rules`.

### Install a pinned version that is missing

```bash
xaden fetch 0.3.0
```

- `xaden fetch 0.3.0`: shows the version, the source and the checksum, then asks `Download and install Xaden 0.3.0 now? [y/N]`. Only a yes downloads. It installs the download only if its checksum equals the one in `xaden.conf`.

Xaden never downloads anything without that yes, and the yes is not remembered. Without a terminal (an IDE git
client, a script, an assistant) nothing downloads: the command exits with code 3 and prints the
`xaden fetch <version>` to run yourself. Assistants show the question to you and never answer it. In CI, the
workflow step names the version and the checksum and changes only by pull request. Other installed versions live in
`~/.local/share/xaden/versions`; set `XADEN_HOME` to move them.

### Move the team to a newer version

```bash
xaden upgrade --check
xaden upgrade 0.3.0
```

- `xaden upgrade --check`: asks, then looks for a newer release. It is the only way Xaden looks.
- `xaden upgrade 0.3.0`: works on a branch for a pull request. It bumps the version and checksum in `xaden.conf`, regenerates `xaden/RULES.md`, shows the diff and the changelog entries between the two versions, and updates the workflow.

Your team reviews the pull request, so everyone moves at once.

## Autopilot for a new project

When you start a plain new project and do not want to choose every tool, let Xaden set it up.

### Run it

```bash
xaden new --autopilot --stack python my-app
```

- `xaden new --autopilot --stack python my-app`: prints one plan and asks once. Use `--stack node` for a Node project.

### What the plan covers

The `xaden/` layout, the stack's preset, mode `strict`, hooks in the clone, a CI workflow pinned to the
installed Xaden version, `git init` on `main` and a first commit. It prints the exact install commands for the
development tools, with pinned versions. You run them; Xaden does not.

### What it never does

It never pushes, publishes or downloads, and a later package needs its own approval. A folder that already
holds code, a build file or history stops with a pointer to `xaden adopt`. It ends with a summary of the
checks: tools that are not installed yet are reported as skipped, and a run with skipped checks ends with a
warning, never a success sign.

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
