#!/usr/bin/env bash
# Python stack for scripts/check.sh. Sourced, not executed.
# Detected by pyproject.toml, requirements*.txt or setup.py.

# stack_check: lint, format, types, security, dependency audit, tests.
stack_check() {
  if ! ls pyproject.toml requirements*.txt setup.py >/dev/null 2>&1; then
    return 0
  fi
  run_tool "python: ruff lint" ruff check .
  run_tool "python: ruff format" ruff format --check .
  run_tool "python: mypy" mypy .
  run_tool "python: bandit" bandit -q -r . -x ./.venv,./node_modules,./tests
  run_tool "python: pip-audit" pip-audit
  if [ -d tests ]; then
    run_tool "python: pytest" pytest -q
  fi
}
