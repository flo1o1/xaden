# shellcheck shell=bash
# shellcheck disable=SC2016 # bash -c programs are single-quoted on purpose
# Smoke test area "adoption" (REQ-066 to REQ-076: adopting Xaden in existing repositories).
# Sourced by tests/smoke.sh, which defines the helpers and creates the demo project first.

# message_of <function> <args...>: what a lib.sh message helper prints on both streams.
message_of() { bash -c 'source "$1"; shift; "$@"' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh" "$@" 2>&1 || true; }

# REQ-074 four kinds of messages, plain fallbacks, no hand-made signs
test_messages() {
  assert "plain error when not a terminal" test "$(message_of die boom)" = "ERROR: boom"
  assert "plain warning when not a terminal" test "$(message_of warn careful)" = "WARNING: careful"
  assert "plain success when not a terminal" test "$(message_of ok fine)" = "OK: fine"
  assert "CI forces plain text" test "$(CI=1 message_of ok fine)" = "OK: fine"
  assert "warnings go to stderr" test -z "$(bash -c 'source "$1"; warn x' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh" 2>/dev/null)"
  assert "errors exit non-zero" bash -c '! bash -c '\''source "$1"; die x'\'' _ "$1" 2>/dev/null' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh"

  local asked
  asked="$(XADEN_TEST_MODE=1 XADEN_TEST_ANSWER=y message_of ask "Go on?")"
  assert "question is marked, last line, shows the default" test "$(printf '%s\n' "$asked" | tail -n 1)" = "[?] Go on? [y/N] y"
  assert "separator line comes before the question" test "$(printf '%s\n' "$asked" | head -n 1)" = "----------------------------------------"
  assert "yes answers a question" env XADEN_TEST_MODE=1 XADEN_TEST_ANSWER=yes bash -c 'source "$1"; ask "Go on?" >/dev/null' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh"
  assert_fails "empty answer is no" env XADEN_TEST_MODE=1 XADEN_TEST_ANSWER= bash -c 'source "$1"; ask "Go on?" >/dev/null' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh"
  assert_fails "other answers are no" env XADEN_TEST_MODE=1 XADEN_TEST_ANSWER=maybe bash -c 'source "$1"; ask "Go on?" >/dev/null' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh"
  assert_fails "no terminal and no test mode: nothing is asked" bash -c 'source "$1"; ask "Go on?" </dev/null' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh"
  assert_fails "the test answer is ignored without test mode" env XADEN_TEST_ANSWER=y bash -c 'source "$1"; ask "Go on?" </dev/null >/dev/null' _ "$SCAFFOLD_ROOT/template/scripts/lib.sh"

  assert "no script prints a sign by hand" bash -c \
    '! grep -rIl -e "🐉" -e "⚠" -e "🔥" -e "✅" "$1/scripts" "$1/template/scripts" | grep -v "template/scripts/lib.sh$" | grep .' _ "$SCAFFOLD_ROOT"
  assert "no script reads an answer by hand" bash -c \
    '! grep -rnE "(^|[^_a-z])read( -[a-z]+)* -p|ask\(\)" "$1/scripts" "$1/template/scripts" | grep -v "template/scripts/lib.sh:" | grep .' _ "$SCAFFOLD_ROOT"
}

XADEN="$SCAFFOLD_ROOT/scripts/xaden.sh"
# The git hooks of the fixtures call `xaden`: it must be this checkout's command, not one installed on the machine.
mkdir -p "$WORKDIR/bin" && ln -sf "$XADEN" "$WORKDIR/bin/xaden"
export PATH="$WORKDIR/bin:$PATH"
XOUT="$WORKDIR/xaden.out"
XRC=0

# x_in <dir> <args...>: runs the xaden command in a directory; output in $XOUT, status in $XRC.
x_in() {
  local dir=$1
  shift
  XRC=0
  (cd "$dir" && "$XADEN" "$@") >"$XOUT" 2>&1 || XRC=$?
}

# x_answers <answer> <dir> <args...>: like x_in, with a test answer for every question.
x_answers() {
  local answer=$1
  shift
  XADEN_TEST_MODE=1 XADEN_TEST_ANSWER=$answer x_in "$@"
}

# make_repo <dir> <kind>: a repository with history. Kinds: shop (npm test, make lint, CI, an
# AGENTS.md that contradicts the rules), bare-python (no tests or linters), husky, empty.
make_repo() {
  local dir=$1 kind=$2
  rm -rf "$dir" && mkdir -p "$dir"
  git -C "$dir" init -q -b main
  case "$kind" in
    empty) return 0 ;;
    shop)
      mkdir -p "$dir/.github/workflows" "$dir/docs" "$dir/scripts"
      printf '{ "name": "shop", "scripts": { "test": "node --test" } }\n' >"$dir/package.json"
      printf 'lint:\n\techo lint\n' >"$dir/Makefile"
      printf '# Shop\n' >"$dir/README.md"
      printf '# Changelog\n' >"$dir/CHANGELOG.md"
      printf 'guide\n' >"$dir/docs/guide.md"
      printf 'name: ci\non: push\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo hi\n' >"$dir/.github/workflows/ci.yml"
      printf '#!/bin/sh\necho $1\n' >"$dir/scripts/build.sh" # an unquoted variable: shellcheck SC2086
      printf '# Rules\n- Skip tests when in a hurry.\n- Never skip the linter.\n' >"$dir/AGENTS.md" ;;
    bare-python)
      printf '[project]\nname = "bare"\n' >"$dir/pyproject.toml"
      printf 'print(1)\n' >"$dir/app.py"
      printf '# Bare\n' >"$dir/README.md" ;;
    pre-commit | lefthook)
      printf '{ "name": "m", "scripts": { "test": "node --test", "lint": "echo lint" } }\n' >"$dir/package.json"
      if [ "$kind" = pre-commit ]; then printf 'repos: []\n' >"$dir/.pre-commit-config.yaml"; else printf 'pre-commit:\n  commands: {}\n' >"$dir/lefthook.yml"; fi
      printf '# M\n' >"$dir/README.md" ;;
    husky)
      mkdir -p "$dir/.husky"
      printf '{ "name": "h", "scripts": { "test": "node --test", "lint": "echo lint" } }\n' >"$dir/package.json"
      printf '#!/usr/bin/env sh\nnpm run lint\n' >"$dir/.husky/pre-commit"
      printf '# H\n' >"$dir/README.md" ;;
  esac
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "initial"
  git -C "$dir" commit -q --allow-empty -m "feat: second"
}

