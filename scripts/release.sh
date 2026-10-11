#!/usr/bin/env bash
# Cuts a release: bumps VERSION (SemVer), stamps CHANGELOG and docs, commits, tags. Never pushes.
# Refuses to release while the user/admin guides still contain TODO markers.
# Usage: scripts/release.sh <major|minor|patch>
#   major = breaking change, minor = backwards-compatible feature, patch = bug fix
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"
cd "$ROOT"

# stamp_changelog <version>: turns "Unreleased" content into a dated release section.
stamp_changelog() {
  local version=$1 today tmp
  today="$(date +%F)"
  tmp="$(mktemp)"
  awk -v v="$version" -v d="$today" '
    /^## \[Unreleased\]/ { print; print ""; print "## [" v "] - " d; next }
    { print }
  ' CHANGELOG.md >"$tmp"
  mv "$tmp" CHANGELOG.md
}

# stamp_docs <version>: sets "Applies to version" in the user and admin guides.
stamp_docs() {
  local version=$1 file tmp
  for file in docs/user-guide.md docs/admin-guide.md; do
    tmp="$(mktemp)"
    awk -v v="$version" '/^\*\*Applies to version:\*\*/ { print "**Applies to version:** " v; next } { print }' "$file" >"$tmp"
    cat "$tmp" >"$file"
    rm -f "$tmp"
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

  "$ROOT/scripts/check.sh"
  "$ROOT/scripts/check-docs.sh" --release || die "documentation incomplete; run the documentation prompt (/docs)"
  stamp_changelog "$next"
  stamp_docs "$next"
  printf '%s\n' "$next" >VERSION
  git add VERSION CHANGELOG.md docs/user-guide.md docs/admin-guide.md
  git commit -q -m "chore(release): v$next"
  git tag -a "v$next" -m "Release v$next"
  info "released v$next (not pushed; run: git push --follow-tags)"
}

main "$@"
