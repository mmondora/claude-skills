---
name: architecture-review-facilitation
cluster: functional-architecture
description: "Architecture review governance and facilitation. Divulgative, decisional, and lightweight review types. Requestor preparation, facilitation guide, outcome recording. Use when preparing architecture reviews, evaluating proposals, or establishing review governance."
---

# Architecture Review Facilitation

> **Version**: 1.0.0 | **Last updated**: 2026-02-14

## Purpose

Architecture Reviews are the governance mechanism ensuring architectural coherence without becoming a bottleneck. This skill covers divulgative reviews (sharing knowledge, building alignment), decisional reviews (evaluating proposals, approving/rejecting), and lightweight reviews (async, document-based). Reviews are the lobby -- where strategic intent meets implementation proposals. A well-run review accelerates delivery; a poorly run review becomes an ivory tower that teams route around.

---

## Review Types

Three review types, each with distinct goals and formats.

### Divulgative Review

**Goal**: share knowledge, build alignment, surface concerns early. No approval gate -- the decision has already been made or does not require one. **Format**: 30 min. Presenter walks through the architecture, attendees ask questions, concerns are recorded but do not block.

**When to use**: new service onboarding, post-mortem architecture changes, technology adoption announcements, cross-team knowledge sharing.

### Decisional Review

**Goal**: evaluate a proposal and reach a verdict. **Format**: 45 min. Structured agenda (see Conductor Guide below). **Verdicts**:

| Verdict | Meaning |
|---------|---------|
| **APPROVED** | Proceed as proposed. ADR status set to `accepted`. |
| **APPROVED WITH CONDITIONS** | Proceed after satisfying listed conditions. Conditions are tracked as action items with owners and deadlines. |
| **REJECTED** | Proposal does not meet requirements. Rejection rationale recorded. Requestor may resubmit after addressing feedback. |

Decision requires quorum: at least 2 senior engineers/architects present. Tie-breaking: designated architecture owner has final call.

### Lightweight Review

**Goal**: async approval for low-risk, well-documented proposals. **Format**: ADR or RFC circulated via PR. Reviewers comment within 48 hours. Silence after 48h = consent. **Escalation**: any reviewer can escalate to a decisional review by commenting `ESCALATE` with rationale.

### Decision Matrix: Which Type?

| Factor | Lightweight | Divulgative | Decisional |
|--------|-------------|-------------|------------|
| Blast radius | Single service | Any | Multiple services or cross-team |
| Reversibility | Easily reversible | Any | Difficult or impossible to reverse |
| Cost impact | < $500/month | Any | > $500/month or new vendor |
| Teams affected | 1 team | 1+ teams | 2+ teams |
| Data model change | Additive only | Any | Breaking or migration required |
| Compliance impact | None | None | Any |

If any factor falls in the "Decisional" column, use a decisional review. If none do but knowledge sharing is needed, use divulgative. Otherwise, lightweight.

---

## Review Preparation -- Requestor Checklist

Before requesting a review, the requestor prepares the following. Incomplete submissions are returned without scheduling.

1. **Problem statement**: what problem are we solving, for whom, and why now?
2. **Options considered**: minimum 3 options -- the recommended approach, at least one alternative, and "do nothing" (with explicit cost of inaction)
3. **Recommended option**: which option and why -- trade-offs articulated, not just advantages
4. **NFR impact**: latency, throughput, availability, cost, security, compliance implications
5. **Risk assessment**: what can go wrong, likelihood, mitigation
6. **ADR draft**: follows `architecture-decision-records/SKILL.md` format, status set to `proposed`
7. **C4 diagrams**: context (L1) mandatory, container (L2) for multi-service changes, component (L3) only if reviewing internal design
8. **Blast radius analysis**: which services, teams, data stores, and external integrations are affected

### Review Request Template

```markdown
# Architecture Review Request

**Requestor**: {{requestor}}
**Date submitted**: {{YYYY-MM-DD}}
**Requested review type**: {{Decisional / Divulgative / Lightweight}}
**Target review date**: {{YYYY-MM-DD or "ASAP" for emergency}}

## Problem Statement
{{2-3 sentences: what, for whom, why now}}

## Options Considered
1. **{{Option A — Recommended}}**: {{one-line summary}}
2. **{{Option B}}**: {{one-line summary}}
3. **Do nothing**: {{explicit cost of inaction}}

## Recommendation
{{Which option and key trade-offs}}

## Blast Radius
- **Services affected**: {{list}}
- **Teams affected**: {{list}}
- **Data stores affected**: {{list}}
- **External integrations affected**: {{list}}

## Attachments
- [ ] ADR draft (link)
- [ ] C4 diagrams (link)
- [ ] NFR impact analysis
- [ ] Risk assessment
```

---

## Review Facilitation -- Conductor Guide

The conductor (facilitator) is not the requestor. The conductor owns the process; the requestor owns the content.

### Decisional Review Structure (45 min)

| Phase | Duration | Activity |
|-------|----------|----------|
| **Context** | 10 min | Requestor presents problem and recommendation. Attendees have read the ADR beforehand -- this is a recap, not a first reading. |
| **Questions** | 15 min | Structured Q&A. Conductor ensures questions are answered, not debated. Park tangential topics. |
| **Evaluation** | 10 min | Discuss trade-offs, risks, alternatives. Conductor tracks concerns on a shared board. |
| **Decision** | 10 min | Conductor calls for verdict. Record decision, conditions, and action items. |

### Divulgative Review Structure (30 min)

