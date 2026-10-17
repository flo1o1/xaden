---
id: REQ-094
type: job
epic: release-and-docs
priority: should
status: approved
updated: 2026-10-17
---

# Xaden installs from a signed release zip that holds no maintainer files

## Job

When I install Xaden to use it, I want to download a signed release zip that contains only what Xaden needs to run, so I can run it without maintainer material (tests, scaffold requirements, signing docs and scripts, hooks, CI) and without a clone.

## Acceptance criteria

- Given the release archive (zip and tar.gz), then it holds none of: `tests/`, `docs/requirements/`, `docs/security-reviews/`, `docs/threat-model.md`, `docs/release-signing.md`, `docs/site-pages.txt`, `.githooks/`, `.github/`, `.claude/`, `inbox/`, `AGENTS.md` and `CLAUDE.md` at the root, and the scripts `release-scaffold.sh`, `sign-release.sh`, `check-*.sh` and `setup.sh`; it does hold `template/`, the other `scripts/`, `docs/guide/`, `release-signers`, `VERSION`, `CHANGELOG.md`, `LICENSE`, `README.md` and `GETTING-STARTED.md`
- Given the extracted archive, then `scripts/install.sh`, `xaden version`, `xaden create` and `xaden adopt --dry-run` work (smoke test)
- Given `scripts/sign-release.sh <version>`, then it also writes `dist/xaden-<version>.zip` from the tag and an SSH signature `dist/xaden-<version>.zip.sig` of that file, prints the upload command without uploading, and keeps the tree checksum and its signature, so `xaden fetch` and `xaden upgrade` work unchanged
- Given `docs/guide/admin/install-xaden.md`, then the signed zip from the release page is the recommended way, with the verification before extracting (`ssh-keygen -Y verify`, public key taken from the website because `release-signers` is inside the zip); cloning is described as the way for contributors
- Given a clone, then `scripts/check-release-archive.sh` (part of `scripts/check-scaffold.sh`) fails when a maintainer path reaches an archive made by `git archive`, or when a top-level path is neither excluded by `.gitattributes` nor on the list of shipped paths
- Given `docs/guide/developer/release-a-version.md`, then it contains no path or name from a maintainer's own machine, only generic examples
