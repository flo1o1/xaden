#!/usr/bin/env bash
# Smoke test for the scaffold: generates a project and exercises its tooling.
# Usage: tests/smoke.sh   (needs git)
# REQ-009: .github/workflows/scaffold-ci.yml runs this file on ubuntu-latest and macos-latest.
set -euo pipefail

SCAFFOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../template/scripts/lib.sh
source "$SCAFFOLD_ROOT/template/scripts/lib.sh"
# shellcheck source=SCRIPTDIR/../scripts/scaffold-lib.sh
source "$SCAFFOLD_ROOT/scripts/scaffold-lib.sh"

# REQ-025: isolated from the user's git configuration; failures show the command output;
# SMOKE_REQUIRE_TOOLS=1 (set in CI) turns tool-dependent skips into failures.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
# Strictness is chosen per test call; an inherited STRICT=1 (CI) must not leak into fixtures.
unset STRICT
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
PROJECT="$WORKDIR/demo app/demo-app" # space in the path on purpose (REQ-018)
mkdir -p "$(dirname "$PROJECT")"
OUTPUT="$WORKDIR/last-command.log"
PASSED=0
SKIPPED=0

# show_output: prints the tail of the last command's output (diagnostics on failure).
show_output() {
  echo "----- output of the failed command (last 40 lines) -----" >&2
  tail -n 40 "$OUTPUT" >&2
  echo "--------------------------------------------------------" >&2
}

# assert <description> <command...>: runs the command, dies with its output if it fails.
assert() {
  local description=$1
  shift
  if ("$@") >"$OUTPUT" 2>&1; then
    PASSED=$((PASSED + 1))
    printf 'ok   %s\n' "$description"
  else
    show_output
    die "FAILED: $description"
  fi
}

# assert_fails <description> <command...>: command must exit non-zero.
assert_fails() {
  local description=$1
  shift
  if ("$@") >"$OUTPUT" 2>&1; then
    show_output
    die "FAILED (expected failure): $description"
  fi
  PASSED=$((PASSED + 1))
  printf 'ok   %s\n' "$description"
}