# adopted_copy <name>: an adopted shop in the work folder; prints the worktree with the adoption.
adopted_copy() {
  local repo="$WORKDIR/repos/$1"
  make_repo "$repo" shop
  x_in "$repo" adopt --yes --assistants claude >/dev/null || true
  printf '%s' "$repo-adopt-xaden"
}

# REQ-067 the scan reports and changes nothing; the plan shows the exact diff and writes nothing
test_scan_and_plan() {
  local repo="$WORKDIR/repos/scan-shop" before
  make_repo "$repo" shop
  before="$(git -C "$repo" status --porcelain; git -C "$repo" branch --list | wc -l)"
  x_in "$repo" adopt --scan
  assert "scan succeeds" test "$XRC" -eq 0
  assert "scan names the stack" grep -q 'stack .*node' "$XOUT"
  assert "scan finds the test runner" grep -q 'test runner .*npm test' "$XOUT"
  assert "scan finds the linters" grep -q 'linters .*make lint' "$XOUT"
  assert "scan finds the CI system" grep -q 'CI .*github-actions' "$XOUT"
  assert "scan finds the hook manager" grep -q 'hook manager .*plain' "$XOUT"
  assert "scan finds the commit convention" grep -q 'commit convention .*other' "$XOUT"
  assert "scan finds AGENTS.md" grep -q 'assistant files .*AGENTS.md' "$XOUT"
  assert "scan lists a contradicting rule with file and line" grep -q 'AGENTS.md:2: .*Skip tests' "$XOUT"
  assert "a rule that forbids skipping is no contradiction" bash -c '! grep -q "AGENTS.md:3" "$1"' _ "$XOUT"
  assert "scan changes nothing" test "$(git -C "$repo" status --porcelain; git -C "$repo" branch --list | wc -l)" = "$before"
  assert "scan wrote no xaden folder" test ! -e "$repo/xaden"

  x_in "$repo" adopt --plan
  assert "plan succeeds" test "$XRC" -eq 0
  assert "plan lists the created files" grep -q 'A.xaden/xaden.conf' "$XOUT"
  assert "plan lists the touched file" grep -q 'M.AGENTS.md' "$XOUT"
  assert "plan prints the exact diff" grep -q '^+++ b/xaden/xaden.conf' "$XOUT"
  assert "plan changes nothing" test "$(git -C "$repo" status --porcelain; git -C "$repo" branch --list | wc -l)" = "$before"
  assert "plan creates no worktree" test "$(git -C "$repo" worktree list | wc -l | tr -d ' ')" = "1"

  x_in "$repo" adopt
  assert "without a terminal nothing is applied" test ! -e "$repo-adopt-xaden"
  assert "without a terminal the apply command is named" grep -q 'xaden adopt --yes' "$XOUT"

  local unknown="$WORKDIR/repos/unknown"
  make_repo "$unknown" empty
  printf 'int main(void) { return 0; }\n' >"$unknown/main.c"
  git -C "$unknown" add -A && git -C "$unknown" commit -q -m "initial"
  x_in "$unknown" adopt --scan
  assert "an unrecognised build is said, not guessed" grep -q 'not recognised.*no build system recognised' "$XOUT"
  assert "no command is guessed" bash -c '! grep -q "test runner .*[a-z]" "$1" || grep -q "test runner .*none" "$1"' _ "$XOUT"
}

