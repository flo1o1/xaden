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
3. Confirm all `done` requirements are reflected in the changelog.
4. Run [[security-review]] on everything changed since the last tag.
5. Show me the proposed bump and reason. **Wait for my confirmation.**
6. Run `scripts/release.sh <part>`. It checks, stamps the changelog, commits and tags. Do not push.

## Done when
- [ ] Tag `vX.Y.Z` exists locally