# need_tool <tool> <what>: true if available; otherwise skip visibly, or fail in CI.
need_tool() {
  has_command "$1" && return 0
  [ "${SMOKE_REQUIRE_TOOLS:-0}" = "1" ] && die "required tool missing in CI: $1 ($2)"
  SKIPPED=$((SKIPPED + 1))
  printf 'SKIP %s (%s not installed)\n' "$2" "$1"
  return 1
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

# REQ-038 MIT license for the scaffold only
test_license() {
  assert "scaffold is MIT licensed" grep -qx 'MIT License' "$SCAFFOLD_ROOT/LICENSE"
  assert "generated projects do not inherit the scaffold license" test ! -e "$PROJECT/LICENSE"
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
  assert_fails "feat citing a draft requirement rejected (REQ-021)" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add endpoint\n\nRefs: REQ-001\n')"
  sed 's/| must     | draft  |/| must     | approved |/' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/approved.md"
  cp "$WORKDIR/approved.md" "$PROJECT/docs/requirements/REQUIREMENTS.md"
  git -C "$PROJECT" add docs/requirements/REQUIREMENTS.md
  assert "feat citing an approved requirement accepted" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add endpoint\n\nRefs: REQ-001\n')"
  git -C "$PROJECT" reset -q --hard
  assert_fails "feat without Refs rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add endpoint\n')"
  assert_fails "invented requirement ID rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat(api): add x\n\nRefs: REQ-042\n')" # traceability: ignore
  assert_fails "invented rule ID rejected" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'refactor: tidy per CC-77\n')"
  assert "fix with Refs none accepted" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'fix: typo\n\nRefs: none\n')"
  assert "req.sh shows known requirement" "$PROJECT/scripts/req.sh" show REQ-001
  assert_fails "req.sh rejects unknown requirement" "$PROJECT/scripts/req.sh" show REQ-999 # traceability: ignore
  assert "context status lists rules" grep -q 'CC-09' <("$PROJECT/scripts/context-status.sh")
  assert "pack carries fingerprint and clean-code details" grep -q 'CLEAN CODE DETAILS' "$PROJECT/context-pack.md"
  # REQ-023 complete and safely written pack
  assert "pack includes the security checklist" grep -q 'Secure coding checklist' "$PROJECT/context-pack.md"
  assert "pack includes unreleased changes" grep -q 'Project created from vibe-coding scaffold' "$PROJECT/context-pack.md"
  assert "pack lists what it excludes" grep -q 'NOT INCLUDED' "$PROJECT/context-pack.md"
  # REQ-028 threat model at kickoff
  assert "project has a threat model with an ASVS level" grep -q 'ASVS level' "$PROJECT/docs/threat-model.md"
  assert "kickoff fills the threat model" grep -q 'docs/threat-model.md' "$PROJECT/prompts/kickoff.md"
  assert "security review reads the threat model" grep -q 'docs/threat-model.md' "$PROJECT/prompts/security-review.md"
  assert "pack includes the threat model" grep -q '^# PROJECT DOCUMENT (docs/threat-model.md)' "$PROJECT/context-pack.md"
  mv "$PROJECT/docs/threat-model.md" "$WORKDIR/threat-model.md"
  assert "pack names a missing threat model" bash -c "'$PROJECT/scripts/pack-context.sh' && grep -q 'threat-model.md (MISSING' '$PROJECT/context-pack.md'"
  mv "$WORKDIR/threat-model.md" "$PROJECT/docs/threat-model.md"
  # REQ-029 precise security checklist
  local topic
  for topic in 'not a replacement' 'DNS rebinding' 'hard links' 'size limit before reading' \
    'tenant A cannot reach' 'revoke sessions' 'Password reset' 'Rate and resource limits' \
    'Safe parsing' 'Data retention' '## Web applications \*(web)\*'; do
    assert "security checklist covers: $topic" grep -q "$topic" "$PROJECT/docs/security.md"
  done
  # REQ-039 WSTG test areas missing so far, in checklist and review prompt
  for topic in 'open redirect' 'parameter pollution' 'response splitting' 'request smuggling' \
    'LDAP' 'file inclusion' 'vertical privilege escalation' 'user enumeration' 'default or shared accounts' \
    'session tokens in URLs' 'Strict-Transport-Security' '\.git/' 'is public: no secrets there' \
    'at rest' 'separate origin' 'upload frequency' 'Anti-automation' 'LIKE' 'ReDoS' 'audit trail' \
    'Separate duties' 'postMessage' 'localStorage' 'PCI DSS'; do
    assert "security checklist covers: $topic" grep -qi "$topic" "$PROJECT/docs/security.md"
  done
  for topic in 'open redirects' 'privilege escalation' 'user enumeration' 'ReDoS' 'request' \
    'smuggling' 'postMessage' 'segregation of duties'; do
    assert "security review checks: $topic" grep -qi "$topic" "$PROJECT/prompts/security-review.md"
  done
  assert_fails "obsolete technologies left out" grep -Eqi 'flash|silverlight|cvss v2' "$PROJECT/docs/security.md" "$PROJECT/prompts/security-review.md"
  # REQ-030 dependency policy with accountable exceptions
  for topic in '^## Dependencies' 'Lockfiles' 'Licenses' 'install scripts' 'Updates'; do
    assert "dependency policy covers: $topic" grep -q "$topic" "$PROJECT/docs/security.md"
  done
  assert "exceptions need owner and expiry" grep -q '| Owner | Expires (YYYY-MM-DD) |' "$PROJECT/docs/security-exceptions.md"
  assert "release prompt blocks on expired exceptions" grep -q 'security-exceptions.md' "$PROJECT/prompts/release.md"
  # REQ-031 vulnerability reporting and incident policy
  for topic in '^## Reporting a vulnerability' '^## Secret rotation' '^## Incident response basics' 'SBOM'; do
    assert "SECURITY.md covers: $topic" grep -q "$topic" "$PROJECT/SECURITY.md"
  done
  # REQ-032 recorded security review reports
  for topic in '^## Scope' '^## Evidence' '^## Limitations' '^## Findings' '^## Remediation summary'; do
    assert "review report template has: $topic" grep -q "$topic" "$PROJECT/docs/security-reviews/0000-template.md"
  done
  assert "review prompt writes the report" grep -q 'docs/security-reviews/0000-template.md' "$PROJECT/prompts/security-review.md"
  assert "review prompt says a checklist is not proof" grep -q 'not proof of security' "$PROJECT/prompts/security-review.md"
  assert "review template is updated with the scaffold" is_managed docs/security-reviews/0000-template.md
  local owned
  for owned in SECURITY.md docs/threat-model.md docs/security-exceptions.md; do
    assert_fails "$owned is project-owned, never overwritten by updates" is_managed "$owned"
  done
  # REQ-042 architecture document with rules for new code
  local section
  for section in '^## Layers and dependency direction' '^## Composition root' '^## Rules for new code' '^## Third-party code'; do
    assert "architecture template has: $section" grep -q "$section" "$PROJECT/docs/architecture.md"
  done
  # REQ-043 versioned persisted data, migrations without data loss
  for section in 'carries a version' 'migrates older versions automatically' 'only that part is dropped' \
    'Keep the old data until' 'migration test' 'breaking change (major version)'; do
    assert "architecture migration rules: $section" grep -q "$section" "$PROJECT/docs/architecture.md"
  done
  assert "clean-code guide points to the migration rules" grep -q 'migration rules in .docs/architecture.md.' "$PROJECT/docs/clean-code.md"
  assert "release prompt counts format changes as breaking" grep -q 'stored or exchanged data formats' "$PROJECT/prompts/release.md"
  assert "kickoff fills the architecture" grep -q 'docs/architecture.md' "$PROJECT/prompts/kickoff.md"
  assert "feature prompt follows the rules for new code" grep -q 'Rules for new code' "$PROJECT/prompts/feature.md"
  assert "code review checks layering" grep -q 'docs/architecture.md' "$PROJECT/prompts/code-review.md"
  assert "pack includes the architecture" grep -q '^# PROJECT DOCUMENT (docs/architecture.md)' "$PROJECT/context-pack.md"
  assert_fails "architecture is project-owned, never overwritten by updates" is_managed docs/architecture.md
  "$PROJECT/scripts/pack-context.sh" feature >/dev/null 2>&1
  cp "$PROJECT/context-pack.md" "$WORKDIR/pack-before.md"
  assert_fails "unknown prompt name rejected" "$PROJECT/scripts/pack-context.sh" feature no-such-prompt
  assert "failed pack keeps the previous pack" cmp -s "$PROJECT/context-pack.md" "$WORKDIR/pack-before.md"

  sed 's/ draft / bogus /' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/bad.md"
  assert_fails "invalid requirement status rejected" "$PROJECT/scripts/check-requirements.sh" "$WORKDIR/bad.md"
  # REQ-021 complete fields and real dates
  awk -F'|' 'BEGIN { OFS = "|" } /^\| REQ-001/ { $6 = " " } { print }' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/empty-acceptance.md"
  assert_fails "empty acceptance criteria rejected" "$PROJECT/scripts/check-requirements.sh" "$WORKDIR/empty-acceptance.md"
  awk -F'|' 'BEGIN { OFS = "|" } /^\| REQ-001/ { $7 = " not-a-date " } { print }' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/bad-date.md"
  assert_fails "invalid date rejected" "$PROJECT/scripts/check-requirements.sh" "$WORKDIR/bad-date.md"
  awk -F'|' 'BEGIN { OFS = "|" } /^\| REQ-001/ { $7 = " {{DATE}} " } { print }' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/placeholder-date.md"
  assert_fails "unfilled date placeholder rejected in projects" "$PROJECT/scripts/check-requirements.sh" "$WORKDIR/placeholder-date.md"
  assert_fails "placeholder requirement blocks a release" "$PROJECT/scripts/check-requirements.sh" --release
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
  if need_tool semgrep "staged SAST fixture"; then
    printf 'def run(user_input):\n    return eval(user_input)\n' >"$PROJECT/unsafe.py"
    git -C "$PROJECT" add unsafe.py
    assert_fails "staged check blocks eval via local semgrep rule" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
    # REQ-040 the new rules ship with projects and run in the pre-commit check
    printf 'from flask import redirect, request\n\n\ndef go():\n    return redirect(request.args.get("next"))\n' >"$PROJECT/unsafe.py"
    git -C "$PROJECT" add unsafe.py
    assert_fails "staged check blocks an open redirect via local semgrep rule" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
  fi
  git -C "$PROJECT" reset -q --hard
  rm -f "$PROJECT/clean.py" "$PROJECT/unsafe.py"
}

