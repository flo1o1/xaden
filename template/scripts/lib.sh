#!/usr/bin/env bash
# Shared helpers for scripts in this repo. Source it; do not execute it.
# Portable on Linux and macOS (bash >= 3.2, POSIX sed/awk/tar only).

# Check results (REQ-019): every check is passed, failed or skipped; finish_checks reports them.
FAILURES=0
CHECKS_PASSED=0
SKIPPED_CHECKS=""
# "1" makes a missing tool a failure instead of a skipped check.
STRICT="${STRICT:-0}"

info() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# has_command <name>: true if <name> is on PATH.
has_command() { command -v "$1" >/dev/null 2>&1; }

# record_missing_tool <label> <binary>: a check whose tool is missing is skipped (reported
# as INCOMPLETE), or failed when STRICT=1.
record_missing_tool() {
  if [ "$STRICT" = "1" ]; then
    warn "required tool missing: $2 ($1)"
    FAILURES=$((FAILURES + 1))
  else
    warn "SKIPPED $1: '$2' not installed"
    SKIPPED_CHECKS="$SKIPPED_CHECKS${SKIPPED_CHECKS:+, }$1"
  fi
}

# run_tool <label> <binary> [args...]: runs one check and records passed or failed;
# a missing binary is recorded by record_missing_tool.
run_tool() {
  local label=$1 binary=$2
  shift 2
  if ! has_command "$binary"; then
    record_missing_tool "$label" "$binary"
    return 0
  fi
  info "$label"
  if "$binary" "$@"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    warn "$label failed"
    FAILURES=$((FAILURES + 1))
  fi
}

# finish_checks: prints the summary and exits. Failures exit 1. Skipped checks never count
# as passed: the run is reported INCOMPLETE (exit 0 locally; --strict turns skips into failures).
finish_checks() {
  printf '==> summary: %d passed, %d failed, skipped: %s\n' \
    "$CHECKS_PASSED" "$FAILURES" "${SKIPPED_CHECKS:-none}"
  [ "$FAILURES" -eq 0 ] || die "$FAILURES check(s) failed"
  if [ -n "$SKIPPED_CHECKS" ]; then
    warn "INCOMPLETE: not all checks ran. Install the missing tools, or use --strict to require them."
    exit 0
  fi
  info "all checks passed"
}

# --- check helpers shared by check.sh and the scaffold's check-scaffold.sh -------------
# Modes: "staged" = pre-commit (staged files only, offline, seconds);
#        "full"   = everything (CI, release, before declaring work done).

# Files selected by the last collect_files call (bash array).
TARGETS=()
# Staged mode (REQ-020): the real repository, a temporary export of its index (exactly what
# will be committed) and the NUL-separated list of staged paths.
GIT_REPO=""
SNAPSHOT=""
STAGED_LIST=""

# enter_staged_snapshot <repo-root>: exports the git index to a temporary directory and
# changes into it, so checks see the staged content, not unstaged edits. Untracked dependency
# folders are linked so linters resolve. The working tree is never modified.
enter_staged_snapshot() {
  local dependency_dir
  GIT_REPO=$1
  SNAPSHOT="$(mktemp -d)"
  STAGED_LIST="$(mktemp)"
  trap 'rm -rf "$SNAPSHOT" "$STAGED_LIST"' EXIT
  git -C "$GIT_REPO" checkout-index --all --prefix="$SNAPSHOT/"
  git -C "$GIT_REPO" diff --cached --name-only -z --diff-filter=ACMR >"$STAGED_LIST"
  for dependency_dir in node_modules .venv; do
    if [ -d "$GIT_REPO/$dependency_dir" ]; then ln -s "$GIT_REPO/$dependency_dir" "$SNAPSHOT/$dependency_dir"; fi
  done
  export PROJECT_ROOT="$SNAPSHOT"
  cd "$SNAPSHOT" || die "cannot enter staged snapshot $SNAPSHOT"
}

# list_project_files: NUL-separated paths of the project's files (git-tracked files, or every
# regular file inside a staged snapshot, which only contains tracked files).
list_project_files() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git ls-files -z
  else
    find . -type f | sed 's|^\./||' | tr '\n' '\0' # POSIX; names with newlines are unsupported
  fi
}

# collect_files <mode> <include-regex> [exclude-regex]: fills TARGETS with matching staged
# (staged mode) or tracked (full mode) files, relative to the current directory.
collect_files() {
  local mode=$1 pattern=$2 exclude=${3:-^$} file
  TARGETS=()
  while IFS= read -r -d '' file; do
    if [ -f "$file" ] && printf '%s\n' "$file" | grep -E "$pattern" | grep -Evq "$exclude"; then
      TARGETS+=("$file")
    fi
  done < <(if [ "$mode" = "staged" ]; then cat "$STAGED_LIST"; else list_project_files; fi)
}

