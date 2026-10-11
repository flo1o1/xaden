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

Not recommended: frameworks that bring their own complete workflow (for example Superpowers,
with its own brainstorm, plan, TDD and review phases). They duplicate the workflow in
`AGENTS.md` and `prompts/`, and two workflows give the assistant conflicting instructions.
