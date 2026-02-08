---
skill: production-readiness-review
version: 1.0.0
last-updated: 2026-02-08
domain: delivery
depends-on: [observability, security, compliance, cicd-pipeline]
---

# Production Readiness Review (PRR)

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

- [ ] Structured logging with correlation ID (see `observability.md`)
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

- [ ] Authentication and authorization enforced on all endpoints (see `authn-authz.md`)
- [ ] Tenant isolation verified with automated tests
- [ ] Secrets management validated (no hardcoded credentials)
- [ ] Security scanning passed: SAST, dependency scan, container scan (see `security-testing.md`)
- [ ] Threat model updated (for high-impact services)
- [ ] Least privilege: service accounts have minimum required permissions

### 6. Data & Compliance

- [ ] Data classification documented (PII fields identified)
- [ ] Audit trail for business-critical operations
- [ ] Data retention policies defined and automated
- [ ] Backup and restore tested
- [ ] GDPR compliance verified (if handling EU data) — see `compliance.md`
- [ ] Multi-tenant data isolation verified

### 7. Release Safety

- [ ] Rollback strategy defined and tested (see `release.md`)
- [ ] Database migrations are backward-compatible (additive only)
- [ ] Feature flags for risky features (kill switch available)
- [ ] Canary or blue-green deploy configured
- [ ] Automatic rollback on SLO breach in first N minutes
- [ ] Smoke tests in staging passed

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

## Anti-Patterns

- **"We'll handle it in production"**: if it's not ready now, it won't magically be ready after deploy
- **No on-call ownership**: a service without an owner is an orphan waiting to become an incident
- **PRR as ceremony**: if the checklist is rubber-stamped without verification, it provides false confidence
- **PRR too late**: running PRR after the deploy date is committed makes NO-GO politically impossible

---

## For Claude Code

When preparing a service for production: generate PRR checklist populated with actual service configuration, identify missing items (no health check endpoint, no runbook, missing alerts), suggest concrete fixes for each gap. Reference specific skills for each area.

---

*Internal references*: `observability.md`, `security.md`, `security-testing.md`, `compliance.md`, `release.md`, `cicd.md`