| Phase | Duration | Activity |
|-------|----------|----------|
| **Presentation** | 15 min | Architecture walkthrough with diagrams. |
| **Q&A** | 10 min | Questions and concerns. |
| **Actions** | 5 min | Record follow-ups and open questions. |

### Facilitation Rules

1. **Pre-read enforced**: if attendees have not read the ADR, reschedule. Do not waste 45 minutes on live reading.
2. **Timebox strictly**: the conductor cuts discussions that exceed phase duration. Unresolved topics become action items.
3. **No laptops open** (except for reference material): reviews require active attention.
4. **Disagree and commit**: once a verdict is reached, it is binding. Disagreements are recorded in the ADR but do not reopen the decision.
5. **Requestor speaks last** in evaluation phase: prevents anchoring bias.
6. **One conversation at a time**: side conversations kill review quality.

### Decision Protocol

- Conductor asks each senior reviewer for their position: APPROVE, APPROVE WITH CONDITIONS, or REJECT.
- Conditions must be specific, actionable, and have a deadline.
- If no consensus: architecture owner makes the final call and records the rationale.
- Verdict is announced in the meeting and confirmed in writing within 24 hours.

---

## Review Outcome Record Template

```markdown
# Architecture Review Outcome

**Date**: {{YYYY-MM-DD}}
**Review type**: {{Decisional / Divulgative / Lightweight}}
**Conductor**: {{name}}
**Requestor**: {{name}}
**Attendees**: {{names and roles}}

## Proposal Summary
{{2-3 sentences summarizing what was proposed}}

## Decision
**Verdict**: {{APPROVED / APPROVED WITH CONDITIONS / REJECTED / N/A (divulgative)}}

### Conditions (if applicable)
1. {{Condition}} — **Owner**: {{name}} — **Deadline**: {{YYYY-MM-DD}}
2. {{Condition}} — **Owner**: {{name}} — **Deadline**: {{YYYY-MM-DD}}

### Rationale
{{Why this verdict was reached. Key arguments for and against.}}

### Risks Accepted
- {{Risk 1}}: {{mitigation or acceptance rationale}}
- {{Risk 2}}: {{mitigation or acceptance rationale}}

## Action Items
| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| {{action}} | {{name}} | {{date}} | Open |

## Related ADR
{{Link to ADR created or updated as a result of this review}}

## Notes
{{Additional discussion points, dissenting opinions, or parking lot items}}
```

---

## Review Cadence and Governance

### Cadence

- **2 review slots per week**: Tuesday and Thursday, 30-45 min each.
- **Review backlog**: maintained in a shared board (Jira, Linear, or GitHub Project). Requests are FIFO unless an emergency review is triggered.
- **Target time-from-request-to-review**: < 5 business days. If the backlog exceeds 5 days, add a temporary third slot.

### Emergency Reviews

Triggered when a production incident or critical deadline requires an immediate architectural decision. Emergency reviews follow decisional format but can be called with 4 hours notice. Minimum quorum: 1 architecture owner + 1 senior engineer. Emergency decisions are provisional -- they must be ratified in the next regular review slot.

### Governance Metrics

| Metric | Target | Measured |
|--------|--------|----------|
| Time from request to review | < 5 business days | Weekly |
| Review completion rate | > 90% of scheduled reviews held | Monthly |
| Condition closure rate | > 80% conditions closed by deadline | Monthly |
| ADR linkage | 100% of decisional reviews produce an ADR | Per review |
| Attendee preparation rate | > 80% have read pre-read material | Per review (conductor assessment) |

Review governance is itself reviewed quarterly. If metrics consistently miss targets, adjust cadence, format, or preparation requirements.

---

## Anti-Patterns

- **Rubber stamp review**: reviewers approve everything without critical evaluation -- reviews exist to challenge assumptions, not to validate foregone conclusions
- **Ivory tower review**: review board disconnected from implementation reality, issuing mandates that teams cannot execute within constraints
- **Review too late**: architecture review after implementation is complete -- reviewing code that's already in production is a postmortem, not a review
- **Scope creep**: a review that was supposed to evaluate a caching strategy devolves into redesigning the entire data layer -- conductor must enforce scope boundaries
- **Missing "do nothing" option**: every proposal must include the cost of inaction; without it, reviewers cannot evaluate whether the change is worth the disruption
- **Decision without quorum**: a single person approving a cross-team change bypasses the governance purpose -- minimum quorum is non-negotiable
- **Review as performance**: reviews where the requestor presents for 40 minutes and gets 5 minutes of rubber-stamp questions -- the ratio should be inverted
- **Zombie conditions**: APPROVED WITH CONDITIONS where conditions are never tracked or enforced -- conditions without owners and deadlines are wishes, not governance

---

## For Claude Code

When preparing architecture reviews: generate the review request template pre-filled with available context, ensure the "do nothing" option is always included with explicit cost of inaction, produce C4 diagrams at the appropriate level for the blast radius, and draft the ADR in `proposed` status. When facilitating reviews: enforce the phase structure and timeboxes, generate the outcome record template with all fields populated from the discussion, and create action items with owners and deadlines. When establishing review governance: set up the cadence, define the backlog tracking mechanism, and configure the governance metrics. Never skip the requestor checklist -- return incomplete submissions with specific feedback on what is missing. Always link review outcomes to ADRs.

---

*Internal references*: `architecture-decision-records/SKILL.md`, `architecture-communication/SKILL.md`, `nfr-specification/SKILL.md`, `trade-off-analysis/SKILL.md`, `architecture-risk-assessment/SKILL.md`
