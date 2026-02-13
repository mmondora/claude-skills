---
name: production-readiness-review
cluster: delivery-release
description: "Production readiness GO/NO-GO framework. NFR checklist covering availability, scalability, observability, security, compliance. Use before deploying new services or major changes to production."
---

# Production Readiness Review (PRR)

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

A structured GO / NO-GO decision framework for production deployments. Ensures non-functional requirements (NFRs) are met before code reaches users.

---

## When to Run a PRR

- New service going to production for the first time
- Major architecture change affecting production behavior
- Major release with breaking changes or new infrastructure
- New country/region rollout at scale
- After a significant incident (as part of remediation validation)

---

## PRR Checklist

### 1. Availability & Resiliency

- [ ] Redundancy: no single point of failure for critical paths
- [ ] Failover: automatic failover for stateful components (database, cache)
- [ ] Graceful degradation: system continues with reduced functionality when dependencies fail
- [ ] Timeouts configured for all external calls (HTTP, database, message queue)
- [ ] Retry with exponential backoff for transient failures
- [ ] Circuit breaker for dependencies that can be temporarily unavailable
- [ ] Health check endpoints: `/health` (liveness) and `/ready` (readiness)

### 2. Scalability

- [ ] Load characteristics understood and documented (expected RPS, peak patterns)
- [ ] Horizontal scaling strategy defined (Cloud Run auto-scaling, GKE HPA)
- [ ] Capacity plan for peak load (Black Friday, launch day, campaign)
- [ ] Database connection pooling configured for expected concurrency
- [ ] No shared mutable state preventing horizontal scaling

### 3. Observability

- [ ] Structured logging with correlation ID (see `observability/SKILL.md`)
- [ ] 4 golden signals metrics: request rate, error rate, latency, saturation
- [ ] Distributed tracing enabled for critical paths
- [ ] Dashboards exist and linked in runbook
- [ ] Alerts configured for SLO breaches
- [ ] SLOs defined: availability target, latency target (p95, p99), error budget

### 4. Operability

- [ ] Ownership defined: team name, on-call rotation, escalation path
- [ ] Runbook exists with: first response steps, common failure scenarios, escalation triggers
- [ ] Deployment runbook: pre-deploy checklist, deploy steps, post-deploy validation, rollback steps
- [ ] Dependency map documented: what this service depends on, what depends on this service
- [ ] Secrets managed via Secret Manager (not env vars or config files)

### 5. Security

- [ ] Authentication and authorization enforced on all endpoints (see `authn-authz/SKILL.md`)
- [ ] Tenant isolation verified with automated tests
- [ ] Secrets management validated (no hardcoded credentials)
- [ ] Security scanning passed: SAST, dependency scan, container scan (see `security-testing/SKILL.md`)
- [ ] Threat model updated (for high-impact services)
- [ ] Least privilege: service accounts have minimum required permissions

### 6. Data & Compliance

- [ ] Data classification documented (PII fields identified)
- [ ] Audit trail for business-critical operations
- [ ] Data retention policies defined and automated
- [ ] Backup and restore tested
- [ ] GDPR compliance verified (if handling EU data) — see `compliance-privacy/SKILL.md`
- [ ] Multi-tenant data isolation verified

### 7. Release Safety

- [ ] Rollback strategy defined and tested (see `release-management/SKILL.md`)
- [ ] Database migrations are backward-compatible (additive only)
- [ ] Feature flags for risky features (kill switch available)
- [ ] Canary or blue-green deploy configured
- [ ] Automatic rollback on SLO breach in first N minutes
- [ ] Smoke tests in staging passed

### 8. Verification & Testing

- [ ] Load test executed at 2x expected peak (see `performance-testing/SKILL.md`)
- [ ] Chaos experiment passed: service recovers from dependency failure
- [ ] DNS configured and propagated (if new domain/subdomain)
- [ ] TLS certificate valid and auto-renewing
- [ ] CDN configured for static assets (if applicable)

### 9. Cost Readiness

- [ ] Monthly cost estimate documented (see `finops/SKILL.md`)
- [ ] Budget alerts configured for the service
- [ ] Autoscaling max-instances capped to prevent cost runaway
- [ ] Non-prod environments configured to scale to zero

