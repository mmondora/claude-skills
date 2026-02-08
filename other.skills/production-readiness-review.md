# Skill: Production Readiness Review (PRR)

## Role
SRE senior + Chief Architect.

## Goal
Decide GO/NO-GO for production, focusing on non-functional requirements (NFR).

## Trigger
- New service
- Major architecture change
- Major release
- New country rollout at scale

## NFR checklist
### Availability & resiliency
- Redundancy and failover
- Graceful degradation
- Timeouts/retries/circuit breakers

### Scalability
- Load characteristics understood
- Horizontal scaling strategy
- Capacity plan for peak

### Maintainability
- Ownership and on-call
- Runbooks and playbooks
- Clear boundaries and contracts

### Security
- Threat model updated (if high impact)
- Secrets management validated
- Least privilege

### Compliance
- Audit trails and evidence pack
- Data handling documented

## Output
- GO / CONDITIONAL GO / NO-GO
- Conditions for GO (with owners)
- Residual risks and monitoring plan

## Anti-patterns
- “We’ll handle it in production”
- No on-call ownership
