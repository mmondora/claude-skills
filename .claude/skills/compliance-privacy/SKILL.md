---
name: compliance-privacy
cluster: security-compliance
description: "GDPR compliance and privacy as architectural constraints. Data minimization, right to be forgotten, data residency, audit trails, retention policies. Use when handling PII, designing audit systems, or implementing data export/deletion."
---

# Compliance & Privacy

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

Compliance and privacy requirements as architectural constraints. GDPR as baseline (operating in EU/Italy), with formal assessment framework, evidence pack generation, and attention to data residency, audit trail, and data retention.

---

## GDPR — Architectural Implications

### Data Minimization

Collect only data necessary for the declared purpose. Every PII field has a documented reason. If it's not needed, don't collect it. If it stops being needed, delete it.

### Right to Be Forgotten (Art. 17)

Architecture must support complete deletion of a user's data. This means: knowing where all of a user's data is (data map), being able to delete or anonymize it across all systems (including backups, logs, caches, analytics) within a reasonable time.

Architectural implication: if using Event Sourcing, events with PII must support crypto-shredding (encrypt PII with a per-user key, delete the key to "forget"). If logs contain PII, they must have retention policies with auto-delete.

### GDPR Deletion Workflow (Right to Be Forgotten)

Implementation steps for processing a data deletion request:

```typescript
async function processDataDeletionRequest(userId: string, tenantId: string): Promise<DeletionReport> {
  const report: DeletionReport = { userId, requestedAt: new Date(), actions: [] };

  // 1. Primary data stores
  await userRepository.anonymize(tenantId, userId);         // Replace PII with placeholder
  report.actions.push({ store: 'users', action: 'anonymized' });

  await invoiceRepository.anonymizeByUser(tenantId, userId); // Anonymize user ref in invoices
  report.actions.push({ store: 'invoices', action: 'anonymized' });

  // 2. Cache invalidation
  await cacheService.invalidateUser(tenantId, userId);
  report.actions.push({ store: 'cache', action: 'invalidated' });

  // 3. Search index
  await searchService.removeUserDocuments(tenantId, userId);
  report.actions.push({ store: 'search-index', action: 'removed' });

  // 4. Analytics (anonymize, don't delete — retain aggregated data)
  await analyticsService.anonymizeUser(tenantId, userId);
  report.actions.push({ store: 'analytics', action: 'anonymized' });

  // 5. Audit log entry (the deletion request itself is an auditable event)
  await auditLog.record({
    action: 'gdpr.data_deletion',
    tenantId,
    userId: 'SYSTEM',
    detail: `Data deletion processed for user ${userId}`,
  });

  // 6. Schedule: backups containing this user's data will expire per retention policy
  report.backupNote = 'Backups containing user data will expire within 30-day retention window';

  return report;
}
```

Key principles: anonymize rather than delete where referential integrity matters (invoices need line items, just not PII). Log the deletion action itself for audit compliance. Backups are covered by retention policy — not individually scrubbed.

### Data Portability (Art. 20)

Users can request their data in machine-readable format (JSON, CSV). Architecture must have an endpoint or process that exports all of a user's data.

### Lawful Basis

Every processing activity has a documented legal basis (consent, contract, legitimate interest, legal obligation). Consent is: specific, informed, revocable. Consent state is tracked and auditable.

---

## GDPR Practical Checklist

For every product change involving personal data:

- [ ] **Data minimization**: only collecting what is necessary for the declared purpose
- [ ] **Purpose limitation**: processing purpose documented
- [ ] **Retention policy**: defined and enforced (not indefinite)
- [ ] **Access control**: personal data accessible only to authorized roles
- [ ] **Encryption**: in transit (TLS) and at rest (where applicable)
- [ ] **Logging redaction**: PII masked or excluded from application logs
- [ ] **DSAR support**: Data Subject Access Request — export and delete capabilities exist
- [ ] **DPA/vendor review**: third-party processors have Data Processing Agreement
- [ ] **Privacy impact**: assessed as Low / Medium / High

Trigger for this checklist: new data fields/entities, new tracking/analytics, new third-party integrations, country rollout.

---

## Data Residency

For EU clients: data must reside in EU (region `europe-west` on GCP). Verify all used services (Firestore, Cloud SQL, Pub/Sub, Cloud Functions) are configured in EU regions.

Watch out for global services: some GCP services are multi-region by default (Cloud Storage multi-region, BigQuery US). Configure location explicitly.

### Cross-Border Data Transfers

For non-EU data processing: Standard Contractual Clauses (SCCs) required for data transfers outside EU/EEA. Verify cloud provider sub-processors and data transfer mechanisms. Document transfers in Records of Processing Activities (ROPA).

---

## Other Regulations

**CCPA** (California): similar to GDPR but with opt-out model (vs opt-in). If serving US users, implement "Do Not Sell My Personal Information" link. CCPA applies to businesses with >$25M revenue or >50K consumers.

**LGPD** (Brazil): closely modeled on GDPR. Requires Data Protection Officer (DPO) and consent basis. If expanding to Brazil, existing GDPR infrastructure covers most requirements.

**Principle**: design for GDPR compliance first (most restrictive). Other regulations are mostly subsets. Record regulation-specific requirements in ADR when entering new markets.

### DPIA (Data Protection Impact Assessment)

Required for high-risk processing: automated decision-making affecting individuals, large-scale processing of sensitive data, systematic monitoring. Conduct before implementation, document in `docs/compliance/dpia-<feature>.md`.

