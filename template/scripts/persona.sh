#!/usr/bin/env bash
# Creates a user persona from docs/personas/0000-template.md (REQ-061).
# Usage: scripts/persona.sh new "<name>"   creates docs/personas/<slug>.md; prints its path
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
DIR="$PERSONAS_DIR"
# An adopted project has no copy of the template: the installed Xaden provides it.
TEMPLATE="$DIR/0000-template.md"
[ -f "$TEMPLATE" ] || TEMPLATE="$TOOLS_DIR/docs/personas/0000-template.md"
# More personas dilute the checks; fewer miss whole user groups.
RECOMMENDED_MAXIMUM=5
NAME_LENGTH=60

# persona_count: number of persona files, without the template.
persona_count() {
  find "$DIR" -maxdepth 1 -name '*.md' ! -name '0000-template.md' | wc -l | tr -d ' '
}

# new_persona <name>: copies the template with name and date filled in; prints the new path.
new_persona() {
  local name=$1 slug path
  [ -n "$name" ] || die "usage: scripts/persona.sh new \"<name>\""
  # Validated so it is safe as a sed replacement and a YAML value: one line, no / \ & or :.
  if [ "${#name}" -gt "$NAME_LENGTH" ] || [ "$(printf '%s\n' "$name" | wc -l)" -ne 1 ] \
    || printf '%s' "$name" | grep -q '[/\\&:]'; then
    die "name must be one line of at most $NAME_LENGTH characters without / \\ & or :"
  fi
  slug="$(slugify "$name")"
  [ -n "$slug" ] || die "name gives an empty file name: $name"
  [ -f "$TEMPLATE" ] || die "persona template not found (update the scaffold)"
  mkdir -p "$DIR"
  path="$DIR/$slug.md"
  # -L too: -e follows a dangling link, and writing through it would leave the project.
  if [ -e "$path" ] || [ -L "$path" ]; then die "persona exists already: ${path#"$ROOT"/}"; fi
  sed -e "s/{{PERSONA_NAME}}/$name/g" -e "s/{{PERSONA_DATE}}/$(date +%Y-%m-%d)/g" "$TEMPLATE" >"$path"
  if [ "$(persona_count)" -gt "$RECOMMENDED_MAXIMUM" ]; then
    warn "$(persona_count) personas; 3 to $RECOMMENDED_MAXIMUM keep the checks focused. Merge similar ones."
  fi
  printf '%s\n' "${path#"$ROOT"/}"
}

case "${1:-}" in
  new) new_persona "${2:-}" ;;
  *) die "usage: scripts/persona.sh new \"<name>\"" ;;
esac
