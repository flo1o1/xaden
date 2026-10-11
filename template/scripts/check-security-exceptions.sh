#!/usr/bin/env bash
# Fails when an accepted security exception has expired or lacks an owner or a valid date (REQ-057).
# Reads the table rows of docs/security-exceptions.md; rows inside <!-- comments --> are ignored.
# Columns: ID | Finding | Why accepted | Mitigation | Owner | Expires (YYYY-MM-DD).
# A row is valid through its expiry day. Date-dependent, so scripts/check.sh runs it only in
# the full run, never in the pre-commit hook.
# Usage: scripts/check-security-exceptions.sh   (CHECK_DATE=YYYY-MM-DD overrides today, for tests)
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"

EXCEPTIONS_FILE="$ROOT/docs/security-exceptions.md"
TODAY="${CHECK_DATE:-$(date +%F)}"

# exception_problems <file> <today>: one line per invalid or expired row, nothing when all are fine.
# shellcheck disable=SC2016 # single-quoted awk program, not shell
exception_problems() {
  awk -F'|' -v today="$2" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /<!--/ { in_comment = 1 }
    in_comment { if (/-->/) in_comment = 0; next }
    !/^\|/ || /^\|[ \t]*-+[ \t]*\|/ { next }
    {
      id = trim($2); owner = trim($6); expires = trim($7)
      if (id == "ID") next
      if (id == "") { print "row without ID: " $0; next }
      if (owner == "") { print id ": no owner"; next }
      if (expires !~ /^[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]$/) { print id ": expiry \"" expires "\" is not YYYY-MM-DD"; next }
      if (expires < today) print id ": expired on " expires "; fix it, or renew it with a new date and reason"
    }' "$1"
}

printf '%s' "$TODAY" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || die "CHECK_DATE must be YYYY-MM-DD (got: $TODAY)"
if [ ! -f "$EXCEPTIONS_FILE" ]; then # projects generated before REQ-030 have none
  echo "no docs/security-exceptions.md; nothing to check"
  exit 0
fi
problems="$(exception_problems "$EXCEPTIONS_FILE" "$TODAY")"
if [ -n "$problems" ]; then
  printf '%s\n' "$problems" | while IFS= read -r problem; do warn "docs/security-exceptions.md: $problem"; done
  exit 1
fi
echo "security exceptions OK"