# REQ-066 REQ-070 REQ-073 adopting: own branch and worktree, nothing of the team's changes, small footprint
test_adopt_and_remove() {
  local repo="$WORKDIR/repos/adopt-shop" worktree changed
  make_repo "$repo" shop
  x_in "$repo" adopt --yes --assistants claude
  worktree="$repo-adopt-xaden"
  assert "adopt succeeds" test "$XRC" -eq 0
  assert "adopt works on its own branch and worktree" test "$(git -C "$worktree" branch --show-current)" = "chore/adopt-xaden"
  assert "the default branch is untouched" test "$(git -C "$repo" rev-parse main)" = "$(git -C "$repo" rev-parse HEAD)"
  assert "the first commit message names Xaden" git -C "$worktree" log -1 --format=%s main..HEAD
  changed="$(git -C "$worktree" diff --name-only main HEAD | grep -Ev '^(xaden/|AGENTS\.md$|CLAUDE\.md$|\.github/workflows/xaden\.yml$)' || true)"
  assert "only xaden/, AGENTS.md, CLAUDE.md and the documented workflow change (REQ-073)" test -z "$changed"
  assert "README, docs, scripts and CHANGELOG are untouched (REQ-066)" test -z "$(git -C "$worktree" diff --name-only main HEAD -- README.md docs scripts CHANGELOG.md package.json Makefile .github/workflows/ci.yml)"
  assert "the existing workflow is untouched" cmp -s "$repo/.github/workflows/ci.yml" "$worktree/.github/workflows/ci.yml"
  assert "CLAUDE.md is one line for Claude users" test "$(cat "$worktree/CLAUDE.md")" = "@AGENTS.md"
  assert "AGENTS.md keeps the team's own text" grep -q 'Skip tests when in a hurry' "$worktree/AGENTS.md"
  assert "AGENTS.md gets one marked block" test "$(grep -c 'xaden:begin' "$worktree/AGENTS.md")" = "1"
  assert "team content is plain Markdown plus one settings file (REQ-070)" test -f "$worktree/xaden/xaden.conf" -a -f "$worktree/xaden/requirements/INDEX.md" -a -d "$worktree/xaden/personas" -a -d "$worktree/xaden/security-reviews"
  assert "no editor specific files" test -z "$(find "$worktree/xaden" -name '.obsidian' -o -name '.vscode')"
  assert "tooling is not copied into the repository" test ! -e "$worktree/scripts/check.sh" -a ! -e "$worktree/prompts" -a ! -e "$worktree/xaden/scripts"
  assert "RULES.md says it is generated" grep -q 'Generated, do not edit' "$worktree/xaden/RULES.md"
  assert "RULES.md has no path of the copied layout" bash -c '! grep -nE "scripts/[a-z-]+\.sh|docs/(requirements|personas|threat-model|security)" "$1"' _ "$worktree/xaden/RULES.md"
  assert "RULES.md makes a mode change an approval point" grep -q 'Approval point' "$worktree/xaden/RULES.md"
  assert "the version and checksum are pinned" grep -Eq '^checksum = [0-9a-f]{64}$' "$worktree/xaden/xaden.conf"
  assert "the build's commands are mapped" grep -q '^check.test = npm test$' "$worktree/xaden/xaden.conf"
  assert "git hooks of the clone are chained, not replaced" grep -q 'xaden hook pre-commit' "$repo/.git/hooks/pre-commit"
  assert "core.hooksPath is not set" test -z "$(git -C "$repo" config --get core.hooksPath || true)"
  assert "violations that exist are recorded" test -f "$worktree/xaden/baselines/shellcheck.txt"
  assert "adopting twice is refused" bash -c 'cd "$1" && ! "$2" adopt --yes' _ "$worktree" "$XADEN"

  printf '%s\n' 'text added by the team' >>"$worktree/AGENTS.md"
  git -C "$worktree" -c core.hooksPath=/dev/null commit -q -n -am "docs: team text"
  x_in "$worktree" remove --yes
  assert "remove succeeds" test "$XRC" -eq 0
  assert "remove deletes the xaden folder" test ! -e "$worktree/xaden"
  assert "remove deletes the workflow and CLAUDE.md" test ! -e "$worktree/.github/workflows/xaden.yml" -a ! -e "$worktree/CLAUDE.md"
  assert "remove keeps the team's text in AGENTS.md" grep -q 'text added by the team' "$worktree/AGENTS.md"
  assert "remove takes the block out" bash -c '! grep -q xaden "$1"' _ "$worktree/AGENTS.md"
  assert "remove leaves nothing but the adoption's own paths in git status" test -z "$(git -C "$worktree" status --porcelain | grep -Ev ' (xaden/|AGENTS\.md|CLAUDE\.md|\.github/workflows/xaden\.yml)' || true)"
  assert "remove unchains the git hooks" bash -c '! test -e "$1/.git/hooks/pre-commit"' _ "$repo"

  local no_ci="$WORKDIR/repos/no-ci" plain
  make_repo "$no_ci" shop
  x_in "$no_ci" adopt --yes --skip-ci
  assert "--skip-ci adds no workflow" test ! -e "$no_ci-adopt-xaden/.github/workflows/xaden.yml"
  assert "without Claude users there is no CLAUDE.md" test ! -e "$no_ci-adopt-xaden/CLAUDE.md"
  plain="$(git -C "$no_ci-adopt-xaden" diff --name-only main HEAD | grep -Ev '^(xaden/|AGENTS\.md$)' || true)"
  assert "the footprint without the workflow is xaden/ and AGENTS.md" test -z "$plain"

  local claude="$WORKDIR/repos/claude" 
  make_repo "$claude" shop
  printf '# Claude\n@AGENTS.md\n' >"$claude/CLAUDE.md"
  git -C "$claude" add -A && git -C "$claude" commit -q -m "docs: claude"
  x_in "$claude" adopt --yes --assistants claude --skip-ci
  assert "an existing CLAUDE.md that has the line stays as it is" cmp -s "$claude/CLAUDE.md" "$claude-adopt-xaden/CLAUDE.md"
  local claude2="$WORKDIR/repos/claude2"
  make_repo "$claude2" shop
  printf '# Claude\nown rules\n' >"$claude2/CLAUDE.md"
  git -C "$claude2" add -A && git -C "$claude2" commit -q -m "docs: claude"
  x_in "$claude2" adopt --yes --assistants claude --skip-ci
  assert "an existing CLAUDE.md gains the line" test "$(tail -n 1 "$claude2-adopt-xaden/CLAUDE.md")" = "@AGENTS.md"
  assert "an existing CLAUDE.md keeps its text" grep -q 'own rules' "$claude2-adopt-xaden/CLAUDE.md"

  local empty="$WORKDIR/repos/empty"
  make_repo "$empty" empty
  x_in "$empty" adopt --yes --skip-ci
  assert "an empty repository gets the same layout" test -f "$empty/xaden/xaden.conf" -a -f "$empty/xaden/RULES.md" -a -f "$empty/AGENTS.md"
  assert "an empty repository gets a commit on the adoption branch" test "$(git -C "$empty" branch --show-current)" = "chore/adopt-xaden"
}

