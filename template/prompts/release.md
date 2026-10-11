---
title: Release
type: prompt
status: stable
version: 1.0.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, release, semver]
---

# Release

## Goal
Choose the correct SemVer bump and cut the release safely.

## Steps
1. Read `CHANGELOG.md` → Unreleased and `git log` since the last tag.
2. Decide the bump: any breaking change → `major`; else any `feat` → `minor`; else `patch`.
   (While `0.x`, breaking changes may bump `minor`; tell me if you use that rule.)
3. Confirm all `done` requirements are reflected in the changelog. Show me
   `scripts/check-traceability.sh --matrix`.
4. Run `scripts/check-docs.sh --release`; if it fails, run [[documentation]] first.
5. Run [[security-review]] on everything changed since the last tag. Check
   `docs/security-exceptions.md`: an expired row blocks the release until it is fixed or I renew it.
6. Show me the proposed bump and reason. **Wait for my confirmation.**
7. Run `scripts/release.sh <part>`. It checks, stamps changelog and guides, commits and tags. Do not push.

## Done when
- [ ] Tag `vX.Y.Z` exists locally