# lint_shell <mode>: shellcheck on shell scripts and extension-less git hooks.
lint_shell() {
  collect_files "$1" '(\.sh$|(^|/)hooks/[^/.]+$|^\.githooks/)'
  [ ${#TARGETS[@]} -eq 0 ] && return 0
  run_tool "shellcheck" shellcheck -x "${TARGETS[@]}" # -x: follow sourced lib.sh even if unstaged
}

# scan_secrets <mode>: gitleaks on the staged diff, or on the whole git history. Always runs
# against the real repository (GIT_REPO in staged mode), never the snapshot.
scan_secrets() {
  local repo="${GIT_REPO:-.}" scope=()
  [ "$1" = "staged" ] && scope=(--staged)
  if has_command gitleaks && gitleaks git --help >/dev/null 2>&1; then
    run_tool "secret scan (gitleaks)" gitleaks git --no-banner --redact --log-level warn ${scope[@]+"${scope[@]}"} "$repo"
  elif [ "$1" = "staged" ]; then # gitleaks < 8.19
    run_tool "secret scan (gitleaks)" gitleaks protect --staged --no-banner --redact --source "$repo"
  else
    run_tool "secret scan (gitleaks)" gitleaks detect --no-banner --redact --source "$repo"
  fi
}

# scan_sast <mode> <rules-dir> [exclude-regex]: semgrep with versioned local rules only (no network).
scan_sast() {
  collect_files "$1" '\.(py|js|jsx|mjs|cjs|ts|tsx)$' "${3:-^$}"
  [ ${#TARGETS[@]} -eq 0 ] && return 0
  SEMGREP_ENABLE_VERSION_CHECK=0 run_tool "SAST (semgrep, local rules)" \
    semgrep scan --config "$2" --metrics=off --disable-version-check --error --quiet "${TARGETS[@]}"
}

# run_required_tool <label> <binary> [args...]: like run_tool, but a missing binary always
# fails. Used for tools a detected stack depends on, so "not installed" never looks green.
run_required_tool() {
  local saved_strict=$STRICT
  STRICT=1
  run_tool "$@"
  STRICT=$saved_strict
}

# require <condition-description> <command...>: counts a failure unless the command succeeds.
require() {
  local description=$1
  shift
  if ! "$@" >/dev/null 2>&1; then
    warn "missing: $description"
    FAILURES=$((FAILURES + 1))
  fi
}

# is_semver <string>: true for MAJOR.MINOR.PATCH with plain digits.
is_semver() { printf '%s' "$1" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; }

# stamp_changelog <file> <version>: turns "Unreleased" content into a dated release section.
stamp_changelog() {
  local file=$1 version=$2 tmp
  tmp="$(mktemp)"
  awk -v v="$version" -v d="$(date +%F)" '
    /^## \[Unreleased\]/ { print; print ""; print "## [" v "] - " d; next }
    { print }
  ' "$file" >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

# --- release helpers (REQ-024): never leave a partial release behind -----------------

# ensure_tag_absent <tag>: dies before anything changes if the release tag already exists.
ensure_tag_absent() {
  if git rev-parse -q --verify "refs/tags/$1" >/dev/null; then
    die "tag $1 already exists; nothing was changed"
  fi
}

# commit_release_or_restore <message> <files...>: commits the release files; if the commit
# fails, restores them to HEAD so the working tree is exactly as before, then dies.
commit_release_or_restore() {
  local message=$1
  shift
  git add -- "$@"
  if ! git commit -q -m "$message"; then
    git reset -q -- "$@"
    git checkout -q -- "$@"
    die "release commit failed; release files restored, nothing was changed"
  fi
}

# tag_release_or_report <tag>: tags HEAD; on failure explains the partial state and the
# two ways out, then dies.
tag_release_or_report() {
  if ! git tag -a "$1" -m "Release $1"; then
    warn "PARTIAL RELEASE: commit $(git rev-parse --short HEAD) exists, but tag $1 could not be created."
    warn "Either retry: git tag -a $1 -m \"Release $1\""
    warn "or undo the release commit: git reset --hard HEAD~1"
    die "tagging failed"
  fi
}

# bump_version <current> <major|minor|patch>: prints the next SemVer.
bump_version() {
  local current=$1 part=$2 major minor patch
  is_semver "$current" || die "not a valid SemVer: $current"
  IFS=. read -r major minor patch <<EOF
$current
EOF
  case "$part" in
    major) printf '%d.0.0\n' $((major + 1)) ;;
    minor) printf '%d.%d.0\n' "$major" $((minor + 1)) ;;
    patch) printf '%d.%d.%d\n' "$major" "$minor" $((patch + 1)) ;;
    *) die "bump part must be major, minor or patch (got: $part)" ;;
  esac
}