# REQ-069 existing hooks, CI and tools are chained, reused and never replaced
test_reuse_of_existing_tooling() {
  local repo="$WORKDIR/repos/hook-plain" husky="$WORKDIR/repos/hook-husky" worktree out
  make_repo "$repo" shop
  printf '#!/bin/sh\necho team hook\n' >"$repo/.git/hooks/pre-commit" && chmod +x "$repo/.git/hooks/pre-commit"
  x_in "$repo" adopt --yes --skip-ci
  assert "an existing plain git hook keeps its content" grep -q 'echo team hook' "$repo/.git/hooks/pre-commit"
  assert "Xaden is chained into the existing hook" grep -q 'xaden hook pre-commit' "$repo/.git/hooks/pre-commit"
  assert "a commit-msg hook is added" grep -q 'xaden hook commit-msg' "$repo/.git/hooks/commit-msg"

  make_repo "$husky" husky
  x_in "$husky" adopt --yes --skip-ci
  worktree="$husky-adopt-xaden"
  assert "husky: the existing hook keeps its command" grep -q 'npm run lint' "$worktree/.husky/pre-commit"
  assert "husky: Xaden is chained into the tracked hook" grep -q 'xaden hook pre-commit' "$worktree/.husky/pre-commit"
  assert "husky: core.hooksPath is not set over the manager" test -z "$(git -C "$husky" config --get core.hooksPath || true)"
  assert "husky: the hook step is its own commit" bash -c 'git -C "$1" log --format=%s main..HEAD | grep -q "husky hooks"' _ "$worktree"
  assert "husky: a mapped test and lint command are used" grep -q '^check.lint = npm run lint$' "$worktree/xaden/xaden.conf"

  local manager
  for manager in pre-commit lefthook; do
    make_repo "$WORKDIR/repos/$manager" $manager
    printf '#!/usr/bin/env bash\n# File generated by %s\necho %s ran\n' "$manager" "$manager" >"$WORKDIR/repos/$manager/.git/hooks/pre-commit" && chmod +x "$WORKDIR/repos/$manager/.git/hooks/pre-commit"
    x_in "$WORKDIR/repos/$manager" adopt --scan
    assert "$manager: the hook manager is recognised" grep -q "hook manager .*$manager" "$XOUT"
    x_in "$WORKDIR/repos/$manager" adopt --yes --skip-ci
    assert "$manager: adoption succeeds" test "$XRC" -eq 0
    assert "$manager: the generated hook keeps its content" grep -q "$manager ran" "$WORKDIR/repos/$manager/.git/hooks/pre-commit"
    assert "$manager: Xaden is chained into it" grep -q 'xaden hook pre-commit' "$WORKDIR/repos/$manager/.git/hooks/pre-commit"
    assert "$manager: no tracked file changes for the hook" test -z "$(git -C "$WORKDIR/repos/$manager-adopt-xaden" diff --name-only main HEAD | grep -E 'lefthook|pre-commit-config|husky' || true)"
    x_in "$WORKDIR/repos/$manager-adopt-xaden" setup
    assert "$manager: xaden setup is idempotent" test "$(grep -c 'xaden hook pre-commit' "$WORKDIR/repos/$manager/.git/hooks/pre-commit")" = "1"
  done

  make_repo "$WORKDIR/repos/overcommit" shop
  : >"$WORKDIR/repos/overcommit/.overcommit.yml"
  x_in "$WORKDIR/repos/overcommit" adopt --yes
  assert "an unsupported hook manager stops with a manual step" test "$XRC" -eq 4
  assert "the manual step is named" grep -q 'Manual step' "$XOUT"
  assert "nothing was created for the unsupported hook manager" test ! -e "$WORKDIR/repos/overcommit-adopt-xaden"
  make_repo "$WORKDIR/repos/gitlab" shop
  : >"$WORKDIR/repos/gitlab/.gitlab-ci.yml" && rm -rf "$WORKDIR/repos/gitlab/.github"
  x_in "$WORKDIR/repos/gitlab" adopt --yes
  assert "an unsupported CI system stops with a manual step" test "$XRC" -eq 4
  x_in "$WORKDIR/repos/gitlab" adopt --yes --skip-ci
  assert "--skip-ci adopts without the unsupported CI system" test "$XRC" -eq 0

  out="$WORKDIR/repos/hook-plain-adopt-xaden"
  x_in "$out" check
  assert "the mapped test command runs" grep -q '^==> check: test' "$XOUT"
  assert "the mapped lint command runs" grep -q '^==> check: lint' "$XOUT"
  assert "Xaden's own language presets stay unused" bash -c '! grep -q "python:\|node:" "$1"' _ "$XOUT"

  # gaps and presets
  local bare="$WORKDIR/repos/bare"
  make_repo "$bare" bare-python
  x_in "$bare" adopt --scan
  assert "the scan lists each gap" grep -q 'gaps .*test lint typecheck' "$XOUT"
  x_in "$bare" adopt --yes --skip-ci --mode strict
  assert "without the preset no configuration file is added" test ! -e "$bare-adopt-xaden/ruff.toml"
  x_in "$bare-adopt-xaden" check
  assert "strict: a gap is an error" test "$XRC" -ne 0
  assert "the gap is named" grep -q "gap: no 'lint' check is configured" "$XOUT"
  git -C "$bare" worktree remove --force "$bare-adopt-xaden" && git -C "$bare" branch -D chore/adopt-xaden >/dev/null
  x_in "$bare" adopt --yes --skip-ci --mode advisory
  x_in "$bare-adopt-xaden" check
  assert "advisory: a gap is a warning" grep -q "WARNING: gap: no 'lint' check" "$XOUT"
  git -C "$bare" worktree remove --force "$bare-adopt-xaden" && git -C "$bare" branch -D chore/adopt-xaden >/dev/null
  printf '[lint]\nselect = ["E"]\n' >"$bare/ruff.toml"
  git -C "$bare" add -A && git -C "$bare" commit -q -m "build: own ruff configuration"
  x_in "$bare" adopt --yes --skip-ci --preset
  worktree="$bare-adopt-xaden"
  assert "the preset is its own commit" bash -c 'git -C "$1" log --format=%s main..HEAD | grep -q "python preset"' _ "$worktree"
  assert "the preset writes its configuration at the root" test -f "$worktree/mypy.ini" -a -f "$worktree/requirements-dev.txt"
  assert "an existing partial configuration is never overwritten" grep -q 'select = \["E"\]' "$worktree/ruff.toml"
  assert "the difference is shown" grep -q 'ruff.toml exists and differs' "$XOUT"
  assert "the install command is printed, not run" grep -q 'pip install -r requirements-dev.txt' "$XOUT"
  assert "the preset maps its commands" grep -q '^check.typecheck = mypy \.$' "$worktree/xaden/xaden.conf"
  assert "the preset's commit has only preset files and the mapping" test -z "$(git -C "$worktree" show --name-only --format= HEAD | grep -Ev '^(mypy\.ini|requirements-dev\.txt|xaden/xaden\.conf|xaden/footprint\.txt)$' || true)"
}

# fake_release <dir> <version>: a release folder with v<version>.tar.gz, built from this working tree.
fake_release() {
  local dir=$1 version=$2 tree="$1/build/xaden-$2"
  rm -rf "$dir" && mkdir -p "$tree"
  git -C "$SCAFFOLD_ROOT" ls-files -z | (cd "$SCAFFOLD_ROOT" && xargs -0 tar cf - 2>/dev/null) | tar xf - -C "$tree"
  printf '%s\n' "$version" >"$tree/VERSION"
  printf '## [%s] - 2099-01-01\n\n### Added\n- Something new in %s.\n\n' "$version" "$version" >"$WORKDIR/entry.md"
  { sed -n '1,/^## \[Unreleased\]/p' "$tree/CHANGELOG.md"; printf '\n'; cat "$WORKDIR/entry.md"; sed '1,/^## \[Unreleased\]/d' "$tree/CHANGELOG.md"; } >"$tree/CHANGELOG.md.new"
  mv "$tree/CHANGELOG.md.new" "$tree/CHANGELOG.md"
  tar czf "$dir/v$version.tar.gz" -C "$dir/build" "xaden-$version"
}

