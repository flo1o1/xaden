# shellcheck shell=bash
# Smoke test area "security" (docs/requirements/security). Sourced by tests/smoke.sh, which
# defines the helpers and creates the demo project first.

# REQ-052 dependencies are verified before they are proposed
test_dependency_vetting() {
  local security="$PROJECT/docs/security.md"
  assert "dependency policy names slopsquatting" grep -q 'slopsquatting' "$security"
  assert "dependency policy requires a registry lookup" grep -q 'look up the exact name in the' "$security"
  assert "suspicious packages are not installed" grep -q 'say so and do not install it' "$security"
}

# REQ-057: an accepted security exception fails the full check once it has expired.
test_security_exceptions() {
  local file="$PROJECT/docs/security-exceptions.md" check="$PROJECT/scripts/check-security-exceptions.sh"
  local row='| SE-001 | GHSA-xxxx in lib@1.0.0 | not reachable | input never parsed | Dana | 2026-06-14 |'
  assert "no accepted exceptions pass" env CHECK_DATE=2026-06-15 "$check"
  printf '%s\n' "$row" >>"$file"
  assert_fails_with "expired exception fails" "SE-001" env CHECK_DATE=2026-06-15 "$check"
  assert "exception expiring today passes" env CHECK_DATE=2026-06-14 "$check"
  assert_fails_with "full check fails on an expired exception" "SE-001" \
    bash -c "cd '$PROJECT' && CHECK_DATE=2026-06-15 scripts/check.sh"
  git -C "$PROJECT" add docs/security-exceptions.md
  assert "staged check ignores the expiry date" bash -c "cd '$PROJECT' && CHECK_DATE=2026-06-15 scripts/check.sh --staged"
  git -C "$PROJECT" reset -q --hard
  printf '%s\n' "${row/Dana/ }" >>"$file"
  assert_fails_with "exception without owner fails" "SE-001" env CHECK_DATE=2026-06-01 "$check"
  git -C "$PROJECT" checkout -q -- docs/security-exceptions.md
  printf '%s\n' "${row/2026-06-14/end of June}" >>"$file"
  assert_fails_with "exception with an invalid date fails" "SE-001" env CHECK_DATE=2026-06-01 "$check"
  git -C "$PROJECT" checkout -q -- docs/security-exceptions.md
  printf '%s\n' "${row/2026-06-14/2026-13-01}" >>"$file"
  assert_fails_with "exception with an impossible month fails" "SE-001" env CHECK_DATE=2026-06-01 "$check"
  git -C "$PROJECT" checkout -q -- docs/security-exceptions.md
}

test_dependency_vetting
test_security_exceptions
