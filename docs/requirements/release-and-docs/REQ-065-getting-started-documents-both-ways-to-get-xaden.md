---
id: REQ-065
type: job
epic: release-and-docs
priority: should
status: in-progress
updated: 2026-10-13
---

# Getting started documents both ways to get Xaden: zip download and clone

## Job

When I want to try Xaden, I want Getting Started to describe both ways to get it, downloading the release as a zip archive and cloning the repository, so I can start with the one that fits me, with or without git history and updates.

## Acceptance criteria

- Given `GETTING-STARTED.md`, then it has an install section with both ways, each with its steps up to a working `xaden` command
- Given the zip way, then it says how to verify the download, how to update (download again) and that the link of `scripts/install.sh` points into the extracted folder
- Given the clone way, then it says how to update (`git pull`) and how to pick a release tag instead of `main`
- Given both ways, then the section says when to choose which
- Given the install section, then it has a short subsection per operating system (Linux, macOS, Windows) for the differences: prerequisites, which shell profile receives the `PATH` line, and for Windows the route (WSL recommended, Git Bash) with its support status (untested until verified, native PowerShell not supported)
- Given each documented command sequence, when run on a clean Linux or macOS machine, then it works (verified by the smoke test where possible, otherwise marked untested)
