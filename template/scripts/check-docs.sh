#!/usr/bin/env bash
# Validates user and admin documentation.
# Always: required headings exist. With --release: no unfilled "<!-- TODO" markers remain in
# the guides, SECURITY.md and docs/threat-model.md (REQ-058).
# Structure only: it cannot tell whether the written content is correct (REQ-037).
# Usage: scripts/check-docs.sh [--release]
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"

RELEASE_MODE=0
[ "${1:-}" = "--release" ] && RELEASE_MODE=1

USER_HEADINGS="Overview|System requirements|Installation|Getting started|Usage|Troubleshooting|Uninstall|Support"
ADMIN_HEADINGS="Overview|System requirements|Installation|Configuration|Security hardening|Deployment|Backup and restore|Monitoring and logs|Upgrade|Troubleshooting|Uninstall"

# check_headings <file> <pipe-separated headings>: counts one failure per missing "## heading".
check_headings() {
  local file=$1 heading
  [ -f "$file" ] || { warn "missing document: $file"; FAILURES=$((FAILURES + 1)); return 0; }
  while IFS= read -r heading; do
    if ! grep -qx "## $heading" "$file"; then
      warn "$file: missing section '## $heading'"
      FAILURES=$((FAILURES + 1))
    fi
  done < <(printf '%s\n' "$2" | tr '|' '\n')
}

# check_filled <file>: counts a failure if "<!-- TODO" markers remain; the word TODO in prose is fine.
check_filled() {
  local count
  [ -f "$1" ] || return 0 # projects generated before the security documents existed
  count=$(grep -c '<!-- TODO' "$1" || true)
  if [ "$count" -gt 0 ]; then
    warn "$1: $count unfilled TODO marker(s)"
    FAILURES=$((FAILURES + 1))
  fi
}

layout_init "$ROOT"
# An adopted project keeps its own documentation; Xaden requires no guides there (REQ-070).
if [ "$LAYOUT" = "adopted" ]; then
  # No guides to check, but a release is still blocked by unfilled security documents.
  if [ "$RELEASE_MODE" = "1" ]; then
    check_filled "$ROOT/SECURITY.md"
    check_filled "$THREAT_MODEL_FILE"
    [ "$FAILURES" -eq 0 ] || exit 1
  fi
  echo "docs OK (an adopted project has no guides to check)"
  exit 0
fi

check_headings "$ROOT/docs/user-guide.md" "$USER_HEADINGS"
check_headings "$ROOT/docs/admin-guide.md" "$ADMIN_HEADINGS"

if [ "$RELEASE_MODE" = "1" ]; then
  check_filled "$ROOT/docs/user-guide.md"
  check_filled "$ROOT/docs/admin-guide.md"
  check_filled "$ROOT/SECURITY.md"
  check_filled "$ROOT/docs/threat-model.md"
fi

[ "$FAILURES" -eq 0 ] || exit 1
echo "docs OK (structure only; content not verified)"
