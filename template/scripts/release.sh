#!/usr/bin/env bash
# Cuts a release: bumps VERSION (SemVer), stamps CHANGELOG and docs, commits, tags. Never pushes.
# Refuses to release while the user/admin guides still contain TODO markers.
# Usage: scripts/release.sh <major|minor|patch>
#   major = breaking change, minor = backwards-compatible feature, patch = bug fix
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"
cd "$ROOT"

# stamp_docs <version>: sets "Applies to version" in the user and admin guides.
stamp_docs() {
  local file
  for file in docs/user-guide.md docs/admin-guide.md; do
    rewrite_file "$file" awk -v v="$1" '/^\*\*Applies to version:\*\*/ { print "**Applies to version:** " v; next } { print }'
  done
}

main() {
  local part=${1:-} current next
  [ -n "$part" ] || die "usage: scripts/release.sh <major|minor|patch>"
  git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
  [ -z "$(git status --porcelain)" ] || die "working tree not clean; commit or stash first"
  grep -q '^## \[Unreleased\]' CHANGELOG.md || die "CHANGELOG.md has no [Unreleased] section"

  current="$(tr -d '[:space:]' <VERSION)"
  next="$(bump_version "$current" "$part")"
  ensure_tag_absent "v$next" # all validation happens before the first change (REQ-024)

  "$SCRIPTS/check.sh" --strict # every required tool must run (REQ-019)
  "$SCRIPTS/check-requirements.sh" --release || die "replace template placeholders in the requirements first"
  "$SCRIPTS/check-docs.sh" --release || die "documentation incomplete; run the documentation prompt (/docs)"
  stamp_changelog CHANGELOG.md "$next"
  stamp_docs "$next"
  printf '%s\n' "$next" >VERSION
  commit_release_or_restore "chore(release): v$next" VERSION CHANGELOG.md docs/user-guide.md docs/admin-guide.md
  tag_release_or_report "v$next"
  info "released v$next (not pushed; run: git push --follow-tags)"
}

main "$@"
