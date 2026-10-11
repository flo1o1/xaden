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

# assert_fails_with <description> <expected-text> <command...>: command must exit non-zero and
# its output must contain the expected text, so it fails for the right reason.
assert_fails_with() {
  local description=$1 expected=$2
  shift 2
  if ("$@") >"$OUTPUT" 2>&1; then
    show_output
    die "FAILED (expected failure): $description"
  fi
  if ! grep -q -- "$expected" "$OUTPUT"; then
    show_output
    die "FAILED (wrong reason, expected '$expected'): $description"
  fi
  PASSED=$((PASSED + 1))
  printf 'ok   %s\n' "$description"
}

# req_file <root> <REQ-nnn>: path of a requirement file below <root>/docs/requirements.
req_file() {
  find "$1/docs/requirements" -name "$2-*.md" | head -n 1
}

# edit_file <file> <sed-expression>: edits a file in place (portable, no sed -i).
edit_file() {
  sed "$2" "$1" >"$1.edit" && mv "$1.edit" "$1"
}

# set_status <REQ-nnn> <status>: changes a requirement's status in the demo project and
# regenerates the index.
set_status() {
  edit_file "$(req_file "$PROJECT" "$1")" "s/^status: .*/status: $2/"
  "$PROJECT/scripts/req.sh" index >/dev/null
}

# requirements_variant <name> <sed-expression>: a copy of the demo project's requirements with
# REQ-001 edited and the index regenerated; prints the requirements directory.
requirements_variant() {
  local root="$WORKDIR/variants/$1"
  rm -rf "$root" && mkdir -p "$root/docs"
  cp -R "$PROJECT/docs/requirements" "$root/docs/"
  edit_file "$(req_file "$root" REQ-001)" "$2"
  PROJECT_ROOT="$root" "$PROJECT/scripts/req.sh" index >/dev/null
  printf '%s' "$root/docs/requirements"
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
  set_status REQ-001 approved
  git -C "$PROJECT" add docs/requirements
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

  local check="$PROJECT/scripts/check-requirements.sh"
  assert_fails_with "invalid requirement status rejected" 'unknown status' \
    "$check" "$(requirements_variant bad-status 's/^status: .*/status: bogus/')"
  # REQ-021 complete fields and real dates
  assert_fails_with "empty acceptance criteria rejected" 'Acceptance criteria' \
    "$check" "$(requirements_variant no-criteria '/^- TODO: Given/d')"
  assert_fails_with "invalid date rejected" 'invalid date' \
    "$check" "$(requirements_variant bad-date 's/^updated: .*/updated: not-a-date/')"
  assert_fails_with "unfilled date placeholder rejected in projects" 'unfilled' \
    "$check" "$(requirements_variant placeholder-date 's/^updated: .*/updated: {{DATE}}/')"
  assert_fails_with "placeholder requirement blocks a release" 'before a release' "$check" --release
}

# REQ-046 functional requirements as jobs to be done, quality requirements as goals
test_job_stories() {
  local check="$PROJECT/scripts/check-requirements.sh"
  assert_fails_with "a job without a job story is rejected" 'When …, I want to …, so I can …' \
    "$check" "$(requirements_variant feature-text 's/^TODO: When .*/Export invoices as PDF./')"
  assert "a job story is accepted" "$check" "$(requirements_variant job-story \
    's/^TODO: When .*/When I close a month, I want to export all invoices, so I can send them to my accountant./')"
  assert_fails_with "a quality requirement needs a quality goal" 'Quality goal' \
    "$check" "$(requirements_variant quality-without-goal 's/^type: job/type: quality/')"
  assert "a quality requirement with a goal is accepted" "$check" "$(requirements_variant quality-goal \
    's/^type: job/type: quality/; s/^## Job/## Quality goal/; s/^TODO: When .*/95 % of searches answer within one second./')"
  assert "a natural job story with 'I want a' is accepted" "$check" "$(requirements_variant want-a \
    's/^TODO: When .*/When I close a month, I want a PDF of all invoices, so I can send it to my accountant./')"
  assert "TODO text only warns outside a release" bash -c "'$check' 2>&1 | grep -q 'contains TODO text'"
  assert "the word TODO in real content is no marker" bash -c "! '$check' '$(requirements_variant todo-word \
    's/^TODO: When .*/When TODOs pile up, I want a list of them, so I can plan the work./; s/^- TODO: .*/- Given open TODOs, when I list them, then all are shown./')' 2>&1 | grep -q 'REQ-001-.*contains TODO'"
  assert_fails_with "unknown requirement type rejected" 'type must be one of' \
    "$check" "$(requirements_variant bad-type 's/^type: job/type: story/')"
  # REQ-049 the scaffold uses the format it prescribes
  assert "scaffold's own requirements are finished job and quality files" \
    "$PROJECT/scripts/check-requirements.sh" --release "$SCAFFOLD_ROOT/docs/requirements"
  assert "AGENTS.md defines the job story format" grep -q 'When <situation>, I want to <motivation>, so I can <expected' "$PROJECT/AGENTS.md"
  assert "kickoff writes requirements as jobs" grep -q 'Find the jobs my users hire the software for' "$PROJECT/prompts/kickoff.md"
}

