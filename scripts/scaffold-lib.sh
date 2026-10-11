#!/usr/bin/env bash
# Scaffold-level helpers shared by new-project.sh and update-scaffold.sh. Source it.
# Requires template/scripts/lib.sh to be sourced first.

# Files the scaffold owns in generated projects (prefix match when ending in "/").
# Everything else (code, requirements, guides, README, CHANGELOG, VERSION, .gitignore,
# .claude/settings.json, .env.example) belongs to the project and is never updated.
MANAGED_PATHS="scripts/ prompts/ presets/ .claude/commands/ .semgrep/ .github/workflows/
.github/copilot-instructions.md .continue/ .clinerules .aider.conf.yml .obsidian/app.json
.obsidian/core-plugins.json .obsidian/templates.json AGENTS.md CLAUDE.md docs/clean-code.md
docs/security.md docs/local-llm.md docs/optional-tools.md docs/decisions/0000-template.md docs/security-reviews/0000-template.md
.editorconfig .gitattributes
inbox/README.md"

# Where a project records which scaffold version and files it was built from.
SCAFFOLD_STATE_DIR=".scaffold"

# is_project_name <name>: true for a safe directory/package name (lowercase letters, digits,
# hyphens; starts with a letter; 2-51 characters).
is_project_name() { printf '%s' "$1" | grep -Eq '^[a-z][a-z0-9-]{1,50}$'; }

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

# export_template <source-dir> <destination-dir>: writes the reviewed template content.
# Policy (REQ-018):
# - In a git checkout: only files *tracked* under <source-dir> (committed or added), with
#   their working-tree content and modes, so maintainers can test edits before committing.
#   Untracked and ignored files (secrets, dependencies, drop-zone content) are never exported.
#   A warning names the case where uncommitted edits are included.
# - Outside git (e.g. a downloaded archive): all files except secrets, dependencies,
#   caches and drop-zone content.
# - Symbolic links are refused in both cases.
export_template() {
  local source=$1 destination=$2 repo prefix pathspec staging
  mkdir -p "$destination"
  if repo="$(git -C "$source" rev-parse --show-toplevel 2>/dev/null)"; then
    prefix="$(git -C "$source" rev-parse --show-prefix)"
    pathspec="${prefix:-.}" # git rejects an empty pathspec when exporting a repository root
    if git -C "$repo" ls-files -s -- "$pathspec" | awk '$1 == "120000" { found = 1 } END { exit !found }'; then
      die "template contains symbolic links; refusing to export"
    fi
    git -C "$repo" diff HEAD --quiet -- "$pathspec" 2>/dev/null ||
      warn "exporting uncommitted edits of tracked template files"
    staging="$(mktemp -d)"
    # Tracked paths that still exist in the working tree (deleted files are skipped).
    git -C "$repo" ls-files -z -- "$pathspec" | while IFS= read -r -d '' file; do
      if [ -f "$repo/$file" ]; then printf '%s\n' "$file"; fi
    done | (cd "$repo" && tar cf - -T -) | (cd "$staging" && tar xf -)
    (cd "$staging/$prefix" && tar cf - .) | (cd "$destination" && tar xf -)
    rm -rf "$staging"
  else
    [ -z "$(cd "$source" && find . -type l | head -n 1)" ] || die "template contains symbolic links; refusing to export"
    (cd "$source" && find . \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ \) -prune -o \
      -type f ! -name .DS_Store ! -name .env ! \( -name '.env.*' ! -name .env.example \) \
      ! -name '*.scaffold-new' ! -name context-pack.md ! \( -path './inbox/*' ! -name README.md \) -print |
      tar cf - -T -) | (cd "$destination" && tar xf -)
  fi
}

# template_files <exported-template-dir>: relative paths of all files, sorted.
# Only use on a directory produced by export_template.
template_files() {
  (cd "$1" && find . -type f | sed 's|^\./||' | sort)
}

# keep_managed: filter; prints the paths read from stdin (one per line) the scaffold manages.
keep_managed() {
  local file
  while IFS= read -r file; do
    if is_managed "$file"; then printf '%s\n' "$file"; fi
  done
}

# managed_template_files <template-dir>: template files the scaffold manages.
managed_template_files() { template_files "$1" | keep_managed; }

# render_file <source> <project-name>: prints a template file with placeholders filled.
render_file() { sed -e "s/{{PROJECT_NAME}}/$2/g" "$1"; }

# content_sum: checksum of stdin (POSIX cksum: CRC and size).
content_sum() { cksum | awk '{ print $1 "-" $2 }'; }

# has_symlink_on_path <root> <relative-path>: true if the path or any directory between <root>
# and it is a symbolic link. Writing there could leave <root>: a project's committed files are
# untrusted (security review 2026-10-11).
has_symlink_on_path() {
  local current=$1 rest=$2
  while [ -n "$rest" ]; do
    current="$current/${rest%%/*}"
    [ -L "$current" ] && return 0
    case "$rest" in */*) rest=${rest#*/} ;; *) rest="" ;; esac
  done
  return 1
}

# refuse_symlink_on_path <root> <relative-path>: dies before a write that could leave <root>.
refuse_symlink_on_path() {
  ! has_symlink_on_path "$1" "$2" || die "refusing to write through a symbolic link: $2"
}

# write_manifest <project-dir> <template-dir> <project-name> <scaffold-version>:
# records the checksum of every managed file as the template renders it now.
write_manifest() {
  local project=$1 template=$2 name=$3 version=$4 file
  for file in version project-name manifest; do refuse_symlink_on_path "$project" "$SCAFFOLD_STATE_DIR/$file"; done
  mkdir -p "$project/$SCAFFOLD_STATE_DIR"
  printf '%s\n' "$version" >"$project/$SCAFFOLD_STATE_DIR/version"
  printf '%s\n' "$name" >"$project/$SCAFFOLD_STATE_DIR/project-name"
  managed_template_files "$template" | while IFS= read -r file; do
    printf '%s\t%s\n' "$(render_file "$template/$file" "$name" | content_sum)" "$file"
  done >"$project/$SCAFFOLD_STATE_DIR/manifest"
}