# REQ-003 clean-code rules, REQ-015 linter presets and mandatory stack checks
test_stack_enforcement() {
  if need_tool ruff "python preset fixture"; then
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
  if need_tool npm "node stack fixture"; then
    (cd "$PROJECT" && npm init -y >/dev/null)
    git -C "$PROJECT" add package.json
    assert_fails "node without lint script fails" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
    git -C "$PROJECT" reset -q --hard && git -C "$PROJECT" clean -qfd
  fi
}

# REQ-024 releases never leave a partial state
test_release_failures() {
  local head hooks="$WORKDIR/failing-hooks"
  head="$(git -C "$PROJECT" rev-parse HEAD)"
  git -C "$PROJECT" tag v0.1.1
  assert_fails "existing tag aborts the release" "$PROJECT/scripts/release.sh" patch
  assert "nothing changed after tag conflict" test "$(git -C "$PROJECT" rev-parse HEAD)$(git -C "$PROJECT" status --porcelain)" = "$head"
  git -C "$PROJECT" tag -d v0.1.1 >/dev/null
  mkdir -p "$hooks" && printf '#!/bin/sh\nexit 1\n' >"$hooks/pre-commit" && chmod +x "$hooks/pre-commit"
  git -C "$PROJECT" config core.hooksPath "$hooks"
  assert_fails "failing release commit aborts" "$PROJECT/scripts/release.sh" patch
  assert "files restored after failed commit" test "$(git -C "$PROJECT" rev-parse HEAD)$(git -C "$PROJECT" status --porcelain)" = "$head"
  git -C "$PROJECT" config core.hooksPath scripts/hooks
  chmod 500 "$PROJECT/.git/refs/tags"
  assert "failed tag is reported with recovery steps" bash -c "! '$PROJECT/scripts/release.sh' patch 2>&1 | tee '$WORKDIR/tag-fail.log' >/dev/null; grep -q 'PARTIAL RELEASE' '$WORKDIR/tag-fail.log'"
  chmod 700 "$PROJECT/.git/refs/tags"
  git -C "$PROJECT" reset -q --hard "$head"
}

