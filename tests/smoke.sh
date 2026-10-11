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

# msg <text with \n escapes>: writes a commit message file (git passes a regular file to hooks); prints its path.
msg() {
  printf '%b' "$1" >"$WORKDIR/commit-msg.txt"
  printf '%s' "$WORKDIR/commit-msg.txt"
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
  assert "docs structure valid" "$PROJECT/scripts/check-docs.sh"
  assert_fails "docs check --release flags TODOs" "$PROJECT/scripts/check-docs.sh" --release
  assert "pack-context works" "$PROJECT/scripts/pack-context.sh" feature
  assert_fails "pack-context rejects path traversal" "$PROJECT/scripts/pack-context.sh" ../AGENTS
  assert_fails "bad commit message rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg "did stuff\n")"
  assert "feat with valid Refs accepted" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add endpoint\n\nRefs: REQ-001\n')"
  assert_fails "feat without Refs rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add endpoint\n')"
  assert_fails "invented requirement ID rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add x\n\nRefs: REQ-042\n')"
  assert_fails "invented rule ID rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'refactor: tidy per CC-77\n')"
  assert "fix with Refs none accepted" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'fix: typo\n\nRefs: none\n')"
  assert "req.sh shows known requirement" "$PROJECT/scripts/req.sh" show REQ-001
  assert_fails "req.sh rejects unknown requirement" "$PROJECT/scripts/req.sh" show REQ-999
  assert "context status lists rules" grep -q 'CC-09' <("$PROJECT/scripts/context-status.sh")
  assert "pack carries fingerprint and clean-code details" grep -q 'CLEAN CODE DETAILS' "$PROJECT/context-pack.md"

  sed 's/ draft / bogus /' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/bad.md"
  assert_fails "invalid requirement status rejected" "$PROJECT/scripts/check-requirements.sh" "$WORKDIR/bad.md"
}

test_setup_and_commit_checks() {
  git -C "$PROJECT" config --unset core.hooksPath
  assert "setup activates hooks" "$PROJECT/scripts/setup.sh"
  assert "hooks path restored" test "$(git -C "$PROJECT" config core.hooksPath)" = "scripts/hooks"
  assert "verify-commits accepts valid history" "$PROJECT/scripts/verify-commits.sh" HEAD~1..HEAD
  git -C "$PROJECT" commit -q --allow-empty --no-verify -m "feat: sneaked past hooks"
  assert_fails "verify-commits catches skipped hooks" "$PROJECT/scripts/verify-commits.sh" HEAD~1..HEAD
  git -C "$PROJECT" reset -q --hard HEAD~1
}

test_release() {
  assert_fails "release blocked by TODO markers in docs" "$PROJECT/scripts/release.sh" patch
  sed -i.bak '/TODO/d' "$PROJECT"/docs/*-guide.md && rm -f "$PROJECT"/docs/*.bak
  git -C "$PROJECT" commit -q -am "docs: fill guides"
  assert "release patch" "$PROJECT/scripts/release.sh" patch
  assert "VERSION bumped" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")" = "0.1.1"
  assert "guide stamped with version" grep -q 'Applies to version:\*\* 0.1.1' "$PROJECT/docs/user-guide.md"
  assert "tag created" git -C "$PROJECT" rev-parse v0.1.1
}

# git needs an identity inside the sandbox project.
export GIT_AUTHOR_NAME=smoke GIT_AUTHOR_EMAIL=smoke@example.invalid
export GIT_COMMITTER_NAME=smoke GIT_COMMITTER_EMAIL=smoke@example.invalid

test_bump_version
test_new_project
test_generated_project
test_setup_and_commit_checks
test_release
info "smoke test passed ($PASSED assertions)"