---

## PRR Decision

### GO
All critical items passed. Non-critical items have owners and timelines.

### CONDITIONAL GO
Critical items passed but significant risks remain. Conditions documented with:
- What must happen before full traffic
- Who owns each condition
- Deadline for each condition
- Enhanced monitoring plan during conditional period

### NO-GO
Critical items failed. Service must not go to production until:
- Blocking items listed with owners
- Re-review date scheduled
- Risk assessment of delay documented

---

## PRR Output Document

```markdown
# PRR: [Service Name] — [Date]

## Decision: GO / CONDITIONAL GO / NO-GO

## Participants
- [names and roles]

## Summary
[2-3 sentences on overall readiness]

## Checklist Results
| Area | Status | Notes |
|------|--------|-------|
| Availability & Resiliency | PASS / PARTIAL / FAIL | ... |
| Scalability | PASS / PARTIAL / FAIL | ... |
| Observability | PASS / PARTIAL / FAIL | ... |
| Operability | PASS / PARTIAL / FAIL | ... |
| Security | PASS / PARTIAL / FAIL | ... |
| Data & Compliance | PASS / PARTIAL / FAIL | ... |
| Release Safety | PASS / PARTIAL / FAIL | ... |

## Conditions (if CONDITIONAL GO)
| Condition | Owner | Deadline |
|-----------|-------|----------|
| ... | ... | ... |

## Residual Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| ... | ... | ... | ... |

## Monitoring Plan
[Enhanced monitoring for first N days post-launch]
```

---

## Example PRR Output (Filled In)

```markdown
# PRR: Invoice API Service — 2026-02-08

## Decision: CONDITIONAL GO

## Participants
- Mario Rossi (Tech Lead), Anna Bianchi (SRE), Luca Verdi (Security)

## Summary
Invoice API is ready for production with two conditions: runbook completion
and load test validation. Core functionality, security, and observability
meet production standards.

## Checklist Results
| Area | Status | Notes |
|------|--------|-------|
| Availability & Resiliency | PASS | Circuit breaker on Stripe, health endpoints present |
| Scalability | PASS | Cloud Run auto-scaling, tested to 200 RPS |
| Observability | PASS | OTel tracing, pino logging, SLO alerts configured |
| Operability | PARTIAL | Runbook 80% complete — missing rollback steps |
| Security | PASS | Auth on all endpoints, tenant isolation tested |
| Data & Compliance | PASS | GDPR checklist complete, audit trail active |
| Release Safety | PASS | Canary deploy configured, feature flag ready |

## Conditions (CONDITIONAL GO)
| Condition | Owner | Deadline |
|-----------|-------|----------|
| Complete runbook rollback section | @anna | 2026-02-10 |
| Run full load test at 2x expected peak | @mario | 2026-02-12 |

## Residual Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Stripe API rate limiting under peak | Low | Medium | Circuit breaker + queue |
| Cold start latency on first request | Medium | Low | min-instances=1 in prod |

## Monitoring Plan
Enhanced monitoring for first 7 days:
- Error rate dashboard reviewed every 2 hours
- p99 latency alert threshold lowered to 1.5s (from 2s)
- Daily review of Stripe integration metrics
```

---

## Anti-Patterns

- **"We'll handle it in production"**: if it's not ready now, it won't magically be ready after deploy
- **No on-call ownership**: a service without an owner is an orphan waiting to become an incident
- **PRR as ceremony**: if the checklist is rubber-stamped without verification, it provides false confidence
- **PRR too late**: running PRR after the deploy date is committed makes NO-GO politically impossible

---

## For Claude Code

When preparing a service for production: generate PRR checklist populated with actual service configuration, identify missing items (no health check endpoint, no runbook, missing alerts), suggest concrete fixes for each gap. Reference specific skills for each area.

---

*Internal references*: `observability/SKILL.md`, `security-by-design/SKILL.md`, `security-testing/SKILL.md`, `compliance-privacy/SKILL.md`, `release-management/SKILL.md`, `cicd-pipeline/SKILL.md`
