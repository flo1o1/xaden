#!/usr/bin/env bash
# Looks up requirements so nobody has to quote them from memory.
# Usage: scripts/req.sh list            one line per requirement
#        scripts/req.sh show REQ-nnn    all fields of one requirement
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"
FILE="$ROOT/docs/requirements/REQUIREMENTS.md"

# list_requirements: prints "ID [status, priority] text".
list_requirements() {
  awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^\| *REQ-/ { printf "%s [%s, %s] %s\n", trim($2), trim($5), trim($4), trim($3) }
  ' "$FILE"
}

# show_requirement <REQ-nnn>: prints every field of one requirement; dies if unknown.
show_requirement() {
  local id=$1 output
  printf '%s' "$id" | grep -Eq '^REQ-[0-9]{3,}$' || die "invalid requirement ID: $id"
  output=$(awk -F'|' -v id="$id" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    trim($2) == id {
      printf "ID: %s\nRequirement: %s\nPriority: %s\nStatus: %s\nAcceptance: %s\nUpdated: %s\n", \
        trim($2), trim($3), trim($4), trim($5), trim($6), trim($7)
    }
  ' "$FILE")
  [ -n "$output" ] || die "$id does not exist in docs/requirements/REQUIREMENTS.md"
  printf '%s\n' "$output"
}

case "${1:-}" in
  list) list_requirements ;;
  show) show_requirement "${2:-}" ;;
  *) die "usage: scripts/req.sh list | show REQ-nnn" ;;
esac
