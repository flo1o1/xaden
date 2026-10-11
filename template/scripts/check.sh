#!/usr/bin/env bash
# Static analysis for this project.
# Usage: scripts/check.sh [--staged] [--strict]
#   (default)  full run: all files, types, tests, dependency audits. Use in CI, before
#              releases and before declaring work done.
#   --staged   pre-commit run: staged files only, offline, a few seconds.
#   --strict   missing tools count as failures instead of being skipped.
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"

MODE=full
for arg in "$@"; do
  case "$arg" in
    --staged) MODE=staged ;;
    --strict) STRICT=1 ;;
    *) die "unknown option: $arg (usage: scripts/check.sh [--staged] [--strict])" ;;
  esac
done
cd "$ROOT"

# check_project_files: requirements, docs structure, traceability (cheap, always run).
check_project_files() {
  run_tool "requirements format" "$SCRIPTS/check-requirements.sh"
  run_tool "documentation structure" "$SCRIPTS/check-docs.sh"
  run_tool "requirement traceability" "$SCRIPTS/check-traceability.sh"
}

# check_stacks: each file in stacks/ defines stack_check <mode> for one language.
check_stacks() {
  local stack_file
  for stack_file in "$SCRIPTS"/stacks/*.sh; do
    # shellcheck disable=SC1090 # stack files are discovered at runtime
    source "$stack_file"
    stack_check "$MODE"
  done
}

info "check mode: $MODE"
check_project_files
lint_shell "$MODE"
scan_secrets "$MODE"
scan_sast "$MODE" "$ROOT/.semgrep"
check_stacks

finish_checks
