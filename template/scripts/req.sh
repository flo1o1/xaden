#!/usr/bin/env bash
# Looks up and creates requirements so nobody has to quote them from memory (REQ-047).
# Usage: scripts/req.sh list                          one line per requirement
#        scripts/req.sh show REQ-nnn                  the requirement file
#        scripts/req.sh new <epic> <job|quality> "<title>"   creates the next REQ-nnn as draft
#        scripts/req.sh index                         rewrites docs/requirements/INDEX.md
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"
# shellcheck source=SCRIPTDIR/requirements-lib.sh
source "$SCRIPTS/requirements-lib.sh"
layout_init "$ROOT"
DIR="$REQ_DIR"
# Text the new file starts with; check-requirements.sh warns until it is replaced.
TODO_JOB="TODO: When <situation>, I want to <motivation>, so I can <expected outcome>."
TODO_QUALITY="TODO: <measurable quality goal, e.g. \"95 % of searches answer within 1 s\">."
TODO_CRITERION="TODO: Given <context>, when <action>, then <observable result>."

# list_requirements: prints "ID [status, priority] title", sorted by ID.
list_requirements() {
  requirement_records "$DIR" | LC_ALL=C sort | awk -F'\t' '{ printf "%s [%s, %s] %s\n", $1, $2, $3, $6 }'
}

# show_requirement <REQ-nnn>: prints the path and the content of one requirement.
show_requirement() {
  local path
  path="$(requirement_path "$DIR" "$1")"
  printf 'File: %s\n\n' "${path#"$ROOT"/}"
  cat "$path"
}

# new_requirement <epic> <type> <title>: creates the next requirement as a draft and
# refreshes the index. Prints the new file's path.
new_requirement() {
  local epic=$1 type=$2 title=$3 id path statement="$TODO_JOB"
  is_epic_name "$epic" || die "epic must be lowercase words with dashes: $epic"
  case " $REQUIREMENT_TYPES " in *" $type "*) ;; *) die "type must be one of: $REQUIREMENT_TYPES" ;; esac
  [ -n "$title" ] || die "title is empty"
  [ "$type" = "quality" ] && statement="$TODO_QUALITY"
  write_epic "$DIR/$epic" "$epic" "TODO: The big job this epic serves (When …, I want to …, so I can …)."
  id="$(next_requirement_id "$DIR")"
  path="$DIR/$epic/$id-$(slugify "$title").md"
  write_requirement "$path" "$id" "$type" "$epic" "should" "draft" "$(date +%Y-%m-%d)" \
    "$title" "$statement" "$TODO_CRITERION"
  write_index
  printf '%s\n' "${path#"$ROOT"/}"
}

# write_index: regenerates INDEX.md from the requirement files.
write_index() {
  render_index "$DIR" >"$DIR/$INDEX_FILE"
}

[ -d "$DIR" ] || die "${DIR#"$ROOT"/} not found (old table format? run scripts/migrate-requirements.sh)"
case "${1:-}" in
  list) list_requirements ;;
  show) show_requirement "${2:-}" ;;
  new) new_requirement "${2:-}" "${3:-}" "${4:-}" ;;
  index) write_index && info "wrote ${DIR#"$ROOT"/}/$INDEX_FILE" ;;
  *) die "usage: scripts/req.sh list | show REQ-nnn | new <epic> <job|quality> \"<title>\" | index" ;;
esac
