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
  cp "$SCAFFOLD_ROOT/template/scripts/lib.sh" "$SCAFFOLD_ROOT/template/scripts/layout.sh" "$SCAFFOLD_ROOT/template/scripts/gate.sh" "$copy/template/scripts/"
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

# REQ-065: the guide documents both ways to get Xaden, and both ways work as written.
test_install_ways() {
  local install="$SCAFFOLD_ROOT/docs/guide/admin/install-xaden.md" platforms="$SCAFFOLD_ROOT/docs/guide/admin/requirements-and-platforms.md"
  local update="$SCAFFOLD_ROOT/docs/guide/admin/update-xaden.md"
  local extracted="$WORKDIR/extracted-zip" clone="$WORKDIR/cloned-xaden" heading version
  for heading in '## Install with git \(recommended\)' '## Install from a zip archive' '## When to choose which' '## Verify what you downloaded'; do
    assert "install guide has the heading $heading" grep -qE "^$heading\$" "$install"
  done
  for heading in '## Linux' '## macOS' '## Windows'; do
    assert "platform guide has the heading $heading" grep -qE "^$heading\$" "$platforms"
  done
  assert "guide states the Windows support level" grep -q 'untested' "$platforms"
  assert "guide says native PowerShell is not supported" grep -qi 'native PowerShell is not supported' "$platforms"
  assert "guide says the maintainer signs the checksum of every release" grep -q 'signs the checksum of every release' "$install"
  assert "guide explains the zip update" grep -q 'Download the new release' "$update"
  assert "guide explains the clone update" grep -q 'git -C ~/.xaden pull' "$update"
  assert "guide explains picking a release tag" grep -q 'git -C ~/.xaden checkout v' "$update"

  # The zip way: an archive has no .git; install.sh and xaden create must still work from it.
  version="$(tr -d '[:space:]' <"$SCAFFOLD_ROOT/VERSION")"
  mkdir -p "$extracted"
  git -C "$SCAFFOLD_ROOT" archive HEAD | tar -x -C "$extracted"
  assert "extracted archive has no git history" test ! -e "$extracted/.git"
  assert "extracted archive installs the xaden command" "$extracted/scripts/install.sh" "$WORKDIR/zip-bin"
  assert "xaden from the archive prints the version" test "$("$WORKDIR/zip-bin/xaden" version)" = "$version"
  assert "xaden from the archive creates a project" bash -c "cd '$WORKDIR' && '$WORKDIR/zip-bin/xaden' create zip-app"
  # The documented zip update: a second extraction replaces the link only after the first is uninstalled.
  mkdir -p "$extracted-next"
  git -C "$SCAFFOLD_ROOT" archive HEAD | tar -x -C "$extracted-next"
  assert_fails "a newer extraction does not replace the old link" "$extracted-next/scripts/install.sh" "$WORKDIR/zip-bin"
  assert "the old extraction removes its own link" "$extracted/scripts/install.sh" --uninstall "$WORKDIR/zip-bin"
  assert "the newer extraction installs afterwards" "$extracted-next/scripts/install.sh" "$WORKDIR/zip-bin"

  # The clone way: a release tag can be checked out and git pull follows the branch.
  git clone -q "$SCAFFOLD_ROOT" "$clone"
  # A clone has the release tags; a checkout between releases has none yet.
  git -C "$clone" rev-parse -q --verify "refs/tags/v$version" >/dev/null || git -C "$clone" tag "v$version"
  assert "a release tag can be checked out in a clone" git -C "$clone" checkout -q "v$version"
  assert "the clone installs the xaden command" "$clone/scripts/install.sh" "$WORKDIR/clone-bin"
  assert "xaden from the clone prints the version" test "$("$WORKDIR/clone-bin/xaden" version)" = "$version"
}


