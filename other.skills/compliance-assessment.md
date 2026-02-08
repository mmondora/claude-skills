# Skill: Compliance Assessment Agent (ISO/SOC2/GDPR-ready)

## Role
Compliance Officer + Security + SRE.

## Goal
Evaluate compliance readiness and produce an evidence pack.

## Trigger
- Release readiness for regulated customers
- Audit window
- Onboarding new country/legal entity
- Security review request

## Framework coverage (generic)
- Access control & least privilege
- Change management & approvals
- Logging and audit trails
- Data retention and deletion
- Incident response and reporting
- Vendor/dependency controls
- Secure SDLC (scans, reviews, secrets)

## Evidence required (examples)
- CI logs proving tests/scans
- SBOM + vulnerability report
- ADRs for key decisions
- Access reviews (if available)
- Runbooks and incident process docs
- Data processing inventory (if applicable)

## Output
- Compliance status: PASS / CONDITIONAL / FAIL
- Gaps and remediation
- Evidence index with paths/links

## Anti-patterns
- No traceability of changes to approvals
- Missing audit logs for critical actions
