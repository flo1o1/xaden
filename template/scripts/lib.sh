#!/usr/bin/env bash
# Shared helpers for scripts in this repo. Source it; do not execute it.
# Portable on Linux and macOS (bash >= 3.2, POSIX sed/awk/tar only).

# Count of failed checks; callers read it to decide the exit code.
FAILURES=0
# "1" makes a missing tool a failure instead of a skipped check.
STRICT="${STRICT:-0}"

info() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# has_command <name>: true if <name> is on PATH.
has_command() { command -v "$1" >/dev/null 2>&1; }

# run_tool <label> <binary> [args...]
# Runs <binary>; counts a failure if it exits non-zero. A missing binary is
# skipped with a warning, or counted as failure when STRICT=1.
run_tool() {
  local label=$1 binary=$2
  shift 2
  if ! has_command "$binary"; then
    if [ "$STRICT" = "1" ]; then
      warn "required tool missing: $binary ($label)"
      FAILURES=$((FAILURES + 1))
    else
      warn "skipping $label: '$binary' not installed"
    fi
    return 0
  fi
  info "$label"
  if ! "$binary" "$@"; then
    warn "$label failed"
    FAILURES=$((FAILURES + 1))
  fi
}

# --- check helpers shared by check.sh and the scaffold's check-scaffold.sh -------------
# Modes: "staged" = pre-commit (staged files only, offline, seconds);
#        "full"   = everything (CI, release, before declaring work done).

# Files selected by the last collect_files call (bash array).
TARGETS=()

# collect_files <mode> <include-regex> [exclude-regex]: fills TARGETS with matching staged
# (staged mode) or tracked (full mode) files, relative to the current directory.
collect_files() {
  local mode=$1 pattern=$2 exclude=${3:-^$} file
  TARGETS=()
  while IFS= read -r file; do
    [ -f "$file" ] && TARGETS+=("$file")
  done < <(
    if [ "$mode" = "staged" ]; then
      git diff --cached --name-only --diff-filter=ACMR
    else
      git ls-files
    fi | grep -E "$pattern" | grep -Ev "$exclude" || true
  )
}

# lint_shell <mode>: shellcheck on shell scripts and extension-less git hooks.
lint_shell() {
  collect_files "$1" '(\.sh$|(^|/)hooks/[^/.]+$|^\.githooks/)'
  [ ${#TARGETS[@]} -eq 0 ] && return 0
  run_tool "shellcheck" shellcheck "${TARGETS[@]}"
}

# scan_secrets <mode>: gitleaks on the staged diff, or on the whole git history.
scan_secrets() {
  local scope=()
  [ "$1" = "staged" ] && scope=(--staged)
  if has_command gitleaks && gitleaks git --help >/dev/null 2>&1; then
    run_tool "secret scan (gitleaks)" gitleaks git --no-banner --redact --log-level warn ${scope[@]+"${scope[@]}"}
  elif [ "$1" = "staged" ]; then # gitleaks < 8.19
    run_tool "secret scan (gitleaks)" gitleaks protect --staged --no-banner --redact
  else
    run_tool "secret scan (gitleaks)" gitleaks detect --no-banner --redact
  fi
}

# scan_sast <mode> <rules-dir> [exclude-regex]: semgrep with versioned local rules only (no network).
scan_sast() {
  collect_files "$1" '\.(py|js|jsx|mjs|cjs|ts|tsx)$' "${3:-^$}"
  [ ${#TARGETS[@]} -eq 0 ] && return 0
  SEMGREP_ENABLE_VERSION_CHECK=0 run_tool "SAST (semgrep, local rules)" \
    semgrep scan --config "$2" --metrics=off --disable-version-check --error --quiet "${TARGETS[@]}"
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
