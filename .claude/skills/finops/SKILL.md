---
name: finops
description: "Cloud cost management as an architectural discipline. Unit economics, right-sizing, GCP free tier optimization, budget alerts, serverless-first. Use when making infrastructure decisions, estimating costs, or optimizing cloud spending."
---

# FinOps

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

## For Claude Code

When generating infra: prefer serverless/pay-per-use, include cost allocation labels, suggest scale-to-zero for non-prod, and in every ADR estimate monthly cost. Do not suggest always-on resources without explicit justification.

---

*Internal references*: `cloud-architecture.md`, `adr.md`, `iac.md`
