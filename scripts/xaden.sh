#!/usr/bin/env bash
# The `xaden` command (REQ-056): one entry point for the scaffold's scripts and the current
# project's own scripts, usable from any directory. scripts/install.sh links it onto PATH.
# Usage: xaden <command> [args...]   (`xaden help` lists the commands)
set -euo pipefail

# resolve_link <path>: follows symbolic links to the real file (older macOS has no readlink -f).
resolve_link() {
  local path=$1 target
  while [ -L "$path" ]; do
    target="$(readlink "$path")"
    case "$target" in
      /*) path=$target ;;
      *) path="$(dirname "$path")/$target" ;;
    esac
  done
  printf '%s' "$path"
}

SCAFFOLD_ROOT="$(cd "$(dirname "$(resolve_link "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$SCAFFOLD_ROOT/template/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: xaden <command> [args...]

Scaffold commands (any directory):
  new <name> [dir]   create a project in ./<name>, or in <dir>
  update [--apply]   bring the current project to this scaffold version (dry run without --apply)
  version            print the scaffold version
  help               show this list

Project commands (anywhere inside a project; run the project's own scripts/):
  setup              activate git hooks, report missing tools    scripts/setup.sh
  check [...]        static analysis (--staged, --strict)        scripts/check.sh
  req [...]          requirements: list, show, new, index         scripts/req.sh
  pack [--brief] [REQ-nnn...] [prompt...]
                     context pack for chat tools                  scripts/pack-context.sh
  release <part>     cut a release: major, minor or patch         scripts/release.sh
EOF
}

# project_root: the top of the git project around the current directory; dies outside one.
project_root() {
  git rev-parse --show-toplevel 2>/dev/null || die "run this inside a project (no git repository here)"
}

# run_project_script <script> [args...]: runs the current project's own scripts/<script>
# from the project root. This runs the project's code, as running the script by hand would.
run_project_script() {
  local script=$1 root
  shift
  root="$(project_root)"
  [ -x "$root/scripts/$script" ] || die "not a Xaden project: $root/scripts/$script is missing"
  cd "$root"
  exec "$root/scripts/$script" "$@"
}

main() {
  local command=${1:-help} root
  [ "$#" -gt 0 ] && shift
  case "$command" in
    new)
      [ -n "${1:-}" ] || die "usage: xaden new <name> [dir]"
      exec "$SCAFFOLD_ROOT/scripts/new-project.sh" "$1" "${2:-$PWD/$1}"
      ;;
    update)
      root="$(project_root)"
      exec "$SCAFFOLD_ROOT/scripts/update-scaffold.sh" "$root" "$@"
      ;;
    version) tr -d '[:space:]' <"$SCAFFOLD_ROOT/VERSION" && echo ;;
    help | -h | --help) usage ;;
    setup) run_project_script setup.sh "$@" ;;
    check) run_project_script check.sh "$@" ;;
    req) run_project_script req.sh "$@" ;;
    pack) run_project_script pack-context.sh "$@" ;;
    release) run_project_script release.sh "$@" ;;
    *)
      usage >&2
      die "unknown command: $command"
      ;;
  esac
}

main "$@"
