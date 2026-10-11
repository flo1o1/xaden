#!/usr/bin/env bash
# Smoke test for the scaffold: generates a project and exercises its tooling.
# Usage: tests/smoke.sh   (works on Linux and macOS; needs git)
set -euo pipefail

SCAFFOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCAFFOLD_ROOT/scripts/lib.sh"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
PROJECT="$WORKDIR/demo-app"
PASSED=0

# assert <description> <command...>: runs the command, dies if it fails.
assert() {
  local description=$1
  shift
  if ("$@") >/dev/null 2>&1; then
    PASSED=$((PASSED + 1))
    printf 'ok   %s\n' "$description"
  else
    die "FAILED: $description"
  fi
}

# assert_fails <description> <command...>: command must exit non-zero.
assert_fails() {
  local description=$1
  shift
  if ("$@") >/dev/null 2>&1; then die "FAILED (expected failure): $description"; fi
  PASSED=$((PASSED + 1))
  printf 'ok   %s\n' "$description"
}

test_bump_version() {
  assert "bump patch" test "$(bump_version 1.2.3 patch)" = "1.2.4"
  assert "bump minor resets patch" test "$(bump_version 1.2.3 minor)" = "1.3.0"
  assert "bump major resets rest" test "$(bump_version 1.2.3 major)" = "2.0.0"
  assert_fails "reject invalid semver" bump_version "1.2" patch
}

test_new_project() {
  assert_fails "reject bad project name" "$SCAFFOLD_ROOT/scripts/new-project.sh" "Bad Name" "$WORKDIR/x"
  assert "create project" "$SCAFFOLD_ROOT/scripts/new-project.sh" demo-app "$PROJECT"
  assert "no placeholders left" test -z "$(grep -rl '{{PROJECT_NAME}}' "$PROJECT" --exclude-dir=.git || true)"
  assert "scaffold-only files removed" test ! -e "$PROJECT/tests"
  assert "own git repo with first commit" git -C "$PROJECT" log --oneline -1
  assert "hooks path configured" test "$(git -C "$PROJECT" config core.hooksPath)" = "scripts/hooks"
}

test_generated_project() {
  assert "checks pass" "$PROJECT/scripts/check.sh"
  assert "pack-context works" "$PROJECT/scripts/pack-context.sh" feature
  assert_fails "pack-context rejects path traversal" "$PROJECT/scripts/pack-context.sh" ../AGENTS
  assert_fails "bad commit message rejected" "$PROJECT/scripts/hooks/commit-msg" <(echo "did stuff")
  assert "good commit message accepted" "$PROJECT/scripts/hooks/commit-msg" <(echo "feat(api): add endpoint")

  sed 's/ draft / bogus /' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/bad.md"
  assert_fails "invalid requirement status rejected" "$PROJECT/scripts/check-requirements.sh" "$WORKDIR/bad.md"
}

test_release() {
  assert "release patch" "$PROJECT/scripts/release.sh" patch
  assert "VERSION bumped" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")" = "0.1.1"
  assert "tag created" git -C "$PROJECT" rev-parse v0.1.1
}

# git needs an identity inside the sandbox project.
export GIT_AUTHOR_NAME=smoke GIT_AUTHOR_EMAIL=smoke@example.invalid
export GIT_COMMITTER_NAME=smoke GIT_COMMITTER_EMAIL=smoke@example.invalid

test_bump_version
test_new_project
test_generated_project
test_release
info "smoke test passed ($PASSED assertions)"
