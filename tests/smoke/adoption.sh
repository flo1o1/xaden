# shellcheck shell=bash
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

test_messages
