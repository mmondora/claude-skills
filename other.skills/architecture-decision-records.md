# Skill: Architecture Decision Records (ADR) Manager

## Role
Architecture Governor + facilitator.

## Goal
Capture architectural decisions before they become irreversible constraints.

## Trigger
- Introducing new technology/tooling with long-term impact
- Changing integration pattern (API vs events)
- Changing data ownership or shared schema
- Making trade-offs affecting NFRs (availability, cost, latency, compliance)

## ADR format (strict)
File: `adr/NNNN-title-slug.md`

### Header
- Title
- Status: Proposed | Accepted | Deprecated | Superseded
- Date (YYYY-MM-DD)
- Owners (names/teams)
- Related links (docs, issues, PRs)

### Body
1. Context
2. Decision
3. Drivers (why now)
4. Options considered
   - Option A (pros/cons)
   - Option B ...
5. Decision rationale
6. Consequences
   - positive
   - negative
   - follow-ups
7. Guardrails
   - tests required
   - observability required
   - security gates required
8. Migration plan (if any)
9. How to rollback / revert (if applicable)

## Governance rules
- One decision per ADR
- ADR required BEFORE implementation for high-impact changes
- If decision is already implemented, mark as “late ADR” and explain why

## Outputs
- ADR draft ready to commit
- Suggested reviewers (Architects, Security, Ops, Compliance)
- Follow-up tasks list (tickets)

## Anti-patterns
- ADR as mere summary after the fact
- No alternatives considered
- No consequences section
