#!/usr/bin/env bash
# Checks the scaffold repository itself: its own requirements, the template's integrity,
# shell lint, secret scan, SAST (local rules + rule tests) and the end-to-end smoke test.
# Usage: [STRICT=1] scripts/check-scaffold.sh [--staged]   (STRICT=1: missing tools fail, as in CI)
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
  if "$@"; then CHECKS_PASSED=$((CHECKS_PASSED + 1)); else FAILURES=$((FAILURES + 1)); fi
}

# test_semgrep_rules: proves every local rule fires on its fixtures in tests/semgrep/.
test_semgrep_rules() {
  local workdir status=0
  workdir="$(mktemp -d)"
  cp "$ROOT"/template/.semgrep/rules.yml "$ROOT"/tests/semgrep/rules.* "$workdir/"
  semgrep --test --metrics=off --disable-version-check "$workdir" || status=$?
  rm -rf "$workdir"
  return "$status"
}

if [ "$MODE" = "staged" ]; then
  enter_staged_snapshot "$ROOT" # checks see exactly the staged content (REQ-020)
  ROOT="$SNAPSHOT"
fi

info "check mode: $MODE"
run_step "scaffold requirements" "$TEMPLATE_SCRIPTS/check-requirements.sh" "$ROOT/docs/requirements"
run_step "scaffold traceability" env PROJECT_ROOT="$ROOT" "$TEMPLATE_SCRIPTS/check-traceability.sh"
run_step "template requirements format" env PROJECT_ROOT="$ROOT/template" ALLOW_TEMPLATE_PLACEHOLDERS=1 "$TEMPLATE_SCRIPTS/check-requirements.sh"
run_step "template docs structure" env PROJECT_ROOT="$ROOT/template" "$TEMPLATE_SCRIPTS/check-docs.sh"
lint_shell "$MODE"
scan_secrets "$MODE"
# tests/semgrep holds deliberately vulnerable fixtures; scan everything else.
scan_sast "$MODE" "$ROOT/template/.semgrep" '^tests/semgrep/'

if [ "$MODE" = "full" ]; then
  if has_command semgrep; then
    run_step "semgrep rule tests" test_semgrep_rules
  else
    record_missing_tool "semgrep rule tests" semgrep
  fi
  run_step "smoke test" "$ROOT/tests/smoke.sh"
fi

finish_checks
