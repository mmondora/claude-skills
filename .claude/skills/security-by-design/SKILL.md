---
name: security-by-design
description: "Security as a design property, not an added layer. OWASP Top 10, supply chain security, secrets management, zero trust. Use when writing endpoints, handling user input, managing dependencies, or configuring infrastructure."
---

# Security by Design

## Purpose

Security is a design property, not an added layer. Covers OWASP, supply chain security, dependency management, secrets management, and zero trust approach.

---

## OWASP Top 10 — Operational Rules

**Injection (SQL, NoSQL, OS command)**: never concatenate user input in queries. Use parameterized queries (Drizzle/Prisma do this natively), validate every input with Zod at API entry.

**Broken Authentication**: robust session management (see `authn-authz.md`). Short-lived tokens (15min access, 7d refresh). Rate limiting on login endpoints. No passwords in logs.

**Sensitive Data Exposure**: TLS everywhere (including service-to-service). Encryption at rest for sensitive data. Never credentials, tokens, or PII in URLs, logs, or unnecessary response bodies.

**Broken Access Control**: authorization at every level (API gateway, service, database query). Never trust the client for authorization decisions. Every endpoint verifies the user/service has permission for the specific resource.

**Security Misconfiguration**: mandatory HTTP security headers (Content-Security-Policy, X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security). Disable headers revealing technology (X-Powered-By). Restrictive CORS (never `*` in production).

**Cross-Site Scripting (XSS)**: output sanitization (React and Vue do this by default with escaping, but beware `dangerouslySetInnerHTML` / `v-html`). Content-Security-Policy to block inline scripts.

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

*Internal references*: `authn-authz.md`, `compliance.md`, `security-testing.md`, `containers.md`