# REQ-071 REQ-072 pinned versions, upgrades and downloads only with a yes
test_versions_and_downloads() {
  local repo worktree releases="$WORKDIR/releases" home="$WORKDIR/xaden-home" upgraded
  fake_release "$releases" 9.9.9
  export XADEN_RELEASES_URL="file://$releases" XADEN_HOME="$home"
  worktree="$(adopted_copy versions)"
  repo="${worktree%-adopt-xaden}"

  x_in "$worktree" doctor
  assert "doctor reports installed and pinned version" grep -q 'installed 0.2.3, project pinned 0.2.3' "$XOUT"
  PATH="$(path_without curl)" x_in "$worktree" doctor
  assert "doctor works without curl, so it uses no network" grep -q 'installed 0.2.3' "$XOUT"
  x_in "$worktree" upgrade --check
  assert "looking for newer releases needs a terminal and a yes" test "$XRC" -eq 3
  assert "nothing was looked up without a terminal" grep -q 'did not look for a newer release' "$XOUT"

  x_answers n "$worktree" upgrade 9.9.9
  assert "no answer but yes downloads nothing" test ! -e "$home/versions/9.9.9"
  assert "a no leaves no upgrade branch" test -z "$(git -C "$repo" branch --list 'chore/upgrade-xaden-*')"
  x_in "$worktree" upgrade 9.9.9
  assert "without a terminal nothing downloads, exit code 3" test "$XRC" -eq 3
  assert "without a terminal the exact command is named" grep -q 'xaden fetch 9.9.9' "$XOUT"
  assert "without a terminal nothing is installed" test ! -e "$home/versions"

  x_answers y "$worktree" upgrade 9.9.9
  upgraded="$worktree-upgrade-xaden-9.9.9"
  assert "upgrade works on a branch for a pull request" test "$(git -C "$upgraded" branch --show-current)" = "chore/upgrade-xaden-9.9.9"
  assert "upgrade bumps the version" grep -q '^version = 9.9.9$' "$upgraded/xaden/xaden.conf"
  assert "upgrade bumps the checksum" test "$(grep '^checksum' "$upgraded/xaden/xaden.conf")" != "$(grep '^checksum' "$worktree/xaden/xaden.conf")"
  assert "upgrade regenerates RULES.md for the new version" grep -q 'Generated from Xaden 9.9.9' "$upgraded/xaden/RULES.md"
  assert "upgrade shows the changelog entries" grep -q 'Something new in 9.9.9' "$XOUT"
  assert "upgrade shows the diff" grep -q 'xaden/xaden.conf' "$XOUT"
  assert "upgrade updates the pinned workflow" grep -q 'XADEN_VERSION: "9.9.9"' "$upgraded/.github/workflows/xaden.yml"
  assert "the project on the old branch is unchanged" grep -q '^version = 0.2.3$' "$worktree/xaden/xaden.conf"
  assert "the downloaded version is installed once" test -x "$home/versions/9.9.9/scripts/xaden.sh"

  # a newer Xaden installed on one machine changes no repository file; the pinned one is used
  x_in "$worktree" doctor
  assert "an installed newer version changes nothing in the project" test -z "$(git -C "$worktree" status --porcelain)"

  # a pinned version that is missing
  rm -rf "$home"
  x_in "$upgraded" check
  assert "a missing pinned version without a terminal exits with 3" test "$XRC" -eq 3
  assert "the exact fetch command is printed" grep -q 'xaden fetch 9.9.9' "$XOUT"
  assert "the source and the checksum are shown" grep -q 'checksum:' "$XOUT"
  assert "nothing was installed" test ! -e "$home"
  x_answers n "$upgraded" check
  assert "the answer no downloads nothing" test ! -e "$home"
  x_answers "" "$upgraded" check
  assert "no answer is no" test ! -e "$home"
  x_answers y "$upgraded" check
  assert "a yes installs the pinned version after the checksum matched" test -x "$home/versions/9.9.9/scripts/xaden.sh"
  x_in "$upgraded" check
  assert "the yes is not remembered, the next run uses the installed copy without asking" test -x "$home/versions/9.9.9/scripts/xaden.sh"
  assert "the project check runs with the pinned version" grep -q 'check mode: full' "$XOUT"
  rm -rf "$home"
  edit_file "$upgraded/xaden/xaden.conf" 's/^checksum = .*/checksum = 0000000000000000000000000000000000000000000000000000000000000000/'
  x_answers y "$upgraded" fetch 9.9.9
  assert "a checksum mismatch exits non-zero" test "$XRC" -eq 5
  assert "a checksum mismatch installs nothing" test ! -e "$home/versions/9.9.9"
  assert "a checksum mismatch is a plain error without jokes" grep -q 'does not match the checksum' "$XOUT"

  # rules that do not match the pinned version fail the check and name the fix
  edit_file "$worktree/xaden/RULES.md" 's/Generated, do not edit/Edited by hand/'
  x_in "$worktree" check
  assert "RULES.md that does not match the pinned version fails" test "$XRC" -ne 0
  assert "the fix is named" grep -q 'run: xaden rules' "$XOUT"
  x_in "$worktree" rules
  x_in "$worktree" check
  assert "xaden rules repairs it" test "$XRC" -eq 0

  # an archive from the network that is not safe to extract
  if need_tool python3 "unsafe archive tests"; then
    local bad="$WORKDIR/bad-releases" worktree2
    mkdir -p "$bad"
    python3 - "$bad" <<'PY'
import io, sys, tarfile
out = sys.argv[1]
def archive(name, members):
    with tarfile.open(f"{out}/{name}", "w:gz") as tar:
        for member, data, kind in members:
            info = tarfile.TarInfo(member)
            if kind == "link":
                info.type = tarfile.SYMTYPE
                info.linkname = "/etc"
                tar.addfile(info)
            else:
                info.size = len(data)
                tar.addfile(info, io.BytesIO(data))
archive("v8.8.8.tar.gz", [("xaden-8.8.8/VERSION", b"8.8.8\n", "file"), ("xaden-8.8.8/../evil", b"x", "file")])
archive("v8.8.7.tar.gz", [("xaden-8.8.7/VERSION", b"8.8.7\n", "file"), ("xaden-8.8.7/link", b"", "link")])
PY
    worktree2="$(adopted_copy unsafe)"
    for version in 8.8.8 8.8.7; do
      XADEN_RELEASES_URL="file://$bad" x_answers y "$worktree2" upgrade "$version"
      assert "an unsafe archive ($version) is refused" test "$XRC" -ne 0
      assert "an unsafe archive ($version) installs nothing" test ! -e "$home/versions/$version"
    done
    assert "an unsafe archive writes nothing outside its folder" test ! -e "$WORKDIR/evil"
  fi

  # REQ-077 signed releases: the pinned checksum comes from the maintainer, not from the download
  if need_tool ssh-keygen "signature tests"; then
    local sign="$WORKDIR/sign" assets="$WORKDIR/assets/v9.9.9" extracted signed_worktree
    mkdir -p "$sign" "$assets" "$sign/tree"
    ssh-keygen -q -t ed25519 -N '' -C test -f "$sign/key" && ssh-keygen -q -t ed25519 -N '' -C other -f "$sign/other"
    printf 'release@xaden.dev namespaces="xaden-release" %s\n' "$(cat "$sign/key.pub")" >"$sign/signers"
    tar xzf "$releases/v9.9.9.tar.gz" -C "$sign/tree" --strip-components=1
    extracted="$(tree_checksum "$sign/tree")"
    printf '%s  xaden-9.9.9\n' "$extracted" >"$assets/xaden-9.9.9.checksum"
    ssh-keygen -q -Y sign -f "$sign/key" -n xaden-release "$assets/xaden-9.9.9.checksum"
    export XADEN_ASSETS_URL="file://$WORKDIR/assets" XADEN_SIGNERS_FILE="$sign/signers"
    signed_worktree="$(adopted_copy signed)"

    rm -rf "$home"
    x_answers y "$signed_worktree" upgrade 9.9.9
    assert "a signed release upgrades" test "$XRC" -eq 0
    assert "the signature is reported as verified" grep -q 'signature verified' "$XOUT"
    assert "the pinned checksum is the signed one" grep -q "^checksum = $extracted\$" "$signed_worktree-upgrade-xaden-9.9.9/xaden/xaden.conf"

    rm -rf "$home" "$signed_worktree-upgrade-xaden-9.9.9" && git -C "${signed_worktree%-adopt-xaden}" worktree prune && git -C "${signed_worktree%-adopt-xaden}" branch -D chore/upgrade-xaden-9.9.9 >/dev/null
    printf '%s  xaden-9.9.9\n' "0000000000000000000000000000000000000000000000000000000000000000" >"$assets/xaden-9.9.9.checksum.tampered"
    cp "$assets/xaden-9.9.9.checksum" "$assets/original.checksum" && cp "$assets/xaden-9.9.9.checksum.tampered" "$assets/xaden-9.9.9.checksum"
    x_answers y "$signed_worktree" upgrade 9.9.9
    assert "a changed checksum file fails with exit code 6" test "$XRC" -eq 6
    assert "nothing is installed after a bad signature" test ! -e "$home/versions/9.9.9"

    cp "$assets/original.checksum" "$assets/xaden-9.9.9.checksum" && rm -f "$assets/xaden-9.9.9.checksum.sig"
    ssh-keygen -q -Y sign -f "$sign/other" -n xaden-release "$assets/xaden-9.9.9.checksum"
    x_answers y "$signed_worktree" upgrade 9.9.9
    assert "a signature by an unknown key fails with exit code 6" test "$XRC" -eq 6

    rm -rf "${assets:?}"/* "$home"
    x_answers y "$signed_worktree" upgrade 9.9.9
    assert "a release without a signature is installed with a warning" test "$XRC" -eq 0
    assert "the warning names trust on first use" grep -q 'trust on first use' "$XOUT"
    unset XADEN_ASSETS_URL XADEN_SIGNERS_FILE
  fi

  assert "only fetch.sh reaches the network" bash -c \
    '! grep -rnE "^[^#]*(curl|wget)[[:space:]]|^[^#]*git (clone|fetch|pull|ls-remote)" "$1/scripts" "$1/template/scripts" --include="*.sh" | grep -v "scripts/fetch.sh:" | grep .' _ "$SCAFFOLD_ROOT"
  unset XADEN_RELEASES_URL XADEN_HOME
}

# REQ-068 modes and baselines
test_modes_and_baselines() {
  need_tool shellcheck "mode and baseline tests" || return 0
  local worktree="$WORKDIR/repos/modes-adopt-xaden" repo="$WORKDIR/repos/modes" baseline
  make_repo "$repo" shop
  x_in "$repo" adopt --yes --skip-ci
  baseline="$worktree/xaden/baselines/shellcheck.txt"
  assert "existing violations are recorded" test -s "$baseline"
  x_in "$worktree" check
  assert "recorded violations do not fail the checks" test "$XRC" -eq 0

  printf 'echo $2\n' >>"$worktree/scripts/build.sh"
  git -C "$worktree" add -A && git -C "$worktree" -c core.hooksPath=/dev/null commit -q -n -m "fix: add a violation"
  x_in "$worktree" check
  assert "changed-files: a new violation in a changed file fails" test "$XRC" -ne 0
  assert "the violation is named" grep -q 'build.sh: note: Double quote' "$XOUT"
  edit_file "$worktree/xaden/xaden.conf" 's/^mode = .*/mode = advisory/'
  x_in "$worktree" check
  assert "advisory: the same violation only warns" test "$XRC" -eq 0
  assert "advisory says it is not blocking" grep -q 'advisory mode: not blocking' "$XOUT"
  edit_file "$worktree/xaden/xaden.conf" 's/^mode = .*/mode = strict/'
  x_in "$worktree" check
  assert "strict: it fails" test "$XRC" -ne 0

  # a violation in a file the change does not touch
  git -C "$worktree" reset -q --hard HEAD~1
  edit_file "$worktree/xaden/xaden.conf" 's/^mode = .*/mode = changed-files/'
  : >"$baseline"
  x_in "$worktree" check
  assert "changed-files: a violation in an untouched file does not fail" test "$XRC" -eq 0
  edit_file "$worktree/xaden/xaden.conf" 's/^mode = .*/mode = strict/'
  x_in "$worktree" check
  assert "strict: a violation in any file fails" test "$XRC" -ne 0
  git -C "$worktree" checkout -q -- xaden/baselines

  # the baseline shrinks when a violation is fixed, and never grows
  printf '#!/bin/sh\necho "$1"\n' >"$worktree/scripts/build.sh"
  env -u CI "$XADEN" check >/dev/null 2>&1 || true # (cwd is not the project: harmless)
  (cd "$worktree" && env -u CI "$XADEN" check) >"$XOUT" 2>&1 || true
  assert "a fixed violation leaves the baseline" test ! -s "$baseline"
  assert "the baseline says it shrank" grep -q 'shrank by 1' "$XOUT"
  printf 'echo $3\n' >>"$worktree/scripts/build.sh"
  (cd "$worktree" && env -u CI "$XADEN" check) >"$XOUT" 2>&1 || true
  assert "the baseline never grows" test ! -s "$baseline"
  git -C "$worktree" checkout -q -- scripts/build.sh

  # another commit convention: references only advise
  printf 'wip stuff\n' >"$WORKDIR/message.txt"
  x_in "$worktree" hook commit-msg "$WORKDIR/message.txt"
  assert "another convention: the commit message hook passes" test "$XRC" -eq 0
  edit_file "$worktree/xaden/xaden.conf" 's/^commit-convention = .*/commit-convention = conventional/'
  x_in "$worktree" hook commit-msg "$WORKDIR/message.txt"
  assert "Conventional Commits: the hook rejects a bad message" test "$XRC" -ne 0
  assert "the rule file makes a mode change an approval point (REQ-044)" bash -c 'tr "\n" " " <"$1" | grep -q "mode. in .xaden/xaden.conf.*is an .*Approval point"' _ "$SCAFFOLD_ROOT/template/AGENTS.md"

  # a real commit goes through the chained hook
  git -C "$worktree" checkout -q -- xaden/xaden.conf
  printf 'echo $4\n' >>"$worktree/scripts/build.sh"
  git -C "$worktree" add scripts/build.sh
  assert_fails "the pre-commit hook blocks a new violation in a changed file" git -C "$worktree" commit -q -m "fix: bad script"
  git -C "$worktree" checkout -q HEAD -- scripts/build.sh
  printf '# note\n' >>"$worktree/README.md"
  git -C "$worktree" add README.md
  assert "the pre-commit hook lets a clean commit through" git -C "$worktree" commit -q -m "docs: note"
}

