#!/usr/bin/env bash
# Rejects commit messages that cite rules/requirements which do not exist.
# Usage: scripts/verify-refs.sh <commit-message-file>
# - Every REQ-nnn must be a row in REQUIREMENTS.md; every CC-nn a rule in AGENTS.md.
# - `feat` needs a "Refs: REQ-nnn" trailer; `fix` needs one or "Refs: none".
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"

MESSAGE_FILE=${1:-}
[ -f "$MESSAGE_FILE" ] || die "usage: scripts/verify-refs.sh <commit-message-file>"
RULES_FILE="${RULES_FILE:-$ROOT/AGENTS.md}"  # where CC-nn rules are defined

# read_committed_version <path>: the file as it will be committed (git index) when tracked,
# otherwise the working-tree file. Unstaged edits must not validate a commit (REQ-020).
read_committed_version() {
  git -C "$(dirname "$1")" show ":./$(basename "$1")" 2>/dev/null || cat "$1"
}

REQUIREMENTS_TEXT="$(read_committed_version "$ROOT/docs/requirements/REQUIREMENTS.md")"
RULES_TEXT="$(read_committed_version "$RULES_FILE")"

# check_cited_ids: every cited ID must exist in the source of truth.
check_cited_ids() {
  local id
  while IFS= read -r id; do
    case "$id" in
      REQ-*) printf '%s\n' "$REQUIREMENTS_TEXT" | grep -Eq "^\| *$id " || die "commit cites unknown requirement $id" ;;
      CC-*) printf '%s\n' "$RULES_TEXT" | grep -Eq "^- \*\*$id\*\*" || die "commit cites unknown rule $id" ;;
    esac
  done < <(grep -oE 'REQ-[0-9]{3,}|CC-[0-9]{2}' "$MESSAGE_FILE" | sort -u)
}

# requirement_status <REQ-nnn>: status column of the requirement as committed.
requirement_status() {
  printf '%s\n' "$REQUIREMENTS_TEXT" | awk -F'|' -v id="$1" '
    { gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $5) }
    $2 == id { print $5 }'
}

# check_referenced_status <refs-text>: feat/fix may only implement approved, in-progress or
# done requirements; drafts must be approved first, dropped ones are gone (REQ-021).
check_referenced_status() {
  local id status
  for id in $(printf '%s' "$1" | grep -oE 'REQ-[0-9]{3,}' | sort -u); do
    status="$(requirement_status "$id")"
    case "$status" in
      approved | in-progress | done) ;;
      *) die "$id has status '$status'; feat/fix may only reference approved, in-progress or done requirements" ;;
    esac
  done
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
  case "$type" in feat | fix) check_referenced_status "$refs" ;; esac
}

check_cited_ids
check_required_trailer
