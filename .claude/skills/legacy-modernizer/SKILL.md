---
name: legacy-modernizer
cluster: architecture-patterns
description: "Incremental migration strategies for legacy systems. Strangler fig pattern, branch by abstraction, characterization testing, zero-downtime migration. Use when modernizing legacy codebases, decomposing monoliths, upgrading frameworks, or reducing technical debt."
---

# Legacy Modernizer

> **Version**: 1.3.0 | **Last updated**: 2026-02-14

## Purpose

Legacy modernization is a discipline of incremental, risk-managed transformation — not a one-time heroic rewrite. Without structured migration strategies, teams attempt big-bang rewrites that statistically fail 70%+ of the time, destroying months of effort and destabilizing production. This skill provides proven patterns (strangler fig, branch by abstraction, expand/contract) that deliver continuous value while progressively replacing legacy components. The goal is zero-downtime migration with rollback capability at every step.

---

## Strangler Fig Pattern

The primary strategy for replacing legacy systems. A facade/proxy intercepts all traffic and incrementally routes requests to new implementations while legacy handles the rest. Migration is a routing decision, not a deployment event.

```typescript
// Strangler fig facade — routes requests to legacy or new service
import express from 'express';
import httpProxy from 'http-proxy';

const app = express();
const proxy = httpProxy.createProxyServer();

const NEW_SERVICE_URL = process.env.NEW_SERVICE_URL!;
const LEGACY_URL = process.env.LEGACY_URL!;

const MIGRATED_ROUTES = new Set(['/api/v1/invoices', '/api/v1/users']);

app.use(async (req, res, next) => {
  if (MIGRATED_ROUTES.has(req.path)) {
    // Forward to new service
    const response = await fetch(`${NEW_SERVICE_URL}${req.path}`, {
      method: req.method,
      headers: req.headers as Record<string, string>,
      body: ['GET', 'HEAD'].includes(req.method) ? undefined : req.body,
    });
    res.status(response.status).json(await response.json());
  } else {
    // Forward to legacy system
    proxy.web(req, res, { target: LEGACY_URL });
  }
});
```

Key rules: the facade owns routing logic, feature flags control which routes are migrated, and both systems run simultaneously until cutover is complete.

---

## Branch by Abstraction

For replacing internal components without affecting callers. Introduce an abstraction layer, implement the new version behind it, switch traffic via feature flag, then remove the old implementation.

```typescript
// Step 1: Define abstraction
interface NotificationSender {
  send(userId: string, message: string): Promise<void>;
}

// Step 2: Wrap legacy behind abstraction
class LegacyEmailSender implements NotificationSender {
  async send(userId: string, message: string): Promise<void> {
    await legacySmtpClient.sendEmail(userId, message);
  }
}

// Step 3: Build new implementation behind same abstraction
class ModernNotificationSender implements NotificationSender {
  async send(userId: string, message: string): Promise<void> {
    await pubSubClient.publish('notifications', { userId, message });
  }
}

// Step 4: Feature flag controls which implementation is active
function getNotificationSender(): NotificationSender {
  return featureFlags.isEnabled('modern-notifications')
    ? new ModernNotificationSender()
    : new LegacyEmailSender();
}
```

---

## Characterization Testing

Before modifying any legacy code, capture its actual behavior as a test suite. These tests document what the system *does*, not what it *should* do — they are your safety net against unintended behavioral changes.

```typescript
// Golden master / characterization test pattern
import { describe, it, expect } from 'vitest';
import { legacyPricingEngine } from '../legacy/pricing-engine';

// Captured from production — these ARE the spec
const goldenMasterCases = [
  { input: { sku: 'WIDGET-A', qty: 1, region: 'US' }, expected: 29.99 },
  { input: { sku: 'WIDGET-A', qty: 10, region: 'US' }, expected: 269.91 },
  { input: { sku: 'WIDGET-A', qty: 1, region: 'EU' }, expected: 34.99 },
  { input: { sku: 'WIDGET-B', qty: 5, region: 'US' }, expected: 74.95 },
];

describe('Legacy pricing engine — characterization tests', () => {
  it.each(goldenMasterCases)(
    'calculates price for $input.sku qty=$input.qty region=$input.region',
    ({ input, expected }) => {
      const result = legacyPricingEngine.calculate(input.sku, input.qty, input.region);
      expect(result).toBeCloseTo(expected, 2);
    },
  );
});
```