# REQ-070 prompts, REQ-075 ignore list
test_prompts_and_ignore_list() {
  local worktree
  worktree="$(adopted_copy prompts)"
  x_in "$worktree" prompt kickoff
  assert "a default prompt is printed for the adopted layout" grep -q 'xaden req' "$XOUT"
  assert "the printed prompt names no path of the copied layout" bash -c '! grep -nE "scripts/(req|check|persona)\.sh|docs/requirements" "$1"' _ "$XOUT"
  mkdir -p "$worktree/xaden/prompts" && printf 'The team kickoff.\n' >"$worktree/xaden/prompts/kickoff.md"
  x_in "$worktree" prompt kickoff
  assert "a team prompt of the same name overrides the default" grep -q 'The team kickoff' "$XOUT"
  x_in "$worktree" prompt no-such-prompt
  assert "an unknown prompt is an error" test "$XRC" -ne 0

  local before
  before="$(git -C "$worktree" status --porcelain)"
  x_in "$worktree" ignore-list
  assert "the ignore list names the Xaden paths" test "$(cat "$XOUT")" = "$(printf 'xaden/\nAGENTS.md\nCLAUDE.md')"
  assert "the ignore list changes no file" test "$(git -C "$worktree" status --porcelain)" = "$before"
  rm "$worktree/CLAUDE.md"
  x_in "$worktree" ignore-list
  assert "CLAUDE.md is listed only when present" test "$(cat "$XOUT")" = "$(printf 'xaden/\nAGENTS.md')"
}

