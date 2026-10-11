# Secure coding checklist

Baseline: the OWASP ASVS level chosen in `docs/threat-model.md` says *what* to build;
the OWASP Web Security Testing Guide (WSTG) says *how* to test it; the OWASP Top 10 names the
most common failures. Applies to AI-generated code at least as much as to hand-written code.
Sections marked *(web)* apply only to software with a browser client.

## All applications

- **Input**: validate on the server/boundary — type, length, range, format; allow-list over deny-list.
- **Injection**: parameterized queries only; never build SQL/shell/HTML/paths by string concatenation.
  Avoid `eval`, `exec`, `shell=True`.
- **Safe parsing**: limit input size, nesting depth and element count before parsing; disable XML
  external entities and DTDs; no unsafe deserialization (`pickle`, `yaml.load`, Java/PHP native
  serialization) of untrusted data.
- **Authentication**: use a vetted library; hash passwords with Argon2id/bcrypt/scrypt; rate-limit
  logins; offer MFA where the ASVS level asks for it.
- **Sessions and tokens**: idle and absolute expiry; rotate session IDs on login; revoke sessions
  and tokens on logout, password change and account removal; short-lived access tokens.
- **Password reset**: single-use, random, short-lived tokens stored hashed; the same response for
  known and unknown accounts; existing sessions revoked after a reset; rate-limited.
- **Authorization**: check server-side on every request and every object; deny by default.
  Multi-tenant data is filtered by tenant in the query, not after loading.
  Tests: for each protected operation, a negative test proves user A cannot read or change user
  B's object, and tenant A cannot reach tenant B's data (IDOR).
- **Rate and resource limits**: limit login, reset and other expensive operations per client and
  per account; cap request body size, page size, query cost, upload size and processing time.
- **Secrets**: only from environment/secret store; never in code, logs, URLs, or git.
  `.env` is gitignored; keep `.env.example` with fake values.
- **Crypto**: no home-made crypto; TLS everywhere; modern algorithms; secure random for tokens.
- **Files and uploads**: enforce a size limit before reading the whole file; check content, not
  the extension or client-supplied type; generate server-side names; store outside the web root.
- **Paths and archives**: resolve paths and verify they stay inside the intended base directory;
  do not follow symbolic links from untrusted sources. When extracting archives, reject absolute
  paths, `..` segments, symbolic and hard links, and cap total size and file count (zip bombs).
- **Outbound requests (SSRF)**: allow-list destinations where possible. Otherwise resolve the host,
  reject loopback, private, link-local and cloud-metadata addresses (`127.0.0.0/8`, `10.0.0.0/8`,
  `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `::1`, `fc00::/7`, `fe80::/10`), and connect
  to the address you checked so DNS rebinding cannot swap it. Disable redirects or re-check every
  hop. Set timeouts and response size limits.
- **Errors and logging**: generic messages to users; details to logs; log security events
  (logins, permission denials, admin actions) without passwords, tokens or personal data.
- **Data retention**: collect the minimum; define how long each sensitive data type is kept
  (see the threat model); deletion covers copies, caches, exports and derived data; backups
  expire on a schedule.
- **Config**: debug off in production, least privilege for services and tokens.

## Dependencies

- **Adding**: ask the user first (AGENTS.md §6). Prefer widely used, maintained packages; check
  the license, maintainer activity, download count and whether it runs install scripts
  (`postinstall`, `setup.py` code). Keep the set minimal.
- **Lockfiles**: commit the lockfile (`package-lock.json`, `uv.lock`/`poetry.lock` or pinned
  `requirements*.txt`); install from it in CI (`npm ci`). Never edit it by hand.
- **Licenses**: record the allowed licenses for this project in `docs/decisions/`; ask before
  adding a copyleft (GPL, AGPL) or unknown license to software you distribute.
- **Updates**: apply security fixes promptly; review other updates at least monthly; read the
  changelog of major versions before upgrading; one dependency per commit when practical.
- **Audit**: `scripts/check.sh` runs the stack's audit tool. A known vulnerability that cannot be
  fixed yet is recorded in `docs/security-exceptions.md` with owner, reason and expiry; never
  silence the audit without such an entry.
- **Supply chain (optional)**: when you ship artifacts to others, consider a software bill of
  materials (SBOM, e.g. CycloneDX or SPDX) and build provenance. Ask the user before adding tools.

## Web applications *(web)*

- **Output**: context-aware encoding (HTML, JS, URL); set a Content-Security-Policy and the usual
  security headers (`X-Content-Type-Options`, `Referrer-Policy`, frame protection).
- **Cookies**: `Secure`, `HttpOnly`, `SameSite`; prefer the `__Host-` prefix for session cookies.
- **CSRF**: when the browser sends credentials automatically (cookies, HTTP auth), protect every
  state-changing request with a CSRF token or a strict `Origin`/`Sec-Fetch-Site` check.
  `SameSite` cookies are defence in depth, not a replacement: they do not stop same-site attacks
  from sibling subdomains and depend on browser behaviour. Never change state on `GET`.
  APIs that only accept tokens from an `Authorization` header are not exposed to CSRF.
- **CORS**: narrow allowed origins; never reflect an arbitrary `Origin` together with credentials.

Run a security review (`/security` in Claude Code, or `prompts/security-review.md`)
after each feature touching the above and before every release.
