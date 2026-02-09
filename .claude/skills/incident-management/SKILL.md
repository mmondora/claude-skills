---
name: incident-management
description: "Incident response process from detection to postmortem. Severity levels, communication templates, blameless postmortems, incident metrics. Use when defining on-call processes, responding to production incidents, or conducting postmortems."
---

# Incident Management

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

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

### Incident Commander Responsibilities

The incident commander (IC) is assigned during triage. IC responsibilities: own the incident until resolution, coordinate responders (don't fix — coordinate), manage communication cadence (status updates every 30min for SEV1, every 1hr for SEV2), make escalation decisions, ensure all actions are documented with timestamps.

IC does NOT need to be the most senior engineer. IC needs to be calm, organized, and available. Rotate IC duty to build the skill across the team.

### Incident Classification

| Type | Examples | Special Handling |
|------|----------|-----------------|
| **Availability** | Service down, degraded performance | Standard incident process |
| **Security** | Data breach, unauthorized access, credential leak | Involve security team immediately, preserve evidence, consider legal notification obligations |
| **Data** | Data corruption, data loss, wrong data served | Stop writes immediately, assess blast radius, involve DBA |

Security incidents have additional requirements: preserve logs and evidence (do not delete), assess notification obligations (GDPR: 72hr to DPA), involve legal if PII is exposed.

---

## On-Call Expectations

### Rotation & Tooling

Primary + secondary on-call rotation. Response time aligned with severity table. Tools: PagerDuty or Opsgenie for alerting, Slack for coordination, runbooks in repo.

**On-call compensation**: on-call is work. Compensate with time-off-in-lieu, monetary compensation, or both. Document policy. Engineers who aren't compensated for on-call will deprioritize it.

### Authority

On-call has authority to: rollback deployments, disable features via kill switches, scale infrastructure, declare incidents and assign severity. No approval needed for mitigation actions during active incidents.

### Runbooks

Runbooks for every known failure scenario (see `observability/SKILL.md`). Written for someone at 3 AM who doesn't know the service deeply. Copy-pasteable commands, clear escalation triggers.

### Handoff Template

```markdown
## On-Call Handoff — [Date]
### Open Incidents: [list or "none"]
### Recent Changes: [deploys in last 48h]
### Known Issues: [flaky alerts, degraded dependencies]
### Upcoming Risks: [scheduled migrations, expected traffic spikes]
### Notes: [anything the next person should know]
```

Handoff at rotation boundary is mandatory, not optional.

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

- **MTTA** (Mean Time to Acknowledge): time from alert to first human response. Target: < 5 min for SEV1. Measures on-call responsiveness.

---

## War Room Protocol

For SEV1 incidents lasting > 30 minutes:

1. IC opens a video/voice bridge (permanent war room link)
2. All relevant responders join — no spectators (IC controls admission)
3. IC runs 5-minute check-ins: "What have we tried? What's next? What's blocking?"
4. Dedicated scribe documents timeline in real-time
5. IC communicates outward (stakeholders, status page) — responders focus on fixing

---

## Game Days & Chaos Engineering

Proactive incident preparedness:

**Game days** (quarterly): simulate a realistic incident scenario. Team practices the full incident process (detect → triage → mitigate → resolve → postmortem). Evaluate: did runbooks work? Were on-call contacts reachable? Did alerting fire correctly?

**Chaos engineering lite**: controlled failure injection in staging. Start simple: kill a pod, add latency to a dependency, exhaust connection pool. Graduate to production chaos only with circuit breakers and kill switches in place.

| Experiment | What it Tests | Prerequisites |
|-----------|--------------|---------------|
| Kill service instance | Auto-restart, health checks | Redundancy, health probes |
| Add 5s latency to DB | Timeouts, circuit breakers | Timeout configuration |
| Revoke service account | IAM dependency, error handling | Fallback behavior |
| Fill disk to 90% | Alerting, log rotation | Monitoring, disk alerts |

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