# REQ-064: the site contract lists existing pages and the scaffold holds no site credential.
test_site_pages() {
  local copy="$WORKDIR/site-pages" check="$SCAFFOLD_ROOT/scripts/check-site-pages.sh"
  assert "every listed site page exists" "$check" "$SCAFFOLD_ROOT"
  mkdir -p "$copy/docs" "$copy/template/scripts" "$copy/.github/workflows"
  cp "$SCAFFOLD_ROOT/template/scripts/lib.sh" "$SCAFFOLD_ROOT/template/scripts/layout.sh" "$SCAFFOLD_ROOT/template/scripts/gate.sh" "$copy/template/scripts/"
  printf 'README.md\n' >"$copy/docs/site-pages.txt"
  assert_fails "a missing site page fails the check" "$check" "$copy"
  : >"$copy/README.md"
  assert "a present site page passes" "$check" "$copy"
  printf 'token: $%s\n' '{{ secrets.SITE_DEPLOY_KEY }}' >"$copy/.github/workflows/x.yml"
  assert_fails "a site credential in a workflow fails the check" "$check" "$copy"
  printf 'token: $%s\n' '{{ secrets["SITE_DEPLOY_KEY"] }}' >"$copy/.github/workflows/x.yml"
  assert_fails "a bracket-style secret in a workflow fails the check" "$check" "$copy"
  printf 'all: $%s\n' '{{ toJSON(secrets) }}' >"$copy/.github/workflows/x.yml"
  assert_fails "passing all secrets fails the check" "$check" "$copy"
  printf 'token: $%s\n' '{{ secrets.GITHUB_TOKEN }}' >"$copy/.github/workflows/x.yml"
  assert "the built-in GITHUB_TOKEN passes" "$check" "$copy"
  printf 'README.md\nGETTING-STARTED.md' >"$copy/docs/site-pages.txt"
  assert_fails "a missing last line without newline fails the check" "$check" "$copy"
}

# The guides link to each other with relative paths (the website turns them into page links): every target exists.
test_guide_links() {
  local file link target broken=""
  while IFS= read -r file; do
    while IFS= read -r link; do
      target="${link%%#*}"
      [ -n "$target" ] || continue
      [ -e "$(dirname "$file")/$target" ] || broken="$broken ${file#"$SCAFFOLD_ROOT"/}->$link"
    done < <(grep -oE '\]\([^)#][^)]*\.md(#[^)]*)?\)' "$file" | sed -e 's/^](//' -e 's/)$//')
  done < <(find "$SCAFFOLD_ROOT/docs/guide" -name '*.md'; printf '%s\n' "$SCAFFOLD_ROOT/GETTING-STARTED.md")
  assert "every relative link in the guides resolves" test -z "$broken"
}

# REQ-077: signing a release runs clean and leaves no temp folder behind. Runs on a minimal copy with a
# throwaway key; TMPDIR points at a folder of its own so a leftover staging folder shows.
test_sign_release() {
  local copy="$WORKDIR/sign-release" tmp="$WORKDIR/sign-tmp" err="$WORKDIR/sign-release.err" rc=0
  need_tool ssh-keygen "signing test" || return 0
  mkdir -p "$copy/scripts" "$copy/template/scripts" "$tmp"
  cp "$SCAFFOLD_ROOT/scripts/sign-release.sh" "$SCAFFOLD_ROOT/scripts/scaffold-lib.sh" "$copy/scripts/"
  cp "$SCAFFOLD_ROOT/template/scripts/lib.sh" "$SCAFFOLD_ROOT/template/scripts/layout.sh" "$SCAFFOLD_ROOT/template/scripts/gate.sh" "$copy/template/scripts/"
  printf '0.1.0\n' >"$copy/VERSION"
  git -C "$copy" init -q -b main && git -C "$copy" add -A && git -C "$copy" commit -q -m "chore: init" && git -C "$copy" tag v0.1.0
  ssh-keygen -q -t ed25519 -N '' -C test -f "$WORKDIR/sign-key"
  env TMPDIR="$tmp" XADEN_SIGNING_KEY="$WORKDIR/sign-key" "$copy/scripts/sign-release.sh" 0.1.0 >/dev/null 2>"$err" || rc=$?
  assert "signing a release exits 0" test "$rc" -eq 0
  assert "signing prints no shell error" test ! -s "$err"
  assert "the checksum and its signature are written" test -s "$copy/dist/xaden-0.1.0.checksum" -a -s "$copy/dist/xaden-0.1.0.checksum.sig"
  assert "signing leaves no temp folder behind" test -z "$(ls -A "$tmp")"
}

test_bump_version
test_guide_links
test_site_pages
test_scaffold_release_failures
test_sign_release
test_release
test_install_ways
