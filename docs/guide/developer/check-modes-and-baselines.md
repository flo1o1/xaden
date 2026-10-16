# Check modes and baselines

Decide how strict the checks are, and let a repository with existing findings adopt Xaden without failing on what was already
there.

## The three modes

The `mode` in `xaden/xaden.conf` decides what a new finding does:

| Mode | A new finding |
|------|---------------|
| `advisory` | warns and passes |
| `changed-files` (default when you adopt a repository) | fails if it is in a file the change touches |
| `strict` (default for a new project) | fails in any file |

Changing the mode is an approval point: loosening a gate needs the team's agreement, so make the change in a pull request.

## Baselines

When a repository is adopted, Xaden runs your check commands once and records what they report in `xaden/baselines/`, one list per
check. A finding in the baseline never fails a check, in any mode.

A baseline only shrinks. When you fix a finding, the next full run on your machine removes it from the list and tells you to commit
the smaller file. In CI the run only warns, because CI does not change files. A new finding is never added to a baseline; it fails
the check in the mode you chose. Letting a baseline grow is an approval point.

A failure that names no file, such as a failing test, cannot be baselined. In `advisory` it warns; in the other modes it fails.

## Commit convention

If your repository does not use Conventional Commits, the `Refs:` checks only advise. Set `commit-convention = conventional` in
`xaden/xaden.conf` when the team opts in.

## Gaps: no tests or linters yet

If the repository lacks tests, linters or a type checker for its stack, `xaden adopt --scan` lists each gap. A gap is reported by
`xaden check`: a warning in `advisory` and `changed-files`, an error in `strict`.

You can close a gap in two ways:

- Name your own command: add `check.test = <command>` (or `check.lint`, `check.typecheck`) to `xaden/xaden.conf`.
- Use Xaden's preset for Python or Node: `xaden adopt --preset` while adopting, or later:

```bash
xaden preset python
```

- `xaden preset python`: writes the preset's configuration at the repository root where its tools expect it, maps the check commands in `xaden/xaden.conf`, and prints the command that installs the tools. You run that command yourself. A file you already have is never overwritten; Xaden shows the difference and asks before it saves its version next to yours as `<file>.xaden-new`.

## Next

[Kick off with your assistant](kick-off-with-your-assistant.md).
