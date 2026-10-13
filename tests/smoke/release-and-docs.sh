# shellcheck shell=bash
# Smoke test area "release-and-docs" (docs/requirements/release-and-docs). Sourced by tests/smoke.sh, which
# defines the helpers and creates the demo project first.

# REQ-007 semantic versioning
test_bump_version() {
  assert "bump patch" test "$(bump_version 1.2.3 patch)" = "1.2.4"
  assert "bump minor resets patch" test "$(bump_version 1.2.3 minor)" = "1.3.0"
  assert "bump major resets rest" test "$(bump_version 1.2.3 major)" = "2.0.0"
  assert_fails "reject invalid semver" bump_version "1.2" patch
}

# REQ-024: the scaffold's own release restores its files when stamping fails. Runs on a minimal
# copy with the full scaffold check stubbed out (the real one would run this smoke test again).
test_scaffold_release_failures() {
  local copy="$WORKDIR/scaffold-release" head
  mkdir -p "$copy/scripts" "$copy/template/scripts"
  cp "$SCAFFOLD_ROOT/scripts/release-scaffold.sh" "$copy/scripts/"
  cp "$SCAFFOLD_ROOT/template/scripts/lib.sh" "$copy/template/scripts/"
  printf '#!/bin/sh\nexit 0\n' >"$copy/scripts/check-scaffold.sh" && chmod +x "$copy/scripts/check-scaffold.sh"
  printf '0.1.0\n' >"$copy/VERSION"
  printf '# Changelog\n\n## [Unreleased]\n\n- change\n' >"$copy/CHANGELOG.md"
  git -C "$copy" init -q -b main && git -C "$copy" add -A && git -C "$copy" commit -q -m "chore: init"
  head="$(git -C "$copy" rev-parse HEAD)"
  chmod 444 "$copy/VERSION"
  assert_fails "unwritable VERSION aborts the scaffold release" "$copy/scripts/release-scaffold.sh" patch
  assert "scaffold release files restored after failed stamp" test "$(git -C "$copy" rev-parse HEAD)$(git -C "$copy" status --porcelain)" = "$head"
  chmod 644 "$copy/VERSION"
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
  # REQ-058 security documents must be filled before a release
  assert_fails_with "release blocked by markers in SECURITY.md" "SECURITY.md" "$PROJECT/scripts/release.sh" patch
  assert "blocked release left VERSION unchanged" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")" = "0.1.0"
  edit_file "$PROJECT/SECURITY.md" '/<!-- TODO/d'
  git -C "$PROJECT" commit -q -am "docs: fill SECURITY.md"
  assert_fails_with "release blocked by markers in the threat model" "threat-model.md" "$PROJECT/scripts/check-docs.sh" --release
  edit_file "$PROJECT/docs/threat-model.md" '/<!-- TODO/d'
  git -C "$PROJECT" commit -q -am "docs: fill threat model"
  printf 'Mark a TODO item as done.\n' >>"$PROJECT/docs/user-guide.md"
  printf 'Rotate TODO list API keys yearly.\n' >>"$PROJECT/SECURITY.md"
  assert "the word TODO in guide prose does not block a release" "$PROJECT/scripts/check-docs.sh" --release
  git -C "$PROJECT" checkout -q -- docs/user-guide.md SECURITY.md
  test_release_failures
  assert "release patch (release commit on main allowed)" env ALLOW_MAIN_COMMIT=0 "$PROJECT/scripts/release.sh" patch
  assert "VERSION bumped" test "$(tr -d '[:space:]' <"$PROJECT/VERSION")" = "0.1.1"
  assert "guide stamped with version" grep -q 'Applies to version:\*\* 0.1.1' "$PROJECT/docs/user-guide.md"
  assert "tag created" git -C "$PROJECT" rev-parse v0.1.1
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
  chmod 444 "$PROJECT/docs/admin-guide.md"
  assert_fails "unwritable guide aborts the release" "$PROJECT/scripts/release.sh" patch
  assert "files restored after failed docs stamp" test "$(git -C "$PROJECT" rev-parse HEAD)$(git -C "$PROJECT" status --porcelain)" = "$head"
  chmod 644 "$PROJECT/docs/admin-guide.md"
  chmod 500 "$PROJECT/.git/refs/tags"
  assert "failed tag is reported with recovery steps" bash -c "! '$PROJECT/scripts/release.sh' patch 2>&1 | tee '$WORKDIR/tag-fail.log' >/dev/null; grep -q 'PARTIAL RELEASE' '$WORKDIR/tag-fail.log'"
  chmod 700 "$PROJECT/.git/refs/tags"
  git -C "$PROJECT" reset -q --hard "$head"
}

test_bump_version
test_scaffold_release_failures
test_release
