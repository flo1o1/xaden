#!/usr/bin/env bash
# Sets up a plain new project in the recommended way after one confirmation (REQ-076).
# Usage: xaden new --autopilot [--stack python|node] [--assistants <list>] <name> [dir]
# It prints one plan with everything it will do and asks once. A yes applies the plan; anything
# else changes nothing. It never pushes, never publishes, and downloads nothing: the commands that
# install the development tools are printed for you to run. A folder that already holds code, a
# build file or history is a job for `xaden adopt`: autopilot stops there and changes nothing.
# shellcheck disable=SC2034 # TOOLS_DIR is read by layout.sh, ADOPT_PRESET by the steps in adopt-lib.sh
set -euo pipefail

SCAFFOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$SCAFFOLD_ROOT/template/scripts/lib.sh"
# shellcheck source=SCRIPTDIR/../template/scripts/requirements-lib.sh
source "$SCAFFOLD_ROOT/template/scripts/requirements-lib.sh"
# shellcheck source=SCRIPTDIR/scaffold-lib.sh
source "$SCAFFOLD_ROOT/scripts/scaffold-lib.sh"
# shellcheck source=SCRIPTDIR/adopt-scan.sh
source "$SCAFFOLD_ROOT/scripts/adopt-scan.sh"
# shellcheck source=SCRIPTDIR/adopt-lib.sh
source "$SCAFFOLD_ROOT/scripts/adopt-lib.sh"

TOOLS_DIR="$SCAFFOLD_ROOT/template"
STACK=""
ADOPT_PRESET=""
NAME=""
TARGET=""

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --autopilot) ;;
      --stack)
        shift
        case "${1:-}" in python | node) STACK=$1 ;; *) die "--stack must be python or node" ;; esac ;;
      --assistants)
        shift
        printf '%s' "${1:-}" | grep -Eq '^[a-z0-9]+(,[a-z0-9]+)*$' || die "--assistants takes a comma separated list such as claude,codex"
        ADOPT_ASSISTANTS=$1 ;;
      -*) die "unknown option: $1" ;;
      *) if [ -z "$NAME" ]; then NAME=$1; elif [ -z "$TARGET" ]; then TARGET=$1; else die "too many arguments"; fi ;;
    esac
    shift
  done
  [ -n "$NAME" ] || die "usage: xaden new --autopilot [--stack python|node] <name> [dir]"
  is_project_name "$NAME" || die "invalid project name '$NAME' (use lowercase letters, digits, hyphens)"
  TARGET="${TARGET:-$PWD/$NAME}"
}

# refuse_existing_work: a folder with code, a build file or history is for `xaden adopt`.
refuse_existing_work() {
  [ -e "$TARGET" ] || return 0
  [ -d "$TARGET" ] || die "$TARGET exists and is not a folder"
  if [ -n "$(find "$TARGET" -mindepth 1 -maxdepth 1 ! -name .git | head -n 1)" ] ||
    git -C "$TARGET" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    warn "$TARGET already contains code, a build file or history. Nothing was changed."
    echo "Use 'cd $TARGET && xaden adopt' to add Xaden to it." >&2
    exit 2
  fi
}

# choose_stack: from --stack, else one question per stack.
choose_stack() {
  [ -z "$STACK" ] || return 0
  has_terminal || die "name the stack: xaden new --autopilot --stack python|node $NAME"
  if ask "Is this a Python project?"; then STACK=python
  elif ask "Is this a Node (JavaScript or TypeScript) project?"; then STACK=node
  else die "autopilot knows python and node; for other stacks use: xaden new $NAME"
  fi
}

# print_plan: everything the run will do.
print_plan() {
  info "autopilot plan for $NAME ($STACK) in $TARGET"
  cat <<EOF
  1. git init (branch main) and a first commit with the layout below
  2. xaden/: requirements, personas, security reviews, baselines, xaden.conf (Xaden $(running_version) pinned with its checksum), RULES.md
  3. AGENTS.md with the Xaden block${ADOPT_ASSISTANTS:+, CLAUDE.md for: $ADOPT_ASSISTANTS}
  4. the $STACK preset: $(preset_files "$STACK" | tr '\n' ' ')
  5. checks mapped in xaden.conf: $(preset_commands "$STACK" | sed 's/^/check./;s/=/ = /' | tr '\n' ';')
  6. mode strict: every violation fails; no baseline is needed in a new project
  7. git hooks of this clone (pre-commit, commit-msg) that run the checks
  8. a CI workflow, .github/workflows/xaden.yml, pinned to Xaden $(running_version) and its checksum
  Install commands (printed at the end; you run them, Xaden does not):
    $(preset_install_command "$STACK")
  Packages and versions: only those above; a package added later needs its own approval.
  Nothing is pushed, published or downloaded.
EOF
}

# apply_autopilot: the plan, in the new folder.
apply_autopilot() {
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
  git -C "$TARGET" init -q -b main
  ADOPT_REPO="$TARGET"
  ADOPT_MODE=strict
  ADOPT_DEFAULT_BRANCH=main
  SCAN_STACKS=$STACK SCAN_CONVENTION=conventional SCAN_TEST="" SCAN_LINT="" SCAN_TYPECHECK=""
  SCAN_GAPS="$(expected_kinds)"
  ADOPT_PRESET=$STACK
  apply_core "$TARGET"
  commit_step "$TARGET" "chore: initialize project with Xaden $(running_version)"
  apply_ci "$TARGET"
  commit_step "$TARGET" "ci: run Xaden's checks in a workflow"
  apply_preset "$TARGET" "$STACK"
  commit_step "$TARGET" "chore: add Xaden's $STACK preset"
  install_local_hooks "$TARGET"
}

# summary: what exists, and an honest result of the checks (REQ-074: skipped checks end with a warning).
summary() {
  local result
  info "created in $TARGET"
  git -C "$TARGET" ls-files | sed 's/^/  /'
  info "install the development tools (run this yourself):"
  echo "  cd $TARGET && $(preset_install_command "$STACK")"
  info "checks now"
  result="$(cd "$TARGET" && PROJECT_ROOT="$TARGET" "$SCAFFOLD_ROOT/template/scripts/check.sh" 2>&1)" || true
  printf '%s\n' "$result" | grep -E '^==> summary|SKIPPED|INCOMPLETE|failed|gap:' || true
  if printf '%s' "$result" | grep -Eq 'INCOMPLETE|SKIPPED|, [1-9][0-9]* failed|[1-9][0-9]* check\(s\) failed'; then
    warn "not all checks pass or ran yet: install the tools above, write the first test (xaden prompt kickoff), then run: xaden check"
  else
    ok "all checks passed"
  fi
}

main() {
  parse_arguments "$@"
  has_command git || die "git is required"
  refuse_existing_work
  choose_stack
  print_plan
  if ! has_terminal; then
    echo "No terminal, so nothing was changed. Run it in a terminal to confirm the plan."
    return 0
  fi
  ask "Create $NAME with this setup?" || { echo "Nothing was changed."; return 0; }
  apply_autopilot
  summary
}

main "$@"