Generate characterization tests by replaying production logs or by exercising the legacy system with known inputs and recording outputs. Coverage target: 80%+ of actively-used code paths before any refactoring begins.

---

## Migration Decision Framework

| Strategy | When to Use | Risk | Duration | Rollback |
|---|---|---|---|---|
| **Strangler fig** | Replacing an entire system or service | Low | Weeks–months | Route back to legacy |
| **Branch by abstraction** | Replacing internal component | Low | Days–weeks | Toggle feature flag |
| **Parallel run** | High-risk domain (finance, billing) | Medium | Weeks | Compare outputs, use legacy as source of truth |
| **Expand/contract** | Database schema changes | Low | Days–weeks | Contract phase is reversible |
| **Big bang** | **Never** — only acceptable for trivial systems with <1K LOC | Extreme | N/A | None |

Select the strategy with the lowest blast radius. Combine strategies when migrating complex systems (e.g., strangler fig for services + expand/contract for database).

---

## Database Migration: Expand/Contract

Zero-downtime schema changes require two phases. **Expand**: add new columns/tables, dual-write to old and new, backfill historical data. **Contract**: after all consumers read from new schema, drop old columns/tables.

```sql
-- EXPAND PHASE: add new column, keep old column
ALTER TABLE customers ADD COLUMN full_name TEXT;

-- Backfill from legacy columns
UPDATE customers SET full_name = first_name || ' ' || last_name
  WHERE full_name IS NULL;

-- Application dual-writes to both old and new columns during transition

-- CONTRACT PHASE (weeks later, after all readers migrated):
ALTER TABLE customers DROP COLUMN first_name;
ALTER TABLE customers DROP COLUMN last_name;
```

Rules: never rename or drop columns in a single migration. Each migration must be backward-compatible with the previous application version. Test rollback of every migration before applying to production.

---

## Anti-Patterns

- **Big-bang rewrite** — 70%+ of large rewrites fail; incremental migration with continuous delivery is the only proven path at scale
- **Migrating without characterization tests** — changing behavior you don't understand guarantees regressions that surface in production weeks later
- **Shared database between old and new** — creates tight coupling that prevents independent deployment; use database-per-service with a synchronization layer
- **Removing legacy before new is proven** — premature decommission eliminates rollback; keep legacy running until new handles 100% of traffic for 2+ weeks with stable error rates
- **Migrating everything at once** — tackle the highest-value, lowest-risk modules first; build team confidence and organizational trust incrementally
- **Ignoring data migration** — code migration without data migration leaves the system half-transformed and operationally fragile
- **No rollback plan per step** — every migration step must have a documented, tested rollback procedure; if you cannot roll back, you cannot safely roll forward

---

## For Claude Code

When modernizing legacy systems: always use strangler fig pattern with a facade/proxy layer, never attempt big-bang rewrites. Generate characterization tests capturing existing behavior before any refactoring. Use feature flags for incremental traffic shifting between legacy and new implementations. Apply expand/contract pattern for database schema changes — never break backward compatibility mid-migration. Include rollback procedures for every migration step. Generate migration decision records as ADRs. Structure migration code by feature/domain, not by technical layer. When decomposing monoliths, identify bounded contexts first, extract the least-coupled module, and validate with parallel-run comparison before cutting over. Reference `testing-strategy/SKILL.md` for characterization test patterns and `feature-management/SKILL.md` for progressive rollout.

---

*Internal references*: `event-driven-architecture/SKILL.md`, `data-modeling/SKILL.md`, `testing-strategy/SKILL.md`, `feature-management/SKILL.md`
