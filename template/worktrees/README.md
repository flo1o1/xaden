# worktrees/

One folder per change in progress: `git worktree add worktrees/<slug> -b <type>/<slug> main`.
Everything in this folder except this README is ignored by git and skipped by the checks.

Remove a worktree when its change is merged: `git worktree remove worktrees/<slug>`.
Move one with `git worktree move`, never with `mv` (git stores absolute paths).
