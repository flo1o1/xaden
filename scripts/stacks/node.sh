#!/usr/bin/env bash
# Node/TypeScript stack for scripts/check.sh. Sourced, not executed.
# Detected by package.json. Uses npm scripts so each project owns its tooling:
# define "lint", "typecheck" and "test" in package.json.

# stack_check: lint, typecheck, tests, dependency audit.
stack_check() {
  [ -f package.json ] || return 0
  run_tool "node: lint" npm run --if-present --silent lint
  run_tool "node: typecheck" npm run --if-present --silent typecheck
  run_tool "node: test" npm run --if-present --silent test
  run_tool "node: npm audit" npm audit --audit-level=high
}
