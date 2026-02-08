---
skill: architecture-decision-records
version: 1.0.0
last-updated: 2026-02-08
domain: foundations
depends-on: [architectural-principles, diagrams]
---

# Architecture Decision Records (ADR)

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

**Cost impact is mandatory.** Every ADR must include estimated cost implications (infrastructure, development time, operational complexity). Reference `finops.md` for cost modeling.

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
4. Decisional review meeting: 30 min max (see `architecture-comms.md`)
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

## Anti-Patterns

- **ADR as post-mortem**: writing the ADR after the code is merged defeats the purpose of deliberation
- **No alternatives considered**: if there's only one option, either you haven't looked hard enough or it's not worth an ADR
- **No consequences section**: every decision has trade-offs; pretending otherwise is dishonest
- **ADR without guardrails**: if you can't test or observe whether the decision works, you can't know if it was right
- **Orphan ADR**: an accepted ADR with no follow-up tickets means the decision exists on paper but not in code

---

## For Claude Code

When an architectural decision is needed: generate ADR draft following the format above, suggest reviewers based on impact area, generate follow-up ticket descriptions. When referencing a decision in code or documentation, link to the ADR by number. Every non-obvious architectural choice in generated code should reference an ADR or be flagged as needing one.

---

*Internal references*: `architecture-comms.md`, `diagrams.md`, `finops.md`, `compliance.md`
