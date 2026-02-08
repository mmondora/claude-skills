---
skill: infrastructure-as-code
version: 1.0.0
last-updated: 2026-02-08
domain: cloud-infra
depends-on: [cloud-architecture]
---

# Infrastructure as Code

## Purpose

Rules for managing infrastructure through versioned code. Terraform as multi-cloud default, Pulumi as TypeScript-native alternative. Zero ClickOps.

---

## Principles

**Everything is code**: every cloud resource exists in a versioned configuration file. If it's not in the repo, it doesn't exist. No manual changes from the console — ever.

**Idempotency**: applying the same code N times produces the same result. Terraform and Pulumi guarantee this natively when used correctly.

**State management**: the state file is the source of truth. For Terraform: remote state in GCS bucket with object versioning. For Pulumi: state managed by Pulumi Cloud or GCS backend.

**Modularity**: resources grouped by functional domain (networking, compute, database, monitoring), not by resource type. Modules are reusable across environments with parameterization.

---

## Terraform Conventions

```
infra/
  modules/
    cloud-run-service/
      main.tf
      variables.tf
      outputs.tf
    firestore-database/
    pubsub-topic/
  environments/
    dev/
      main.tf
      terraform.tfvars
      backend.tf
    staging/
    production/
```

**Naming**: resources prefixed `{project}-{env}-{resource}`. Mandatory tags: `environment`, `team`, `cost-center`, `managed-by: terraform`.

**Plan before apply**: `terraform plan` in CI on every PR. `terraform apply` only after approval and merge. Never manual `apply` from local.

**Drift detection**: periodic CI job (weekly) running `terraform plan` and flagging drift. Every drift is an incident to resolve.

---

## Pulumi (TypeScript alternative)

Pulumi lets you write IaC in TypeScript, reusing the same language as your backend. Advantage: types, conditional logic, testing with standard frameworks. Disadvantage: less mature than Terraform, smaller community.

Use Pulumi when the team is full-TypeScript and infrastructure complexity justifies programmatic logic in IaC files.

---

## Secrets in IaC

Never secrets in .tf or .tfvars files. Use GCP Secret Manager referenced from Terraform, or Pulumi Config with encryption. Sensitive values marked `sensitive = true` in Terraform (hidden from plan output).

---

## For Claude Code

When generating IaC: modules per functional domain, parameterized variables per environment, remote state, mandatory tags, outputs for every resource consumed by other modules. Generate a `README.md` per module with: what it does, inputs, outputs, usage example.

---

*Internal references*: `cloud-architecture.md`, `finops.md`, `security.md`
