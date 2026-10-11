#!/usr/bin/env bash
# Bundles rules + requirements + chosen prompt(s) into one pasteable Markdown block,
# for chat UIs without file access (ChatGPT, web UIs, small local models).
# Usage: scripts/pack-context.sh [prompt-name ...]   e.g. scripts/pack-context.sh feature
# Output: context-pack.md (gitignored); also copied to the clipboard if a tool exists.
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPTS/lib.sh"
OUT="$ROOT/context-pack.md"

# strip_frontmatter <file>: prints the file without a leading YAML block.
strip_frontmatter() {
  awk 'NR == 1 && $0 == "---" { skip = 1; next } skip && $0 == "---" { skip = 0; next } !skip' "$1"
}

# append_section <title> <file>: adds one titled section to the output.
append_section() {
  printf '\n# %s\n\n' "$1" >>"$OUT"
  strip_frontmatter "$2" >>"$OUT"
}

# copy_to_clipboard: best-effort, silent when no clipboard tool exists.
copy_to_clipboard() {
  if has_command pbcopy; then pbcopy <"$OUT"
  elif has_command wl-copy; then wl-copy <"$OUT"
  elif has_command xclip; then xclip -selection clipboard <"$OUT"
  else return 1
  fi
}

main() {
  local name
  : >"$OUT"
  {
    echo "# CONTEXT STATUS"
    echo
    "$SCRIPTS/context-status.sh"
    echo
    echo "INSTRUCTION: Begin your first reply with the exact line starting \"CONTEXT CHECK\" above."
    echo "Use ONLY the rules (CC-nn) and requirements (REQ-nnn) below. If something is not below, say so and ask."
  } >>"$OUT"
  append_section "PROJECT RULES (AGENTS.md)" "$ROOT/AGENTS.md"
  append_section "CLEAN CODE DETAILS (docs/clean-code.md)" "$ROOT/docs/clean-code.md"
  append_section "REQUIREMENTS" "$ROOT/docs/requirements/REQUIREMENTS.md"
  for name in "$@"; do
    printf '%s' "$name" | grep -Eq '^[a-z0-9-]+$' || die "invalid prompt name: $name"
    [ -f "$ROOT/prompts/$name.md" ] || die "no such prompt: prompts/$name.md"
    append_section "TASK PROMPT ($name)" "$ROOT/prompts/$name.md"
  done
  info "wrote $OUT ($(wc -c <"$OUT" | tr -d ' ') bytes)"
  copy_to_clipboard && info "copied to clipboard" || true
}

main "$@"
