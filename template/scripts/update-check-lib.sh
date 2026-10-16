#!/usr/bin/env bash
# The offline half of the update check (REQ-084): which setting is in effect, when the next check
# is due, and the cached result. Sourced by xaden, fetch.sh and context-status.sh. Nothing here
# uses the network; the lookup itself lives in scripts/fetch.sh, the only script that may.
# shellcheck source=SCRIPTDIR/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# shellcheck disable=SC2034 # read by scripts/fetch.sh
UPDATE_CHECK_FORMS="off, or a number with h or d (1h or more), for example 12h, 1d, 7d"
UPDATE_CHECK_CACHE_NAME="xaden-update-check"

# update_check_setting <conf>: "<value> <source>" of the setting in effect. The environment
# overrides the project file for one person; without either the check is off.
update_check_setting() {
  local value
  if [ -n "${XADEN_UPDATE_CHECK:-}" ]; then
    printf '%s XADEN_UPDATE_CHECK' "$XADEN_UPDATE_CHECK"
  elif value="$(conf_get "$1" update-check)" && [ -n "$value" ]; then
    printf '%s xaden/xaden.conf' "$value"
  else
    printf 'off default'
  fi
}

# update_check_seconds <value>: the interval in seconds ("0" for off). Returns 1 for a value that
# is not off and not a whole number of hours or days of at least one hour.
update_check_seconds() {
  case "$1" in
    off) echo 0 ;;
    [1-9]*h) is_whole_number "${1%h}" && echo $((${1%h} * 3600)) ;;
    [1-9]*d) is_whole_number "${1%d}" && echo $((${1%d} * 86400)) ;;
    *) return 1 ;;
  esac
}

# is_whole_number <text>: digits only.
is_whole_number() { printf '%s' "$1" | grep -Eq '^[0-9]+$'; }

# update_check_now: the clock in epoch seconds; tests may set it.
update_check_now() {
  if [ "${XADEN_TEST_MODE:-0}" = "1" ] && [ -n "${XADEN_NOW:-}" ]; then printf '%s' "$XADEN_NOW"; else date +%s; fi
}

# update_check_cache <root>: where the result is kept. In the git folder, so it is never tracked
# and all worktrees of a repository share it.
update_check_cache() {
  local common
  common="$(cd "$1" && cd "$(git rev-parse --git-common-dir 2>/dev/null)" && pwd)" || return 1
  printf '%s/%s' "$common" "$UPDATE_CHECK_CACHE_NAME"
}

# update_check_is_due <cache> <seconds>: true when there is no cache or it is older than the interval.
update_check_is_due() {
  local checked
  [ -f "$1" ] || return 0
  checked="$(sed -n 's/^checked //p' "$1" | head -n 1)"
  is_whole_number "${checked:-x}" || return 0
  [ $(($(update_check_now) - checked)) -ge "$2" ]
}

# update_check_print_cached <root>: the cached result, if any (offline).
update_check_print_cached() {
  local cache
  cache="$(update_check_cache "$1")" || return 0
  [ -f "$cache" ] || return 0
  grep -v '^checked ' "$cache" || true
}