# REQ-007 release, REQ-010 docs gate
test_release() {
  assert_fails "release blocked by TODO markers in docs" "$PROJECT/scripts/release.sh" patch
  sed 's/Describe the first requirement here/Users can export data as CSV/' \
    "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/real-req.md"
  cp "$WORKDIR/real-req.md" "$PROJECT/docs/requirements/REQUIREMENTS.md"
  git -C "$PROJECT" commit -q -am "docs(requirements): replace placeholder"
  if need_tool gitleaks "release without scanner fixture"; then
    sed -i.bak '/TODO/d' "$PROJECT"/docs/*-guide.md && rm -f "$PROJECT"/docs/*.bak
    git -C "$PROJECT" commit -q -am "docs: fill guides"
    assert_fails "release fails when a required scanner is missing" bash -c "PATH='$(path_without gitleaks)' '$PROJECT/scripts/release.sh' patch"
    assert "failed release left VERSION unchanged" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")" = "0.1.0"
    git -C "$PROJECT" reset -q --hard HEAD~1
  fi
  sed -i.bak '/TODO/d' "$PROJECT"/docs/*-guide.md && rm -f "$PROJECT"/docs/*.bak
  git -C "$PROJECT" commit -q -am "docs: fill guides"
  test_release_failures
  assert "release patch" "$PROJECT/scripts/release.sh" patch
  assert "VERSION bumped" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")" = "0.1.1"
  assert "guide stamped with version" grep -q 'Applies to version:\*\* 0.1.1' "$PROJECT/docs/user-guide.md"
  assert "tag created" git -C "$PROJECT" rev-parse v0.1.1
}

# REQ-018 safe generation: a git copy of the scaffold with junk that must never be copied
test_generation_safety() {
  local source="$WORKDIR/source-scaffold" target="$WORKDIR/safety/generated app"
  export_template "$SCAFFOLD_ROOT" "$source"
  git -C "$source" init -q -b main && git -C "$source" add -A && git -C "$source" commit -q -m "chore: fixture"
  printf 'SECRET=fixture\n' >"$source/template/.env"
  printf 'private\n' >"$source/template/local-private-note.txt"
  mkdir -p "$source/template/node_modules/pkg" && printf 'x\n' >"$source/template/node_modules/pkg/index.js"
  printf 'dropped\n' >"$source/template/inbox/dropped.txt"
  printf '\nUNCOMMITTED EDIT\n' >>"$source/template/prompts/bugfix.md"
  local before
  before="$(git -C "$source" status --porcelain)"
  assert "generate from git source with junk" "$source/scripts/new-project.sh" safe-app "$target"
  assert "untracked private file not copied" test ! -e "$target/local-private-note.txt"
  assert ".env not copied" test ! -e "$target/.env"
  assert "node_modules not copied" test ! -e "$target/node_modules"
  assert "inbox content not copied" test ! -e "$target/inbox/dropped.txt"
  assert "uncommitted edit of tracked file copied (maintainer testing)" grep -q 'UNCOMMITTED EDIT' "$target/prompts/bugfix.md"
  assert "executable bits preserved" test -x "$target/scripts/check.sh"
  assert "source left untouched" test "$(git -C "$source" status --porcelain)" = "$before"
  assert_fails "existing target refused" "$source/scripts/new-project.sh" safe-app "$target"
  ln -s ../README.md "$source/template/link.md" && git -C "$source" add template/link.md
  assert_fails "symlink in template refused" "$source/scripts/new-project.sh" link-app "$WORKDIR/link-app"
  assert "nothing created when export is refused" test ! -e "$WORKDIR/link-app"
  git -C "$source" rm -q --cached template/link.md && rm "$source/template/link.md"
  sed 's/| draft  |/| bogus  |/' "$source/template/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/bad-req.md"
  cp "$WORKDIR/bad-req.md" "$source/template/docs/requirements/REQUIREMENTS.md"
  assert_fails "generation fails when the first commit is rejected" "$source/scripts/new-project.sh" late-fail "$WORKDIR/late-fail"
  assert "partial project removed after late failure" test ! -e "$WORKDIR/late-fail"
}

# path_without <tool>: prints a PATH where every command except <tool> is available.
path_without() {
  local bin="$WORKDIR/path-without-$1" dir file
  mkdir -p "$bin"
  local IFS=:
  for dir in $PATH; do
    for file in "$dir"/*; do
      [ -x "$file" ] && [ ! -e "$bin/${file##*/}" ] && [ "${file##*/}" != "$1" ] && ln -s "$file" "$bin/${file##*/}"
    done
  done
  printf '%s' "$bin"
}

