#!/usr/bin/env bash
# Creates a new project from this scaffold in a fresh directory with its own git repo.
# Usage: scripts/new-project.sh <project-name> [target-dir]
#   project-name: lowercase letters, digits, hyphens (2-51 chars), starts with a letter
#   target-dir:   defaults to ../<project-name>; must not exist yet
set -euo pipefail

SCAFFOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCAFFOLD_ROOT/scripts/lib.sh"

# Files that belong to the scaffold itself, not to generated projects.
SCAFFOLD_ONLY="tests scripts/new-project.sh README.md GETTING-STARTED.md CHANGELOG.md VERSION"

# validate_name <name>: dies unless the name is a safe directory/package name.
validate_name() {
  printf '%s' "$1" | grep -Eq '^[a-z][a-z0-9-]{1,50}$' ||
    die "invalid project name '$1' (use lowercase letters, digits, hyphens)"
}

# copy_scaffold <destination>: copies tracked scaffold content, without git history.
copy_scaffold() {
  mkdir -p "$1"
  (cd "$SCAFFOLD_ROOT" && tar cf - --exclude=.git --exclude=context-pack.md .) | (cd "$1" && tar xf -)
}

# remove_scaffold_only <dir>: deletes files that only make sense in the scaffold.
remove_scaffold_only() {
  local item
  for item in $SCAFFOLD_ONLY; do rm -rf "${1:?}/$item"; done
}

# fill_placeholders <dir> <name>: replaces {{PROJECT_NAME}} and {{DATE}} in text files.
fill_placeholders() {
  local dir=$1 name=$2 today file tmp
  today="$(date +%F)"
  # grep -l lists only files that actually contain a placeholder.
  grep -rlE '\{\{(PROJECT_NAME|DATE)\}\}' "$dir" --exclude-dir=.git | while IFS= read -r file; do
    tmp="$(mktemp)"
    sed -e "s/{{PROJECT_NAME}}/$name/g" -e "s/{{DATE}}/$today/g" "$file" >"$tmp"
    cat "$tmp" >"$file" # keep the original file mode
    rm -f "$tmp"
  done
}

# write_project_files <dir>: fresh README, VERSION and CHANGELOG for the new project.
write_project_files() {
  local dir=$1
  mv "$dir/scripts/README.project.tpl" "$dir/README.md"
  printf '0.1.0\n' >"$dir/VERSION"
  cat >"$dir/CHANGELOG.md" <<EOF
# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Project created from vibe-coding scaffold.
EOF
}

# init_repository <dir>: git init, install hooks, first commit.
init_repository() {
  local dir=$1
  git -C "$dir" init -q -b main
  git -C "$dir" config core.hooksPath scripts/hooks
  chmod +x "$dir"/scripts/*.sh "$dir"/scripts/hooks/*
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

  copy_scaffold "$target"
  target="$(cd "$target" && pwd)"
  remove_scaffold_only "$target"
  write_project_files "$target"
  fill_placeholders "$target" "$name"
  init_repository "$target"

  info "created $name at $target"
  echo "Next: open the folder in your LLM tool, then run the 'kickoff' prompt (prompts/kickoff.md)."
  echo "Obsidian: open the folder as a vault to review prompts."
}

main "$@"
