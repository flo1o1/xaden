# Security exceptions

Known vulnerabilities or security findings that cannot be fixed yet and were accepted
deliberately. Every row needs an owner and an expiry date; on expiry, fix the issue or
renew the decision with a new date and reason (the full `scripts/check.sh` fails on an
expired row, a row without owner or a date that is not YYYY-MM-DD). Never silence an audit or scanner finding
without a row here. Review this file before every release.

| ID | Finding (advisory, package@version, or review finding) | Why it is accepted | Mitigation | Owner | Expires (YYYY-MM-DD) |
|----|--------------------------------------------------------|--------------------|------------|-------|----------------------|

<!-- Example row:
| SE-001 | GHSA-xxxx-xxxx-xxxx in example-lib@1.2.3 | Vulnerable function is not called; no fixed version yet | Input never reaches parse_url() | Jane Doe | 2026-12-31 |
-->