### Consent Management

Track consent state per user per purpose with timestamp and version:

```typescript
interface ConsentRecord {
  userId: string;
  tenantId: string;
  purpose: 'marketing' | 'analytics' | 'personalization';
  granted: boolean;
  timestamp: string; // ISO-8601
  policyVersion: string; // version of privacy policy at consent time
  channel: 'web' | 'ios' | 'api'; // where consent was collected
}
```

Consent withdrawal must be as easy as granting consent (GDPR Art. 7). Never pre-check consent boxes.

---

## Audit Trail

Every operation on sensitive or business-critical data produces an immutable audit log. The audit log includes: who (user ID, service ID), what (action, resource, modified fields — old/new values), when (timestamp), from where (IP, device, session), why (context: endpoint, batch job, manual operation).

Audit log is separate from application log. Has long retention (7 years for Italian tax requirements) and is not modifiable after writing. Firestore with security rules preventing update/delete, or BigQuery append-only.

---

## Data Retention

Every data type has an explicit retention policy: operational data (contract duration + N months), tax data (10 years in Italy), application logs (30-90 days), audit logs (7+ years), analytics data (anonymized, indefinite), backups (aligned with primary data retention).

Retention policies are automated: lifecycle policies on Cloud Storage, TTL on Firestore, partition expiration on BigQuery.

---

## Multi-Tenancy and Data Isolation

In multi-tenant context, data isolation between tenants is a compliance requirement. Patterns: database-per-tenant (maximum isolation, maximum cost), schema-per-tenant (good compromise for Cloud SQL), row-level security with tenant_id (minimum cost, requires discipline).

Pattern choice based on risk profile, recorded in ADR. Regardless of pattern, verify with automated tests that a tenant can never access another's data.

---

## Compliance Assessment Framework

### When to Assess

- Release readiness for regulated customers
- Audit window (annual or as required)
- Onboarding new country/legal entity
- Security review request
- Major architecture change

### Framework Coverage (Generic — ISO/SOC2/GDPR)

| Area | What to verify |
|------|----------------|
| Access control | Least privilege, MFA, access reviews |
| Change management | Approvals, audit trail for changes |
| Logging & audit | Immutable logs, correlation IDs, retention |
| Data retention & deletion | Automated lifecycle, verified deletion |
| Incident response | Documented process, tested runbook |
| Vendor/dependency controls | DPA, supply chain scanning, SBOM |
| Secure SDLC | CI scans, code review, secret detection |

### Assessment Output

- **Status**: PASS / CONDITIONAL / FAIL
- **Gaps**: specific items not meeting requirements, with remediation steps
- **Evidence index**: paths/links to supporting artifacts

---

## Audit Evidence Pack

For audits and customer assurance, maintain a structured evidence pack:

### Evidence Pack Structure

```
/evidence/<release-or-date>/
  release-summary.md           # What was released, version, date
  ci-artifacts/                 # Test reports, scan outputs, coverage
  sbom/                         # SBOM files (CycloneDX/SPDX)
  adr/                          # Referenced ADRs for this release
  policies/                     # Secure SDLC policies, access policies
  operations/                   # Runbooks, SLOs, dashboard links
  approvals/                    # Change tickets, sign-offs
  INDEX.md                      # Master index with checksums
```

### Rules

- Include SHA-256 checksums for key artifacts (test reports, SBOM, scan results)
- No secrets in evidence pack
- Every artifact traceable to a specific release tag/commit
- INDEX.md lists all artifacts with description, path, and checksum
- Missing evidence explicitly listed (not silently omitted)

### INDEX.md Format

```markdown
# Evidence Pack — v1.3.0 (2026-02-08)

| Artifact | Path | SHA-256 | Notes |
|----------|------|---------|-------|
| Unit test report | ci-artifacts/unit-test-report.xml | a1b2c3... | 247 tests, 100% pass |
| Coverage report | ci-artifacts/coverage.json | d4e5f6... | 78.3% branch coverage |
| SBOM | sbom/sbom-cyclonedx.json | g7h8i9... | 142 dependencies |
| Security scan | ci-artifacts/semgrep-report.json | j0k1l2... | 0 critical, 0 high |
| Container scan | ci-artifacts/trivy-report.json | m3n4o5... | 0 critical |

## Missing Evidence
- [ ] Load test results (scheduled for next release)
```

---

## Anti-Patterns

- **Evidence spread across tools without index**: if auditors can't find it, it doesn't exist
- **Non-repeatable "screenshots only" evidence**: evidence must be reproducible from CI
- **No traceability from changes to approvals**: every production change must trace to an approved ticket
- **Missing audit logs for critical actions**: "we don't log that" is not acceptable for regulated data
- **Logging PII in application logs**: audit trail yes, application log no
- **Unlimited retention**: storing data forever "just in case" violates data minimization

---

## For Claude Code

When generating code handling PII: document the legal basis in a comment, include masking in logs, generate endpoints for data export and data deletion, verify data residency in cloud configuration. Include tenant_id in every multi-tenant database query. When preparing releases for regulated customers, generate evidence pack structure and INDEX.md. Include compliance assessment checklist in PRR (see `production-readiness-review/SKILL.md`).

---

*Internal references*: `security-by-design/SKILL.md`, `authn-authz/SKILL.md`, `data-modeling/SKILL.md`, `production-readiness-review/SKILL.md`
