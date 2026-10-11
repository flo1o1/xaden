#!/usr/bin/env bash
# Validates docs/requirements/REQUIREMENTS.md.
# Rules: unique IDs `REQ-nnn`, known priority (MoSCoW) and status, 7 table columns,
# at least one requirement row. Exit 1 on any violation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="${1:-$ROOT/docs/requirements/REQUIREMENTS.md}"

[ -f "$FILE" ] || { echo "ERROR: $FILE not found" >&2; exit 1; }

awk -F'|' '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function fail(msg) { printf "REQUIREMENTS: line %d: %s\n", NR, msg > "/dev/stderr"; errors++ }
  BEGIN {
    split("must should could wont", p, " "); for (i in p) priorities[p[i]] = 1
    split("draft approved in-progress done dropped", s, " "); for (i in s) statuses[s[i]] = 1
  }
  /^\| *REQ-/ {
    rows++
    id = trim($2); priority = trim($4); status = trim($5)
    if (NF != 8) fail("expected 6 columns, got " (NF - 2))
    if (id !~ /^REQ-[0-9][0-9][0-9]+$/) fail("bad ID \"" id "\"")
    if (id in seen) fail("duplicate ID " id)
    seen[id] = 1
    if (!(priority in priorities)) fail(id ": unknown priority \"" priority "\"")
    if (!(status in statuses)) fail(id ": unknown status \"" status "\"")
  }
  END {
    if (rows == 0) { print "REQUIREMENTS: no requirement rows found" > "/dev/stderr"; errors++ }
    if (errors > 0) exit 1
    printf "requirements OK (%d)\n", rows
  }
' "$FILE"
