#!/usr/bin/env bash
# Traceability between requirements and tests.
# Fails when a `done` requirement is not referenced by any test file, or when a test cites a
# requirement ID that does not exist. Tests reference requirements by writing the ID
# (e.g. a comment `# REQ-003` or a test name containing it). Lines containing
# `traceability: ignore` are skipped (for deliberately invalid IDs in test data).
# Usage: scripts/check-traceability.sh            check
#        scripts/check-traceability.sh --matrix   print requirement → tests → commits table
set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"
cd "$ROOT"

# Test files: anything under a tests/test/__tests__ directory, or named *_test.*, *.test.*,
# *.spec.*, test_*.
TEST_FILE_PATTERN='(^|/)(tests?|__tests__)/|(^|/)test_[^/]*$|_test\.[^/]+$|\.(test|spec)\.[^/]+$'

# requirement_rows: "ID STATUS" for every requirement.
requirement_rows() {
  "$SCRIPTS/req.sh" list | sed -E 's/^(REQ-[0-9]+) \[([^,]*),.*/\1 \2/'
}

# test_files: tracked (incl. staged) test files, one per line.
test_files() { git ls-files | grep -E "$TEST_FILE_PATTERN" || true; }

# tests_citing <REQ-nnn>: test files that mention the ID (word match), comma-separated.
tests_citing() {
  test_files | while IFS= read -r file; do
    if grep -qE "(^|[^0-9A-Za-z-])$1([^0-9]|$)" "$file" 2>/dev/null; then printf '%s\n' "$file"; fi
  done | paste -sd, - || true
}

# check_done_requirements_are_tested: every done requirement appears in a test.
check_done_requirements_are_tested() {
  local id status
  while read -r id status; do
    [ "$status" = "done" ] || continue
    if [ -z "$(tests_citing "$id")" ]; then
      warn "$id is done but no test references it"
      FAILURES=$((FAILURES + 1))
    fi
  done < <(requirement_rows)
}

# check_tests_cite_known_requirements: no invented IDs in tests.
check_tests_cite_known_requirements() {
  local known id
  known="$(requirement_rows | cut -d' ' -f1)"
  while IFS= read -r id; do
    if ! printf '%s\n' "$known" | grep -qx "$id"; then
      warn "tests cite $id, which is not in REQUIREMENTS.md"
      FAILURES=$((FAILURES + 1))
    fi
  done < <(test_files | while IFS= read -r file; do
    grep -v 'traceability: ignore' "$file" 2>/dev/null | grep -oE 'REQ-[0-9]{3,}' || true
  done | sort -u)
}

# print_matrix: markdown table requirement | status | tests | commits.
print_matrix() {
  local id status tests commits
  echo "| Requirement | Status | Tests | Commits |"
  echo "|-------------|--------|-------|---------|"
  while read -r id status; do
    tests="$(tests_citing "$id")"
    commits="$(git log --oneline --grep="Refs:.*$id" 2>/dev/null | wc -l | tr -d ' ')"
    printf '| %s | %s | %s | %s |\n' "$id" "$status" "${tests:-—}" "$commits"
  done < <(requirement_rows)
}

if [ "${1:-}" = "--matrix" ]; then
  print_matrix
  exit 0
fi
check_done_requirements_are_tested
check_tests_cite_known_requirements
[ "$FAILURES" -eq 0 ] || exit 1
echo "traceability OK"
