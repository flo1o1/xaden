#!/usr/bin/env bash
# Smoke test for the scaffold: generates a project and exercises its tooling.
# Usage: tests/smoke.sh   (needs git)
# REQ-009: .github/workflows/scaffold-ci.yml runs this file on ubuntu-latest and macos-latest.
set -euo pipefail

SCAFFOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$SCAFFOLD_ROOT/template/scripts/lib.sh"

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

# REQ-007 semantic versioning
test_bump_version() {
  assert "bump patch" test "$(bump_version 1.2.3 patch)" = "1.2.4"
  assert "bump minor resets patch" test "$(bump_version 1.2.3 minor)" = "1.3.0"
  assert "bump major resets rest" test "$(bump_version 1.2.3 major)" = "2.0.0"
  assert_fails "reject invalid semver" bump_version "1.2" patch
}

# REQ-001 project creation, REQ-013 template separation
test_new_project() {
  assert_fails "reject bad project name" "$SCAFFOLD_ROOT/scripts/new-project.sh" "Bad Name" "$WORKDIR/x"
  assert "create project" "$SCAFFOLD_ROOT/scripts/new-project.sh" demo-app "$PROJECT"
  assert "no placeholders left" test -z "$(grep -rl '{{PROJECT_NAME}}' "$PROJECT" --exclude-dir=.git || true)"
  assert "scaffold-only files not copied" test ! -e "$PROJECT/tests" -a ! -e "$PROJECT/template" -a ! -e "$PROJECT/scripts/new-project.sh"
  assert "project gets template rules" grep -q 'CC-09' "$PROJECT/AGENTS.md"
  assert "own git repo with first commit" git -C "$PROJECT" log --oneline -1
  assert "hooks path configured" test "$(git -C "$PROJECT" config core.hooksPath)" = "scripts/hooks"
}

# REQ-004 static analysis, REQ-006 requirements tracking, REQ-010 docs, REQ-011 grounding, REQ-002 chat context pack
test_generated_project() {
  assert "checks pass" "$PROJECT/scripts/check.sh"
  assert "docs structure valid" "$PROJECT/scripts/check-docs.sh"
  assert_fails "docs check --release flags TODOs" "$PROJECT/scripts/check-docs.sh" --release
  assert "pack-context works" "$PROJECT/scripts/pack-context.sh" feature
  assert_fails "pack-context rejects path traversal" "$PROJECT/scripts/pack-context.sh" ../AGENTS
  assert_fails "bad commit message rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg "did stuff\n")"
  assert "feat with valid Refs accepted" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add endpoint\n\nRefs: REQ-001\n')"
  assert_fails "feat without Refs rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add endpoint\n')"
  assert_fails "invented requirement ID rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add x\n\nRefs: REQ-042\n')" # traceability: ignore
  assert_fails "invented rule ID rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'refactor: tidy per CC-77\n')"
  assert "fix with Refs none accepted" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'fix: typo\n\nRefs: none\n')"
  assert "req.sh shows known requirement" "$PROJECT/scripts/req.sh" show REQ-001
  assert_fails "req.sh rejects unknown requirement" "$PROJECT/scripts/req.sh" show REQ-999 # traceability: ignore
  assert "context status lists rules" grep -q 'CC-09' <("$PROJECT/scripts/context-status.sh")
  assert "pack carries fingerprint and clean-code details" grep -q 'CLEAN CODE DETAILS' "$PROJECT/context-pack.md"

  sed 's/ draft / bogus /' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/bad.md"
  assert_fails "invalid requirement status rejected" "$PROJECT/scripts/check-requirements.sh" "$WORKDIR/bad.md"
}

# REQ-012 usable by others (setup after clone, CI commit checks)
test_setup_and_commit_checks() {
  git -C "$PROJECT" config --unset core.hooksPath
  assert "setup activates hooks" "$PROJECT/scripts/setup.sh"
  assert "hooks path restored" test "$(git -C "$PROJECT" config core.hooksPath)" = "scripts/hooks"
  assert "verify-commits accepts valid history" "$PROJECT/scripts/verify-commits.sh" HEAD~1..HEAD
  git -C "$PROJECT" commit -q --allow-empty --no-verify -m "feat: sneaked past hooks"
  assert_fails "verify-commits catches skipped hooks" "$PROJECT/scripts/verify-commits.sh" HEAD~1..HEAD
  git -C "$PROJECT" reset -q --hard HEAD~1
}

# REQ-014 fast offline pre-commit, REQ-005 security (SAST blocks eval)
test_staged_checks() {
  printf 'x = 1\n' >"$PROJECT/clean.py"
  git -C "$PROJECT" add clean.py
  assert "staged check passes on clean file" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
  if has_command semgrep; then
    printf 'def run(user_input):\n    return eval(user_input)\n' >"$PROJECT/unsafe.py"
    git -C "$PROJECT" add unsafe.py
    assert_fails "staged check blocks eval via local semgrep rule" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
  fi
  git -C "$PROJECT" reset -q --hard
  rm -f "$PROJECT/clean.py" "$PROJECT/unsafe.py"
}

