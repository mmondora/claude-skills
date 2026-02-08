---
name: feature-management
description: "Feature flags, progressive rollout, A/B testing, and kill switches. Flag types, hygiene, implementation patterns. Use when implementing feature toggles, planning gradual rollouts, or adding kill switches for external dependencies."
---

# Feature Management

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

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

### Flag Naming Convention

```
<type>.<domain>.<feature>

Examples:
  release.invoicing.pdf-export
  ops.payments.stripe-integration
  experiment.onboarding.simplified-flow
  permission.reporting.advanced-analytics
```

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
  attributes?: Record<string, string>; // for targeting rules
}
```

### Flag Evaluation with Context

```typescript
class FirestoreFeatureFlagService implements FeatureFlagService {
  async isEnabled(flagName: string, context: FlagContext): Promise<boolean> {
    const flag = await this.getFlagConfig(flagName);
    if (!flag || !flag.enabled) return false;

    // Environment check
    if (flag.environments && !flag.environments.includes(context.environment)) {
      return false;
    }

    // Tenant targeting
    if (flag.allowedTenants?.length) {
      return flag.allowedTenants.includes(context.tenantId);
    }

    // Percentage rollout (deterministic hash for consistency)
    if (flag.rolloutPercentage !== undefined) {
      const hash = this.hashKey(`${flagName}:${context.tenantId}`);
      return (hash % 100) < flag.rolloutPercentage;
    }

    return true;
  }

  private hashKey(key: string): number {
    let hash = 0;
    for (const char of key) hash = ((hash << 5) - hash + char.charCodeAt(0)) | 0;
    return Math.abs(hash);
  }
}
```

### Flag Hygiene

Every flag has: an owner (who decides when to activate/remove), an expected expiration date, a ticket for removal. CI check: warn if a flag exists > 30 days without removal ticket. Dead code behind removed flags is eliminated in the same PR.

---

## Progressive Rollout

For risky features: gradual activation. 1% -> 5% -> 20% -> 50% -> 100%. At each step: monitor key metrics (error rate, latency, conversion rate). If metrics degrade, stop and roll back the flag.

---

## A/B Testing

### Experiment Design

```typescript
interface Experiment {
  name: string;                    // e.g., 'experiment.onboarding.simplified-flow'
  variants: string[];              // e.g., ['control', 'simplified']
  trafficAllocation: number;       // percentage of users in experiment (e.g., 20)
  startDate: string;
  endDate: string;
  primaryMetric: string;           // e.g., 'onboarding_completion_rate'
  minimumSampleSize: number;       // calculated for statistical significance
}
```

### Statistical Significance

Before declaring a winner: minimum sample size per variant (use a sample size calculator — typically 1,000+ per variant for 5% minimum detectable effect at 95% confidence). Run for at least 1 full business cycle (typically 1-2 weeks). Do not peek and stop early on "promising" results — that's p-hacking.

---

## Kill Switch

Every integration with external services has a kill switch. If the external service is down, the kill switch disables the feature and the system degrades gracefully. Automatable: linked to circuit breaker, activates when circuit breaker is OPEN for > N minutes.

---

## Dead Flag Cleanup

Flags that have been 100% rolled out or expired experiments must be removed:

```typescript
// Scheduled cleanup job (runs weekly)
async function detectDeadFlags(): Promise<DeadFlag[]> {
  const flags = await flagStore.getAll();
  const now = new Date();
  return flags.filter(flag => {
    const ageInDays = (now.getTime() - new Date(flag.createdAt).getTime()) / (1000 * 60 * 60 * 24);
    return (
      (flag.type === 'release' && flag.rolloutPercentage === 100 && ageInDays > 14) ||
      (flag.type === 'experiment' && new Date(flag.endDate) < now) ||
      (flag.type === 'release' && ageInDays > 30 && !flag.removalTicket)
    );
  });
}
```

Dead flag alert generates a ticket automatically. Flag and associated code branches are removed in the same PR.

---

## Operational Checklist

- [ ] Flag registered in flag service with owner and expiration
- [ ] Both branches (flag on/off) tested
- [ ] Monitoring includes flag state as metric dimension
- [ ] Rollback plan: disable flag (no deploy needed)
- [ ] Removal ticket created before or at 100% rollout
- [ ] No business logic in flag evaluation (flags toggle features, not implement them)

---

## Anti-Patterns

- **Flag spaghetti**: nested flag checks (`if flagA && !flagB || flagC`) — keep flag evaluation simple, one flag per feature
- **Permanent release flags**: a "temporary" flag that lives for 6 months — enforce expiration with CI checks
- **Testing only the flag-on path**: the flag-off path is the production path until rollout — test both
- **Flag as configuration**: using feature flags for app config (timeouts, limits) — use environment variables or config service
- **No cleanup process**: flags accumulate until nobody knows which are active — automate detection and cleanup

---

## For Claude Code

When implementing features behind flags: use FeatureFlagService interface (not direct provider access), always include the else branch (behavior without flag), generate tests for both branches (flag on/off), comment the expected removal ticket in the code. Follow the naming convention: `<type>.<domain>.<feature>`.

---

*Internal references*: `cicd-pipeline/SKILL.md`, `release-management/SKILL.md`, `observability/SKILL.md`
