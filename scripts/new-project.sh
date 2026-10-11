#!/usr/bin/env bash
# Creates a new project from template/ in a fresh directory with its own git repo.
# Usage: scripts/new-project.sh <project-name> [target-dir]
#   project-name: lowercase letters, digits, hyphens (2-51 chars), starts with a letter
#   target-dir:   defaults to ../<project-name>; must not exist yet
set -euo pipefail

SCAFFOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$SCAFFOLD_ROOT/template"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$TEMPLATE/scripts/lib.sh"

# validate_name <name>: dies unless the name is a safe directory/package name.
validate_name() {
  printf '%s' "$1" | grep -Eq '^[a-z][a-z0-9-]{1,50}$' ||
    die "invalid project name '$1' (use lowercase letters, digits, hyphens)"
}

# copy_template <destination>: copies template/ including dotfiles.
copy_template() {
  mkdir -p "$1"
  (cd "$TEMPLATE" && tar cf - --exclude=context-pack.md .) | (cd "$1" && tar xf -)
}

# fill_placeholders <dir> <name>: replaces {{PROJECT_NAME}} and {{DATE}} in text files.
fill_placeholders() {
  local dir=$1 name=$2 today file tmp
  today="$(date +%F)"
  grep -rlE '\{\{(PROJECT_NAME|DATE)\}\}' "$dir" | while IFS= read -r file; do
    tmp="$(mktemp)"
    sed -e "s/{{PROJECT_NAME}}/$name/g" -e "s/{{DATE}}/$today/g" "$file" >"$tmp"
    cat "$tmp" >"$file" # keep the original file mode
    rm -f "$tmp"
  done
}

# init_repository <dir>: git init, activate hooks, first commit.
init_repository() {
  local dir=$1
  git -C "$dir" init -q -b main
  "$dir/scripts/setup.sh" >/dev/null
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "chore: initialize project from vibe-coding scaffold"
}

main() {
  local name=${1:-} target
  [ -n "$name" ] || die "usage: scripts/new-project.sh <project-name> [target-dir]"
  validate_name "$name"
  target="${2:-$SCAFFOLD_ROOT/../$name}"
  [ ! -e "$target" ] || die "target already exists: $target"
  has_command git || die "git is required"

  copy_template "$target"
  target="$(cd "$target" && pwd)"
  fill_placeholders "$target" "$name"
  init_repository "$target"

  info "created $name at $target"
  echo "Next: open the folder in your LLM tool, then run the 'kickoff' prompt (prompts/kickoff.md)."
  echo "Obsidian: open the folder as a vault to review prompts."
}

main "$@"
