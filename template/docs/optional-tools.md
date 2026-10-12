# Optional tools

Extra checks that make code more robust where they fit. None is required. `scripts/check.sh`
(full run) prints a `TIP:` line for each one that fits this project and is not adopted yet; tips
never change the result. Once adopted, the check runs it and its findings fail the run like any
other check. Ask the user before installing anything (AGENTS.md §10).

## Quality checks

| Tool | Fits when | Catches | Adopt | `scripts/check.sh` then |
|------|-----------|---------|-------|-------------------------|
| [actionlint](https://github.com/rhysd/actionlint) | `.github/workflows/` exists | Workflow syntax and expression errors before CI runs them | Install the binary | Lints workflow files (also before each commit) |
| [zizmor](https://github.com/zizmorcore/zizmor) | `.github/workflows/` exists | Workflow security problems: template injection, leaked credentials, cache poisoning | Install the binary | Audits workflow files offline (also before each commit) |
| [jscpd](https://github.com/kucherenko/jscpd) | Source code exists | Copy-pasted code (CC-03) | Install jscpd (global or dev dependency) and add `.jscpd.json` | Fails when duplication exceeds `threshold` |
| [vulture](https://github.com/jendrikseipp/vulture) | Python | Unused functions, classes, variables, imports | Add to `requirements-dev.txt`; add `[tool.vulture]` to `pyproject.toml` | Runs `vulture` with that configuration |
| [knip](https://knip.dev) | Node | Unused files, exports and dependencies | `npm install --save-dev knip`; `npm pkg set scripts.deadcode=knip` | Runs `npm run deadcode` |
| [Hypothesis](https://hypothesis.readthedocs.io) | Python | Edge cases example tests miss (property-based tests) | Add to `requirements-dev.txt`; write property tests | Runs them with the other tests |
| [fast-check](https://fast-check.dev) | Node | Same, for JavaScript and TypeScript | `npm install --save-dev fast-check` | Runs them with the other tests |
| [mutmut](https://github.com/boxed/mutmut) | Python | Tests that run code but check too little (mutation testing) | Add to `requirements-dev.txt` | Nothing (slow): run `mutmut run` before releases |
| [StrykerJS](https://stryker-mutator.io) | Node | Same, for JavaScript and TypeScript | `npm init stryker` | Nothing (slow): run `npx stryker run` before releases |

Starting configurations (adjust paths to the project):

```toml
# pyproject.toml
[tool.vulture]
paths = ["src", "tests"]
min_confidence = 80
```

```json
{ "threshold": 5, "ignore": ["**/node_modules/**", "**/.venv/**"] }
```

The second block is `.jscpd.json`: the run fails when more than 5 % of the code is duplicated.
Lower the threshold as duplication goes down; raising it needs the user's approval (AGENTS.md §5).
False positives of vulture go into a whitelist file (`vulture --make-whitelist`) listed in `paths`.

When to use which test technique: `docs/clean-code.md` → Tests.

## Assistant plugins (Claude Code)

Public plugins that add depth to reviews. They are optional, and this project's `AGENTS.md`
takes precedence over them (§10). Install from the named sources only.

| Plugin | Adds | Install |
|--------|------|---------|
| Anthropic `code-review`, `security-guidance`, `pr-review-toolkit` | Parallel review agents for logic and edge cases; security review of diffs | `/plugin install code-review@claude-plugins-official` (same for the others) |
| [Trail of Bits](https://github.com/trailofbits/skills) | Security analysis by an audit firm: CodeQL and semgrep workflows, SARIF parsing, GitHub Actions auditing | `/plugin marketplace add trailofbits/skills`, then pick plugins in `/plugin` |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | Smallest complete change: reuse before writing, one test for risky logic | `/plugin marketplace add DietrichGebert/ponytail`, then `/plugin install ponytail@ponytail` |
| [Caveman](https://github.com/JuliusBrussee/caveman) | Shorter replies, fewer output tokens; code, commits and project files stay in normal prose | `/plugin marketplace add JuliusBrussee/caveman`, then `/plugin install caveman@caveman` |
| [Token Optimizer](https://github.com/alexgreensh/token-optimizer) | Smaller context: compresses command, search and tool output; context audits. License: PolyForm Noncommercial (small-business permission), not open source | `/plugin marketplace add alexgreensh/token-optimizer`, then `/plugin install token-optimizer@alexgreensh-token-optimizer` |
| [claude-mem](https://github.com/thedotmack/claude-mem) | Memory of past sessions: records sessions, compresses them with a model and adds relevant memories to new ones. License: Apache-2.0 | `/plugin marketplace add thedotmack/claude-mem`, then `/plugin install claude-mem` |
| [obsidian-skills](https://github.com/kepano/obsidian-skills) | Obsidian Flavored Markdown, Bases, JSON Canvas and the Obsidian CLI, for editing the prompt library in `prompts/` (an Obsidian vault). License: MIT | `/plugin marketplace add kepano/obsidian-skills`, then `/plugin install obsidian@obsidian-skills` |

Compressed output is a summary: a completion report must quote failing lines from the full output
(rerun the check or expand the archived result). Use one output-compression plugin at a time.
Token Optimizer keeps full tool output on disk in your home directory (private file permissions;
credentials removed by pattern only), so never print secrets in a session.
claude-mem stores sessions in `~/.claude-mem` (use its `<private>` tags for sensitive text); its
hosted memory service (the claude-mem observer) receives session content, so choose your Anthropic
plan or your own model key when code must not leave your assistant's provider. Its memories are
context: requirements and rules are still looked up in the files (`AGENTS.md` §0).
Use Obsidian syntax from obsidian-skills in `prompts/` only; `AGENTS.md`, requirements and guides
stay plain Markdown, because other assistants and the check scripts read them.

Not recommended: frameworks that bring their own complete workflow (for example Superpowers,
with its own brainstorm, plan, TDD and review phases). They duplicate the workflow in
`AGENTS.md` and `prompts/`, and two workflows give the assistant conflicting instructions.
