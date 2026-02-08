---
name: architecture-communication
description: "Communicating architectural decisions to stakeholders. Architecture Reviews, ADR presentation, stakeholder-adapted communication. Use when preparing architecture reviews, presenting technical decisions, or writing documentation for different audiences."
---

# Architecture Communication

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

## Purpose

Communicating architectural decisions to different stakeholders. Architecture Reviews, ADR presentation, stakeholder management, and architecture documentation as a living artifact. The best architecture is useless if it's not understood and adopted.

---

## Architecture Review

### Review Types

**Educational**: presents an architecture or pattern to the team. Goal: alignment and understanding. No decision to make — knowledge to share. Format: 20 min presentation + 10 min Q&A.

**Decisional**: presents alternatives for an architectural decision. Goal: make an informed decision. Format: ADR pre-circulated → 30 min discussion → decision. Participants read the ADR before the meeting — the meeting is NOT for presenting the ADR, it's for discussing it.

### Decisional Review Structure

Preparation (before meeting): ADR draft with context, alternatives, recommendation. Circulated at least 2 business days before. Reviewers have read and prepared questions.

Discussion (in meeting): 5 min context recap (don't re-read the ADR — key points only). 20 min discussion of alternatives and trade-offs. 5 min decision and action items.

Output: ADR updated with "accepted" status and any discussion notes.

---

## Communicating to Different Stakeholders

**For developers**: technical detail, C4 Level 2-3 diagrams, code examples, ADR with detailed alternatives. Precise language.

**For engineering managers**: impact on teams and timeline, risks, dependencies, costs. C4 Level 1-2 diagrams. Less implementation detail, more organizational impact.

**For product managers / business**: what changes for the user, timeline, business risks, costs. C4 Level 1 diagram only. Zero technical jargon — if you say "microservices" and the PM doesn't understand, you've communicated poorly.

**For executives**: cost, risk, timeline, strategic impact. One slide. Numbers. If it takes 5 slides to explain the decision, it's either too complex for that audience level or hasn't been synthesized enough.

---

## Architecture Documentation Structure

For each service or capability, maintain living documentation:

### Required Outputs

1. `docs/architecture/<service-or-capability>/overview.md`
2. C4 diagrams: context, container, component (only if needed)
3. `nfr.md` — non-functional requirements and targets
4. `operability.md` — SRE readiness (dashboards, alerts, runbooks)
5. Links to relevant ADRs

### overview.md — Mandatory Content

#### 1. Context & Objectives
- Business problem, users, and success metrics
- Constraints (time, cost, compliance)
- Scope and non-scope

#### 2. Background & Evolution
- Milestones achieved
- Prior architectures and why they changed
- Current known limitations

#### 3. Architecture (C4)
- Each diagram with short narrative explanation
- System boundaries and trust boundaries called out

#### 4. Key Flows
- Critical user journeys (happy path + error paths)
- Critical integrations (sync and async)
- Failure modes and fallback behavior

#### 5. Data Ownership & Lifecycle
- System of record per entity
- Projection patterns (CQRS, read models)
- Retention and deletion policy (link to `compliance.md`)

#### 6. NFR Targets
- Availability target, latency target, throughput assumptions
- Scalability strategy
- Resilience strategy

#### 7. Security & Compliance
- AuthN/AuthZ model (link to `authn-authz.md`)
- Data classification (PII fields identified)
- Audit logging scope

#### 8. External Services & Integrations
- Which external services are used (APIs, cloud services)
- Guardrails adopted (contract tests, policies, observability gates)
- Circuit breaker and fallback behavior for each dependency

### Example: overview.md Excerpt (Section 1 + 4)

```markdown
# Invoice Platform — Architecture Overview

## 1. Context & Objectives

The Invoice Platform enables small businesses to create, send, and track
invoices. Target: 1,000 active businesses within 6 months of launch.

**Success metrics**: invoice creation < 3s (p95), 99.9% availability,
< $100/month cloud cost at 1,000 tenants.

**Constraints**: GDPR compliance (EU data residency), 4-week MVP timeline,
3-person engineering team, budget < $200/month for infrastructure.

**Scope**: Invoice CRUD, PDF export, email sending, payment status tracking.
**Non-scope**: Payment processing (use Stripe), accounting integration (v2).

## 4. Key Flows

### Invoice Creation (Happy Path)
1. User fills invoice form in React SPA
2. Client sends POST /api/v1/tenants/{id}/invoices with JWT
3. API validates input (Zod), saves to Firestore
4. API publishes `invoicing.invoice.created` event to Pub/Sub
5. Worker processes event: generates PDF, sends email notification
6. Client receives 201 Created with invoice data

### Invoice Creation (Error: Duplicate)
1-2. Same as happy path
3. Firestore write fails (duplicate invoice number for tenant)
4. API returns 409 Conflict with RFC 7807 error body
5. Client displays error message, user corrects invoice number
```

### Quality Checks for Architecture Docs

- Document is readable by an Engineering Manager (not just architects)
- Every major choice links to an ADR
- Customization uses extension points (not core hardcoding)
- No static snapshot: evolution section documents past decisions and future direction
- Explicit data ownership — if nobody knows who owns the data, it's an incident waiting to happen

---

## Communication Anti-Patterns

**Architecture astronaut**: presents beautiful abstract solutions nobody understands or can implement. Come back to earth: what changes tomorrow morning for people writing code?

**Decision by committee**: 15 people in a meeting where nobody makes a decision. Rule: deciders are named in the ADR. Others are consulted, not deciders.

**Architecture by PowerPoint**: beautiful slides, zero implementation. Architecture lives in code and infrastructure, not in slides.

**Diagram without narrative**: a C4 diagram with boxes and arrows but no explanation of why those boundaries exist is decoration, not documentation.

**Documentation as static snapshot**: architecture docs that describe the initial design but never mention evolution, known limitations, or future direction become misleading artifacts.

---

## For Claude Code

When generating documentation for communication: adapt detail level to audience, use C4 diagrams at appropriate level, for ADRs always include "impact" section with team/cost/timeline impact. Never generate documentation requiring tribal knowledge to understand. When creating architecture docs, follow the overview.md structure above with all 8 sections.

---

*Internal references*: `adr.md`, `diagrams.md`, `technical-docs.md`, `production-readiness.md`
