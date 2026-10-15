---
id: REQ-065
type: job
epic: release-and-docs
priority: should
status: done
updated: 2026-10-13
---

# Getting started documents both ways to get Xaden: zip download and clone

## Job

When I want to try Xaden, I want Getting Started to describe both ways to get it, downloading the release as a zip archive and cloning the repository, so I can start with the one that fits me, with or without git history and updates.

## Acceptance criteria

- Given `docs/guide/admin/install-xaden.md`, then it describes both ways, each with its steps up to a working `xaden` command, and `GETTING-STARTED.md` links to it
- Given the zip way, then the install guide says how to verify the download and that the link of `scripts/install.sh` points into the extracted folder, and `docs/guide/admin/update-xaden.md` says how to update (download again)
- Given the clone way, then `docs/guide/admin/update-xaden.md` says how to update (`git pull`) and how to pick a release tag instead of `main`
- Given both ways, then the section says when to choose which
- Given `docs/guide/admin/requirements-and-platforms.md`, then it has a short section per operating system (Linux, macOS, Windows) for the differences: prerequisites, which shell profile receives the `PATH` line, and for Windows the route (WSL recommended, Git Bash) with its support status (untested until verified, native PowerShell not supported)
- Given each documented command sequence, when run on a clean Linux or macOS machine, then it works (verified by the smoke test where possible, otherwise marked untested)
