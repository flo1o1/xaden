#!/usr/bin/env bash
# Installs the `xaden` command (REQ-056): a symbolic link to this checkout's scripts/xaden.sh
# in a directory on PATH. Writes nothing else; `git pull` in the checkout updates the command.
# Usage: scripts/install.sh [--uninstall] [bin-dir]   (default bin-dir: ~/.local/bin)
set -euo pipefail

SCAFFOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$SCAFFOLD_ROOT/template/scripts/lib.sh"

COMMAND_NAME="xaden"
COMMAND_SCRIPT="$SCAFFOLD_ROOT/scripts/xaden.sh"

# is_our_link <path>: true if <path> is a symbolic link to this checkout's command script.
is_our_link() { [ -L "$1" ] && [ "$(readlink "$1")" = "$COMMAND_SCRIPT" ]; }

# install_link <bin-dir>: creates the link; never replaces another file of that name.
install_link() {
  local link="$1/$COMMAND_NAME"
  if is_our_link "$link"; then
    info "already installed: $link"
  else
    [ ! -e "$link" ] && [ ! -L "$link" ] || die "$link exists and is not this checkout's xaden; left unchanged"
    mkdir -p "$1"
    ln -s "$COMMAND_SCRIPT" "$link"
    info "installed $link -> $COMMAND_SCRIPT"
  fi
  case ":$PATH:" in
    *":$1:"*) ;;
    *) warn "$1 is not on PATH; add this line to your shell profile: export PATH=\"$1:\$PATH\"" ;;
  esac
}

# uninstall_link <bin-dir>: removes the link only if it points to this checkout.
uninstall_link() {
  local link="$1/$COMMAND_NAME"
  is_our_link "$link" || die "$link is not a link to $COMMAND_SCRIPT; left unchanged"
  rm "$link"
  info "removed $link"
}

main() {
  local uninstall=0 bin_dir="" arg
  for arg in "$@"; do
    case "$arg" in
      --uninstall) uninstall=1 ;;
      -*) die "usage: scripts/install.sh [--uninstall] [bin-dir]" ;;
      *) bin_dir=$arg ;;
    esac
  done
  bin_dir="${bin_dir:-${HOME:?HOME is not set}/.local/bin}"
  if [ "$uninstall" = "1" ]; then uninstall_link "$bin_dir"; else install_link "$bin_dir"; fi
}

main "$@"
