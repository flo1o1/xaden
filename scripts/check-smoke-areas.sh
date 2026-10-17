#!/usr/bin/env bash
# Checks that AGENTS.md has a row for every smoke area (REQ-092), so the list of what each area
# covers cannot go stale. An area is a file tests/smoke/<area>.sh; its row starts with | `<area>` |.
# Usage: scripts/check-smoke-areas.sh [scaffold-root]
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$ROOT/template/scripts/lib.sh"

missing=0
count=0
for file in "$ROOT"/tests/smoke/*.sh; do
  area="$(basename "$file" .sh)"
  [ "$area" = lib ] && continue
  count=$((count + 1))
  grep -qF "| \`$area\` |" "$ROOT/AGENTS.md" || { warn "smoke area $area has no row in AGENTS.md"; missing=1; }
done
[ "$missing" -eq 0 ] || exit 1
info "smoke areas: $count, each with a row in AGENTS.md"
