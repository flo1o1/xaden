#!/usr/bin/env bash
# Validates docs/requirements/REQUIREMENTS.md.
# Rules: 6 columns; unique IDs `REQ-nnn`; non-empty requirement text and acceptance criteria;
# known priority (MoSCoW) and status; `Updated` is a real YYYY-MM-DD date; at least one row.
# The date placeholder is accepted only with ALLOW_TEMPLATE_PLACEHOLDERS=1 (the scaffold's
# own template check). --release additionally rejects template placeholders.
# Usage: scripts/check-requirements.sh [--release] [file]
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"

RELEASE_MODE=0
if [ "${1:-}" = "--release" ]; then
  RELEASE_MODE=1
  shift
fi
FILE="${1:-$ROOT/docs/requirements/REQUIREMENTS.md}"
# Text of the placeholder row created by the scaffold; it must be replaced before a release.
PLACEHOLDER_TEXT="Describe the first requirement here"
# The date placeholder, assembled from two parts so project generation (which fills every
# literal occurrence in the template) does not rewrite it here.
DATE_PLACEHOLDER="{{""DATE}}"

[ -f "$FILE" ] || { echo "ERROR: $FILE not found" >&2; exit 1; }

awk -F'|' -v release="$RELEASE_MODE" -v allow_placeholders="${ALLOW_TEMPLATE_PLACEHOLDERS:-0}" \
  -v placeholder_text="$PLACEHOLDER_TEXT" -v date_placeholder="$DATE_PLACEHOLDER" '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function fail(msg) { printf "REQUIREMENTS: line %d: %s\n", NR, msg > "/dev/stderr"; errors++ }
  function valid_date(d) {
    return d ~ /^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/
  }
  BEGIN {
    split("must should could wont", p, " "); for (i in p) priorities[p[i]] = 1
    split("draft approved in-progress done dropped", s, " "); for (i in s) statuses[s[i]] = 1
  }
  /^\| *REQ-/ {
    rows++
    id = trim($2); text = trim($3); priority = trim($4); status = trim($5)
    acceptance = trim($6); updated = trim($7)
    if (NF != 8) fail("expected 6 columns, got " (NF - 2))
    if (id !~ /^REQ-[0-9][0-9][0-9]+$/) fail("bad ID \"" id "\"")
    if (id in seen) fail("duplicate ID " id)
    seen[id] = 1
    if (text == "") fail(id ": empty requirement text")
    if (acceptance == "") fail(id ": empty acceptance criteria")
    if (!(priority in priorities)) fail(id ": unknown priority \"" priority "\"")
    if (!(status in statuses)) fail(id ": unknown status \"" status "\"")
    if (updated == date_placeholder) {
      if (allow_placeholders != "1") fail(id ": unfilled " date_placeholder " placeholder")
    } else if (!valid_date(updated)) {
      fail(id ": invalid date \"" updated "\" (expected YYYY-MM-DD)")
    }
    if (release == "1" && (text == placeholder_text || $0 ~ /\{\{/)) {
      fail(id ": template placeholder must be replaced before a release")
    }
  }
  END {
    if (rows == 0) { print "REQUIREMENTS: no requirement rows found" > "/dev/stderr"; errors++ }
    if (errors > 0) exit 1
    printf "requirements OK (%d)\n", rows
  }
' "$FILE"
