#!/usr/bin/env bash
# Installs the clean-code linter preset for a stack into this project. Never overwrites
# existing files and never installs packages: it prints the install command instead
# (AGENTS.md: ask before adding dependencies).
# Usage: scripts/apply-preset.sh <python|node>
set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"
PRESETS="$ROOT/presets"
cd "$ROOT"

# copy_preset_file <stack> <file>: copies one preset file unless the project already has it.
copy_preset_file() {
  if [ -e "$2" ]; then
    warn "$2 exists; left unchanged (compare with presets/$1/$2)"
    return 0
  fi
  cp "$PRESETS/$1/$2" "$2"
  info "added $2"
}

# set_npm_script <name> <command>: adds a package.json script unless it is already defined.
set_npm_script() {
  if [ "$(npm pkg get "scripts.$1")" != "{}" ]; then
    warn "package.json script '$1' exists; left unchanged"
    return 0
  fi
  npm pkg set "scripts.$1=$2"
  info "added npm script $1: $2"
}

apply_python() {
  copy_preset_file python ruff.toml
  copy_preset_file python mypy.ini
  copy_preset_file python requirements-dev.txt
  mkdir -p tests
  echo "Install the pinned tools (ask the user first):"
  echo "  python3 -m pip install -r requirements-dev.txt"
}

apply_node() {
  [ -f package.json ] || die "no package.json; run 'npm init' first"
  has_command npm || die "npm is required"
  copy_preset_file node eslint.config.mjs
  set_npm_script lint "eslint ."
  set_npm_script typecheck "tsc --noEmit"
  set_npm_script test "node --test"
  echo "Install the tools (ask the user first):"
  echo "  npm install --save-dev eslint @eslint/js typescript-eslint typescript"
}

case "${1:-}" in
  python) apply_python ;;
  node) apply_node ;;
  *) die "usage: scripts/apply-preset.sh <python|node>" ;;
esac
