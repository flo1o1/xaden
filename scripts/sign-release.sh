#!/usr/bin/env bash
# Signs a release of Xaden (maintainers). Writes dist/xaden-<version>.checksum, the tree checksum of
# the tagged release, and dist/xaden-<version>.checksum.sig, its SSH signature. `xaden fetch` and
# `xaden upgrade` verify the signature with the public keys in `release-signers` and pin the signed
# checksum, so nobody has to trust the first download. Never uploads: it prints the command.
# Usage: XADEN_SIGNING_KEY=<private ssh key> scripts/sign-release.sh <version>   (the tag v<version> must exist)
# Set up the key once: docs/release-signing.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$ROOT/template/scripts/lib.sh"
# shellcheck source=SCRIPTDIR/scaffold-lib.sh
source "$ROOT/scripts/scaffold-lib.sh"

SIGNATURE_NAMESPACE="xaden-release"

main() {
  local version=${1:-} key=${XADEN_SIGNING_KEY:-} staging out
  is_semver "$version" || die "usage: XADEN_SIGNING_KEY=<key> scripts/sign-release.sh <version>"
  [ -f "$key" ] || die "XADEN_SIGNING_KEY must name your private SSH key file (docs/release-signing.md)"
  has_command ssh-keygen || die "ssh-keygen is required"
  git -C "$ROOT" rev-parse -q --verify "refs/tags/v$version" >/dev/null || die "tag v$version does not exist"
  staging="$(mktemp -d)"
  trap 'rm -rf "${staging:?}"' EXIT
  git -C "$ROOT" archive "v$version" | tar -x -C "$staging"
  out="$ROOT/dist"
  mkdir -p "$out"
  printf '%s  xaden-%s\n' "$(tree_checksum "$staging")" "$version" >"$out/xaden-$version.checksum"
  rm -f "$out/xaden-$version.checksum.sig"
  ssh-keygen -q -Y sign -f "$key" -n "$SIGNATURE_NAMESPACE" "$out/xaden-$version.checksum"
  ok "signed: $out/xaden-$version.checksum and .sig"
  echo "Publish both files with the release (this uploads, so it is your call):"
  echo "  gh release upload v$version dist/xaden-$version.checksum dist/xaden-$version.checksum.sig"
}

main "$@"
