---
title: Security review
type: prompt
status: stable
version: 1.0.0
works-with: [claude-code, chatgpt, local-llm]
tags: [prompt, security, review]
---

# Security review

## Goal
Find exploitable weaknesses in the changed code, ranked by risk, with fixes.
(Claude Code: `/security` runs the `alice-security-engineer` skill when installed; this
prompt is the tool-independent equivalent.)

## Inputs
- Scope: {{changed files, or whole project}}

## Steps
1. Read `docs/threat-model.md` and `docs/security.md`. Confirm the entry points (HTTP routes,
   CLI args, files, env, message queues) and trust boundaries against the code; if the code has
   ones the threat model lacks, update the threat model and say so.
2. For each entry point, trace untrusted data to sinks and check (OWASP WSTG categories):
   - Input validation and output encoding; injection (SQL, OS command, template, path, LDAP)
   - Authentication, session expiry and revocation, password reset, password/token storage
   - Authorization: server-side checks per request, per object and per tenant (IDOR), default
     deny; negative tests exist
   - Cryptography and TLS; randomness; hard-coded secrets; secrets in logs
   - File upload/download, archive extraction, path and symlink traversal, SSRF (redirects,
     private addresses, DNS rebinding), safe parsing, deserialization
   - Web only: CSRF (not SameSite alone), CORS, security headers
   - Business-logic abuse (race conditions, replay, rate and resource limits, mass assignment)
   - Data retention, deletion and what gets logged
   - Error handling and information leakage; debug flags
   - Dependencies: new or outdated packages, known CVEs, install scripts
3. Run `scripts/check.sh` (secret scan, SAST, dependency audit) and include its findings.
4. Report each finding: `severity (critical|high|medium|low)` · location `file:line` ·
   what an attacker does · minimal fix as code.
5. Only claim what you verified in the code. Mark guesses as "unverified".
6. After my OK, apply fixes with a regression test each; commit `fix(security): <summary>`.

## Done when
- [ ] Every entry point reviewed or explicitly out of scope
- [ ] Critical/high findings fixed or accepted by me in writing
