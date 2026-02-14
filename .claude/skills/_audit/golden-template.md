# Golden Template for Claude Skills

> Derived from top-scoring skills: **observability** (1.3.0), **api-design** (1.2.0), **data-modeling** (1.2.0).

This template captures the canonical structure, tone, and density that makes a skill score 9-10.

---

## What Makes a Top Skill

1. **Dense operational tone** — every sentence is an instruction or a constraint, not a description. "Use X" not "X can be used."
2. **TypeScript code examples** — real, runnable snippets with comments explaining the WHY, not the WHAT.
3. **Decision tables** — when multiple options exist, a markdown table with columns for criteria, not prose paragraphs.
4. **Specific numbers** — "timeout: 5000ms", "max 3 retries", "cache TTL 300s" — never "use an appropriate timeout."
5. **WHY before HOW** — every section opens with 1-2 sentences explaining the architectural reason before listing rules.
6. **Anti-Patterns with consequences** — not just "don't do X" but "don't do X — causes Y (data loss, cascading failure, etc.)."
7. **For Claude Code paragraph** — a single dense paragraph of imperatives that Claude can follow without ambiguity.

---

## Template

````markdown
---
name: <skill-name-kebab-case>
cluster: <cluster-name>
description: "<1-3 sentences. What the skill covers. Key topics listed. When to use it — include trigger phrases that tell Claude when to load this skill.>"
---

# <Skill Title — Title Case, No Abbreviations>

> **Version**: X.Y.Z | **Last updated**: YYYY-MM-DD

## Purpose

<2-4 sentences. State the architectural property this skill serves. Explain WHY this skill exists — what goes wrong without it. Name the failure mode it prevents.>

---

## <Core Section 1: Foundational Concept>

<1-2 sentence WHY opener explaining the architectural reason this matters.>

### Rules

1. **Rule name** — concrete instruction with specific values. Example: "Set structured log level to `info` in production, `debug` in development. Never use `trace` in production — log volume exceeds 10x and triggers cost alerts."
2. **Rule name** — another concrete instruction.
3. **Rule name** — another concrete instruction.

### Decision Matrix

Use a table when the skill involves choosing between options:

| Criterion | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| Use when  | <specific scenario> | <specific scenario> | <specific scenario> |
| Latency   | <number>ms | <number>ms | <number>ms |
| Trade-off | <concrete trade-off> | <concrete trade-off> | <concrete trade-off> |

### Code Example

```typescript
/**
 * Demonstrates the core pattern.
 * WHY: <1 sentence explaining the architectural reason for this pattern>
 */
import { z } from 'zod';

// Schema-first: validation shared between API boundary and persistence
const ExampleSchema = z.object({
  id: z.string().uuid(),
  tenantId: z.string().uuid(),          // Multi-tenant by default
  name: z.string().min(1).max(255),
  createdAt: z.coerce.date(),
});

type Example = z.infer<typeof ExampleSchema>;

/**
 * Creates a new example entity with tenant isolation.
 * @param input - Validated input (Zod-parsed at route boundary)
 * @param tenantId - Extracted from auth context, never from request body
 * @returns Created entity with generated ID
 * @throws {ConflictError} If entity with same name exists in tenant
 */
export async function createExample(
  input: Omit<Example, 'id' | 'createdAt'>,
  tenantId: string,
): Promise<Example> {
  // tenantId comes from auth context, not user input — prevents tenant crossing
  const entity: Example = {
    ...input,
    id: crypto.randomUUID(),             // UUID v7 preferred for sortability
    tenantId,
    createdAt: new Date(),
  };

  // Repository handles the actual persistence
  return exampleRepository.insert(entity);
}
```

---

## <Core Section 2: Operational Patterns>

<1-2 sentence WHY opener.>

### Rules

1. **Rule name** — instruction with specific thresholds.
2. **Rule name** — instruction referencing related skills.

### Code Example

