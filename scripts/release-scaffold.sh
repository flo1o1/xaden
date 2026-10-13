#!/usr/bin/env bash
# Releases the scaffold: full checks, SemVer bump of the root VERSION, changelog stamp, tag.
# Never pushes. Usage: scripts/release-scaffold.sh <major|minor|patch>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$ROOT/template/scripts/lib.sh"
cd "$ROOT"

# stamp_release <version>: writes the version into CHANGELOG.md and VERSION.
stamp_release() {
  stamp_changelog CHANGELOG.md "$1" && printf '%s\n' "$1" >VERSION
}

main() {
  local part=${1:-} next
  [ -n "$part" ] || die "usage: scripts/release-scaffold.sh <major|minor|patch>"
  [ -z "$(git status --porcelain)" ] || die "working tree not clean; commit or stash first"
  next="$(bump_version "$(tr -d '[:space:]' <VERSION)" "$part")"
  ensure_tag_absent "v$next"

  STRICT=1 "$ROOT/scripts/check-scaffold.sh"
  stamp_release_or_restore stamp_release "$next" VERSION CHANGELOG.md
  commit_release_or_restore "chore(release): scaffold v$next" VERSION CHANGELOG.md
  tag_release_or_report "v$next"
  info "released scaffold v$next (not pushed; see AGENTS.md \"Landing a change on main\")"
}

main "$@"
