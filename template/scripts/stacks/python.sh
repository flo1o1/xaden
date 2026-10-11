#!/usr/bin/env bash
# Python stack for scripts/check.sh. Sourced, not executed.
# Detected by pyproject.toml, requirements*.txt or setup.py. Once detected, its checks are
# mandatory: missing configuration, tools or tests fail instead of being skipped.

# python_has_ruff_config: true if the project configures ruff (preset or own config).
python_has_ruff_config() {
  [ -f ruff.toml ] || [ -f .ruff.toml ] || grep -q '^\[tool\.ruff' pyproject.toml 2>/dev/null
}

# python_detected: true if any Python project marker exists.
python_detected() {
  [ -f pyproject.toml ] || [ -f setup.py ] || ls requirements*.txt >/dev/null 2>&1
}

# stack_check <mode>: staged = lint/format staged files; full = also types, security, audit, tests.
stack_check() {
  python_detected || return 0
  require "ruff configuration (run: scripts/apply-preset.sh python)" python_has_ruff_config
  collect_files "$1" '\.py$'
  if [ ${#TARGETS[@]} -gt 0 ]; then
    run_required_tool "python: ruff lint" ruff check "${TARGETS[@]}"
    run_required_tool "python: ruff format" ruff format --check "${TARGETS[@]}"
  fi
  [ "$1" = "full" ] || return 0
  require "tests/ directory (CC-08)" test -d tests
  run_required_tool "python: mypy" mypy .
  run_required_tool "python: pytest" pytest -q
  run_tool "python: bandit" bandit -q -r . -x ./.venv,./node_modules,./tests
  run_tool "python: pip-audit (network)" pip-audit
}
