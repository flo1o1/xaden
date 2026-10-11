#!/usr/bin/env bash
# One-time setup after cloning the scaffold: activates the maintainer hooks in .githooks/
# and reports missing analysis tools. Usage: scripts/setup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
git -C "$ROOT" config core.hooksPath .githooks
chmod +x "$ROOT"/scripts/*.sh "$ROOT"/.githooks/* "$ROOT"/template/scripts/*.sh "$ROOT"/template/scripts/hooks/*
echo "==> scaffold hooks active (core.hooksPath = .githooks)"
"$ROOT/template/scripts/setup.sh" --tools-only
