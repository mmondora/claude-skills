---
name: architecture-decision-records
cluster: foundations
description: "Architecture Decision Records governance and format. ADR lifecycle, review process, when to write an ADR. Use when making architectural decisions, introducing new technology, or changing integration patterns."
---

# Architecture Decision Records (ADR)

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

Capture architectural decisions before they become irreversible constraints. Every significant decision has a recorded "why" — enabling future evolution instead of blocking it.

---

## When to Write an ADR

An ADR is required **before implementation** when:

- Introducing new technology or tooling with long-term impact
- Changing integration pattern (API → events, sync → async)
- Changing data ownership or shared schema
- Making trade-offs affecting NFRs (availability, cost, latency, compliance)
- Choosing between frameworks, databases, or cloud services
- Establishing a new convention or overriding an existing one

If the decision is already implemented: write a "late ADR" and document why it was late.

---

## ADR Format

File: `adr/NNNN-title-slug.md` (zero-padded, e.g., `adr/0012-switch-to-pubsub.md`)

```markdown
# ADR-NNNN: Title

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXXX

## Date
YYYY-MM-DD

## Owners
Names or teams responsible for this decision.

## Related
Links to docs, issues, PRs, other ADRs.

---

## 1. Context
What is the situation? What problem are we solving?
Include constraints: time, cost, compliance, team skills.

## 2. Decision
What we decided. One sentence, clear and direct.

## 3. Drivers
Why now? What triggered this decision?
(new feature, performance issue, compliance requirement, cost pressure)

## 4. Options Considered

### Option A: [Name]
- **Pros**: ...
- **Cons**: ...
- **Cost impact**: ...

### Option B: [Name]
- **Pros**: ...
- **Cons**: ...
- **Cost impact**: ...

### Option C: [Name] (if applicable)
- **Pros**: ...
- **Cons**: ...
- **Cost impact**: ...

## 5. Decision Rationale
Why Option X was chosen over the others.
Reference principles from architectural-principles if applicable.

## 6. Consequences

### Positive
- ...

### Negative
- ...

### Follow-ups
- Tickets, tasks, or future ADRs this creates.

## 7. Guardrails
- Tests required to validate the decision
- Observability required to monitor the decision's impact
- Security gates required

## 8. Migration Plan
Steps to implement the decision (if replacing existing approach).
Include timeline, backward compatibility window, and rollout strategy.

## 9. Rollback
How to revert this decision if it proves wrong.
Include: conditions that trigger rollback, steps, estimated effort.
```

---

## Governance Rules

**One decision per ADR.** If a single discussion produces multiple decisions, create multiple ADRs.

**ADR required BEFORE implementation** for high-impact changes. The review discussion happens before code is written — not after.

**Cost impact is mandatory.** Every ADR must include estimated cost implications (infrastructure, development time, operational complexity). Reference `finops/SKILL.md` for cost modeling.

**Status lifecycle**: Proposed → Accepted → (optionally) Deprecated or Superseded. A superseded ADR links to its replacement. Deprecated ADRs explain why.

**Immutable history**: never delete an ADR. Supersede it with a new one that references the old.

---

## Review Process

When an ADR is proposed:

1. Author writes the ADR and opens a PR
2. Suggested reviewers based on impact area:
   - **Architecture changes**: Tech Lead, Architects
   - **Security implications**: Security team
   - **Operational changes**: SRE / Ops
   - **Compliance impact**: Compliance / Legal
   - **Cost impact > threshold**: Engineering Manager
3. Reviewers have **2 business days** to review before the decisional meeting
4. Decisional review meeting: 30 min max (see `architecture-communication/SKILL.md`)
5. ADR updated to "Accepted" with any discussion notes, merged

---

## ADR Index

Maintain an `adr/README.md` with a table of all ADRs:

```markdown
| # | Title | Status | Date | Domain |
|---|-------|--------|------|--------|
| 0001 | Use Firestore for MVP | Accepted | 2026-01-15 | data |
| 0002 | Switch to PostgreSQL for invoicing | Accepted | 2026-02-01 | data |
| 0003 | Adopt Pub/Sub for async events | Proposed | 2026-02-08 | messaging |
```

---

## Example ADR (Filled In)

