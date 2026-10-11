#!/usr/bin/env bash
# Runs all static analysis: requirements format, shell lint, secret scan,
# SAST, plus every language stack in scripts/stacks/ that detects its project files.
# Usage: scripts/check.sh [--strict]   (--strict: missing tools count as failures)
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"

[ "${1:-}" = "--strict" ] && STRICT=1
cd "$ROOT"

# check_generic: language-independent checks.
check_generic() {
  info "requirements format"
  "$SCRIPTS/check-requirements.sh" || FAILURES=$((FAILURES + 1))
  info "documentation structure"
  "$SCRIPTS/check-docs.sh" || FAILURES=$((FAILURES + 1))

  local shell_files
  # Paths contain no spaces by construction (scripts/, tests/).
  shell_files=$(find scripts tests -type f \( -name '*.sh' -o -path 'scripts/hooks/*' \) 2>/dev/null | sort || true)
  if [ -n "$shell_files" ]; then
    # shellcheck disable=SC2086 # intentional word splitting of the file list
    run_tool "shellcheck" shellcheck $shell_files
  fi

  run_tool "secret scan (gitleaks)" gitleaks detect --no-banner --redact
  run_tool "SAST (semgrep)" semgrep scan --config p/default --metrics=off --error --quiet
}

# check_stacks: source each stack file; each defines stack_check.
check_stacks() {
  local stack_file
  for stack_file in "$SCRIPTS"/stacks/*.sh; do
    # shellcheck disable=SC1090 # stack files are discovered at runtime
    source "$stack_file"
    stack_check
  done
}

check_generic
check_stacks

if [ "$FAILURES" -gt 0 ]; then
  die "$FAILURES check(s) failed"
fi
info "all checks passed"
