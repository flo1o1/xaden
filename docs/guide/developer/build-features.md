# Build features

Add a feature the way Xaden expects: from a requirement, test first, checked before every commit. Repeat for every feature.

## Before you start

You finished the [kickoff](kick-off-with-your-assistant.md), so the project has approved requirements and a stack with working checks.

## Build one feature

In Claude Code, type:

```text
/feature <what users can do afterwards>
```

In any other assistant, tell it:

```text
Run `xaden prompt feature` and follow it. Feature: <what users can do afterwards>
```

The assistant links the work to a requirement, plans, writes the test first, implements, runs `xaden check`, and runs a security
review when the change touches input, logins, data, files, the network or dependencies. It updates your documentation and changelog
and commits with a `Refs: REQ-nnn` trailer that names the requirement.

You see:

- a commit per coherent step, in Conventional Commit form (`feat: ...`, `fix: ...`);
- a completion report at the end: the checks that ran, the checks that were skipped, unresolved findings, and the evidence for each acceptance criterion.

## When the checks fail

Fix the finding; do not silence a rule without a one-line reason. A commit that cites a requirement that does not exist is rejected,
and so is a `feat` commit without a `Refs:` line. Loosening a linter setting or the mode of the checks is an approval point.

## Other tasks

Claude Code, GitHub Copilot and Mistral Vibe have a slash command for each prompt (Codex CLI a `$name` skill) when your team chose them; other assistants run the `xaden prompt` command.

| You want to | Claude Code | Tell another assistant to run |
|-------------|-------------|-------------------------------|
| Fix a bug (failing test first) | `/bugfix` | `xaden prompt bugfix` |
| Refactor without changing behavior | `/refactor` | `xaden prompt refactor` |
| Review code | `/review` | `xaden prompt code-review` |
| Review security | `/security` | `xaden prompt security-review` |
| Change or add requirements | `/requirements` | `xaden prompt requirements-update` |
| Update documentation | `/docs` | `xaden prompt documentation` |
| Create a user persona | `/persona` | `xaden prompt persona` |

Changed your mind during a feature? Say so; the assistant updates the requirement first and then the code.

## Next

[Release a version](release-a-version.md).
