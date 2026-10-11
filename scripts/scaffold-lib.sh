#!/usr/bin/env bash
# Scaffold-level helpers shared by new-project.sh and update-scaffold.sh. Source it.
# Requires template/scripts/lib.sh to be sourced first.

# Files the scaffold owns in generated projects (prefix match when ending in "/").
# Everything else (code, requirements, guides, README, CHANGELOG, VERSION, .gitignore,
# .claude/settings.json, .env.example) belongs to the project and is never updated.
MANAGED_PATHS="scripts/ prompts/ presets/ .claude/commands/ .semgrep/ .github/workflows/
.github/copilot-instructions.md .continue/ .clinerules .aider.conf.yml .obsidian/app.json
.obsidian/core-plugins.json .obsidian/templates.json AGENTS.md CLAUDE.md docs/clean-code.md
docs/security.md docs/local-llm.md docs/decisions/0000-template.md .editorconfig .gitattributes"

# Where a project records which scaffold version and files it was built from.
SCAFFOLD_STATE_DIR=".scaffold"

# is_managed <relative-path>: true if the scaffold owns this path.
is_managed() {
  local managed
  for managed in $MANAGED_PATHS; do
    case "$managed" in
      */) case "$1" in "$managed"*) return 0 ;; esac ;;
      *) [ "$1" = "$managed" ] && return 0 ;;
    esac
  done
  return 1
}

# template_files <template-dir>: tracked and new (not ignored) files, relative paths, sorted.
# Falls back to find when the template is not inside a git checkout.
template_files() {
  if git -C "$1" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$1" ls-files --cached --others --exclude-standard
  else
    (cd "$1" && find . -type f ! -name '.DS_Store' | sed 's|^\./||')
  fi | while IFS= read -r file; do
    if [ -f "$1/$file" ]; then printf '%s\n' "$file"; fi
  done | sort -u
}

# managed_template_files <template-dir>: template files the scaffold manages.
managed_template_files() {
  template_files "$1" | while IFS= read -r file; do
    if is_managed "$file"; then printf '%s\n' "$file"; fi
  done
}

# render_file <source> <project-name>: prints a template file with placeholders filled.
render_file() { sed -e "s/{{PROJECT_NAME}}/$2/g" "$1"; }

# content_sum: checksum of stdin (POSIX cksum: CRC and size).
content_sum() { cksum | awk '{ print $1 "-" $2 }'; }

# write_manifest <project-dir> <template-dir> <project-name> <scaffold-version>:
# records the checksum of every managed file as the template renders it now.
write_manifest() {
  local project=$1 template=$2 name=$3 version=$4 file
  mkdir -p "$project/$SCAFFOLD_STATE_DIR"
  printf '%s\n' "$version" >"$project/$SCAFFOLD_STATE_DIR/version"
  printf '%s\n' "$name" >"$project/$SCAFFOLD_STATE_DIR/project-name"
  managed_template_files "$template" | while IFS= read -r file; do
    printf '%s\t%s\n' "$(render_file "$template/$file" "$name" | content_sum)" "$file"
  done >"$project/$SCAFFOLD_STATE_DIR/manifest"
}
