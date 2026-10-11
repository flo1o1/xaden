#!/usr/bin/env bash
# Node/TypeScript stack for scripts/check.sh. Sourced, not executed.
# Detected by package.json. Tooling runs through npm scripts ("lint", "typecheck", "test",
# see scripts/apply-preset.sh node). Once detected, missing scripts fail instead of passing silently.

# node_has_script <name>: true if package.json defines the npm script.
node_has_script() { [ "$(npm pkg get "scripts.$1" 2>/dev/null)" != "{}" ]; }

# node_run_script <name>: runs a mandatory npm script, failing if it is not defined.
node_run_script() {
  if ! node_has_script "$1"; then
    warn "missing: npm script '$1' (run: scripts/apply-preset.sh node)"
    FAILURES=$((FAILURES + 1))
    return 0
  fi
  run_required_tool "node: $1" npm run --silent "$1"
}

# stack_check <mode>: staged = lint; full = also typecheck, tests, dependency audit.
stack_check() {
  [ -f package.json ] || return 0
  if ! has_command npm; then
    run_required_tool "node: npm" npm --version
    return 0
  fi
  node_run_script lint
  [ "$1" = "full" ] || return 0
  require "package-lock.json (reproducible installs; run npm install and commit it)" test -f package-lock.json
  node_run_script typecheck
  node_run_script test
  run_tool "node: npm audit (network)" npm audit --audit-level=high
}
