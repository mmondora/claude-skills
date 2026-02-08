---
name: security-testing
description: "Automated security testing in CI. SAST, DAST, dependency scanning, authorization testing, secret detection. Use when adding security scans to pipelines, writing tenant isolation tests, or configuring vulnerability scanning."
---

# Security Testing

## Purpose

Automated security testing integrated into the development cycle. SAST, DAST, dependency scanning, authorization testing, secret detection, and container/IaC scanning.

---

## SAST (Static Application Security Testing)

Static analysis of source code for known vulnerabilities. Run in CI on every PR.

**TypeScript**: ESLint with security plugin (`eslint-plugin-security`), Semgrep with TypeScript/Node.js rules. **Swift**: SwiftLint with custom security rules.

Rules: block PR on CRITICAL/HIGH findings. WARNING as a comment in PR review.

---

## DAST (Dynamic Application Security Testing)

Testing the running application for runtime vulnerabilities. OWASP ZAP as automated scanner in staging.

Workflow: deploy to staging → run ZAP baseline scan → report → fix before production. Cadence: on every release candidate. Full active scan weekly.

---

## Dependency Scanning

`npm audit` in CI (block on critical). Renovate/Dependabot for automatic updates. Socket.dev or Snyk for advanced supply chain analysis (typosquatting, malicious code injection). For Swift: `swift package audit` (if available) or Snyk.

---

## Container Image Scanning

Scan container images for known vulnerabilities before pushing to registry.

**Tools**: Trivy or Grype in CI pipeline.

**Policy**: block on CRITICAL vulnerabilities. HIGH vulnerabilities require exception or fix within 1 sprint.

```yaml
# In GitHub Actions
- name: Scan container image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.IMAGE }}'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'
```

---

## IaC Scanning

Scan Terraform/Kubernetes configuration for security misconfigurations.

**Tools**: Checkov, tfsec, or Trivy (supports IaC scanning).

**Checks**: overly permissive IAM roles, public storage buckets, unencrypted databases, missing network policies, hardcoded credentials in IaC.

---

## Authorization Testing

Automated tests verifying tenant isolation and role-based access. These are the most important security tests in a multi-tenant application.

```typescript
describe('Tenant isolation', () => {
  it('prevents access to another tenant resources', async () => {
    const res = await request(app)
      .get('/api/v1/tenants/t_other/invoices')
      .set('Authorization', `Bearer ${tokenForTenantA}`);
    expect(res.status).toBe(403);
  });
  it('prevents viewer from creating invoices', async () => {
    const res = await request(app)
      .post('/api/v1/tenants/t_test/invoices')
      .set('Authorization', `Bearer ${viewerToken}`)
      .send(validInvoiceData);
    expect(res.status).toBe(403);
  });
});
```

Generate a test for every combination (role × action × resource) — tedious but essential. Use matrix testing or parameterized tests.

---

## Secret Detection

Pre-commit hook (git-secrets, gitleaks) blocking commits containing secret patterns (AWS keys, GCP service account JSON, plaintext passwords). CI scan as backup.

**Patterns to detect**: AWS access keys (`AKIA...`), GCP service account JSON (`"type": "service_account"`), generic passwords (`password\s*=`), private keys (`-----BEGIN.*PRIVATE KEY-----`), API tokens.

---

## Severity Policy & Gating

### Default Severity Policy

| Severity | Action | Timeline |
|----------|--------|----------|
| Critical | **BLOCK** — cannot merge/deploy | Fix immediately |
| High | **BLOCK** unless exception approved | Fix within 1 sprint |
| Medium | **WARN** + backlog ticket created | Fix within 2 sprints |
| Low | Informational | Address opportunistically |

### Exception Process

When a High finding cannot be immediately resolved, document an exception:

```markdown
## Security Exception

**Finding**: [CVE/CWE ID] — [brief description]
**Component**: [package/file affected]
**Justification**: [why it cannot be fixed now]
**Compensating controls**: [what mitigates the risk]
  - e.g., "Not reachable from user input", "WAF rule blocks exploit path"
**Expiry date**: [YYYY-MM-DD — max 90 days]
**Owner**: [person responsible for resolution]
**Ticket**: [link to tracking ticket]
```

Exceptions are reviewed monthly. Expired exceptions become blockers.

---

## Scanning Coverage Summary

| Scan Type | Trigger | Tool | Gate |
|-----------|---------|------|------|
| Secret detection | Pre-commit + CI | gitleaks | PR gate |
| SAST | Every PR | Semgrep, ESLint security | PR gate |
| Dependency scan | Every PR + weekly | npm audit, Snyk | PR gate |
| Container scan | On image build | Trivy | Deploy gate |
| IaC scan | On infra changes | Checkov/tfsec | PR gate |
| DAST | Release candidate | OWASP ZAP | Release gate |
| Authorization tests | Every PR | Vitest/XCTest | PR gate |

---

## For Claude Code

When generating security tests: tenant isolation test for every multi-tenant endpoint, role-based access test for every protected endpoint, include ESLint security plugin in configuration. Don't forget negative tests (access denied = correct behavior). Include container and IaC scanning in CI pipelines. When a security finding is reported, suggest fix with severity and timeline.

---

*Internal references*: `testing-strategy.md`, `security.md`, `authn-authz.md`, `quality-gates.md`
