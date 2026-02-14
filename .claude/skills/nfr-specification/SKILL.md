---
name: nfr-specification
cluster: functional-architecture
description: "Non-functional requirements specification using ISO 25010 quality model. Quality attribute scenarios (SEI method), NFR elicitation, prioritization, and validation. Use when specifying quality attributes, eliciting NFRs from stakeholders, or mapping NFRs to architectural decisions."
---

# Non-Functional Requirements Specification

> **Version**: 1.0.0 | **Last updated**: 2026-02-14

## Purpose

NFRs are architectural constraints that shape every technical decision — they ARE the architecture. A system without explicit NFRs is a system where quality was decided by accident. This skill provides a systematic method for eliciting, documenting, prioritizing, and validating NFRs using ISO 25010 as the quality model and the SEI Quality Attribute Workshop as the scenario method. NFRs bridge the gap between business goals ("99.9% uptime") and technical realization ("multi-region active-active with <500ms failover").

---

## ISO 25010 Quality Model — Operationalized

| Characteristic | Definition | Sub-characteristics | Measurable Indicators | Typical Tensions |
|---|---|---|---|---|
| **Functional Suitability** | Degree to which functions cover stated/implied needs | Completeness, correctness, appropriateness | Feature coverage %, defect density, task completion rate | vs. Maintainability (feature sprawl increases complexity) |
| **Performance Efficiency** | Performance relative to resources used | Time behavior, resource utilization, capacity | p95/p99 latency, throughput (req/s), CPU/memory per request | vs. Security (encryption adds latency), vs. Portability (abstraction layers add overhead) |
| **Compatibility** | Ability to coexist and exchange information | Co-existence, interoperability | Integration success rate, data format conformance, protocol compliance | vs. Security (open interfaces increase attack surface) |
| **Usability** | Effectiveness, efficiency, satisfaction of use | Learnability, operability, error protection, accessibility | Task completion time, error rate, SUS score, WCAG conformance level | vs. Security (MFA friction), vs. Performance (rich UI increases payload) |
| **Reliability** | System performs under stated conditions for stated period | Maturity, availability, fault tolerance, recoverability | MTBF, uptime %, RTO, RPO, error budget burn rate | vs. Performance (redundancy adds latency), vs. Cost (replication is expensive) |
| **Security** | Protection of information and data | Confidentiality, integrity, non-repudiation, accountability, authenticity | Vulnerability count, mean time to patch, auth failure rate, audit coverage | vs. Usability (security friction), vs. Performance (crypto overhead) |
| **Maintainability** | Effectiveness of modification | Modularity, reusability, analysability, modifiability, testability | Cyclomatic complexity, test coverage, deployment frequency, change failure rate | vs. Performance (abstraction overhead), vs. Time-to-market (clean code takes longer) |
| **Portability** | Transferability between environments | Adaptability, installability, replaceability | Environment migration time, platform-specific code %, container compatibility | vs. Performance (abstraction cost), vs. Cost (multi-platform testing) |

Every NFR maps to at least one characteristic. If it doesn't, it's not an NFR — it's a wish.

---

## Quality Attribute Scenarios

The SEI Quality Attribute Workshop defines a testable scenario structure. Every NFR MUST be expressed as a scenario with all six parts — if any part is missing, the NFR is not testable.

| Part | Question | Example |
|------|----------|---------|
| **Source** | Who/what triggers it? | End user, external system, attacker, operator, time |
| **Stimulus** | What happens? | Request, failure, attack, configuration change, load spike |
| **Artifact** | What is affected? | API endpoint, database, service, UI component |
| **Environment** | Under what conditions? | Normal operation, peak load, degraded mode, during deployment |
| **Response** | What should happen? | Process request, log event, failover, reject, degrade |
| **Response Measure** | How to verify? | Latency < Xms, availability > X%, recovery < Xs |

### Example Scenarios

**Performance**: A user (source) submits a search query (stimulus) to the search API (artifact) during peak hours with 10x normal load (environment). The system returns results (response) within 500ms at p95 (response measure).

**Reliability**: A primary database node (source) crashes unexpectedly (stimulus) while the order service (artifact) is processing transactions under normal load (environment). The system fails over to the replica and resumes processing (response) within 30 seconds with zero data loss (response measure).

**Security**: An unauthenticated external actor (source) attempts to access tenant data via API enumeration (stimulus) against the multi-tenant API gateway (artifact) in production (environment). The system rejects the request, logs the attempt with source IP, and triggers a rate limit (response) within 50ms with zero data exposure (response measure).

