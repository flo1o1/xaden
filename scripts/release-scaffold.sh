#!/usr/bin/env bash
# Releases the scaffold: full checks, SemVer bump of the root VERSION, changelog stamp, tag.
# Never pushes. Usage: scripts/release-scaffold.sh <major|minor|patch>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$ROOT/template/scripts/lib.sh"
cd "$ROOT"

main() {
  local part=${1:-} next
  [ -n "$part" ] || die "usage: scripts/release-scaffold.sh <major|minor|patch>"
  [ -z "$(git status --porcelain)" ] || die "working tree not clean; commit or stash first"
  next="$(bump_version "$(tr -d '[:space:]' <VERSION)" "$part")"
  ensure_tag_absent "v$next"

  STRICT=1 "$ROOT/scripts/check-scaffold.sh"
  stamp_changelog CHANGELOG.md "$next"
  printf '%s\n' "$next" >VERSION
  commit_release_or_restore "chore(release): scaffold v$next" VERSION CHANGELOG.md
  tag_release_or_report "v$next"
  info "released scaffold v$next (not pushed; see AGENTS.md \"Landing a change on main\")"
}

main "$@"
