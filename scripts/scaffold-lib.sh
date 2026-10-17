#!/usr/bin/env bash
# Scaffold-level helpers shared by new-project.sh and update-scaffold.sh. Source it.
# Requires template/scripts/lib.sh to be sourced first.

# Files the scaffold owns in generated projects (prefix match when ending in "/").
# Everything else (code, requirements, guides, README, CHANGELOG, VERSION, .gitignore,
# .env.example) belongs to the project and is never updated. .claude/settings.json is managed
# (REQ-059): a project that edited it keeps its file and gets <file>.scaffold-new to merge.
MANAGED_PATHS="scripts/ prompts/ presets/ .claude/commands/ .claude/settings.json .semgrep/ .github/workflows/
.github/copilot-instructions.md .continue/ .clinerules .aider.conf.yml .obsidian/app.json
.obsidian/core-plugins.json .obsidian/templates.json AGENTS.md CLAUDE.md docs/clean-code.md
docs/security.md docs/local-llm.md docs/optional-tools.md docs/decisions/0000-template.md docs/security-reviews/0000-template.md
docs/personas/0000-template.md
.editorconfig .gitattributes
inbox/README.md"

# Where a project records which scaffold version and files it was built from.
SCAFFOLD_STATE_DIR=".scaffold"

# is_project_name <name>: true for a safe directory/package name (lowercase letters, digits,
# hyphens; starts with a letter; 2-51 characters).
is_project_name() { printf '%s' "$1" | grep -Eq '^[a-z][a-z0-9-]{1,50}$'; }

