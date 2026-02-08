---
name: finops
description: "Cloud cost management as an architectural discipline. Unit economics, right-sizing, GCP free tier optimization, budget alerts, serverless-first. Use when making infrastructure decisions, estimating costs, or optimizing cloud spending."
---

# FinOps

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

## Purpose

Cloud cost management as an architectural discipline. Every technical choice has a cost — make it explicit, measurable, and governable.

---

## FinOps Principles

**Cost-aware architecture**: cost is an architectural attribute like performance and security. It must be measured, monitored, and continuously optimized.

**Optimize for unit economics**: the cost that matters is cost per user, per transaction, per tenant — not total cost. If total cost grows but unit cost drops, you're scaling well.

**Right-size, don't over-provision**: size resources for actual load, not "potential" load. Scaling up is easier than scaling down (nobody wants to reduce resources "just in case").

---

## GCP Free Tier & Pay-per-Use

Maximize free tier usage for development and personal projects. For production, prefer pay-per-use models (Cloud Run, Cloud Functions, Firestore) over always-on models (VMs, fixed GKE node pools).

GCP resources with generous free tier: Firestore (1GB storage, 50K reads/day, 20K writes/day), Cloud Run (2M requests/month, 360K GB-seconds), Cloud Functions (2M invocations/month), Cloud Storage (5GB), Pub/Sub (10GB/month).

Caution: free tier limits change. Always verify the official GCP pricing page.

---

## Cost Monitoring

**Budget alerts**: configure budgets in GCP Billing with alerts at 50%, 80%, 100% of monthly budget. Notifications via email and Pub/Sub (for automation).

**Cost allocation**: mandatory labels on every resource (`project`, `team`, `environment`, `feature`). Cost dashboard per team and per feature. Monthly cost review per team.

**Anomaly detection**: alert for cost spikes > 20% vs 7-day trailing average.

---

## Savings Patterns

**Scale to zero**: Cloud Run with min-instances = 0 for non-prod environments. Accept cold starts in dev/staging.

**Preemptible/Spot instances**: for batch workloads, CI/CD, tests. Up to 80% savings. Not for stateful production.

**Committed Use Discounts**: for predictable resources (always-on Cloud SQL in production). Only after 3+ months of stable consumption data.

**Lifecycle policies**: automatically delete logs > 30 days, container artifacts > 90 days, snapshots > 60 days.

**Serverless-first**: prefer Cloud Run over GKE, Cloud Functions over VMs, Firestore over Cloud SQL, when the workload permits. Pay-per-use scales better economically.

---

## FinOps in ADRs

Every ADR with infrastructure impact must include a "Cost Impact" section with: estimated monthly cost per environment (dev, staging, prod), cost at scale with expected load, cost comparison between evaluated alternatives, trigger for review (e.g., "if exceeds €500/month, reconsider alternative X").

---

## Cost Modeling

Calculate cost-per-request for serverless workloads:

```
Cloud Run cost per request =
  (CPU allocation × CPU price per vCPU-second × avg request duration) +
  (Memory allocation × memory price per GiB-second × avg request duration) +
  (request charge per million × 1/1,000,000)
```

**Example** (Cloud Run, europe-west1, 2026 pricing estimates):
- 1 vCPU, 512 MiB, avg 200ms per request
- CPU: 1 × $0.000024/s × 0.2s = $0.0000048
- Memory: 0.5 × $0.0000025/s × 0.2s = $0.00000025
- Per-request: ~$0.0000051
- 1M requests/month: ~$5.10

### Unit Economics Table

| Scale | Requests/month | Cloud Run cost | Firestore cost (est.) | Total | Cost per user |
|-------|---------------|----------------|----------------------|-------|---------------|
| Startup | 100K | ~$0.51 | Free tier | ~$1 | $0.01 |
| Growth | 1M | ~$5.10 | ~$5 | ~$10 | $0.01 |
| Scale | 10M | ~$51 | ~$50 | ~$100 | $0.01 |
| Enterprise | 100M | ~$510 | ~$500 | ~$1,000 | $0.01 |

*Estimates — always verify with GCP Pricing Calculator for current rates.*

---

## Right-Sizing Methodology

Review resource utilization monthly. Action thresholds:

| Metric | Under-utilized | Right-sized | Over-provisioned |
|--------|---------------|-------------|------------------|
| CPU avg | < 10% | 20-60% | > 80% sustained |
| Memory avg | < 20% | 30-70% | > 85% sustained |
| Action | Downsize | Monitor | Upsize or investigate |

Process: pull 30-day utilization metrics → identify resources below threshold → create right-sizing ticket → resize in non-prod first → validate → resize in prod.

---

## Budget Alerts (Terraform)

```hcl
resource "google_billing_budget" "project_budget" {
  billing_account = var.billing_account_id
  display_name    = "${var.project}-monthly-budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = var.monthly_budget_eur
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.8
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    monitoring_notification_channels = var.notification_channels
    enable_project_level_recipients  = true
  }
}
```

---

## Monthly Cost Review Checklist

- [ ] Compare actual vs budget — flag variance > 10%
- [ ] Review top 5 cost items — any unexpected growth?
- [ ] Check for idle resources (unattached disks, stopped VMs, unused IPs)
- [ ] Verify non-prod environments scale to zero outside business hours
- [ ] Review Committed Use Discount utilization (if applicable)
- [ ] Update unit economics with actual numbers
- [ ] Flag any new resources created without cost-center label

---

## Anti-Patterns

- **"We'll optimize later"**: cost grows exponentially if not managed from day one
- **No cost allocation labels**: if you can't attribute cost, you can't optimize it
- **Over-provisioning "for safety"**: size for measured load + 30% buffer, not 10x "just in case"
- **Ignoring free tier limits**: free tier changes — set alerts at 80% of free tier limit
- **No unit economics**: total cost without per-user/per-request context is meaningless

---

## For Claude Code

When generating infra: prefer serverless/pay-per-use, include cost allocation labels, suggest scale-to-zero for non-prod, and in every ADR estimate monthly cost. Do not suggest always-on resources without explicit justification.

---

*Internal references*: `infrastructure-as-code/SKILL.md`, `architecture-decision-records/SKILL.md`, `observability/SKILL.md`
