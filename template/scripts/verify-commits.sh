#!/usr/bin/env bash
# Runs the commit-msg checks (Conventional Commits + REQ/CC references) on a range of
# existing commits. Used by CI so contributors without local hooks are checked too.
# Usage: scripts/verify-commits.sh <git-revision-range>   e.g. origin/main..HEAD
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"

RANGE=${1:-}
[ -n "$RANGE" ] || die "usage: scripts/verify-commits.sh <revision-range>"

message_file="$(mktemp)"
trap 'rm -f "$message_file"' EXIT

failed=0
for commit in $(git -C "$ROOT" rev-list --no-merges "$RANGE"); do
  git -C "$ROOT" log -1 --format=%B "$commit" >"$message_file"
  if ! "$SCRIPTS/hooks/commit-msg" "$message_file"; then
    warn "commit $(git -C "$ROOT" log -1 --format='%h %s' "$commit") failed the message checks"
    failed=$((failed + 1))
  fi
done

[ "$failed" -eq 0 ] || die "$failed commit(s) failed the message checks"
info "commit messages OK"
