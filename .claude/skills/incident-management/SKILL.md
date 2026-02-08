---
name: incident-management
description: "Incident response process from detection to postmortem. Severity levels, communication templates, blameless postmortems, incident metrics. Use when defining on-call processes, responding to production incidents, or conducting postmortems."
---

# Incident Management

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

## Purpose

Structured incident response ensuring fast detection, clear communication, effective resolution, and continuous learning. Incidents are inevitable — unprepared responses are not.

---

## Severity Levels

| Severity | Description | Response Time | Examples |
|----------|-------------|---------------|----------|
| SEV1 — Critical | Service down, data loss, security breach | < 15 min | Production fully unavailable, data corruption, active security breach |
| SEV2 — Major | Significant degradation, key feature broken | < 30 min | Partial outage, payment processing failure, auth service degraded |
| SEV3 — Minor | Non-critical feature broken, workaround exists | < 2 hours | Minor UI bug in production, non-critical integration failure |
| SEV4 — Low | Cosmetic issue, minor inconvenience | Next business day | Typo in UI, minor logging issue, non-user-facing bug |

---

## Incident Response Process

Five phases, each with a clear objective:

- **Detect**: automated alerting (SLO breach), user report, monitoring anomaly. Time to detect = MTTD.
- **Triage**: assign severity, identify incident commander, open communication channel (dedicated Slack channel: `#inc-YYYY-MM-DD-short-description`).
- **Mitigate**: stop the bleeding first. Rollback, feature flag kill switch, scale up, failover. Document every action with timestamp.
- **Resolve**: root cause fix. Deploy fix through normal CI/CD (accelerated review for SEV1-2). Verify fix with monitoring.
- **Postmortem**: within 48 hours for SEV1-2, within 1 week for SEV3. No postmortem needed for SEV4.

---

## On-Call Expectations

Primary + secondary on-call rotation. Response time aligned with severity table. On-call has authority to rollback, disable features, scale infrastructure. Runbooks for every known failure scenario (see `observability/SKILL.md`). Handoff at rotation boundary includes open incidents and recent changes.

---

## Communication Templates

### Status Page Update

```
[Investigating/Identified/Monitoring/Resolved]
Impact: [what users experience]
Current status: [what we know]
Next update: [time]
```

### Internal Slack

```
INCIDENT — SEV[N]: [short description]
Commander: @[name]
Channel: #inc-YYYY-MM-DD-[slug]
Status: [investigating|mitigating|resolved]
Impact: [who/what is affected]
```

---

## Postmortem Format

Blameless — focus on systems, not individuals.

```markdown
# Postmortem: [Incident Title]
Date: YYYY-MM-DD | Severity: SEV[N] | Duration: [X hours]

## Summary
[2-3 sentences: what happened, impact, resolution]

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | Alert fired / user report |
| HH:MM | Incident declared, commander assigned |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Resolved |

## Root Cause
[Technical explanation using 5 Whys]

## Impact
- Users affected: [N]
- Duration: [X hours]
- Revenue impact: [if applicable]

## Action Items
| Action | Owner | Priority | Deadline |
|--------|-------|----------|----------|
| [preventive action] | @[name] | P1 | YYYY-MM-DD |

## Lessons Learned
- What went well
- What went poorly
- Where we got lucky
```

---

## Incident Metrics

- **MTTD** (Mean Time to Detect): time from incident start to alert firing. Target: < 5 min.
- **MTTR** (Mean Time to Resolve): time from detection to resolution. Target: < 1 hour for SEV1.
- **MTBF** (Mean Time Between Failures): time between incidents. Higher is better.

Track monthly, review in team retrospectives.

---

## Anti-Patterns

- **Blame culture**: naming individuals in postmortems kills honesty and learning
- **No postmortem for SEV1-2**: if you don't learn from incidents, you repeat them
- **Hero culture**: relying on one person who "knows the system" instead of runbooks and documentation
- **Alert fatigue**: too many alerts = no alerts. Every alert must be actionable.
- **Skipping severity assignment**: treating every incident as SEV1 wastes resources; treating every incident as SEV4 risks users

---

## For Claude Code

When generating services: include health check endpoints, structured error responses with correlation IDs for incident tracing, runbook templates linked from service README. When generating alerting configuration: include severity-based routing and escalation policies. Generate postmortem template in `docs/incidents/` directory.

---

*Internal references*: `observability/SKILL.md`, `production-readiness-review/SKILL.md`, `release-management/SKILL.md`