```typescript
/**
 * Demonstrates operational pattern.
 * WHY: <architectural reason>
 */

// Example: structured error with correlation ID
export class DomainError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly correlationId: string,
    public readonly metadata?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'DomainError';
  }

  /** RFC 7807 problem detail for API responses */
  toProblemDetail(): ProblemDetail {
    return {
      type: `https://api.example.com/errors/${this.code}`,
      title: this.message,
      status: this.httpStatus(),
      instance: `/errors/${this.correlationId}`,
    };
  }
}
```

---

## <Core Section 3: Advanced / Edge Cases>

<WHY opener — when does the team encounter this, and what goes wrong without guidance.>

### Rules

1. **Rule name** — instruction.
2. **Rule name** — instruction.

### Configuration Example

```yaml
# Example: deployment or infrastructure configuration
# WHY: <reason this configuration exists>
service:
  replicas: 3                    # Minimum for HA — never 1 in production
  resources:
    requests:
      cpu: "250m"                # Based on p95 load testing, not guessing
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"             # 2x request — allows burst without OOM
  healthCheck:
    path: /healthz
    intervalSeconds: 10
    timeoutSeconds: 3            # Fail fast — 3s not 30s
    failureThreshold: 3
```

---

## Anti-Patterns

- **<Name>** — <consequence>. Example: "**Catch-and-ignore** — swallowing errors silently causes silent data corruption; failures surface hours later in unrelated systems."
- **<Name>** — <consequence>. Example: "**God service** — single service handling 5+ bounded contexts; deploys take 45+ minutes, any change risks regression across all domains."
- **<Name>** — <consequence>.
- **<Name>** — <consequence>.
- **<Name>** — <consequence>.
- **<Name>** — <consequence>. (minimum 5, maximum 10)

---

## For Claude Code

When generating <domain> code: always <do A>, never <do B>, always <do C>. <Specific instruction about schema/validation.> <Specific instruction about error handling.> <Specific instruction about testing.> <Specific instruction about multi-tenancy.> Reference <related-skill/SKILL.md> for <topic> and <other-skill/SKILL.md> for <other-topic>. Every generated file must include <specific requirement>. If the task involves <specific scenario>, apply <specific pattern> from this skill.

---

*Internal references*: `related-skill-a/SKILL.md`, `related-skill-b/SKILL.md`, `related-skill-c/SKILL.md`
````

---

## Checklist for Skill Authors

Use this checklist when creating or upgrading a skill:

| # | Requirement | Score Impact |
|---|-------------|-------------|
| 1 | Frontmatter with name, cluster, description (with trigger phrases) | Required for loading |
| 2 | Version line in `> **Version**: X.Y.Z` format | Required for tracking |
| 3 | Purpose section (2-4 sentences, names the failure mode) | +1 |
| 4 | At least 2 core concept sections with rules | +1 |
| 5 | At least 1 TypeScript code example (runnable, with JSDoc) | +1 |
| 6 | Decision table where applicable | +0.5 |
| 7 | Anti-Patterns section (5-10 items, bold name + consequence) | +1 |
| 8 | For Claude Code section (single dense imperative paragraph) | +1 |
| 9 | Internal references line (2-4 related skills) | +0.5 |
| 10 | Specific numbers, not vague guidance ("5000ms" not "appropriate") | +1 |
| 11 | WHY sentence before every HOW block | +1 |
| 12 | Multi-tenant awareness where applicable | +0.5 |

**Score targets**:
- 6-7: Stub — functional but lacks density. Acceptable for niche skills.
- 8: Good — minor gaps. Acceptable for production use.
- 9: Excellent — full structure, dense content. Target for all core skills.
- 10: Exceptional — stands alone as complete reference. Reserved for best-in-class.

---

## Tone Guide

**Do write**:
> Set connection pool size to `max(10, vCPU * 2)`. Monitor `pg_stat_activity` — if `idle` connections exceed 50% of pool, reduce max. Log pool exhaustion events at `warn` level with queue depth.

**Do not write**:
> Consider setting an appropriate connection pool size based on your workload. It's important to monitor database connections and adjust as needed.

The first version is actionable. The second is filler. Every sentence in a skill must pass the test: "Can Claude follow this instruction without asking a clarifying question?" If not, rewrite it.
