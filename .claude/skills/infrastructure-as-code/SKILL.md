---
name: infrastructure-as-code
cluster: cloud-infrastructure
description: "Infrastructure as Code with Terraform and Pulumi. State management, modularity, drift detection, secrets handling. Use when provisioning cloud resources, writing Terraform/Pulumi modules, or managing infrastructure configuration."
---

# Infrastructure as Code

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

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

### Terraform Module Example — GCP Cloud Run Service

```hcl
# modules/cloud-run-service/main.tf
resource "google_cloud_run_v2_service" "service" {
  name     = "${var.project}-${var.environment}-${var.service_name}"
  location = var.region

  template {
    containers {
      image = var.image
      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }
      env {
        name  = "NODE_ENV"
        value = var.environment
      }
      startup_probe {
        http_get { path = "/health" }
      }
      liveness_probe {
        http_get { path = "/health" }
      }
    }
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    service_account = var.service_account_email
  }

  labels = {
    environment  = var.environment
    team         = var.team
    cost-center  = var.cost_center
    managed-by   = "terraform"
  }
}
```

### Backend Configuration Example

```hcl
# environments/production/backend.tf
terraform {
  backend "gcs" {
    bucket = "myproject-terraform-state"
    prefix = "production"
  }
}
```

State locking note: GCS backend provides automatic state locking via object generation. Enable object versioning on the bucket for state recovery.

---

## Pulumi (TypeScript alternative)

Pulumi lets you write IaC in TypeScript, reusing the same language as your backend. Advantage: types, conditional logic, testing with standard frameworks. Disadvantage: less mature than Terraform, smaller community.

Use Pulumi when the team is full-TypeScript and infrastructure complexity justifies programmatic logic in IaC files.

```typescript
import * as gcp from '@pulumi/gcp';

const service = new gcp.cloudrunv2.Service('api-service', {
  location: 'europe-west1',
  template: {
    containers: [{
      image: pulumi.interpolate`${registry}/${imageName}:${imageTag}`,
      resources: { limits: { cpu: '1', memory: '512Mi' } },
    }],
    scaling: { minInstanceCount: 0, maxInstanceCount: 10 },
  },
  labels: { environment: stack, team: 'backend', 'managed-by': 'pulumi' },
});

export const serviceUrl = service.uri;
```

---

## Secrets in IaC

Never secrets in .tf or .tfvars files. Use GCP Secret Manager referenced from Terraform, or Pulumi Config with encryption. Sensitive values marked `sensitive = true` in Terraform (hidden from plan output).

### Secret Manager with Terraform

```hcl
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project}-${var.environment}-db-password"
  replication { auto {} }
  labels = { environment = var.environment, managed-by = "terraform" }
}

# Reference in Cloud Run
resource "google_cloud_run_v2_service" "api" {
  # ...
  template {
    containers {
      env {
        name = "DATABASE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }
  }
}
```

---

## Policy-as-Code

Validate infrastructure compliance before apply:

**Checkov**: scans Terraform for security misconfigurations (public buckets, missing encryption, overly permissive IAM).

**OPA (Open Policy Agent)**: custom policies for organizational rules.

```yaml
# In CI — run Checkov on Terraform
- name: Checkov IaC scan
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: infra/
    framework: terraform
    soft_fail: false  # Block PR on failure
```

### Provider Version Constraints

Always pin provider versions to avoid breaking changes:

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20"  # Allow patch updates only
    }
  }
}
```

### Importing Existing Resources

For resources created manually (ClickOps debt):

```bash
# Import existing resource into Terraform state
terraform import google_cloud_run_v2_service.api projects/my-project/locations/europe-west1/services/my-api

# Then write the matching HCL and run plan to verify
terraform plan  # Should show "No changes"
```

Document every import in a ticket. Goal: zero un-managed resources.

### Remote State References

Access outputs from other Terraform state files:

```hcl
data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "myproject-terraform-state"
    prefix = "networking"
  }
}

# Use outputs from networking state
resource "google_cloud_run_v2_service" "api" {
  # ...
  template {
    vpc_access {
      connector = data.terraform_remote_state.networking.outputs.vpc_connector_id
    }
  }
}
```

---

## Pre-Apply Checklist

- [ ] `terraform plan` reviewed — no unexpected destroys or replacements
- [ ] Sensitive values marked `sensitive = true`
- [ ] All resources have mandatory tags (environment, team, cost-center, managed-by)
- [ ] Module outputs defined for all values consumed by other modules
- [ ] State backend configured with versioning and locking
- [ ] No hardcoded values — all environment-specific values in `.tfvars`
- [ ] Drift detection CI job scheduled (weekly minimum)

---

## Anti-Patterns

- **ClickOps**: creating resources manually in the console defeats IaC's purpose — if it's not in code, it doesn't exist
- **Manual state edits**: `terraform state mv/rm` is an emergency tool, not a workflow — restructure modules instead
- **Hardcoded values in modules**: modules must be parameterized — environment-specific values belong in `.tfvars`
- **Monolithic state**: one state file for the entire infrastructure — split by domain (networking, compute, database)
- **No plan review**: applying without reviewing the plan is deploying blind
- **Ignoring drift**: drift detected and not resolved grows until it becomes a production incident

---

## For Claude Code

When generating IaC: modules per functional domain, parameterized variables per environment, remote state, mandatory tags, outputs for every resource consumed by other modules. Generate a `README.md` per module with: what it does, inputs, outputs, usage example.

---

*Internal references*: `finops/SKILL.md`, `security-by-design/SKILL.md`, `containerization/SKILL.md`
