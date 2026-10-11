#!/usr/bin/env bash
# One-time setup after cloning: activates git hooks and reports missing tools.
# Installs nothing itself; prints the install commands for this OS instead.
# Usage: scripts/setup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"

REQUIRED_TOOLS="bash git awk sed tar grep cksum"
RECOMMENDED_TOOLS="shellcheck gitleaks semgrep"

# activate_hooks: points git at the versioned hooks (git config is not cloned).
activate_hooks() {
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository: $ROOT"
  git -C "$ROOT" config core.hooksPath scripts/hooks
  chmod +x "$ROOT"/scripts/*.sh "$ROOT"/scripts/hooks/*
  info "git hooks active (core.hooksPath = scripts/hooks)"
}

# missing_tools <list>: prints the tools from <list> that are not on PATH.
missing_tools() {
  local tool
  for tool in $1; do has_command "$tool" || printf '%s ' "$tool"; done
}

# install_hint <tools>: prints an install command for the current OS.
install_hint() {
  case "$(uname -s)" in
    Darwin) echo "  brew install $1" ;;
    Linux)
      echo "  shellcheck: sudo apt-get install shellcheck  (or dnf/pacman)"
      echo "  semgrep:    pipx install semgrep"
      echo "  gitleaks:   https://github.com/gitleaks/gitleaks/releases (or: brew install gitleaks)"
      ;;
    *) echo "  unsupported OS: use WSL or Git Bash on Windows" ;;
  esac
}

main() {
  local missing
  missing="$(missing_tools "$REQUIRED_TOOLS")"
  [ -z "$missing" ] || die "required tools missing: $missing"

  activate_hooks

  missing="$(missing_tools "$RECOMMENDED_TOOLS")"
  if [ -n "$missing" ]; then
    warn "recommended tools missing (checks will be skipped): $missing"
    install_hint "$missing"
  else
    info "all recommended analysis tools found"
  fi
  echo "Language tools (ruff, mypy, npm, ...) are checked by scripts/check.sh once your stack exists."
}

main "$@"
