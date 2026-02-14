---
name: architecture-risk-assessment
cluster: functional-architecture
description: "Architectural risk identification, assessment, and mitigation. Risk register, assumption mapping, dependency analysis, failure mode analysis. Use when assessing technical risk, communicating risk to stakeholders, or mapping technical debt as architectural risk."
---

# Architecture Risk Assessment

> **Version**: 1.0.0 | **Last updated**: 2026-02-14

## Purpose

Risk is the shadow side of every architectural decision. This skill provides a systematic method for identifying, assessing, communicating, and mitigating architectural risks -- specifically technical and structural risks that emerge from architectural choices. Risks discovered in the engine room must be communicated to the penthouse in business terms.

---

## Risk Identification Techniques

Four systematic approaches. Apply all four; each surfaces risks the others miss.

### 1. Assumption Mapping

Every architecture rests on assumptions. List them explicitly -- each assumption is a risk source.

| Assumption | Category | If Wrong... | Confidence |
|------------|----------|-------------|------------|
| Peak load stays under 10k RPS | Capacity | Horizontal scaling won't save us; need architectural rework | Medium |
| Auth provider SLA is 99.99% | Dependency | Login unavailable, all user-facing features blocked | High |
| Team will grow from 3 to 8 by Q3 | Organizational | Service decomposition timeline slips; monolith stays longer | Low |
| PII stays in EU region only | Regulatory | GDPR violation, data residency breach, potential fines | High |

Review assumptions quarterly. Confidence below Medium triggers immediate mitigation planning.

### 2. Dependency Analysis

Map every external dependency: third-party APIs, managed services, shared libraries, partner integrations, certificate authorities, DNS providers. For each:

- **Coupling type**: compile-time, runtime, data, operational
- **Failure mode**: what happens when it's down, slow, or returns wrong data
- **Alternatives**: is there a fallback, or is this a single point of failure
- **Contract stability**: how often does the API change, is versioning reliable

Dependencies with no fallback and runtime coupling are critical risks. Dependencies owned by teams outside your organization are higher risk than internal ones.

### 3. Failure Mode Analysis

For each component in the architecture, enumerate failure modes:

| Component | Failure Mode | Blast Radius | Detection Time | Recovery Time |
|-----------|-------------|--------------|----------------|---------------|
| API Gateway | Crash | Total outage -- all traffic blocked | <1 min (health check) | 2 min (auto-restart) |
| API Gateway | Slow (>5s latency) | Cascading timeouts upstream | 3-5 min (SLO alert) | 10 min (scale/restart) |
| Payment Service | Wrong data (duplicate charge) | Financial loss, customer trust | Hours-days (reconciliation) | Manual correction |
| Cache Layer | Resource exhaustion (OOM) | Fallback to DB, 10x latency spike | <2 min (memory alert) | 5 min (eviction/restart) |

Blast radius determines severity. Detection time determines whether the risk is insidious. Recovery time determines business impact duration.

### 4. Change Scenario Analysis

Project forward 12-24 months. Identify what changes and where the architecture is brittle:

- **Traffic 10x**: which components break first? Where are the fixed-size pools, single-writer bottlenecks, unbounded queues?
- **New region**: what assumes single-region? Data residency, latency assumptions, DNS configuration?
- **Regulatory change**: what if PII definition expands? What if audit logging must be immutable for 7 years?
- **Team split**: which services have shared ownership? Where is the domain boundary unclear?
- **Vendor exit**: what if the primary cloud provider doubles pricing? Where is lock-in deepest?

Each brittle point is a risk entry. Score it by likelihood of the change and cost of adaptation.

---

## Risk Assessment Matrix

Quantify risks with three dimensions:

| Dimension | 1 | 2 | 3 | 4 | 5 |
|-----------|---|---|---|---|---|
| **Likelihood** | Rare (<5%) | Unlikely (5-20%) | Possible (20-50%) | Likely (50-80%) | Near-certain (>80%) |
| **Impact** | Negligible | Minor degradation | Significant outage | Major business impact | Existential threat |
| **Detectability** | Immediate (<1 min) | Fast (1-15 min) | Moderate (15 min-1 hr) | Slow (1 hr-1 day) | Hidden (days-months) |

