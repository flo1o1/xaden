#!/usr/bin/env bash
# Cuts a release: bumps VERSION (SemVer), stamps CHANGELOG, commits, tags. Never pushes.
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

main() {
  local part=${1:-} current next
  [ -n "$part" ] || die "usage: scripts/release.sh <major|minor|patch>"
  git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
  [ -z "$(git status --porcelain)" ] || die "working tree not clean; commit or stash first"
  grep -q '^## \[Unreleased\]' CHANGELOG.md || die "CHANGELOG.md has no [Unreleased] section"

  current="$(tr -d '[:space:]' <VERSION)"
  next="$(bump_version "$current" "$part")"

  "$ROOT/scripts/check.sh"
  stamp_changelog "$next"
  printf '%s\n' "$next" >VERSION
  git add VERSION CHANGELOG.md
  git commit -q -m "chore(release): v$next"
  git tag -a "v$next" -m "Release v$next"
  info "released v$next (not pushed; run: git push --follow-tags)"
}

main "$@"