```markdown
# ADR-0001: Use Firestore for Initial Data Storage

## Status
Accepted

## Date
2026-01-15

## Owners
Backend team (lead: @mario)

## Related
- Epic: MVP Data Layer (#42)
- GCP Free Tier analysis: see finops/SKILL.md

---

## 1. Context
We need a database for the MVP. The team is small (3 developers), the data model
is document-oriented (invoices, tenants, users), and we want to minimize
infrastructure management. Expected load: < 1000 users, < 10K documents.

## 2. Decision
Use Firestore (Native mode) as the primary database for the MVP.

## 3. Drivers
- MVP timeline (4 weeks) — no time for database ops
- Team has Firebase experience
- Free tier covers MVP load entirely

## 4. Options Considered

### Option A: Firestore (Native mode)
- **Pros**: zero ops, free tier covers MVP, real-time subscriptions, Firestore Security Rules
- **Cons**: no SQL, limited querying, vendor lock-in, no JOINs
- **Cost impact**: free for MVP load (50K reads/day, 20K writes/day)

### Option B: Cloud SQL (PostgreSQL)
- **Pros**: full SQL, mature tooling, Drizzle ORM, RLS for tenant isolation
- **Cons**: always-on cost (~$30/month minimum), requires connection management
- **Cost impact**: ~$30-50/month for smallest instance

### Option C: PlanetScale (MySQL)
- **Pros**: serverless MySQL, generous free tier, branching for schema changes
- **Cons**: MySQL (not PostgreSQL), external vendor, limited GCP integration
- **Cost impact**: free tier for MVP, ~$29/month for production

## 5. Decision Rationale
Firestore wins on: zero ops overhead, free tier alignment, team familiarity.
The limited querying is acceptable for MVP scope. We accept the trade-off of
vendor coupling in exchange for speed to market.

## 6. Consequences
### Positive
- Zero database infrastructure to manage
- Real-time capabilities for future features
### Negative
- Migration to PostgreSQL will be needed if relational queries become critical
- No native JOIN support — denormalization required
### Follow-ups
- Ticket: Evaluate PostgreSQL migration at 1000+ users (#78)
- Ticket: Define Firestore Security Rules for tenant isolation (#79)

## 7. Guardrails
- Integration tests with Firestore emulator for every repository
- Monitor read/write counts approaching free tier limits (alert at 80%)
- Tenant isolation tests (automated, in CI)

## 8. Migration Plan
N/A — greenfield project.

## 9. Rollback
If Firestore proves insufficient before launch:
- Trigger: query complexity exceeds Firestore capabilities for core features
- Steps: provision Cloud SQL, migrate data with script, update repository layer
- Estimated effort: 1-2 sprints
```

---

## Anti-Patterns

- **ADR as post-mortem**: writing the ADR after the code is merged defeats the purpose of deliberation
- **No alternatives considered**: if there's only one option, either you haven't looked hard enough or it's not worth an ADR
- **No consequences section**: every decision has trade-offs; pretending otherwise is dishonest
- **ADR without guardrails**: if you can't test or observe whether the decision works, you can't know if it was right
- **Orphan ADR**: an accepted ADR with no follow-up tickets means the decision exists on paper but not in code

### ADR Granularity

Not every technical choice needs an ADR. Use this heuristic:

| Decision | ADR? | Why |
|----------|------|-----|
| Choice of database | Yes | Long-term impact, hard to reverse |
| Choice of HTTP library | No | Easy to swap, low impact |
| New event schema | Yes | Public contract, affects consumers |
| Refactoring internal module | No | Internal, easily reversible |
| Adding a new cloud service | Yes | Cost, operational, security impact |

When in doubt: if the decision would be hard to reverse in 6 months, write an ADR.

### Disagreement Escalation

When reviewers disagree on an ADR:

1. Author addresses concerns in writing (update ADR with counterpoints)
2. If still unresolved: time-boxed meeting (30 min max) with named decision-maker
3. Decision-maker decides — document the rationale including the dissenting view
4. No consensus required — one clear decision-maker per ADR avoids paralysis

---

## For Claude Code

When an architectural decision is needed: generate ADR draft following the format above, suggest reviewers based on impact area, generate follow-up ticket descriptions. When referencing a decision in code or documentation, link to the ADR by number. Every non-obvious architectural choice in generated code should reference an ADR or be flagged as needing one.

---

*Internal references*: `architecture-communication/SKILL.md`, `diagrams/SKILL.md`, `finops/SKILL.md`, `compliance-privacy/SKILL.md`
