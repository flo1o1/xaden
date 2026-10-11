#!/usr/bin/env bash
# Checks the scaffold repository itself: its own requirements, the template's integrity,
# shell lint, secret scan, SAST and the end-to-end smoke test.
# Usage: scripts/check-scaffold.sh [--quick]   (--quick: skip the smoke test)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_SCRIPTS="$ROOT/template/scripts"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$TEMPLATE_SCRIPTS/lib.sh"
cd "$ROOT"

# run_step <label> <command...>: runs a check, counting a failure instead of aborting.
run_step() {
  local label=$1
  shift
  info "$label"
  "$@" || FAILURES=$((FAILURES + 1))
}

# shell_files: every shell script in the repository, one per line.
shell_files() {
  { find scripts tests template/scripts -type f -name '*.sh'
    find template/scripts/hooks .githooks -type f; } 2>/dev/null | sort -u
}

run_step "scaffold requirements" "$TEMPLATE_SCRIPTS/check-requirements.sh" "$ROOT/docs/requirements/REQUIREMENTS.md"
run_step "template requirements format" "$TEMPLATE_SCRIPTS/check-requirements.sh"
run_step "template docs structure" "$TEMPLATE_SCRIPTS/check-docs.sh"
# shellcheck disable=SC2046 # file list has no spaces by construction
run_tool "shellcheck" shellcheck $(shell_files)
run_tool "secret scan (gitleaks)" gitleaks detect --no-banner --redact
run_tool "SAST (semgrep)" semgrep scan --config p/default --metrics=off --error --quiet

if [ "${1:-}" != "--quick" ]; then
  run_step "smoke test" "$ROOT/tests/smoke.sh"
fi

[ "$FAILURES" -eq 0 ] || die "$FAILURES check(s) failed"
info "scaffold checks passed"