**Maintainability**: A developer (source) needs to add a new payment provider (stimulus) to the payment service (artifact) during normal development (environment). The change requires modification of only the payment adapter module with no changes to business logic (response), completing in under 2 developer-days with existing tests passing (response measure).

### Transformation: Vague to Testable

| Vague Requirement | Problem | Testable Scenario |
|---|---|---|
| "System must be fast" | No source, no measure, no environment | "Under 1000 concurrent users, API responses complete in <200ms at p99" |
| "System must be secure" | No stimulus, no artifact, no measure | "Penetration test produces zero critical/high findings against OWASP Top 10" |
| "System must be reliable" | No environment, no response measure | "Single AZ failure causes <30s disruption, zero data loss, automatic recovery" |
| "System must scale" | No stimulus bounds, no measure | "System handles 10x baseline load (50k req/s) with <10% latency degradation" |

---

## NFR Elicitation Method

### 1. Scenario-Based Elicitation

Walk stakeholders through concrete failure and success scenarios. "What happens when the database goes down during Black Friday?" extracts more precise NFRs than "What are your availability requirements?" Use the ISO 25010 table as a checklist — systematically ask about each characteristic.

### 2. Quantification Forcing

Reject any NFR without a number. "High availability" becomes "99.95% measured monthly." "Fast response" becomes "p95 < 300ms." If the stakeholder cannot quantify, propose a number and let them push back. The negotiation itself reveals the true requirement.

### 3. Priority Trade-off Workshop

Present NFR pairs in tension and force a choice: "If you can only have one — lower latency or higher availability — which do you choose?" Document the ranked result. Use pairwise comparison across all quality attributes to build a priority stack. This prevents the "everything is P0" trap.

### 4. Operational Context Mapping

Map NFRs to operational realities: deployment frequency, team size, on-call rotation, compliance regime, budget constraints. An NFR of "zero downtime deployments" means nothing if the team deploys once a quarter. Context determines which NFRs are actually load-bearing.

---

## NFR Prioritization Matrix

Score each NFR on four dimensions (1-5 scale). Multiply by weight. Rank by total.

| NFR ID | NFR Description | Business Impact (w=0.4) | Impl. Cost (w=0.2) | Risk if Unmet (w=0.3) | Dependencies (w=0.1) | Weighted Score |
|--------|----------------|------------------------|--------------------|-----------------------|----------------------|----------------|
| NFR-001 | {{description}} | {{1-5}} | {{1-5, inverted: 5=low cost}} | {{1-5}} | {{1-5, inverted: 5=no deps}} | {{computed}} |
| NFR-002 | {{description}} | {{1-5}} | {{1-5}} | {{1-5}} | {{1-5}} | {{computed}} |

**Scoring guide**: Business Impact — 5 = revenue/compliance critical, 1 = nice-to-have. Implementation Cost — 5 = trivial, 1 = requires fundamental rearchitecture (inverted so high score = easy). Risk if Unmet — 5 = system failure or regulatory breach, 1 = minor UX degradation. Dependencies — 5 = standalone, 1 = blocked by 3+ other NFRs.

**Weighted score** = (BI × 0.4) + (IC × 0.2) + (RU × 0.3) + (D × 0.1). NFRs scoring above 3.5 are mandatory for MVP. Between 2.5-3.5: include if budget allows. Below 2.5: defer.

---

## NFR Specification Document Template

```markdown
# NFR Specification: {{Project/Service Name}}

## Context

- **System**: {{system name and brief description}}
- **Stakeholders**: {{list of stakeholders consulted}}
- **Elicitation date**: {{date}}
- **Compliance regime**: {{GDPR, SOC2, HIPAA, none, etc.}}
- **Operational constraints**: {{team size, deployment frequency, budget}}

## Quality Attribute Scenarios

### {{NFR-ID}}: {{Short Title}}

- **Quality attribute**: {{ISO 25010 characteristic}}
- **Priority**: {{P0/P1/P2/P3}}
- **Source**: {{who/what triggers}}
- **Stimulus**: {{what happens}}
- **Artifact**: {{what is affected}}
- **Environment**: {{under what conditions}}
- **Response**: {{expected behavior}}
- **Response measure**: {{quantified acceptance criterion}}
- **Validation method**: {{load test / chaos test / pen test / code review / fitness function}}

(Repeat for each NFR)

## Priority Matrix

| NFR ID | Description | BI (0.4) | IC (0.2) | RU (0.3) | D (0.1) | Score |
|--------|-------------|----------|----------|----------|---------|-------|
| {{id}} | {{desc}}    | {{n}}    | {{n}}    | {{n}}    | {{n}}   | {{s}} |

## Trade-off Decisions

| Decision | Favored Attribute | Sacrificed Attribute | Rationale |
|----------|-------------------|----------------------|-----------|
| {{decision}} | {{attr}} | {{attr}} | {{why}} |

## Validation Strategy

| NFR ID | Validation Method | Tool/Technique | Frequency | Owner |
|--------|-------------------|----------------|-----------|-------|
| {{id}} | {{method}} | {{tool}} | {{freq}} | {{team}} |

## NFR-to-Architecture Mapping

| NFR ID | Architectural Decision | ADR Reference | Fitness Function |
|--------|----------------------|---------------|------------------|
| {{id}} | {{decision}} | {{ADR-NNN}} | {{automated check}} |
```

