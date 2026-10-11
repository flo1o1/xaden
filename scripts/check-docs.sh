#!/usr/bin/env bash
# Validates user and admin documentation.
# Always: required headings exist. With --release: no unfilled "TODO" markers remain.
# Usage: scripts/check-docs.sh [--release]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"

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

# check_filled <file>: counts a failure if TODO markers remain.
check_filled() {
  local count
  count=$(grep -c 'TODO' "$1" || true)
  if [ "$count" -gt 0 ]; then
    warn "$1: $count unfilled TODO marker(s)"
    FAILURES=$((FAILURES + 1))
  fi
}

check_headings "$ROOT/docs/user-guide.md" "$USER_HEADINGS"
check_headings "$ROOT/docs/admin-guide.md" "$ADMIN_HEADINGS"

if [ "$RELEASE_MODE" = "1" ]; then
  check_filled "$ROOT/docs/user-guide.md"
  check_filled "$ROOT/docs/admin-guide.md"
fi

[ "$FAILURES" -eq 0 ] || exit 1
echo "docs OK"