# REQ-019 required checks cannot be skipped silently
test_missing_tools() {
  need_tool gitleaks "missing-scanner fixture" || return 0
  local restricted
  restricted="$(path_without gitleaks)"
  assert "local check reports INCOMPLETE without gitleaks" bash -c "cd '$PROJECT' && PATH='$restricted' scripts/check.sh 2>&1 | grep -q 'INCOMPLETE'"
  assert_fails "strict check fails without gitleaks" bash -c "cd '$PROJECT' && PATH='$restricted' scripts/check.sh --strict"
  assert "summary lists the skipped check" bash -c "cd '$PROJECT' && PATH='$restricted' scripts/check.sh 2>&1 | grep -q 'skipped: secret scan'"
}

# REQ-020 staged snapshot: checks and commit-msg validate what will be committed
test_staged_snapshot() {
  local requirements="$PROJECT/docs/requirements/REQUIREMENTS.md" before_status before_diff
  cp "$requirements" "$WORKDIR/req-original.md"
  # staged content broken, working tree fixed: must fail
  sed 's/| draft  |/| bogus  |/' "$WORKDIR/req-original.md" >"$requirements"
  git -C "$PROJECT" add docs/requirements/REQUIREMENTS.md
  cp "$WORKDIR/req-original.md" "$requirements"
  before_status="$(git -C "$PROJECT" status --porcelain)"
  before_diff="$(git -C "$PROJECT" diff)"
  assert_fails "staged invalid requirement not hidden by unstaged fix" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
  assert "working tree and index untouched by staged check" test "$(git -C "$PROJECT" status --porcelain)$(git -C "$PROJECT" diff)" = "$before_status$before_diff"
  git -C "$PROJECT" reset -q --hard
  # staged content fine, working tree broken: must pass
  sed 's/| draft  |/| bogus  |/' "$WORKDIR/req-original.md" >"$requirements"
  assert "unstaged breakage does not fail the staged check" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
  git -C "$PROJECT" checkout -q -- docs
  if need_tool semgrep "staged SAST snapshot fixture"; then
    printf 'def run(user_input):\n    return eval(user_input)\n' >"$PROJECT/hidden.py"
    git -C "$PROJECT" add hidden.py
    printf 'def run(user_input):\n    return user_input\n' >"$PROJECT/hidden.py"
    assert_fails "staged eval not hidden by unstaged fix" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
    git -C "$PROJECT" reset -q --hard && git -C "$PROJECT" clean -qfd
  fi
  # requirement only in the working tree cannot validate a commit
  awk '{ print } /^\| REQ-001/ { print "| REQ-002 | Second | must | approved | Testable | 2026-10-11 |" }' \
    "$WORKDIR/req-original.md" >"$requirements"
  assert_fails "REQ only in unstaged file rejected by commit-msg" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat: x\n\nRefs: REQ-002\n')"
  git -C "$PROJECT" add docs/requirements/REQUIREMENTS.md
  assert "same REQ accepted once staged" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat: x\n\nRefs: REQ-002\n')"
  git -C "$PROJECT" reset -q --hard
}

