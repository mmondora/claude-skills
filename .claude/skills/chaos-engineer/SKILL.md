---
name: chaos-engineer
cluster: delivery-release
description: "Chaos engineering for resilience validation. Experiment design, blast radius control, failure injection, game days, continuous chaos in CI/CD. Use when designing chaos experiments, validating resilience assumptions, conducting game days, or integrating failure injection into pipelines."
---

# Chaos Engineer

> **Version**: 1.3.0 | **Last updated**: 2026-02-14

## Purpose

Systems fail in production — chaos engineering proves they recover. Without controlled failure injection, teams discover their resilience gaps during real incidents instead of planned experiments. Chaos engineering shifts failure discovery left, from incident response to proactive validation.

---

## Experiment Design

The scientific method applied to resilience. Every experiment requires: a **falsifiable hypothesis** ("the system continues serving \<SLO\> when \<failure\>"), **steady-state definition** with numeric thresholds, **blast radius boundary**, and **abort conditions** that trigger automatic rollback.

```yaml
# chaos-experiment.yaml
experiment:
  name: payment-service-latency
  hypothesis: "Order service degrades gracefully when payment service latency exceeds 2s"
  steady_state:
    metric: order_success_rate
    threshold: ">= 99.5%"
  method:
    type: network-delay
    target: payment-service
    delay_ms: 3000
    duration: 5m
  blast_radius:
    environment: staging
    traffic_percentage: 10
  abort_conditions:
    - metric: error_rate
      threshold: "> 5%"
    - metric: p99_latency
      threshold: "> 10s"
  rollback:
    type: automatic
    trigger: any_abort_condition
```

**Workflow**: map architecture and dependencies, identify weakest assumptions, write hypothesis, define steady state, set blast radius, execute with monitoring, analyze results, implement fixes, repeat.

---

## Failure Injection Patterns

| Failure Type | Tool | Target | What It Validates |
|---|---|---|---|
| Pod kill | Litmus/Chaos Mesh | Kubernetes pods | Self-healing, replica recovery |
| Network delay | tc/toxiproxy | Service links | Timeout handling, circuit breakers |
| CPU stress | stress-ng | Node/container | Autoscaling, throttling behavior |
| DNS failure | CoreDNS manipulation | Service discovery | Fallback, caching, retries |
| Zone outage | Cloud provider API | Availability zone | Multi-AZ redundancy |
| Disk fill | dd/fallocate | Node filesystem | Alerting, log rotation, eviction |
| Dependency kill | Process termination | External services | Graceful degradation, fallbacks |

Choose injection method based on the resilience property under test. Start with the simplest failure that validates the hypothesis — escalate complexity only after simpler experiments pass.

---

## Game Days

Structured team exercises that validate both **technical resilience** and **human response**.

**Planning checklist**:
1. Define scope — which systems, which failure scenarios, which teams participate
2. Establish success criteria — SLOs that must hold, maximum response time for human actions
3. Pre-brief all participants — share experiment plan, communication channels, escalation paths
4. Verify monitoring and alerting — dashboards, on-call routing, war room setup
5. Confirm rollback mechanisms — automated and manual, tested before game day
6. Schedule during business hours — never Friday afternoon; ensure key personnel availability

**Execution protocol**: announce start to all stakeholders, inject failures per plan, observe system and human response, record timeline of events and decisions, abort if any safety boundary is crossed, announce end clearly.

**Post-game retrospective**: timeline reconstruction, gap analysis (what surprised us?), action items with owners and deadlines, update runbooks and monitoring based on findings, share results organization-wide.

---

## Continuous Chaos in CI/CD

Embed chaos experiments in the delivery pipeline for ongoing resilience validation. Run against staging on schedule; gate production deploys on chaos test results.

```yaml
# .github/workflows/chaos.yml
name: Chaos Tests
on:
  schedule:
    - cron: '0 3 * * 1-5'  # Weekdays 3am
jobs:
  chaos:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Apply chaos experiment
        run: |
          kubectl apply -f chaos-experiments/
          sleep 300  # 5min experiment duration
      - name: Validate steady state
        run: |
          RATE=$(curl -s "$PROMETHEUS/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])" | jq '.data.result[0].value[1]')
          if (( $(echo "$RATE > 0.01" | bc -l) )); then
            echo "FAIL: Error rate $RATE exceeds 1% during chaos"
            exit 1
          fi
      - name: Cleanup
        if: always()
        run: kubectl delete -f chaos-experiments/
```

**Integration points**: scheduled runs for regression, pre-deploy gates for critical services, post-deploy smoke chaos for canary validation.

---

## Maturity Model

| Level | Name | Characteristics |
|---|---|---|
| 1 | Ad-hoc | Manual failure injection during incidents; no formal experiments; heroic debugging |
| 2 | Repeatable | Documented experiment specs; game days quarterly; staging-only; manual execution |
| 3 | Automated | Chaos in CI/CD; automated steady-state validation; blast radius controls enforced |
| 4 | Continuous | Production chaos with fine-grained controls; chaos results feed architecture decisions; experiments run daily |

Target level 3 minimum for production systems. Level 4 requires mature observability and incident management processes.

---

## Anti-Patterns

| Anti-Pattern | Why It Fails |
|---|---|
| **Chaos without hypothesis** | Random failure injection without expected outcome is sabotage, not science; every experiment needs a falsifiable hypothesis |
| **Production chaos without safety nets** | Running experiments without abort conditions, rollback, or monitoring turns chaos into an incident |
| **Testing only happy paths** | Injecting failures the system already handles proves nothing; target gaps you suspect but haven't validated |
| **Skipping blast radius control** | Starting with 100% traffic or production-wide experiments; always start staging, then 1% canary, then expand |
| **Ignoring the human factor** | Testing only technical resilience while ignoring runbook quality, team response time, and communication during failure |
| **One-time game days** | Chaos engineering is continuous, not annual; embed experiments in CI/CD for ongoing validation |

---

## For Claude Code

When designing chaos experiments: always define a falsifiable hypothesis before implementation, specify steady-state metrics with numeric thresholds, and include automatic abort conditions. Generate Litmus ChaosEngine manifests for Kubernetes targets, toxiproxy configurations for network chaos. Include blast radius controls (environment isolation, traffic percentage limits). Generate GitHub Actions workflows for scheduled chaos runs with steady-state validation gates. Never generate chaos experiments without rollback procedures. Reference `incident-management/SKILL.md` for post-experiment learning process, `observability/SKILL.md` for monitoring during experiments, `quality-gates/SKILL.md` for CI integration.

---

*Internal references*: `incident-management/SKILL.md`, `observability/SKILL.md`, `quality-gates/SKILL.md`, `error-handling-resilience/SKILL.md`
