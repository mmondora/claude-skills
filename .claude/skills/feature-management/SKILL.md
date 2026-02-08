---
name: feature-management
description: "Feature flags, progressive rollout, A/B testing, and kill switches. Flag types, hygiene, implementation patterns. Use when implementing feature toggles, planning gradual rollouts, or adding kill switches for external dependencies."
---

# Feature Management

## Purpose

Feature flags, progressive rollout, A/B testing, and kill switches as architectural tools for safe releases and controlled experimentation.

---

## Feature Flags

A feature flag is a runtime toggle controlling whether a feature is active. Decouples deployment from release: code is in production but the feature is off until you decide to activate it.

### Flag Types

**Release flag**: activates/deactivates a feature during rollout. Temporary — must be removed within 2 sprints of full release. If a flag is active for > 30 days, it's tech debt.

**Ops flag**: kill switch to rapidly disable a feature in case of problems. Permanent. Every feature with external dependencies (third-party APIs, fragile services) should have one.

**Experiment flag**: A/B testing. Activates for a percentage of users/tenants. Temporary — experiment has a defined duration.

**Permission flag**: feature available only to certain tenants (premium plan, beta testers). Semi-permanent — becomes part of licensing model.

### Implementation

Centralized flag service. Options: Firebase Remote Config (free, Firebase-integrated), GCP-based custom (Firestore document with per-tenant flags), or dedicated services (LaunchDarkly, Unleash self-hosted).

```typescript
interface FeatureFlagService {
  isEnabled(flagName: string, context: FlagContext): Promise<boolean>;
  getVariant(flagName: string, context: FlagContext): Promise<string>;
}
interface FlagContext {
  tenantId: string;
  userId?: string;
  environment: string;
}
```

### Flag Hygiene

Every flag has: an owner (who decides when to activate/remove), an expected expiration date, a ticket for removal. CI check: warn if a flag exists > 30 days without removal ticket. Dead code behind removed flags is eliminated in the same PR.

---

## Progressive Rollout

For risky features: gradual activation. 1% → 5% → 20% → 50% → 100%. At each step: monitor key metrics (error rate, latency, conversion rate). If metrics degrade, stop and roll back the flag.

---

## Kill Switch

Every integration with external services has a kill switch. If the external service is down, the kill switch disables the feature and the system degrades gracefully. Automatable: linked to circuit breaker, activates when circuit breaker is OPEN for > N minutes.

---

## For Claude Code

When implementing features behind flags: use FeatureFlagService interface (not direct provider access), always include the else branch (behavior without flag), generate tests for both branches (flag on/off), comment the expected removal ticket in the code.

---

*Internal references*: `cicd-pipeline.md`, `release-management.md`, `backend-patterns.md`