---

## NFR to Architecture Mapping

Every NFR must trace to at least one architectural decision, recorded as an ADR, validated by an automated fitness function. The chain: **NFR → Architectural Decision → ADR → Fitness Function**.

**Example 1 — Performance**: NFR "p95 latency < 200ms at 5000 req/s" → Decision: use Redis read-through cache for product catalog → ADR-017 → Fitness function: k6 load test in CI asserting p95 < 200ms at 5000 concurrent users.

**Example 2 — Reliability**: NFR "RTO < 60s, RPO = 0 for order data" → Decision: multi-AZ PostgreSQL with synchronous replication and automated failover → ADR-023 → Fitness function: chaos test killing primary DB node, asserting service recovery < 60s and zero lost transactions.

**Example 3 — Maintainability**: NFR "New payment provider integration < 3 developer-days" → Decision: hexagonal architecture with port/adapter pattern for payment gateways → ADR-031 → Fitness function: cyclomatic complexity of payment adapter module stays below threshold, adapter interface coverage > 95%.

If an NFR has no corresponding ADR, it is aspirational. If an ADR has no fitness function, it is unverified. Both states are risks.

---

## Team Topologies Impact

NFR choices directly constrain team structure via Conway's Law. A reliability NFR requiring 99.99% uptime implies an on-call rotation, which implies team size >= 5 (sustainable rotation). A performance NFR requiring sub-10ms latency eliminates microservice decomposition across a network boundary for that path, forcing a single team to own the hot path. A portability NFR requiring multi-cloud support demands a platform team providing cloud-agnostic abstractions. Always validate NFRs against available team capacity — an NFR the organization cannot staff for is an NFR it cannot meet.

---

## Anti-Patterns

- **"Everything is P0"**: when all NFRs are critical, none are — forces trade-off avoidance and guarantees none will be met well
- **Unmeasurable NFRs**: "the system shall be user-friendly" cannot be tested, cannot be validated, and will be interpreted differently by every stakeholder
- **NFRs without ownership**: an NFR assigned to "the team" is owned by nobody — each NFR needs a named team and validation method
- **Copy-paste NFRs**: reusing NFRs from a previous project without adapting to current context produces irrelevant constraints and misses actual risks
- **Late NFR discovery**: discovering a "must support 100k concurrent users" requirement during load testing means the architecture was shaped without its most critical constraint
- **NFR-architecture gap**: documenting NFRs in a requirements doc that architects never read — NFRs must flow directly into ADRs and fitness functions
- **Gold-plating**: specifying 99.999% availability for an internal reporting tool that runs once daily wastes budget that could fund reliability where it matters

---

## For Claude Code

When specifying NFRs: always use the six-part SEI quality attribute scenario format (source, stimulus, artifact, environment, response, response measure) — reject vague statements like "must be fast" or "must be secure." Map every NFR to an ISO 25010 quality characteristic. Generate the prioritization matrix with weighted scoring for any set of NFRs. Produce the full NFR specification document using the template with all placeholders filled. Trace each NFR to an architectural decision and propose a fitness function for automated validation. When reviewing existing NFRs, flag unmeasurable requirements, missing trade-off documentation, and NFRs without validation strategies. Always ask stakeholders to quantify — propose a number if they cannot.

---

*Internal references*: `architecture-decision-records/SKILL.md`, `fitness-functions/SKILL.md`, `trade-off-analysis/SKILL.md`, `observability/SKILL.md`, `performance-testing/SKILL.md`, `production-readiness-review/SKILL.md`