# REQ-047 one file per requirement, epic folders, global IDs, generated index
test_requirement_files() {
  local check="$PROJECT/scripts/check-requirements.sh" variant
  assert_fails_with "epic must match the folder" 'does not match folder' \
    "$check" "$(requirements_variant wrong-epic 's/^epic: .*/epic: other/')"
  assert_fails_with "id must match the file name" 'file name must start with' \
    "$check" "$(requirements_variant wrong-id 's/^id: REQ-001/id: REQ-002/')"
  variant="$(requirements_variant duplicate 's/x/x/')"
  cp "$(req_file "$WORKDIR/variants/duplicate" REQ-001)" "$variant/first-epic/REQ-001-copy.md"
  PROJECT_ROOT="$WORKDIR/variants/duplicate" "$PROJECT/scripts/req.sh" index >/dev/null
  assert_fails_with "duplicate IDs rejected" 'duplicate id' "$check" "$variant"
  variant="$(requirements_variant no-epic 's/x/x/')"
  rm "$variant/first-epic/EPIC.md"
  assert_fails_with "every epic folder needs EPIC.md" 'missing EPIC.md' "$check" "$variant"
  variant="$(requirements_variant stale-index 's/x/x/')"
  edit_file "$(req_file "$WORKDIR/variants/stale-index" REQ-001)" 's/^# .*/# Renamed job/'
  assert_fails_with "a stale index is rejected" 'stale' "$check" "$variant"
  variant="$(requirements_variant old-table 's/x/x/')"
  printf '| ID |\n' >"$variant/REQUIREMENTS.md"
  assert_fails_with "the old table format is rejected with a migration hint" 'migrate-requirements.sh' "$check" "$variant"
  assert "req.sh new creates the next ID in a new epic" bash -c "PROJECT_ROOT='$WORKDIR/variants/stale-index' \
    '$PROJECT/scripts/req.sh' new billing job 'Export invoices' | grep -q 'docs/requirements/billing/REQ-002-export-invoices.md'"
  assert "req.sh new adds the epic and updates the index" bash -c "test -f '$WORKDIR/variants/stale-index/docs/requirements/billing/EPIC.md' \
    && grep -q '| REQ-002 | job | should | draft | Export invoices |' '$WORKDIR/variants/stale-index/docs/requirements/INDEX.md'"
  assert "req.sh show prints the requirement file" bash -c "'$PROJECT/scripts/req.sh' show REQ-001 | grep -q '^## Acceptance criteria'"
  assert "pack includes the index and requirement files" bash -c "grep -q '^# REQUIREMENTS INDEX' '$PROJECT/context-pack.md' \
    && grep -q '^# REQUIREMENTS (docs/requirements/first-epic/REQ-001-' '$PROJECT/context-pack.md'"
  assert "CLAUDE.md imports the requirements index" grep -qx '@docs/requirements/INDEX.md' "$PROJECT/CLAUDE.md"
}

# write_requirements_table <root>: a project in the old single-table format.
write_requirements_table() {
  mkdir -p "$1/docs/requirements"
  printf '%s\n' '# Requirements — legacy' '' \
    '| ID      | Requirement | Priority | Status | Acceptance criteria | Updated |' \
    '|---------|-------------|----------|--------|---------------------|---------|' \
    '| REQ-001 | Users export data as CSV | must | done | CSV has a header row | 2026-01-02 |' \
    '| REQ-002 | Pages load fast | should | draft | Start page under 1 s | 2026-02-03 |' \
    '' '## Change log' '' '- 2026-01-02 REQ-001 added: first export.' >"$1/docs/requirements/REQUIREMENTS.md"
}

