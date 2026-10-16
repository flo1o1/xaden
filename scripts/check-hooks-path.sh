#!/usr/bin/env bash
# Fails when core.hooksPath points to a directory that does not exist: git then runs no hook at all (REQ-083).
# Usage: scripts/check-hooks-path.sh [<repository>]   (default: the repository around the current directory)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/template/scripts/lib.sh"

repo="${1:-.}"
path="$(git -C "$repo" config --get core.hooksPath || true)"
[ -n "$path" ] || exit 0
case "$path" in
  /*) ;;
  *) path="$(git -C "$repo" rev-parse --show-toplevel)/$path" ;; # relative to each worktree's top
esac
[ -d "$path" ] || die "core.hooksPath points to $path, which does not exist, so no git hook runs. Run scripts/setup.sh"
