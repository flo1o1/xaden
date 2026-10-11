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

# python_uses_vulture: true once the project configured vulture (opt-in, REQ-051).
python_uses_vulture() { grep -q '^\[tool\.vulture\]' pyproject.toml 2>/dev/null; }

# python_declares <package>: true if pyproject.toml or a requirements file names the package.
python_declares() {
  grep -qiE "(^|[^a-z0-9_-])$1([^a-z0-9_-]|$)" pyproject.toml requirements*.txt 2>/dev/null
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
  if python_uses_vulture; then run_tool "python: vulture (dead code)" vulture; fi
}

# stack_tips: optional tools that fit a Python project and are not adopted yet.
stack_tips() {
  python_detected || return 0
  python_uses_vulture ||
    tip "python: vulture finds dead code. Add vulture to requirements-dev.txt and [tool.vulture] (paths, min_confidence = 80) to pyproject.toml"
  python_declares hypothesis ||
    tip "python: Hypothesis property-based tests find edge cases that example tests miss. Add hypothesis to requirements-dev.txt"
  python_declares mutmut ||
    tip "python: mutmut shows which code changes no test notices. Add mutmut to requirements-dev.txt; run 'mutmut run' before releases"
  return 0
}
