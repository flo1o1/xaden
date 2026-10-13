---
id: REQ-064
type: job
epic: release-and-docs
priority: should
status: approved
updated: 2026-10-13
---

# A new scaffold release reaches the website without manual steps

## Job

When I push a scaffold release tag, I want the website to pick up that release's documentation without manual steps, so I can be sure the site never shows instructions older than the latest release.

## Acceptance criteria

- Given a pushed release tag `vX.Y.Z`, when the site's build runs, then it renders the docs from the archive of exactly that tag and shows `X.Y.Z`
- Given a release, then the site picks it up within 24 hours without anyone starting a build by hand, and a manual start remains possible
- Given the scaffold repository, then it holds no credential for the site repository (the site fetches released archives; the scaffold never pushes to it)
- Given the doc files the site renders, then their paths are stable and listed in the scaffold's maintainer documentation, and the scaffold's checks fail when one is missing
- Given an untagged commit on main, then it never appears on the site
