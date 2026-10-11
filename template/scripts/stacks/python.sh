#!/usr/bin/env bash
# Python stack for scripts/check.sh. Sourced, not executed.
# Detected by pyproject.toml, requirements*.txt or setup.py.

# stack_check <mode>: staged = lint/format staged files; full = also types, security, audit, tests.
stack_check() {
  if ! ls pyproject.toml requirements*.txt setup.py >/dev/null 2>&1; then
    return 0
  fi
  collect_files "$1" '\.py$'
  if [ ${#TARGETS[@]} -gt 0 ]; then
    run_tool "python: ruff lint" ruff check "${TARGETS[@]}"
    run_tool "python: ruff format" ruff format --check "${TARGETS[@]}"
  fi
  [ "$1" = "full" ] || return 0
  run_tool "python: mypy" mypy .
  run_tool "python: bandit" bandit -q -r . -x ./.venv,./node_modules,./tests
  run_tool "python: pip-audit (network)" pip-audit
  if [ -d tests ]; then
    run_tool "python: pytest" pytest -q
  fi
}
