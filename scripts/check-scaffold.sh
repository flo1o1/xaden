#!/usr/bin/env bash
# Checks the scaffold repository itself: its own requirements, the template's integrity,
# shell lint, secret scan, SAST (local rules + rule tests) and the end-to-end smoke test.
# Usage: scripts/check-scaffold.sh [--staged]
#   (default)  full run incl. semgrep rule tests and tests/smoke.sh
#   --staged   pre-commit run: staged files only, offline, no smoke test
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_SCRIPTS="$ROOT/template/scripts"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$TEMPLATE_SCRIPTS/lib.sh"
cd "$ROOT"

MODE=full
case "${1:-}" in
  "") ;;
  --staged) MODE=staged ;;
  *) die "usage: scripts/check-scaffold.sh [--staged]" ;;
esac

# run_step <label> <command...>: runs a check, counting a failure instead of aborting.
run_step() {
  local label=$1
  shift
  info "$label"
  "$@" || FAILURES=$((FAILURES + 1))
}

# test_semgrep_rules: proves every local rule fires on its fixtures in tests/semgrep/.
test_semgrep_rules() {
  local workdir status=0
  workdir="$(mktemp -d)"
  cp template/.semgrep/rules.yml tests/semgrep/rules.* "$workdir/"
  semgrep --test --metrics=off --disable-version-check "$workdir" || status=$?
  rm -rf "$workdir"
  return "$status"
}

info "check mode: $MODE"
run_step "scaffold requirements" "$TEMPLATE_SCRIPTS/check-requirements.sh" "$ROOT/docs/requirements/REQUIREMENTS.md"
run_step "template requirements format" "$TEMPLATE_SCRIPTS/check-requirements.sh"
run_step "template docs structure" "$TEMPLATE_SCRIPTS/check-docs.sh"
lint_shell "$MODE"
scan_secrets "$MODE"
# tests/semgrep holds deliberately vulnerable fixtures; scan everything else.
scan_sast "$MODE" "$ROOT/template/.semgrep" '^tests/semgrep/'

if [ "$MODE" = "full" ]; then
  has_command semgrep && run_step "semgrep rule tests" test_semgrep_rules
  run_step "smoke test" "$ROOT/tests/smoke.sh"
fi

[ "$FAILURES" -eq 0 ] || die "$FAILURES check(s) failed"
info "scaffold checks passed"