# REQ-076 autopilot
test_autopilot() {
  local base="$WORKDIR/autopilot" project
  rm -rf "$base" && mkdir -p "$base"
  x_in "$base" new --autopilot --stack python demo
  assert "without a terminal autopilot prints the plan and changes nothing" test ! -e "$base/demo"
  assert "the plan names the install commands" grep -q 'pip install -r requirements-dev.txt' "$XOUT"
  x_answers n "$base" new --autopilot --stack python demo
  assert "anything but yes changes nothing" test ! -e "$base/demo"

  mkdir -p "$base/existing" && printf 'print(1)\n' >"$base/existing/app.py"
  x_answers y "$base" new --autopilot --stack python existing
  assert "a folder with code stops and points to adopt" test "$XRC" -eq 2
  assert "it points to xaden adopt" grep -q 'xaden adopt' "$XOUT"
  assert "it changes nothing" test "$(ls -A "$base/existing")" = "app.py"

  PATH="$(path_without curl)" x_answers y "$base" new --autopilot --stack python demo
  project="$base/demo"
  assert "autopilot succeeds without curl, so it downloads nothing" test "$XRC" -eq 0
  assert "the project is a git repository with the first commit on main" test "$(git -C "$project" branch --show-current)" = "main"
  assert "the layout is the xaden folder" test -f "$project/xaden/xaden.conf" -a -f "$project/xaden/RULES.md" -a -f "$project/AGENTS.md"
  assert "the mode is strict" grep -q '^mode = strict$' "$project/xaden/xaden.conf"
  assert "the stack's preset is written" test -f "$project/ruff.toml" -a -f "$project/mypy.ini"
  assert "a CI workflow is added" test -f "$project/.github/workflows/xaden.yml"
  assert "hooks are active" grep -q 'xaden hook pre-commit' "$project/.git/hooks/pre-commit"
  assert "the install commands are printed" grep -q 'pip install -r requirements-dev.txt' "$XOUT"
  assert "nothing is pushed: no remote" test -z "$(git -C "$project" remote)"
  assert "skipped checks end with a warning, never a success sign" bash -c 'tail -n 3 "$1" | grep -q "^WARNING:" && ! grep -q "^OK: all checks passed" "$1"' _ "$XOUT"

  x_answers y "$base" new --autopilot --stack node webapp
  assert "the node stack prints exact package versions" grep -q 'npm install --save-dev --save-exact eslint@10.12.0' "$XOUT"
  x_answers y "$base" new --autopilot --stack python demo
  assert "an existing project is not touched again" test "$XRC" -eq 2
}

