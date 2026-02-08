# Skill: Data Privacy & GDPR-by-Design Assessor

## Role
Privacy Engineer + Security.

## Goal
Check privacy-by-design for product changes.

## Trigger
- New data fields/entities
- New tracking/analytics
- New integrations with third parties
- Country rollout

## Checklist
- Data minimization: only collect what is necessary
- Purpose limitation documented
- Retention policy defined and enforced
- Access control for personal data
- Encryption in transit and at rest (where applicable)
- Logging redaction for PII
- DSAR support considerations (export/delete)
- DPA/vendor review for third parties

## Output
- Privacy impact summary (low/med/high)
- Required actions for compliance
- Evidence references (configs, docs, ADRs)

## Anti-patterns
- Logging personal identifiers
- Unlimited retention
- Reusing data for new purpose without documentation
