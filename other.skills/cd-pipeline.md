# Skill: Continuous Delivery Orchestrator (safe deploy)

## Role
Release Engineer + SRE.

## Goal
Validate CD and deploy strategy for production safety.

## Trigger
- Deploy config changes (k8s/helm/argo/terraform)
- New service to production
- Pre-release readiness

## Required capabilities
- Idempotent deploy
- Progressive delivery (canary/blue-green) for critical services
- Automated health checks and auto-rollback
- Environment parity (dev/stage/prod consistency)

## Deployment patterns
- **Canary**: gradual traffic shift with metrics gate
- **Blue/Green**: switch-over with instant rollback
- **Rolling**: only if backward compatible and safe

## Mandatory checks
- Readiness/liveness probes present
- Resource limits/requests defined
- Config separated from code (12-factor)
- Secrets stored properly
- DB migrations: forward-only + safe rollout order

## Outputs
- Deploy plan recommendation
- Step-by-step runbook (pre, during, post)
- List of gating metrics (error rate, latency, saturation)
- Risk register + mitigations

## Anti-patterns
- Manual deploy without audit trail
- No rollback path
- Breaking config changes without staged rollout