**Risk Score = Likelihood x Impact x Detectability**

| Classification | Score Range | Required Action |
|----------------|-------------|-----------------|
| **Critical** | >60 | Immediate mitigation. Architecture change required. Escalate to CTO. |
| **High** | 30-60 | Mitigation plan within current sprint. Track weekly. |
| **Medium** | 10-30 | Mitigation plan within current quarter. Track bi-weekly. |
| **Low** | <10 | Accept and monitor. Review quarterly. |

Detectability is the most underestimated dimension. A risk with L=2, I=3, D=5 (score 30, High) is more dangerous than L=3, I=3, D=1 (score 9, Low) because you won't know it's happening until the damage is done.

---

## Architecture Risk Register Template

### Risk Summary Table

| ID | Risk | L | I | D | Score | Status | Owner |
|----|------|---|---|---|-------|--------|-------|
| R-001 | {short description} | {1-5} | {1-5} | {1-5} | {L*I*D} | {Open/Mitigating/Accepted/Closed} | {name} |
| R-002 | {short description} | {1-5} | {1-5} | {1-5} | {L*I*D} | {Open/Mitigating/Accepted/Closed} | {name} |

### Detailed Risk Entry

```markdown
## R-{NNN}: {Risk Title}

**Score**: L={n} × I={n} × D={n} = {score} ({classification})
**Status**: {Open | Mitigating | Accepted | Closed}
**Owner**: {name} | **Review date**: {YYYY-MM-DD}

### Description
{What is the risk. Be specific -- not "system might fail" but "payment service has no
circuit breaker; a downstream timeout causes thread pool exhaustion in 90 seconds."}

### Root Cause
{Architectural decision or gap that creates this risk.}

### Business Impact
{In business terms: revenue loss per hour, customer churn, compliance penalty,
reputation damage. Quantify where possible.}

### Trigger Conditions
{Observable conditions that indicate the risk is materializing.
Example: "P95 latency exceeds 2s on payment endpoint for >5 minutes."}

### Mitigation Plan
{Specific actions to reduce L, I, or D. Each action has an owner and deadline.}
1. {Action} — {owner} — {deadline}
2. {Action} — {owner} — {deadline}

### Contingency Plan
{What to do if the risk materializes despite mitigation. Runbook-level detail.}

### Linked ADR
{ADR-{NNN} if an architectural decision was made to address or accept this risk.}
```

---

## Risk Communication

The same risk requires different framing for different audiences.

### Engineering Team

Full technical detail. Include trigger conditions, monitoring queries, runbook links, and blast radius. Example: "R-007: The order service shares a connection pool with the reporting pipeline. Under peak reporting load (daily 02:00 UTC batch), available connections for real-time orders drop below 5. If order volume spikes during the batch window, requests queue beyond the 10s timeout. Mitigation: separate connection pools by workload class. Contingency: kill switch on reporting batch via feature flag."

### Engineering Management

Timeline and resource impact. Strip implementation detail, keep the what and the cost. Example: "R-007 (High, score 40): Our order processing shares database resources with reporting. Under specific timing conditions, orders can fail for up to 30 minutes. Fix requires 1 engineer for 3 days to separate connection pools. Without the fix, we risk a customer-facing outage during any reporting spike. Recommend prioritizing in the current sprint."

### Executive / CTO

Business impact in revenue, reputation, and compliance terms. No technical jargon. Example: "We've identified a High-priority risk to order processing reliability. Under certain conditions, customers could be unable to place orders for up to 30 minutes, representing approximately $45K in lost revenue per incident. The engineering fix is scoped at 3 days. We recommend authorizing it this sprint to protect our 99.9% availability commitment."

---

## Risk-Driven Architecture

The risk register drives the architecture roadmap, not the other way around.

