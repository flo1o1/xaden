---
id: REQ-064
type: job
epic: release-and-docs
priority: should
status: done
updated: 2026-10-14
---

# A new scaffold release reaches the website without manual steps

## Job

When I push a scaffold release tag, I want the website to propose that release's documentation on its own, so I can be sure the site never falls behind and I only review and merge one pull request.

## Acceptance criteria

- Given a pushed release tag `vX.Y.Z`, when the site's build runs, then it renders the docs from the archive of exactly that tag and shows `X.Y.Z`
- Given a release, then the site repository has an open pull request that pins it within 24 hours without anyone starting a job by hand, and a manual start remains possible; merging it (after CI passed) is the one human step
- Given the scaffold repository, then it holds no credential for the site repository (the site fetches released archives; the scaffold never pushes to it)
- Given the doc files the site renders, then their paths are stable and listed in the scaffold's maintainer documentation, and the scaffold's checks fail when one is missing
- Given an untagged commit on main, then it never appears on the site
