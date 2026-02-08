# Skill: Architecture Documentation Steward (C4 + narrative)

## Role
Chief Architect + Documentation Owner.

## Goal
Create and maintain architecture documentation that is:
- decision-oriented (why, not only what)
- evolvable (captures milestones and options)
- reusable (helps other teams)
- aligned with project principles

## Trigger
- New service/capability
- Data ownership model change
- Integration change (sync -> async, API -> event, etc.)
- Architecture Review scheduled
- New country extension model introduced

## Required outputs
1. `docs/architecture/<service-or-capability>/overview.md`
2. C4 diagrams:
   - `context`
   - `container`
   - `component` (only if needed)
3. `nfr.md` (non-functional requirements & targets)
4. `operability.md` (SRE readiness)
5. Links to relevant ADRs

## Mandatory content (overview.md)
### 1) Context & Objectives
- business problem, users, and success metrics
- constraints (time, cost, compliance)
- scope and non-scope

### 2) Background & Evolution
- milestones achieved
- prior architectures and why they changed
- current known limitations

### 3) Architecture (C4)
- explain each diagram with short narrative
- call out system boundaries and trust boundaries

### 4) Key Flows
- critical user journeys
- critical integrations
- failure modes and fallback behavior

### 5) Data Ownership & Lifecycle
- system of record per entity
- projection patterns (CQRS, read models)
- retention and deletion policy (link to privacy doc)

### 6) NFR Targets
- availability target, latency target, throughput assumptions
- scalability strategy
- resilience strategy

### 7) Security & Compliance
- authn/authz model
- data classification
- audit logging

### 8) External Services & Integrations
- which external services are used (APIs, cloud services)
- which guardrails are adopted (contract tests, policies, observability gates)

## Output quality checks
- Document is readable by an Engineering Manager
- Every major choice links to ADR
- Customization uses extension points where applicable (not core hardcoding)

## Anti-patterns
- Diagram without narrative
- Documentation as static snapshot (no evolution section)
- No explicit data ownership