# REQ-003 clean-code rules, REQ-015 linter presets and mandatory stack checks
test_stack_enforcement() {
  if has_command ruff; then
    printf '[project]\nname = "demo"\nversion = "0.1.0"\n' >"$PROJECT/pyproject.toml"
    printf '"""Demo."""\n' >"$PROJECT/ok.py"
    git -C "$PROJECT" add pyproject.toml ok.py
    assert_fails "python without ruff config fails" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
    assert "python preset applies" "$PROJECT/scripts/apply-preset.sh" python
    printf '"""Demo."""\n\n\ndef f(a, b, c, d, e):\n    """Too many args."""\n    return a\n' >"$PROJECT/bad.py"
    git -C "$PROJECT" add ruff.toml bad.py
    assert_fails "preset rejects too many parameters (CC-01)" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
    git -C "$PROJECT" rm -q --cached bad.py
    assert "preset accepts clean code" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
    git -C "$PROJECT" reset -q --hard && git -C "$PROJECT" clean -qfd
  fi
  if has_command npm; then
    (cd "$PROJECT" && npm init -y >/dev/null)
    git -C "$PROJECT" add package.json
    assert_fails "node without lint script fails" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
    git -C "$PROJECT" reset -q --hard && git -C "$PROJECT" clean -qfd
  fi
}

# REQ-007 release, REQ-010 docs gate
test_release() {
  assert_fails "release blocked by TODO markers in docs" "$PROJECT/scripts/release.sh" patch
  sed -i.bak '/TODO/d' "$PROJECT"/docs/*-guide.md && rm -f "$PROJECT"/docs/*.bak
  git -C "$PROJECT" commit -q -am "docs: fill guides"
  assert "release patch" "$PROJECT/scripts/release.sh" patch
  assert "VERSION bumped" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")" = "0.1.1"
  assert "guide stamped with version" grep -q 'Applies to version:\*\* 0.1.1' "$PROJECT/docs/user-guide.md"
  assert "tag created" git -C "$PROJECT" rev-parse v0.1.1
}

# REQ-002 tool-agnostic rules, REQ-005 security review, REQ-008 Obsidian vault
test_template_contents() {
  local pointer
  for pointer in CLAUDE.md .clinerules .continue/rules/project.md .github/copilot-instructions.md .aider.conf.yml; do
    assert "$pointer points to AGENTS.md" grep -q 'AGENTS.md' "$PROJECT/$pointer"
  done
  assert "/security command uses alice skill with fallback" grep -q 'alice-security-engineer' "$PROJECT/.claude/commands/security.md"
  assert "tool-agnostic security prompt present" grep -q 'OWASP' "$PROJECT/prompts/security-review.md"
  assert "Obsidian vault configured" test -f "$PROJECT/.obsidian/app.json"
  assert "every prompt has frontmatter" bash -c "cd '$PROJECT/prompts' && for f in *.md; do head -1 \"\$f\" | grep -qx -- '---' || exit 1; done"
}

# REQ-016 traceability
test_traceability() {
  sed 's/| must     | draft  |/| must     | done   |/' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/req.md"
  cp "$WORKDIR/req.md" "$PROJECT/docs/requirements/REQUIREMENTS.md"
  assert_fails "done requirement without test fails" "$PROJECT/scripts/check-traceability.sh"
  mkdir -p "$PROJECT/tests"
  printf '# REQ-001\n' >"$PROJECT/tests/test_first.py"
  git -C "$PROJECT" add tests/test_first.py
  assert "done requirement with test passes" "$PROJECT/scripts/check-traceability.sh"
  assert "matrix lists the test" grep -q 'tests/test_first.py' <("$PROJECT/scripts/check-traceability.sh" --matrix)
  printf '# REQ-123\n' >"$PROJECT/tests/test_ghost.py" # traceability: ignore
  git -C "$PROJECT" add tests/test_ghost.py
  assert_fails "test citing unknown requirement fails" "$PROJECT/scripts/check-traceability.sh"
  git -C "$PROJECT" reset -q --hard && git -C "$PROJECT" clean -qfd
}

# git needs an identity inside the sandbox project.
export GIT_AUTHOR_NAME=smoke GIT_AUTHOR_EMAIL=smoke@example.invalid
export GIT_COMMITTER_NAME=smoke GIT_COMMITTER_EMAIL=smoke@example.invalid

test_bump_version
test_new_project
test_template_contents
test_generated_project
test_setup_and_commit_checks
test_staged_checks
test_stack_enforcement
test_traceability
test_release
info "smoke test passed ($PASSED assertions)"
