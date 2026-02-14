---
name: trade-off-analysis
cluster: functional-architecture
description: "Systematic trade-off analysis for architectural decisions. Structured evaluation method, weighted scoring, reversibility assessment, cost-of-change estimation. Use when evaluating architectural alternatives, making technology choices, or documenting decision rationale."
---

# Trade-Off Analysis

> **Version**: 1.0.0 | **Last updated**: 2026-02-14

## Purpose

Architecture IS trade-offs. Every decision favors some quality attributes over others, enables some future changes while constraining others. This skill provides a systematic method for making trade-offs explicit, comparable, and recordable. "The architect's value is not in knowing the answer -- it's in knowing the trade-offs."

---

## Trade-Off Analysis Method

Six steps. No shortcuts.

**Step 1 -- Frame the decision.** State the decision as a question. Define scope, constraints, and non-negotiable requirements. Identify stakeholders affected. Example: "How should tenant data be isolated in the invoicing service?"

**Step 2 -- Enumerate options.** Minimum three options. Always include "do nothing" (accept current state) and "defer" (delay decision, gather more data). If you only have two real options, you haven't explored enough.

**Step 3 -- Define evaluation criteria.** Select 4-7 quality attributes or concerns relevant to this decision. Assign weights (must sum to 1.0). Criteria come from NFRs, business priorities, and technical constraints. Common: performance, cost, complexity, time-to-market, reversibility, security posture, operational burden.

**Step 4 -- Evaluate.** Score each option against each criterion on a 1-5 scale (1=poor, 3=acceptable, 5=excellent). Scores must have a one-line justification -- no naked numbers. Multiply by weight to get weighted scores.

**Step 5 -- Analyze tensions.** Identify criteria where top options diverge significantly (score difference >= 2). These are the real trade-offs. Name them explicitly: "We are trading operational simplicity for cost efficiency."

**Step 6 -- Recommend.** State the recommended option, the rationale, what is explicitly sacrificed, reversibility classification, and conditions that would trigger re-evaluation.

---

## Trade-Off Matrix Template

```markdown
# Trade-Off Analysis: [Decision Title]

## Context
[2-3 sentences: what triggered this analysis, constraints, timeline]

## Options

| ID | Option | Description |
|----|--------|-------------|
| A  | [Name] | [One-line description] |
| B  | [Name] | [One-line description] |
| C  | Do nothing | [What happens if we don't act] |

## Evaluation Criteria

| Criterion | Weight | Rationale for weight |
|-----------|--------|---------------------|
| [e.g., Latency] | 0.25 | [Why this matters most/least] |
| [e.g., Cost] | 0.20 | ... |
| [e.g., Complexity] | 0.20 | ... |
| [e.g., Reversibility] | 0.15 | ... |
| [e.g., Security] | 0.20 | ... |
| **Total** | **1.00** | |

## Evaluation Matrix

| Criterion (weight) | Option A | Option B | Option C |
|---------------------|----------|----------|----------|
| Latency (0.25) | 4 — sub-10ms reads | 2 — network hop adds ~50ms | 3 — current baseline |
| Cost (0.20) | 2 — dedicated infra | 4 — shared, pay-per-use | 5 — zero additional cost |
| Complexity (0.20) | 3 — moderate migration | 4 — drop-in replacement | 5 — no change |
| Reversibility (0.15) | 2 — schema migration | 4 — adapter swap | 5 — N/A |
| Security (0.20) | 5 — full isolation | 3 — shared boundary | 3 — unchanged risk |
| **Weighted total** | **3.25** | **3.30** | **4.00** |

## Tension Analysis
- **Latency vs Cost**: Option A wins on latency but costs 3x more than B
- **Security vs Complexity**: Full isolation (A) requires dedicated infra management
- [Identify all criteria with score delta >= 2 between top options]

## Recommendation

| Field | Value |
|-------|-------|
| **Recommended** | Option [X] |
| **Rationale** | [2-3 sentences] |
| **What we sacrifice** | [Explicit: "We accept higher latency in exchange for..."] |
| **Reversibility** | Type [1/2/3] — [effort to reverse] |
| **Review trigger** | [Condition that reopens this decision] |
```

---

## Reversibility Assessment

Not all decisions carry equal weight. Classify before investing analysis effort.

| Type | Characteristics | Examples | Required rigor |
|------|----------------|----------|----------------|
| **Type 1 — Irreversible** | Costly to reverse, months of migration, data loss risk | Database technology, programming language, tenant isolation model, event schema as public contract | Full 6-step analysis, ADR, review meeting |
| **Type 2 — Reversible** | Swap within days/weeks, adapter boundary exists | Caching strategy, pagination approach, HTTP client library, logging provider | Lightweight analysis (steps 1-2-6), document in ADR |
| **Type 3 — Trivial** | Swap in hours, no downstream impact | Utility library, internal naming convention, log format | No formal analysis, decide and move |

### Decision Investment Matrix

| | Low blast radius | High blast radius |
|---|---|---|
| **Irreversible** | Type 2 treatment — lightweight analysis | Type 1 treatment — full analysis + review |
| **Reversible** | Type 3 treatment — just decide | Type 2 treatment — lightweight analysis |

Blast radius = number of services, teams, or contracts affected by a change.

---

## Cost-of-Change Estimation

For each option in a Type 1 or Type 2 analysis, estimate four cost dimensions:

| Dimension | What to estimate | Unit |
|-----------|-----------------|------|
| **Migration effort** | Engineering time to implement, test, deploy | Person-weeks |
| **Blast radius** | Services, teams, contracts, data stores affected | Count + list |
| **Organizational cost** | Training, documentation, hiring, process changes | Qualitative (low/medium/high) |
| **Technical debt created** | Workarounds, adapters, compatibility layers needed | Count of known compromises |

Include cost of reversal: if this decision proves wrong in 12 months, what does unwinding look like? If the reversal cost exceeds the original migration, flag it as a Type 1 decision regardless of initial classification.

---

## Common Architectural Trade-Off Patterns

| Trade-off | Favoring A gives you | Favoring B gives you | Key question |
|-----------|---------------------|---------------------|--------------|
| **Consistency vs Availability** | Correct reads, simpler reasoning | Higher uptime, partition tolerance | Can the business tolerate stale reads? |
| **Buy vs Build** | Faster time-to-market, vendor support | Full control, no license cost | Is this a differentiator or commodity? |
| **Monolith vs Microservices** | Simpler ops, faster iteration, lower latency | Independent deployment, team autonomy | Do you have >1 team and >1 deploy cadence? |
| **Shared vs Dedicated tenancy** | Lower cost, simpler ops | Stronger isolation, per-tenant SLAs | What's the compliance and noisy-neighbor risk? |
| **Sync vs Async** | Simpler flow, immediate feedback | Decoupling, resilience, throughput | Does the caller need the result immediately? |
| **SQL vs NoSQL** | ACID, joins, mature tooling | Schema flexibility, horizontal scale | Is the access pattern known and relational? |
| **Thin vs Thick platform** | Team autonomy, speed | Consistency, governance, reuse | How many teams and how diverse are their needs? |
| **Build vs Configure** | Exact fit, no vendor lock-in | Speed, proven patterns, lower maintenance | Is the budget for ongoing maintenance realistic? |
| **REST vs gRPC vs Events** | Ubiquity (REST), performance (gRPC), decoupling (events) | Varies by axis | What coupling level between producer and consumer? |
| **Single-region vs Multi-region** | Lower cost, simpler ops | Lower latency globally, disaster recovery | What's the RTO/RPO and user geography? |
| **Optimistic vs Pessimistic locking** | Higher throughput, no lock contention | No conflict resolution, simpler reasoning | What's the conflict probability? |
| **Edge vs Origin compute** | Lower latency, reduced origin load | Simpler deployment, full runtime access | Is the logic cacheable and stateless? |

---

## Cognitive Biases in Architectural Decisions

| Bias | How it manifests | Mitigation |
|------|-----------------|------------|
| **Familiarity bias** | Choosing PostgreSQL because "we've always used it" without evaluating fit for the workload | Require minimum 3 options; assign one team member to champion an unfamiliar option |
| **Sunk cost fallacy** | Refusing to migrate away from a failing technology because of prior investment | Evaluate options on future cost only; prior investment is irrelevant to the decision |
| **Anchoring** | First option proposed dominates the discussion regardless of merit | Present all options simultaneously; use blind scoring before group discussion |
| **Confirmation bias** | Seeking evidence that supports the preferred option while dismissing contradictory signals | Assign a designated "red team" reviewer to argue against the leading option |
| **Complexity bias** | Choosing the sophisticated solution (microservices, event sourcing, CQRS) when the simpler one suffices | Apply YAGNI: score "do nothing" and "simplest option" first; complex option must outscore by >15% weighted |
| **Authority bias** | Deferring to the most senior person's preference without rigorous evaluation | Scores are submitted independently before discussion; seniority does not override weighted criteria |

---

## Anti-Patterns

- **Analysis paralysis on Type 3 decisions**: spending a week evaluating utility libraries wastes more than a bad choice would cost -- classify reversibility first, then invest proportionally
- **Binary thinking**: framing decisions as A-vs-B ignores "do nothing", "defer", and hybrid options -- always enumerate at least three alternatives
- **Unweighted criteria**: listing pros and cons without weights makes every criterion implicitly equal, which is almost never true -- assign explicit weights reflecting business priorities
- **Gut-feel recommendation**: arriving at a weighted score favoring Option B but recommending Option A because "it feels right" -- if the model disagrees with intuition, fix the model's criteria or fix the intuition
- **Missing sacrifice acknowledgment**: recommending an option without stating what is given up creates false confidence -- every recommendation explicitly names what is sacrificed
- **Stale trade-off analysis**: a decision made under different constraints (team size, traffic, budget) may no longer hold -- include review triggers and re-evaluate when triggers fire
- **Ignoring organizational cost**: evaluating only technical merit while ignoring training, hiring, and process changes underestimates total cost of adoption

---

## For Claude Code

When evaluating architectural alternatives: apply the 6-step method, always include "do nothing" and "defer" as options, define weighted criteria before scoring, and produce a complete trade-off matrix. Classify every decision by reversibility type before investing analysis effort -- Type 3 decisions get a one-line rationale, Type 1 decisions get the full template. Score all options independently before comparing. Name tensions explicitly where top options diverge by >= 2 points on any criterion. Every recommendation must state what is sacrificed and under what conditions the decision should be revisited. When generating ADRs, embed the trade-off matrix in Section 4 (Options Considered). Flag cognitive biases when detected in the framing: if only two options are presented, demand a third; if the "familiar" option is pre-selected, challenge it.

---

*Internal references*: `architecture-decision-records/SKILL.md`, `nfr-specification/SKILL.md`, `architecture-risk-assessment/SKILL.md`, `architecture-review-facilitation/SKILL.md`
