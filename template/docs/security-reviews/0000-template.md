# Security review YYYY-MM-DD — short scope name

Copy to `docs/security-reviews/YYYY-MM-DD-<scope>.md`. Written by `prompts/security-review.md`.
A completed review records what was checked; it is not proof that the software is secure.

- Reviewer: who ran it (person, or assistant and model) and who approved fixes
- Version / commit: the exact commit reviewed
- Threat model: date of `docs/threat-model.md` used; ASVS level

## Scope

Files, entry points and features reviewed, including related callers, configuration,
permissions and dependencies. Explicitly list what was **out of scope**.

## Evidence

Commands and tools run with their result (e.g. `scripts/check.sh --strict`: passed;
semgrep: 0 findings; dependency audit: 1 finding, see SE-001). Tests that prove controls
(e.g. negative authorization tests). Name every check that was skipped and why.

## Limitations

What could not be verified (no running system, no access to infrastructure, dynamic
behaviour not tested, assumptions taken from the threat model).

## Findings

| # | Severity | Location | Issue (what an attacker does) | Status |
|---|----------|----------|-------------------------------|--------|
| 1 | high | `file:line` | | open / fixed in `<commit>` / accepted in security-exceptions.md / false positive |

Severity: critical · high · medium · low. Mark unverified suspicions as "unverified".

## Remediation summary

Fixed, accepted (with owner and expiry), and still open; the next review trigger.