# REQ-048 migration from the requirements table
test_requirements_migration() {
  local legacy="$WORKDIR/legacy" migrated
  write_requirements_table "$legacy"
  assert "table migrates to requirement files" env PROJECT_ROOT="$legacy" "$PROJECT/scripts/migrate-requirements.sh"
  migrated="$(req_file "$legacy" REQ-001)"
  assert "migration keeps id, status, priority and date" bash -c "grep -qx 'status: done' '$migrated' \
    && grep -qx 'priority: must' '$migrated' && grep -qx 'updated: 2026-01-02' '$migrated' && grep -qx 'epic: unsorted' '$migrated'"
  assert "migration keeps text and acceptance criteria" bash -c "grep -qx '# Users export data as CSV' '$migrated' \
    && grep -qx -- '- CSV has a header row' '$migrated'"
  assert "migration names the file after the text" test -f "$legacy/docs/requirements/unsorted/REQ-002-pages-load-fast.md"
  assert "migration moves the change log" grep -q 'REQ-001 added: first export.' "$legacy/docs/requirements/README.md"
  assert "migration removes the table" test ! -e "$legacy/docs/requirements/REQUIREMENTS.md"
  assert "migrated requirements validate (TODO job stories warn)" "$PROJECT/scripts/check-requirements.sh" "$legacy/docs/requirements"
  assert_fails_with "migrated TODO job stories block a release" 'before a release' \
    "$PROJECT/scripts/check-requirements.sh" --release "$legacy/docs/requirements"
  write_requirements_table "$legacy"
  assert_fails_with "migration never overwrites requirement files" 'already exist' \
    env PROJECT_ROOT="$legacy" "$PROJECT/scripts/migrate-requirements.sh"
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
  assert "CI installs requirements-dev.txt only when present" \
    grep -q 'if \[ -f requirements-dev.txt \]; then python -m pip install -r requirements-dev.txt' "$PROJECT/.github/workflows/ci.yml"
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

# fake_tools <name...>: a directory of stand-in commands that report a finding and fail.
fake_tools() {
  local bin="$WORKDIR/fake-tools" name
  mkdir -p "$bin"
  for name in "$@"; do
    printf '#!/bin/sh\necho "fake finding from %s"\nexit 1\n' "$name" >"$bin/$name"
    chmod +x "$bin/$name"
  done
  printf '%s' "$bin"
}

# REQ-051 optional tools: tips where they fit, checks once adopted
test_optional_tools() {
  local log="$WORKDIR/optional.log" fakes tip_text label
  printf '[project]\nname = "demo"\n' >"$PROJECT/pyproject.toml"
  printf '{ "name": "demo" }\n' >"$PROJECT/package.json"
  printf '"""Demo."""\n' >"$PROJECT/ok.py"
  git -C "$PROJECT" add pyproject.toml package.json ok.py
  (cd "$PROJECT" && scripts/check.sh >"$log" 2>&1) || true
  for tip_text in 'python: vulture' 'python: Hypothesis' 'python: mutmut' 'node: knip' 'node: fast-check' \
    'node: StrykerJS' 'duplication: jscpd'; do
    assert "full check suggests $tip_text" grep -q "^TIP: $tip_text" "$log"
  done
  has_command zizmor || assert "workflow security tip without zizmor" grep -q '^TIP: workflows: zizmor' "$log"
  assert "staged check prints no tips" bash -c "cd '$PROJECT' && ! scripts/check.sh --staged 2>&1 | grep -q '^TIP:'"

  fakes="$(fake_tools actionlint zizmor vulture jscpd)"
  printf '\n[tool.vulture]\npaths = ["ok.py"]\n' >>"$PROJECT/pyproject.toml"
  printf '{ "threshold": 5 }\n' >"$PROJECT/.jscpd.json"
  git -C "$PROJECT" add pyproject.toml .jscpd.json
  (cd "$PROJECT" && PATH="$fakes:$PATH" scripts/check.sh >"$log" 2>&1) || true
  for label in 'python: vulture (dead code)' 'duplication: jscpd' 'workflows: actionlint' 'workflows: zizmor'; do
    assert "adopted $label runs and its findings fail" grep -q "$label failed" "$log"
  done
  assert_fails "adopted tools are no longer suggested" grep -qE '^TIP: (python: vulture|duplication|workflows)' "$log"
  assert "staged check lints staged workflows" bash -c "cd '$PROJECT' && printf '# staged edit\\n' >>.github/workflows/ci.yml && git add .github/workflows/ci.yml && PATH='$fakes:$PATH' scripts/check.sh --staged 2>&1 | grep -q 'workflows: zizmor failed'"
  git -C "$PROJECT" reset -q --hard && git -C "$PROJECT" clean -qfd

  assert "AGENTS.md says how to handle tips" grep -q 'install nothing without approval' "$PROJECT/AGENTS.md"
  assert "optional tools are a managed document" grep -q 'docs/optional-tools.md' "$PROJECT/.scaffold/manifest"
  assert "setup points to the optional tools" bash -c "'$PROJECT/scripts/setup.sh' --tools-only 2>&1 | grep -q 'docs/optional-tools.md'"
  assert "clean-code guide covers property and mutation testing" bash -c "grep -q 'property-based tests' '$PROJECT/docs/clean-code.md' && grep -q 'Mutation testing' '$PROJECT/docs/clean-code.md'"
}

# REQ-052 dependencies are verified before they are proposed
test_dependency_vetting() {
  local security="$PROJECT/docs/security.md"
  assert "dependency policy names slopsquatting" grep -q 'slopsquatting' "$security"
  assert "dependency policy requires a registry lookup" grep -q 'look up the exact name in the' "$security"
  assert "suspicious packages are not installed" grep -q 'say so and do not install it' "$security"
}

# REQ-053 optional assistant plugins are documented, not installed
test_assistant_plugins() {
  local doc="$PROJECT/docs/optional-tools.md" item
  for item in 'code-review@claude-plugins-official' 'trailofbits/skills' 'ponytail@ponytail' \
    'takes precedence over them' 'Not recommended'; do
    assert "optional tools document covers: $item" grep -q -- "$item" "$doc"
  done
  assert "/review offers ponytail-review as an optional second pass" \
    grep -q 'Optional second pass: if the Ponytail plugin is installed' "$PROJECT/.claude/commands/review.md"
}

# REQ-055 maintainers use the project commands on the scaffold itself
test_scaffold_commands() {
  local name prompt
  for name in bugfix refactor review security; do
    prompt="$(sed -n 's|^@template/prompts/\(.*\)$|\1|p' "$SCAFFOLD_ROOT/.claude/commands/$name.md")"
    assert "/$name includes an existing template prompt" test -n "$prompt" -a -f "$SCAFFOLD_ROOT/template/prompts/$prompt"
  done
  assert "AGENTS.md maps prompt paths for the scaffold" grep -q '^## Using the project commands here' "$SCAFFOLD_ROOT/AGENTS.md"
  assert "scaffold threat model names entry points" grep -q '^## Entry points' "$SCAFFOLD_ROOT/docs/threat-model.md"
  assert_fails "projects get no scaffold commands" grep -rq 'template/prompts' "$PROJECT/.claude/commands"
  assert_fails "projects get no scaffold threat model" grep -q 'Vibe Coding Scaffold' "$PROJECT/docs/threat-model.md"
}

# REQ-054 look for mature existing solutions before building
test_look_before_build() {
  local item
  for item in 'Look before you build' 'search the web for a mature solution' 'name, one-line summary, license, website' \
    'No web access: say so'; do
    assert "AGENTS.md rule covers: $item" grep -q -- "$item" "$PROJECT/AGENTS.md"
  done
  assert "feature prompt applies the rule" grep -q 'Look before you build (AGENTS.md' "$PROJECT/prompts/feature.md"
  assert "pack carries the rule" grep -q 'Look before you build' "$PROJECT/context-pack.md"
}

# REQ-024 releases never leave a partial state
test_release_failures() {
  local head hooks="$WORKDIR/failing-hooks"
  head="$(git -C "$PROJECT" rev-parse HEAD)"
  git -C "$PROJECT" tag v0.1.1
  assert_fails "existing tag aborts the release" "$PROJECT/scripts/release.sh" patch
  assert "nothing changed after tag conflict" test "$(git -C "$PROJECT" rev-parse HEAD)$(git -C "$PROJECT" status --porcelain)" = "$head"
  git -C "$PROJECT" tag -d v0.1.1 >/dev/null
  # REQ-007: both release scripts share stamp_changelog, which needs an Unreleased section.
  edit_file "$PROJECT/CHANGELOG.md" 's/^## \[Unreleased\]/## Pending/'
  git -C "$PROJECT" commit -q -am "docs: changelog without Unreleased section"
  assert_fails_with "changelog without Unreleased aborts the release" 'section; nothing was changed' "$PROJECT/scripts/release.sh" patch
  assert "nothing released without Unreleased section" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")$(git -C "$PROJECT" tag -l v0.1.1)" = "0.1.0"
  git -C "$PROJECT" reset -q --hard "$head"
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
  edit_file "$(req_file "$PROJECT" REQ-001)" \
    's/^TODO: When .*/When I close a month, I want to export my data, so I can send it to my accountant./; s/^- TODO: .*/- Given data, when I export, then a CSV file is written./'
  printf '# Reporting\n\n## Goal\n\nWhen I run my business, I want to see my numbers, so I can decide quickly.\n' \
    >"$PROJECT/docs/requirements/first-epic/EPIC.md"
  "$PROJECT/scripts/req.sh" index >/dev/null
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
  printf 'Mark a TODO item as done.\n' >>"$PROJECT/docs/user-guide.md"
  assert "the word TODO in guide prose does not block a release" "$PROJECT/scripts/check-docs.sh" --release
  git -C "$PROJECT" checkout -q -- docs/user-guide.md
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
  edit_file "$(req_file "$source/template" REQ-001)" 's/^status: .*/status: bogus/'
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
  local requirements before_status before_diff in_snapshot
  # REQ-014: large files the commit does not change are not copied; staged ones always are.
  head -c 1100000 /dev/zero >"$PROJECT/large-unchanged.bin"
  git -C "$PROJECT" add large-unchanged.bin && git -C "$PROJECT" commit -q --no-verify -m "chore: large file"
  head -c 1100000 /dev/zero >"$PROJECT/large-staged.bin" && printf 'x\n' >"$PROJECT/small-staged.txt"
  git -C "$PROJECT" add large-staged.bin small-staged.txt
  in_snapshot="source '$PROJECT/scripts/lib.sh'; enter_staged_snapshot '$PROJECT'"
  assert "snapshot leaves out large unchanged files" bash -c "$in_snapshot; test ! -e large-unchanged.bin && test -f AGENTS.md"
  assert "snapshot keeps staged files of any size" bash -c "$in_snapshot; test -f large-staged.bin && test -f small-staged.txt"
  git -C "$PROJECT" reset -q --hard HEAD~1
  requirements="$(req_file "$PROJECT" REQ-001)"
  cp "$requirements" "$WORKDIR/req-original.md"
  # staged content broken, working tree fixed: must fail
  sed 's/^status: .*/status: bogus/' "$WORKDIR/req-original.md" >"$requirements"
  git -C "$PROJECT" add docs/requirements
  cp "$WORKDIR/req-original.md" "$requirements"
  before_status="$(git -C "$PROJECT" status --porcelain)"
  before_diff="$(git -C "$PROJECT" diff)"
  assert_fails "staged invalid requirement not hidden by unstaged fix" bash -c "cd '$PROJECT' && scripts/check.sh --staged"
  assert "working tree and index untouched by staged check" test "$(git -C "$PROJECT" status --porcelain)$(git -C "$PROJECT" diff)" = "$before_status$before_diff"
  git -C "$PROJECT" reset -q --hard
  # staged content fine, working tree broken: must pass
  sed 's/^status: .*/status: bogus/' "$WORKDIR/req-original.md" >"$requirements"
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
  "$PROJECT/scripts/req.sh" new first-epic job "Second job" >/dev/null
  set_status REQ-002 approved
  assert_fails "REQ only in unstaged file rejected by commit-msg" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat: x\n\nRefs: REQ-002\n')"
  git -C "$PROJECT" add docs/requirements
  assert "same REQ accepted once staged" "$PROJECT/scripts/hooks/commit-msg" "$(msg 'feat: x\n\nRefs: REQ-002\n')"
  git -C "$PROJECT" reset -q --hard && git -C "$PROJECT" clean -qfd
}

# REQ-022 commit reference checks cannot be bypassed
test_commit_bypasses() {
  local hook="$PROJECT/scripts/hooks/commit-msg" zero="0000000000000000000000000000000000000000" before_bad
  assert_fails "Merge prefix cannot smuggle an unknown ID" "$hook" "$(msg 'Merge branch x\n\nRefs: REQ-777\n')" # traceability: ignore
  assert_fails "fixup! prefix cannot smuggle an unknown ID" "$hook" "$(msg 'fixup! feat: x\n\nSee REQ-778\n')" # traceability: ignore
  assert "plain Merge message still accepted" "$hook" "$(msg 'Merge branch x\n')"
  assert "IDs in comments and the git commit -v diff are ignored" "$hook" \
    "$(msg 'docs: x\n\n# REQ-779 in a comment\n# ------------------------ >8 ------------------------\n+REQ-780 in the diff\n')" # traceability: ignore
  set_status REQ-001 approved
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
  # optional-tools.md names a public plugin catalogue whose repository is called "skills" (REQ-053)
  assert_fails "generated project references no skills" grep -rli 'skill' "$PROJECT" --exclude-dir=.git --exclude=optional-tools.md
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

# REQ-050 optional add-on rule sets: documented, never installed, never above AGENTS.md
test_add_on_rule_sets() {
  local guide="$SCAFFOLD_ROOT/GETTING-STARTED.md"
  assert "guide lists Ponytail as optional" grep -q '^| Optional: \[Ponytail\]' "$guide"
  assert "guide gives the Claude Code install" grep -q 'plugin install ponytail@ponytail' "$guide"
  assert "guide names the AGENTS.md route for other tools" grep -q "can use its .AGENTS.md." "$guide"
  assert_fails "new projects enable no plugin" grep -qi 'plugin' "$PROJECT/.claude/settings.json"
  assert "AGENTS.md ranks add-on rule sets below itself" grep -q 'they never override this file' "$PROJECT/AGENTS.md"
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
  set_status REQ-001 "done"
  assert_fails "done requirement without test fails" "$PROJECT/scripts/check-traceability.sh"
  mkdir -p "$PROJECT/tests"
  printf 'data = "REQ-001"  # traceability: ignore\n' >"$PROJECT/tests/test_ignored.py"
  git -C "$PROJECT" add tests/test_ignored.py
  assert_fails "ignored line does not count as a test" "$PROJECT/scripts/check-traceability.sh"
  assert "matrix skips ignored lines like the check" grep -q '^| REQ-001 | done | — |' <("$PROJECT/scripts/check-traceability.sh" --matrix)
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
  assert "manifest excludes project files" test -z "$(grep 'docs/requirements/' "$PROJECT/.scaffold/manifest" || true)"
  assert "fresh project is up to date" bash -c "'$SCAFFOLD_ROOT/scripts/update-scaffold.sh' '$PROJECT' | grep -q '0 change(s) planned'"

  # A newer scaffold: one changed prompt, one new prompt, one prompt changed on both sides.
  export_template "$SCAFFOLD_ROOT" "$newer"
  printf '9.9.9\n' >"$newer/VERSION"
  printf '\nUpstream improvement.\n' >>"$newer/template/prompts/bugfix.md"
  printf -- '---\ntitle: New\n---\n# New prompt\n' >"$newer/template/prompts/new-prompt.md"
  printf '\nUpstream change.\n' >>"$newer/template/prompts/feature.md"
  printf '\nMy local tweak.\n' >>"$PROJECT/prompts/feature.md"
  printf '\nProject requirement edit.\n' >>"$PROJECT/docs/requirements/README.md"
  git -C "$PROJECT" commit -q -am "docs: local prompt tweak and requirement edit" --no-verify

  assert "dry run changes nothing" bash -c "'$newer/scripts/update-scaffold.sh' '$PROJECT' >/dev/null && test -z \"\$(git -C '$PROJECT' status --porcelain)\""
  assert "update applies" "$newer/scripts/update-scaffold.sh" "$PROJECT" --apply
  assert "unmodified prompt updated" grep -q 'Upstream improvement.' "$PROJECT/prompts/bugfix.md"
  assert "new prompt added" test -f "$PROJECT/prompts/new-prompt.md"
  assert "local tweak kept on conflict" grep -q 'My local tweak.' "$PROJECT/prompts/feature.md"
  assert "conflict candidate written" grep -q 'Upstream change.' "$PROJECT/prompts/feature.md.scaffold-new"
  assert "project requirements untouched" grep -q 'Project requirement edit.' "$PROJECT/docs/requirements/README.md"
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
test_job_stories
test_requirement_files
test_requirements_migration
test_assistant_trust_rules
test_add_on_rule_sets
test_claude_permissions
test_prompt_workflow
test_setup_and_commit_checks
test_commit_bypasses
test_missing_tools
test_staged_checks
test_staged_snapshot
test_stack_enforcement
test_optional_tools
test_dependency_vetting
test_assistant_plugins
test_look_before_build
test_scaffold_commands
test_traceability
test_scaffold_update
test_release
if [ "$SKIPPED" -gt 0 ]; then
  warn "smoke test INCOMPLETE: $PASSED assertions passed, $SKIPPED fixture(s) skipped"
else
  info "smoke test passed ($PASSED assertions)"
fi