1. **Prioritize by score.** Critical and High risks map directly to architecture initiatives in the current or next sprint. Medium risks map to quarterly objectives. Low risks are monitored.
2. **Explicit acceptance.** Every risk classified Medium or above that is not being mitigated requires an ADR documenting the acceptance rationale, the conditions under which the decision will be revisited, and the owner.
3. **New feature assessment.** Before starting any feature that touches architecture (new service, new dependency, data model change, infrastructure migration), assess it against the register. Does it introduce new risks? Does it increase the score of existing risks? Does it mitigate anything?
4. **Quarterly review.** Re-score all open risks. Close mitigated ones. Add newly discovered ones. Adjust the roadmap. Present the top-5 risks to engineering leadership.
5. **Incident linkage.** Every post-incident review checks whether the incident was a materialized risk from the register. If it was, review why mitigation failed. If it wasn't, add it to the register retroactively and investigate why it was missed.

---

## Architectural Debt as Risk

Technical debt is risk with a misleading name. Reframing debt as risk makes it visible to business stakeholders and prioritizable against features.

| Debt Description | Risk Reframe | L | I | D | Score |
|-----------------|--------------|---|---|---|-------|
| Monolithic database | Scaling bottleneck: single DB becomes write throughput ceiling at 2x current load | 3 | 4 | 3 | 36 (High) |
| No circuit breakers | Cascading failure: one slow dependency takes down all services sharing the thread pool | 3 | 5 | 2 | 30 (High) |
| Hardcoded tenant config | Onboarding delay: each new tenant requires code change and deployment | 4 | 3 | 1 | 12 (Medium) |
| No schema versioning on events | Data corruption: producer schema change silently breaks all downstream consumers | 2 | 5 | 5 | 50 (High) |
| Shared test environment | Release delay: teams block each other; flaky integration tests from state leaks | 4 | 2 | 1 | 8 (Low) |

This reframing converts "we should clean this up someday" into "this has a 36-point risk score and belongs on the architecture roadmap." Business stakeholders understand risk; they do not understand debt.

---

## Anti-Patterns

- **Risk theater**: maintaining a register that nobody reads or updates -- creates false confidence and wastes effort; link risks to sprint planning or stop maintaining the register
- **Boiling-the-ocean assessment**: trying to assess every possible risk at once -- start with the top 10 by gut-feel, score them, iterate; completeness is the enemy of usefulness
- **Likelihood-only scoring**: ignoring detectability -- a rare but undetectable risk (L=1, I=5, D=5 = 25) is more dangerous than a frequent but visible one (L=4, I=3, D=1 = 12)
- **Static register**: scoring risks once and never revisiting -- every architectural change, incident, and quarterly review must trigger re-evaluation
- **Confusing risk with uncertainty**: uncertainty means you don't know what will happen; risk means you know what could happen and can estimate probability -- treat uncertainty by gathering information, treat risk by mitigation
- **Gold-plating mitigation**: over-engineering a fix for a Low-score risk while Critical risks remain open -- always mitigate in score order
- **Technical-only framing**: presenting risks in jargon that non-engineers cannot evaluate -- every risk entry must have a business impact statement in plain language

---

## For Claude Code

When assessing architecture: apply all four identification techniques (assumption mapping, dependency analysis, failure mode analysis, change scenario analysis) before declaring the risk landscape understood. Score every identified risk on all three dimensions -- never omit detectability. Generate a risk register in the template format with summary table and detailed entries. Frame every risk with both technical root cause and business impact. When reviewing PRs or architectural proposals, check them against existing risks: does the change introduce new risks, increase existing scores, or mitigate registered risks? When encountering technical debt, reframe it as a scored risk entry. Link every Critical or High risk to either a mitigation initiative or an acceptance ADR. Generate risk communication at all three audience levels when presenting findings. Never generate a risk assessment without actionable mitigation plans for Critical and High items.

---

*Internal references*: `architecture-decision-records/SKILL.md`, `trade-off-analysis/SKILL.md`, `nfr-specification/SKILL.md`, `production-readiness-review/SKILL.md`, `incident-management/SKILL.md`