# is_managed <relative-path>: true if the scaffold owns this path. Paths from a project's
# manifest are untrusted: a ".." segment could climb out of a managed folder (scripts/../src/x).
is_managed() {
  local managed
  case "/$1/" in */../*) return 1 ;; esac
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
      ! -name '*.scaffold-new' ! \( -path './inbox/*' ! -name README.md \) -print |
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
render_file() { fill_project_name "$2" <"$1"; }

# fill_project_name <project-name>: filter; replaces {{PROJECT_NAME}} on stdin. The name must
# pass is_project_name (it is used in a sed replacement). New projects and update checksums
# must render the same way, so this is the only place that fills the name.
fill_project_name() { sed -e "s/{{PROJECT_NAME}}/$1/g"; }

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

# --- versions and checksums (REQ-071, REQ-072) ------------------------------------------

# sha256_stdin: filter; the SHA-256 (hex) of stdin.
sha256_stdin() {
  if has_command sha256sum; then sha256sum | awk '{ print $1 }'; else shasum -a 256 | awk '{ print $1 }'; fi
}

# tree_checksum <dir>: SHA-256 over the paths and contents of the files of an Xaden tree.
# A git checkout counts its tracked files, an extracted release all files; both give the same
# value for the same release. The CI workflow of an adopted project recomputes it with the same
# find, sed, sort and sha256 steps (scripts/adopt/ci.yml).
tree_checksum() {
  (
    cd "$1" || return
    if [ -e .git ]; then git ls-files; else find . -type f | sed 's|^\./||'; fi |
      LC_ALL=C sort |
      while IFS= read -r file; do printf '%s  %s\n' "$(sha256_stdin <"$file")" "$file"; done |
      sha256_stdin
  )
}

# The installed versions of Xaden besides the one that runs: one folder per version.
xaden_home() { printf '%s' "${XADEN_HOME:-${XDG_DATA_HOME:-${HOME:?HOME is not set}/.local/share}/xaden}"; }
versions_dir() { printf '%s/versions' "$(xaden_home)"; }

# --- what an adopted project records outside xaden/ (REQ-073, REQ-080) ---------------------

FOOTPRINT_FILE="xaden/footprint.txt"

# note_footprint <dir> <kind> <path>: records a path outside xaden/ so `xaden remove` can undo it.
note_footprint() {
  mkdir -p "$1/xaden"
  grep -qxF "$2 $3" "$1/$FOOTPRINT_FILE" 2>/dev/null || printf '%s %s\n' "$2" "$3" >>"$1/$FOOTPRINT_FILE"
}

# command_name <prompt>: the slash command that starts a prompt. Every Xaden command carries the
# xaden- prefix (REQ-087), so it is told apart from the commands of other tools.
command_name() {
  case "$1" in
    code-review) echo xaden-review ;;
    security-review) echo xaden-security ;;
    requirements-update) echo xaden-requirements ;;
    documentation) echo xaden-docs ;;
    *) echo "xaden-$1" ;;
  esac
}

# command_kinds <assistants>: the command file layouts a comma separated list of assistants needs
# (REQ-080, REQ-081). Layouts checked against the vendors' documentation on 2026-10-16:
#   claude   .claude/commands/<name>.md          (REQ-080)
#   copilot  .github/prompts/<name>.prompt.md    https://code.visualstudio.com/docs/copilot/customization/prompt-files
#            front matter description/argument-hint; input is written ${input:task:...}; run as /<name>
#   skills   .agents/skills/<name>/SKILL.md      Mistral Vibe: https://docs.mistral.ai/vibe/code/cli/skills
#            (user-invocable, default true; the folder must be trusted); Codex CLI: https://learn.chatgpt.com/docs/build-skills
#            (name and description required; run as $<name> or /skills). Both read the same files.
# Codex documents no repository level custom slash commands or prompts, so a skill is its only mechanism.
command_kinds() {
  local kinds="" assistant kind
  for assistant in $(printf '%s' "$1" | tr ',' ' '); do
    case "$assistant" in
      claude) kind=claude ;;
      copilot) kind=copilot ;;
      vibe | codex) kind=skills ;;
      *) continue ;;
    esac
    case " $kinds " in *" $kind "*) ;; *) kinds="$kinds $kind" ;; esac
  done
  printf '%s' "${kinds# }"
}

# command_path <kind> <name>: where the command file of that layout lives.
command_path() {
  case "$1" in
    claude) echo ".claude/commands/$2.md" ;;
    copilot) echo ".github/prompts/$2.prompt.md" ;;
    skills) echo ".agents/skills/$2/SKILL.md" ;;
  esac
}

# command_text <kind> <name> <prompt> <title>: the whole file. Never the prompt text itself, so a
# team prompt in xaden/prompts/ is the one every assistant runs.
command_text() {
  local kind=$1 name=$2 prompt=$3 title=$4
  case "$kind" in
    claude)
      # shellcheck disable=SC2016 # $ARGUMENTS is text for the assistant, not for this shell
      printf -- '---\ndescription: %s\n---\n\nRun `xaden prompt %s` and follow it. Task input: $ARGUMENTS\n' "$title" "$prompt" ;;
    copilot)
      # shellcheck disable=SC2016 # ${input:...} is Copilot's variable syntax
      printf -- '---\ndescription: %s\nargument-hint: what the task is\n---\n\nRun `xaden prompt %s` and follow it. Task input: ${input:task:describe the task}\n' "$title" "$prompt" ;;
    skills)
      # shellcheck disable=SC2016 # the backticks are Markdown for the assistant, not command substitution
      printf -- '---\nname: %s\ndescription: %s. Use only when the user asks for it by name (%s).\n---\n\nRun `xaden prompt %s` and follow it. Task input: whatever the user wrote after the name.\n' \
        "$name" "$title" "$name" "$prompt" ;;
  esac
}

# sync_commands <dir> <tools-dir> <assistants>: makes the command files of those assistants match
# the prompts of those tools (REQ-080, REQ-081). A file that exists already is never overwritten;
# only the files the footprint lists as Xaden's own are removed when their prompt is gone.
sync_commands() {
  local dir=$1 tools=$2 assistants=$3 kind prompt name file wanted="" stale
  for kind in $(command_kinds "$assistants"); do
    for prompt in "$tools"/prompts/*.md; do
      prompt="$(basename "$prompt" .md)"
      [ "$prompt" != 00-index ] || continue
      name="$(command_name "$prompt")"
      file="$(command_path "$kind" "$name")"
      wanted="$wanted $file"
      if [ -e "$dir/$file" ]; then
        grep -qxF "file $file" "$dir/$FOOTPRINT_FILE" 2>/dev/null || info "skipped $file: it exists already and stays as it is"
        continue
      fi
      mkdir -p "$dir/$(dirname "$file")"
      command_text "$kind" "$name" "$prompt" "$(sed -n 's/^title: //p' "$tools/prompts/$prompt.md" | head -n 1)" >"$dir/$file"
      note_footprint "$dir" file "$file"
    done
  done
  stale="$(grep -E '^file (\.claude/commands/[a-z0-9-]+\.md|\.github/prompts/[a-z0-9-]+\.prompt\.md|\.agents/skills/[a-z0-9-]+/SKILL\.md)$' "$dir/$FOOTPRINT_FILE" 2>/dev/null | cut -d' ' -f2 || true)"
  for file in $stale; do
    case " $wanted " in *" $file "*) continue ;; esac
    rm -f "${dir:?}/$file"
    (cd "$dir" && rmdir -p "$(dirname "$file")" 2>/dev/null) || true
    grep -vxF "file $file" "$dir/$FOOTPRINT_FILE" >"$dir/$FOOTPRINT_FILE.new" || true
    mv "$dir/$FOOTPRINT_FILE.new" "$dir/$FOOTPRINT_FILE"
  done
}
