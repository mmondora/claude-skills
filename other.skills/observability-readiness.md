# Skill: Observability Readiness Check (SRE baseline)

## Role
SRE lead.

## Goal
Ensure production changes are observable and operable.

## Trigger
- New service
- Significant behavioral change
- Pre-production deploy
- Release readiness

## Mandatory signals
### Logs
- Structured logs (JSON)
- Correlation/trace IDs propagated
- No sensitive data in logs

### Metrics
- RED/USE metrics as applicable
- Business KPIs (if relevant)
- SLO indicators: latency, error rate, saturation

### Traces
- Distributed tracing enabled for critical paths
- Sampling configured

## Operational readiness
- Dashboards exist and linked
- Alerts exist for SLO breaches
- Runbook exists (first response steps)
- Ownership defined (team + escalation)

## Output
- PASS/FAIL
- Missing dashboards/alerts/runbook links
- Suggested SLOs and alert thresholds

## Anti-patterns
- “We’ll add monitoring later”
- Alerts without runbooks
- Logging PII
