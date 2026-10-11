#!/usr/bin/env bash
# Prints rule IDs, requirement IDs and a fingerprint of the rule/requirement files. The
# assistant quotes the CONTEXT CHECK line in its first reply; the user compares it with their
# own run to spot stale or missing context. A consistency aid only: a matching fingerprint
# does not prove that the files were read or followed.
# Usage: scripts/context-status.sh
set -euo pipefail

# SCRIPTS: where the tooling lives. ROOT: the repository it works on; PROJECT_ROOT lets
# another repository (e.g. the scaffold itself) reuse these scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPTS/.." && pwd)}"
RULES_FILES=("$ROOT/AGENTS.md" "$ROOT/docs/clean-code.md" "$ROOT/docs/requirements/REQUIREMENTS.md")

# fingerprint: CRC of all rule and requirement files (POSIX cksum, same on Linux and macOS).
fingerprint() { cat "${RULES_FILES[@]}" | cksum | cut -d' ' -f1; }

# rule_ids: defined rule IDs, e.g. "CC-01 CC-02 ...".
rule_ids() { grep -oE '^- \*\*CC-[0-9]{2}\*\*' "$ROOT/AGENTS.md" | grep -oE 'CC-[0-9]{2}' | tr '\n' ' '; }

# requirement_ids: "REQ-001(draft) REQ-002(done) ...".
requirement_ids() { "$SCRIPTS/req.sh" list | sed -E 's/^(REQ-[0-9]+) \[([^,]*),.*/\1(\2)/' | tr '\n' ' '; }

echo "CONTEXT CHECK $(fingerprint)"
echo "rules: $(rule_ids)"
echo "requirements: $(requirement_ids)"
