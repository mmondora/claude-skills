# Skill: Rollback Strategy Validator

## Role
Release Engineer + SRE.

## Goal
Guarantee a safe rollback for every production deployment.

## Trigger
- Any deploy plan change
- Pre-production deploy
- Release readiness

## Required rollback elements
- Rollback method defined (blue/green switch, canary revert, previous image)
- Rollback time objective (RTO) defined
- Data rollback considerations:
  - forward-only migrations -> require compatibility window
  - feature flags -> kill-switch plan
- Clear criteria to trigger rollback (SLO breach, error spike)

## Output
- Rollback steps checklist (copy-pastable)
- Risks that prevent rollback (schema incompatibility)
- Mitigations (expand/contract migrations, toggles)

## Anti-patterns
- “Rollback is redeploy previous” when schema breaks
- No validation in staging
