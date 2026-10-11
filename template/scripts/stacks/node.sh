#!/usr/bin/env bash
# Node/TypeScript stack for scripts/check.sh. Sourced, not executed.
# Detected by package.json. Tooling runs through npm scripts ("lint", "typecheck", "test",
# see scripts/apply-preset.sh node). Once detected, missing scripts fail instead of passing silently.

# node_has_script <name>: true if package.json defines the npm script.
node_has_script() { [ "$(npm pkg get "scripts.$1" 2>/dev/null)" != "{}" ]; }

# node_declares <text>: true if package.json contains the quoted text (a package or script name).
node_declares() { grep -q "\"$1\"" package.json; }

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
  if node_has_script deadcode; then node_run_script deadcode; fi # optional (REQ-051)
}

# stack_tips: optional tools that fit a Node project and are not adopted yet.
stack_tips() {
  [ -f package.json ] || return 0
  node_declares deadcode ||
    tip "node: knip finds unused files, exports and dependencies. npm install --save-dev knip; npm pkg set scripts.deadcode=knip"
  node_declares fast-check ||
    tip "node: fast-check property-based tests find edge cases that example tests miss. npm install --save-dev fast-check"
  node_declares @stryker-mutator/core ||
    tip "node: StrykerJS shows which code changes no test notices. npm init stryker; run 'npx stryker run' before releases"
  return 0
}
