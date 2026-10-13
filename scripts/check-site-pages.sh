#!/usr/bin/env bash
# Checks the contract with the website (REQ-064): every path in docs/site-pages.txt exists, and no
# workflow holds a credential for the site repository (the site fetches releases; we never push).
# Usage: scripts/check-site-pages.sh [scaffold-root]
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LIST="$ROOT/docs/site-pages.txt"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$ROOT/template/scripts/lib.sh"

[ -s "$LIST" ] || die "docs/site-pages.txt is missing or empty"
missing=0
while IFS= read -r page; do
  [ -f "$ROOT/$page" ] || { warn "site page missing: $page (listed in docs/site-pages.txt)"; missing=1; }
done <"$LIST"
[ "$missing" -eq 0 ] || exit 1

# Only the built-in GITHUB_TOKEN may appear; any other secret could be a site credential.
if grep -rnE 'secrets\.' "$ROOT/.github" 2>/dev/null | grep -v 'secrets\.GITHUB_TOKEN'; then
  die "workflow references a secret other than GITHUB_TOKEN; the scaffold must hold no site credential"
fi
info "site pages: $(wc -l <"$LIST" | tr -d ' ') present, no site credential"