# REQ-022 commit reference checks cannot be bypassed
test_commit_bypasses() {
  local hook="$PROJECT/scripts/hooks/commit-msg" zero="0000000000000000000000000000000000000000" before_bad
  assert_fails "Merge prefix cannot smuggle an unknown ID" "$hook" "$(msg 'Merge branch x\n\nRefs: REQ-777\n')" # traceability: ignore
  assert_fails "fixup! prefix cannot smuggle an unknown ID" "$hook" "$(msg 'fixup! feat: x\n\nSee REQ-778\n')" # traceability: ignore
  assert "plain Merge message still accepted" "$hook" "$(msg 'Merge branch x\n')"
  sed 's/| must     | draft  |/| must     | approved |/' "$PROJECT/docs/requirements/REQUIREMENTS.md" >"$WORKDIR/approved.md"
  cp "$WORKDIR/approved.md" "$PROJECT/docs/requirements/REQUIREMENTS.md"
  git -C "$PROJECT" commit -q -am "docs(requirements): approve REQ-001"
  assert "Refs in prose is not a trailer" bash -c "'$hook' '$(msg 'feat: x\n\nRefs: REQ-001\n\nMore prose after it.\n')' 2>&1 | grep -q \"need a 'Refs: REQ-nnn' trailer\""
  # A first push with a bad commit in the middle: every introduced commit is checked.
  before_bad="$(git -C "$PROJECT" rev-parse HEAD)"
  git -C "$PROJECT" commit -q --allow-empty --no-verify -m "feat: no refs in the middle"
  git -C "$PROJECT" commit -q --allow-empty -m "docs: fine on top"
  assert_fails "CI first push checks the whole new history" \
    env EVENT_NAME=push BEFORE_SHA="$zero" DEFAULT_BRANCH=main "$PROJECT/scripts/verify-commits.sh" --ci
  git -C "$PROJECT" update-ref refs/remotes/origin/main "$before_bad"
  assert_fails "CI pull request range includes the bad commit" \
    env EVENT_NAME=pull_request BASE_REF=main "$PROJECT/scripts/verify-commits.sh" --ci
  assert_fails "CI rejects a malformed base ref" \
    env EVENT_NAME=pull_request BASE_REF='main;rm' "$PROJECT/scripts/verify-commits.sh" --ci
  git -C "$PROJECT" update-ref -d refs/remotes/origin/main
  git -C "$PROJECT" reset -q --hard "$before_bad~1"
}

# REQ-026 local drop zone
test_inbox() {
  printf 'private\n' >"$PROJECT/inbox/notes.txt"
  assert "inbox README tracked" git -C "$PROJECT" ls-files --error-unmatch inbox/README.md
  assert "inbox contents ignored by git" git -C "$PROJECT" check-ignore -q inbox/notes.txt
  assert "inbox contents never staged by add -A" test -z "$(git -C "$PROJECT" add -A --dry-run | grep inbox/notes.txt || true)"
  rm -f "$PROJECT/inbox/notes.txt"
}

# REQ-002 tool-agnostic rules, REQ-005 security review, REQ-008 Obsidian vault
test_template_contents() {
  local pointer
  for pointer in CLAUDE.md .clinerules .continue/rules/project.md .github/copilot-instructions.md .aider.conf.yml; do
    assert "$pointer points to AGENTS.md" grep -q 'AGENTS.md' "$PROJECT/$pointer"
  done
  assert "/security runs the tool-agnostic review prompt" grep -q '@prompts/security-review.md' "$PROJECT/.claude/commands/security.md"
  # REQ-045 no personal skills, plugins or private tools: the generated project names none
  assert_fails "generated project references no skills" grep -rli 'skill' "$PROJECT" --exclude-dir=.git
  assert "tool-agnostic security prompt present" grep -q 'OWASP' "$PROJECT/prompts/security-review.md"
  assert "Obsidian vault configured" test -f "$PROJECT/.obsidian/app.json"
  assert "shared Obsidian config stays tracked" bash -c "! git -C '$PROJECT' check-ignore -q .obsidian/app.json"
  assert "per-user Obsidian state is ignored" bash -c "git -C '$PROJECT' check-ignore -q .obsidian/workspace.json && git -C '$PROJECT' check-ignore -q .obsidian/appearance.json && git -C '$PROJECT' check-ignore -q .obsidian/plugins/x/data.json"
  assert "every prompt has frontmatter" bash -c "cd '$PROJECT/prompts' && for f in *.md; do head -1 \"\$f\" | grep -qx -- '---' || exit 1; done"
}

# REQ-033 trusted instructions versus untrusted content, explicit approvals
test_assistant_trust_rules() {
  local item
  for item in 'issue and pull-request text' 'output of tools and dependencies' 'files in .inbox/.' \
    'authorise running commands' 'destructive or irreversible' 'adding, removing or upgrading dependencies' \
    'affecting production' 'sending code or data outside' 'reading, printing or changing secrets'; do
    assert "AGENTS.md trust rules cover: $item" grep -q -- "$item" "$PROJECT/AGENTS.md"
  done
  assert "pack carries the trust rules" grep -q '^## 10. Trusted instructions and approvals' "$PROJECT/context-pack.md"
}

