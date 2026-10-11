#!/usr/bin/env bash
# Prints what an assistant must have loaded: rule IDs, requirement IDs, a fingerprint of the
# rule/requirement files. The assistant quotes the CONTEXT CHECK line in its first reply, so the
# user can compare it with their own run of this script and spot a model working from memory.
# Usage: scripts/context-status.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULES_FILES=("$ROOT/AGENTS.md" "$ROOT/docs/clean-code.md" "$ROOT/docs/requirements/REQUIREMENTS.md")

# fingerprint: CRC of all rule and requirement files (POSIX cksum, same on Linux and macOS).
fingerprint() { cat "${RULES_FILES[@]}" | cksum | cut -d' ' -f1; }

# rule_ids: defined rule IDs, e.g. "CC-01 CC-02 ...".
rule_ids() { grep -oE '^- \*\*CC-[0-9]{2}\*\*' "$ROOT/AGENTS.md" | grep -oE 'CC-[0-9]{2}' | tr '\n' ' '; }

# requirement_ids: "REQ-001(draft) REQ-002(done) ...".
requirement_ids() { "$ROOT/scripts/req.sh" list | sed -E 's/^(REQ-[0-9]+) \[([^,]*),.*/\1(\2)/' | tr '\n' ' '; }

echo "CONTEXT CHECK $(fingerprint)"
echo "rules: $(rule_ids)"
echo "requirements: $(requirement_ids)"
