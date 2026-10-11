# {{PROJECT_NAME}} — Threat model

Filled at kickoff (`prompts/kickoff.md`), read by every security review
(`prompts/security-review.md`), and updated when a change adds an entry point, a data type,
a dependency on an external service or a new deployment target. Keep it short and true;
"unknown" is a valid answer that the user must resolve.

**Last reviewed:** <!-- TODO: YYYY-MM-DD and the change that triggered the review -->

## System summary

<!-- TODO: What the software does, who uses it, where it runs. One paragraph. -->

## Assets

<!-- TODO: What is worth protecting: data, credentials, money, availability, reputation, compute. -->

## Sensitive data

<!-- TODO: Personal, financial, health, credential or confidential data the software stores,
processes or logs; where it lives; how long it is kept; legal constraints (e.g. GDPR). -->

## Entry points

<!-- TODO: Every way input reaches the code: HTTP routes, CLI arguments, files, uploads,
environment, message queues, webhooks, scheduled jobs, plugins. -->

## Trust boundaries

<!-- TODO: Where data crosses from less trusted to more trusted: browser to server, user to
admin, tenant to tenant, service to database, internet to internal network, third-party APIs. -->

## Attackers and capabilities

<!-- TODO: Who could attack (anonymous internet user, authenticated user, other tenant,
malicious insider, compromised dependency) and what each can do. -->

## Deployment assumptions

<!-- TODO: Hosting, network exposure, TLS termination, who has shell or database access,
secret storage, backups. State assumptions the code relies on. -->

## Security baseline

Verification standard: OWASP ASVS (what to build), OWASP WSTG (how to test it).

- ASVS level: <!-- TODO: L1 (low-risk, no sensitive data), L2 (most applications with
  personal or business data) or L3 (high value: payments, health, critical infrastructure). -->
- Not applicable areas: <!-- TODO: e.g. "no browser client, so CSRF/CSP do not apply". -->

## Threats and mitigations

| Threat | Asset | Mitigation | Requirement / test |
|--------|-------|------------|--------------------|
| <!-- TODO: e.g. user reads another tenant's records --> | | | |

## Accepted risks

<!-- TODO: Risks knowingly not mitigated, with the reason and who accepted them. Vulnerable
dependencies go to docs/security-exceptions.md instead. -->