# REQ-071 a project with a copy of the tooling moves to the pinned layout with `xaden adopt`
test_migration() {
  local repo="$WORKDIR/repos/classic" worktree
  rm -rf "$repo"
  env ALLOW_MAIN_COMMIT=0 "$SCAFFOLD_ROOT/scripts/new-project.sh" classic-app "$repo" >/dev/null 2>&1
  printf '\nOur own twist.\n' >>"$repo/prompts/feature.md"
  git -C "$repo" commit -q -n -am "docs: our feature prompt"
  x_in "$repo" adopt --yes --skip-ci
  worktree="$repo-adopt-xaden"
  assert "migration succeeds" test "$XRC" -eq 0
  assert "requirements move into xaden/" test -f "$worktree/xaden/requirements/INDEX.md" -a -d "$worktree/xaden/requirements/first-epic"
  assert "the copied tooling is removed" test ! -e "$worktree/scripts/check.sh" -a ! -e "$worktree/prompts/bugfix.md" -a ! -e "$worktree/.scaffold"
  assert "a prompt the team edited stays" grep -q 'Our own twist' "$worktree/prompts/feature.md"
  assert "the edited file is listed" grep -q 'prompts/feature.md' "$XOUT"
  assert "the project's own README and guides stay" test -f "$worktree/README.md" -a -f "$worktree/docs/user-guide.md"
  assert "AGENTS.md is now the short block" bash -c '[ "$(wc -l <"$1")" -lt 12 ] && grep -q "xaden/RULES.md" "$1"' _ "$worktree/AGENTS.md"
  assert "the copied hooks path is gone and Xaden is chained" bash -c 'test -z "$(git -C "$1" config --get core.hooksPath || true)" && grep -q "xaden hook pre-commit" "$1/.git/hooks/pre-commit"' _ "$repo"
  x_in "$worktree" check
  assert "the migrated project passes the checks" test "$XRC" -eq 0
}

# REQ-066 `xaden new` creates the same layout `xaden adopt` gives an empty repository
test_new_project_layout() {
  local base="$WORKDIR/new-layout" project
  rm -rf "$base" && mkdir -p "$base"
  x_in "$base" new demo
  project="$base/demo"
  assert "xaden new succeeds" test "$XRC" -eq 0
  assert "the layout is the xaden folder, as adopt writes it" test -f "$project/xaden/xaden.conf" -a -f "$project/xaden/RULES.md" -a -f "$project/AGENTS.md" -a -d "$project/xaden/baselines"
  assert "the project's own files exist" test -f "$project/README.md" -a -f "$project/.gitignore" -a -f "$project/VERSION" -a -f "$project/CHANGELOG.md" -a -f "$project/SECURITY.md" -a -f "$project/xaden/threat-model.md"
  assert "no copy of the tooling" test ! -e "$project/scripts" -a ! -e "$project/prompts" -a ! -e "$project/.scaffold"
  assert "mode strict, workflow and first commit on main" bash -c 'grep -q "^mode = strict$" "$1/xaden/xaden.conf" && test -f "$1/.github/workflows/xaden.yml" && test "$(git -C "$1" branch --show-current)" = main' _ "$project"
  assert "hooks are chained" grep -q 'xaden hook pre-commit' "$project/.git/hooks/pre-commit"
  assert "without Claude users there is no CLAUDE.md" test ! -e "$project/CLAUDE.md"
  assert "the tree is clean after creation" test -z "$(git -C "$project" status --porcelain)"
  x_in "$project" check
  assert "a new project passes its checks" test "$XRC" -eq 0
  x_in "$project" req new core job "First job"
  assert "requirements are created in xaden/requirements" test -f "$project/xaden/requirements/core/REQ-001-first-job.md"
  git -C "$project" checkout -q -- . && git -C "$project" clean -qfd

  x_in "$base" new demo
  assert "an existing project is not created again" test "$XRC" -eq 2
  x_in "$base" new --assistants claude with-claude
  assert "--assistants claude adds CLAUDE.md with one line" test "$(cat "$base/with-claude/CLAUDE.md")" = "@AGENTS.md"
  x_in "$base" new "Bad Name"
  assert "a bad project name is refused" test "$XRC" -ne 0
  GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.useConfigOnly GIT_CONFIG_VALUE_0=true x_in "$base" env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL "$XADEN" new fails
  assert "a failed creation fails" test "$XRC" -ne 0
  assert "a failed creation leaves no partial folder" test ! -e "$base/fails"
  x_in "$base" new --classic classic
  assert "--classic keeps the copied layout" test -f "$base/classic/scripts/check.sh" -a ! -e "$base/classic/xaden"

  # a stack that appears later is noticed, and the preset can be added
  printf '{ "name": "demo" }\n' >"$project/package.json"
  x_in "$project" check
  assert "strict: a stack without checks is an error" test "$XRC" -ne 0
  assert "the gap is named" grep -q "gap: no 'test' check is configured" "$XOUT"
  x_in "$project" preset node
  assert "xaden preset adds the preset's configuration" test -f "$project/eslint.config.mjs"
  assert "xaden preset maps the checks" grep -q '^check.lint = npx eslint \.$' "$project/xaden/xaden.conf"
  assert "xaden preset prints the install command" grep -q 'npm install --save-dev --save-exact eslint@' "$XOUT"

  # release works without guides
  if need_tool gitleaks "release in an adopted project"; then
    local rel="$base/rel"
    x_in "$base" new rel
    x_in "$rel" release minor
    assert "a release is blocked while the security documents have TODO markers" test "$XRC" -ne 0
    assert "the unfilled documents are named" grep -q 'unfilled TODO marker' "$XOUT"
    sed -i.bak 's/<!-- TODO/<!-- done/' "$rel/SECURITY.md" "$rel/xaden/threat-model.md" && rm -f "$rel/SECURITY.md.bak" "$rel/xaden/threat-model.md.bak"
    git -C "$rel" add -A && git -C "$rel" -c core.hooksPath=/dev/null commit -q -m "docs: fill the security documents"
    x_in "$rel" release minor
    assert "xaden release succeeds in an adopted project" test "$XRC" -eq 0
    assert "release bumps VERSION and tags" bash -c 'test "$(cat "$1/VERSION")" = 0.1.0 && git -C "$1" tag | grep -qx v0.1.0' _ "$rel"
    assert "release stamps the changelog" grep -q '^## \[0.1.0\]' "$rel/CHANGELOG.md"
  fi
}

test_messages
test_scan_and_plan
test_adopt_and_remove
test_reuse_of_existing_tooling
test_versions_and_downloads
test_modes_and_baselines
test_prompts_and_ignore_list
test_autopilot
test_migration
test_new_project_layout
