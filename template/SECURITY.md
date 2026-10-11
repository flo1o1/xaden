# Security policy — {{PROJECT_NAME}}

## Supported versions

<!-- TODO: Which versions receive security fixes (e.g. "the latest minor release only"). -->

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

- Contact: <!-- TODO: a monitored address or the repository's private vulnerability reporting link. -->
- Include: affected version, steps to reproduce, impact, and whether it is already public.
- Response: <!-- TODO: when you acknowledge a report and how you keep the reporter informed.
  Only promise what you can keep. -->

We credit reporters in the changelog unless they prefer to stay anonymous.

## Secret rotation

When a secret (API key, password, token, signing key, certificate) may have leaked —
committed to git, printed in a log, sent to a third party, or held by someone who left:

1. Create a new secret in the issuing system; deploy it; confirm the software works with it.
2. Revoke the old secret. Removing it from git history is not enough: assume it is known.
3. Check the issuing system's logs for use of the old secret since the suspected leak.
4. Record what happened, when, and what was rotated (see incident response below).

<!-- TODO: List each secret the software uses, where it is issued, and who can rotate it. -->

## Incident response basics

1. **Contain**: revoke exposed credentials, disable the affected feature or take the service
   offline if data is at risk.
2. **Preserve evidence**: keep logs and affected systems unchanged where possible; note times.
3. **Assess**: which data and users are affected, since when, by which entry point.
4. **Fix**: regression test first, then the fix; run the security review; release.
5. **Notify**: affected users and, where the law requires it, authorities within the legal
   deadline (e.g. GDPR: 72 hours for personal-data breaches).
6. **Learn**: add a requirement, test or semgrep rule so the same mistake is caught next time;
   update `docs/threat-model.md`.

<!-- TODO: Who decides and who is contacted during an incident (names or roles, channels). -->

## Supply chain

Dependency rules, accepted vulnerabilities and optional SBOM/provenance guidance:
`docs/security.md` (section Dependencies) and `docs/security-exceptions.md`.
