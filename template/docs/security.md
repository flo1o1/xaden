# Secure coding checklist

Aligned with the OWASP Web Security Testing Guide (WSTG) and OWASP Top 10.
Applies to AI-generated code at least as much as to hand-written code.

- **Input**: validate on the server/boundary — type, length, range, format; allow-list over deny-list.
- **Injection**: parameterized queries only; never build SQL/shell/HTML/paths by string concatenation.
  Avoid `eval`, `exec`, `shell=True`, unsafe deserialization (`pickle`, `yaml.load`).
- **Output**: context-aware encoding (HTML, JS, URL); set a Content-Security-Policy.
- **AuthN**: use a vetted library; hash passwords with Argon2id/bcrypt/scrypt; rate-limit logins;
  secure, HttpOnly, SameSite cookies; rotate session IDs on login.
- **AuthZ**: check permissions server-side on every request and object (prevent IDOR). Deny by default.
- **Secrets**: only from environment/secret store; never in code, logs, URLs, or git.
  `.env` is gitignored; keep `.env.example` with fake values.
- **Crypto**: no home-made crypto; TLS everywhere; modern algorithms; secure random for tokens.
- **Files**: validate type/size, store outside web root, generate server-side names, block path traversal.
- **SSRF / CSRF / CORS**: allow-list outbound targets; CSRF tokens or SameSite; narrow CORS origins.
- **Errors/Logging**: generic messages to users; detailed ones to logs; no sensitive data in logs.
- **Dependencies**: pin versions, minimal set, run the audit tool (`scripts/check.sh`), review new packages.
- **Config**: debug off in production, least privilege for services and tokens.

Run a security review (`/security` in Claude Code, or `prompts/security-review.md`)
after each feature touching the above and before every release.