# REQ-035 one workflow and approval model across prompts
test_prompt_workflow() {
  local prompts="$PROJECT/prompts" name
  for name in kickoff feature bugfix refactor requirements-update security-review release; do
    assert "$name prompt marks its approval points" grep -q '\*\*Approval point' "$prompts/$name.md"
  done
  assert "AGENTS.md defines approval points and prior approval" grep -q 'already approved that exact step' "$PROJECT/AGENTS.md"
  assert_fails "no prompt uses an unmarked wait phrase" grep -lE 'Wait for my confirmation|Ask me before installing|wait for my OK' "$prompts"/*.md
  assert_fails "feature prompt does not skip requirement approval" grep -q 'status .in-progress.) and' "$prompts/feature.md"
  assert "bugfix is regression-test first" grep -q 'Do not change production code before the test fails' "$prompts/bugfix.md"
  # REQ-036 truthful completion report
  assert "AGENTS.md defines the completion report" bash -c "grep -q '^  COMPLETION REPORT' '$PROJECT/AGENTS.md' && grep -q 'Checks skipped:' '$PROJECT/AGENTS.md' && grep -q 'Acceptance evidence:' '$PROJECT/AGENTS.md'"
  assert "skipped checks are never reported as passed" grep -q 'listed as skipped,' "$PROJECT/AGENTS.md"
  for name in kickoff feature bugfix refactor requirements-update security-review release documentation; do
    assert "$name prompt ends with the completion report" grep -q 'Completion report given' "$prompts/$name.md"
  done
  # REQ-037 honest docs checks, operations guidance
  assert "docs check says it verifies structure only" grep -q 'structure only' <("$PROJECT/scripts/check-docs.sh")
  assert "AGENTS.md says docs check is structure only" grep -q 'It checks structure only' "$PROJECT/AGENTS.md"
  for topic in 'timeouts' 'bounded retries' 'graceful shutdown' 'health checks' 'no secrets or personal data' \
    'rollback path' 'actually tested'; do
    assert "documentation prompt asks for: $topic" grep -q "$topic" "$prompts/documentation.md"
  done
  assert "admin guide asks when the restore was tested" grep -q 'restore was last tested' "$PROJECT/docs/admin-guide.md"
  assert "feature refactors first only when needed" grep -q 'refactor first (\[\[refactor\]\]' "$prompts/feature.md"
}

# read_denied <file-name>: true if a Read(./...) deny pattern in .claude/settings.json matches
# the name. Shell globs stand in for Claude Code's gitignore-style matching of plain names.
read_denied() {
  local pattern
  while IFS= read -r pattern; do
    # shellcheck disable=SC2254 # the pattern is meant to glob
    case "$1" in $pattern) return 0 ;; esac
  done < <(sed -n 's/^ *"Read(\.\/\(.*\))",*$/\1/p' "$PROJECT/.claude/settings.json")
  return 1
}

# REQ-034 accurate Claude Code permission rules
test_claude_permissions() {
  local secret
  for secret in .env .env.local .env.production.local .env.development .env.test .env.staging .env.production; do
    assert "Read denied for $secret" read_denied "$secret"
  done
  assert_fails "Read allowed for .env.example (documentation prompt needs it)" read_denied .env.example
  assert "force-push variants denied" bash -c "grep -q 'git push -f:' '$PROJECT/.claude/settings.json' && grep -q 'git push --force-with-lease:' '$PROJECT/.claude/settings.json'"
  assert "CLAUDE.md states the limits" grep -q 'not a security boundary' "$PROJECT/CLAUDE.md"
  if need_tool python3 "settings.json syntax"; then
    assert "settings.json is valid JSON" python3 -m json.tool "$PROJECT/.claude/settings.json"
  fi
}

# rule_ids <file>: prints the sorted, unique CC-nn IDs a file mentions.
rule_ids() {
  grep -o 'CC-[0-9][0-9]' "$1" | sort -u
}

# REQ-027 proportional, consistent clean-code guidance
test_clean_code_guidance() {
  assert "every CC rule is explained in clean-code.md and none is invented there" \
    test "$(rule_ids "$PROJECT/AGENTS.md")" = "$(rule_ids "$PROJECT/docs/clean-code.md")"
  assert "CC-06 scope agrees in AGENTS.md and clean-code.md" \
    bash -c "grep -q 'CC-06.* Document public APIs' '$PROJECT/AGENTS.md' && grep -q '^- Document public' '$PROJECT/docs/clean-code.md'"
  assert "CC-05 accepts result and option types" grep -q 'exceptions, result or option types' "$PROJECT/AGENTS.md"
  assert "CC-09 forbids unrelated refactoring" grep -q 'No unrelated refactoring' "$PROJECT/AGENTS.md"
  # REQ-041 design, test and refactoring practices
  local practice
  for practice in 'Composition root' 'does work (an algorithm) or coordinates' 'polymorphic objects' \
    'hidden temporal coupling' 'Law of Demeter' 'Size heuristics' 'Name length follows scope' \
    'positive' 'A wrong comment is worse than none' 'English unless' 'Parallel implementation' \
    'characterization' 'check results and state' 'a test that cannot fail' 'Flaky tests' \
    'Test doubles replace' 'Pyramid' 'Given / When / Then'; do
    assert "clean-code guide covers: $practice" grep -q "$practice" "$PROJECT/docs/clean-code.md"
  done
  # REQ-044 linter configuration only gets stricter without approval
  assert "loosening linters is an approval point" grep -q 'raising a threshold, or adding an ignore or suppression is an \*\*Approval point' "$PROJECT/AGENTS.md"
  assert "linter baselines may only shrink" grep -q 'it may only shrink' "$PROJECT/AGENTS.md"
  assert "presets require approval to relax" bash -c "grep -q \"user's approval\" '$PROJECT/presets/node/eslint.config.mjs' && grep -q \"user's approval\" '$PROJECT/presets/python/ruff.toml'"
  assert "ESLint preset forbids var" grep -q '"no-var": "error"' "$PROJECT/presets/node/eslint.config.mjs"
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

# REQ-017 update path for existing projects
test_scaffold_update() {
  local newer="$WORKDIR/newer-scaffold"
  assert "project records scaffold version" test -f "$PROJECT/.scaffold/version"
  assert "manifest lists managed files" grep -q 'prompts/feature.md' "$PROJECT/.scaffold/manifest"
  assert "manifest excludes project files" test -z "$(grep 'REQUIREMENTS.md' "$PROJECT/.scaffold/manifest" || true)"
  assert "fresh project is up to date" bash -c "'$SCAFFOLD_ROOT/scripts/update-scaffold.sh' '$PROJECT' | grep -q '0 change(s) planned'"

  # A newer scaffold: one changed prompt, one new prompt, one prompt changed on both sides.
  export_template "$SCAFFOLD_ROOT" "$newer"
  printf '9.9.9\n' >"$newer/VERSION"
  printf '\nUpstream improvement.\n' >>"$newer/template/prompts/bugfix.md"
  printf -- '---\ntitle: New\n---\n# New prompt\n' >"$newer/template/prompts/new-prompt.md"
  printf '\nUpstream change.\n' >>"$newer/template/prompts/feature.md"
  printf '\nMy local tweak.\n' >>"$PROJECT/prompts/feature.md"
  printf '\nProject requirement edit.\n' >>"$PROJECT/docs/requirements/REQUIREMENTS.md"
  git -C "$PROJECT" commit -q -am "docs: local prompt tweak and requirement edit" --no-verify

  assert "dry run changes nothing" bash -c "'$newer/scripts/update-scaffold.sh' '$PROJECT' >/dev/null && test -z \"\$(git -C '$PROJECT' status --porcelain)\""
  assert "update applies" "$newer/scripts/update-scaffold.sh" "$PROJECT" --apply
  assert "unmodified prompt updated" grep -q 'Upstream improvement.' "$PROJECT/prompts/bugfix.md"
  assert "new prompt added" test -f "$PROJECT/prompts/new-prompt.md"
  assert "local tweak kept on conflict" grep -q 'My local tweak.' "$PROJECT/prompts/feature.md"
  assert "conflict candidate written" grep -q 'Upstream change.' "$PROJECT/prompts/feature.md.scaffold-new"
  assert "project requirements untouched" grep -q 'Project requirement edit.' "$PROJECT/docs/requirements/REQUIREMENTS.md"
  assert "version recorded" test "$(cat "$PROJECT/.scaffold/version")" = "9.9.9"
  git -C "$PROJECT" reset -q --hard HEAD~1 && git -C "$PROJECT" clean -qfdx
}

# git needs an identity inside the sandbox project.
export GIT_AUTHOR_NAME=smoke GIT_AUTHOR_EMAIL=smoke@example.invalid
export GIT_COMMITTER_NAME=smoke GIT_COMMITTER_EMAIL=smoke@example.invalid

test_bump_version
test_new_project
test_license
test_generation_safety
test_template_contents
test_clean_code_guidance
test_inbox
test_generated_project
test_assistant_trust_rules
test_claude_permissions
test_prompt_workflow
test_setup_and_commit_checks
test_commit_bypasses
test_missing_tools
test_staged_checks
test_staged_snapshot
test_stack_enforcement
test_traceability
test_scaffold_update
test_release
if [ "$SKIPPED" -gt 0 ]; then
  warn "smoke test INCOMPLETE: $PASSED assertions passed, $SKIPPED fixture(s) skipped"
else
  info "smoke test passed ($PASSED assertions)"
fi
