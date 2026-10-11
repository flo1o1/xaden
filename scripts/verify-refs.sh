#!/usr/bin/env bash
# Rejects commit messages that cite rules/requirements which do not exist.
# Usage: scripts/verify-refs.sh <commit-message-file>
# - Every REQ-nnn must be a row in REQUIREMENTS.md; every CC-nn a rule in AGENTS.md.
# - `feat` needs a "Refs: REQ-nnn" trailer; `fix` needs one or "Refs: none".
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"

MESSAGE_FILE=${1:-}
[ -f "$MESSAGE_FILE" ] || die "usage: scripts/verify-refs.sh <commit-message-file>"
REQUIREMENTS="$ROOT/docs/requirements/REQUIREMENTS.md"

# check_cited_ids: every cited ID must exist in the source of truth.
check_cited_ids() {
  local id
  while IFS= read -r id; do
    case "$id" in
      REQ-*) grep -Eq "^\| *$id " "$REQUIREMENTS" || die "commit cites unknown requirement $id" ;;
      CC-*) grep -Eq "^- \*\*$id\*\*" "$ROOT/AGENTS.md" || die "commit cites unknown rule $id" ;;
    esac
  done < <(grep -oE 'REQ-[0-9]{3,}|CC-[0-9]{2}' "$MESSAGE_FILE" | sort -u)
}

# check_required_trailer: feat/fix must say which requirement they serve.
check_required_trailer() {
  local type refs
  type=$(head -n 1 "$MESSAGE_FILE" | sed -E 's/^([a-z]+).*/\1/')
  refs=$(grep -E '^Refs:' "$MESSAGE_FILE" || true)
  case "$type" in
    feat) printf '%s' "$refs" | grep -Eq 'REQ-[0-9]{3,}' || die "feat commits need a 'Refs: REQ-nnn' trailer" ;;
    fix) printf '%s' "$refs" | grep -Eq 'REQ-[0-9]{3,}|none' || die "fix commits need 'Refs: REQ-nnn' or 'Refs: none'" ;;
  esac
}

check_cited_ids
check_required_trailer
