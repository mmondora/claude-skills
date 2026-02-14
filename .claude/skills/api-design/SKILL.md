---
name: api-design
cluster: architecture-patterns
description: "API design conventions for REST and GraphQL. Resource naming, versioning, pagination, error responses (RFC 7807), OpenAPI-first workflow, backward compatibility. Use when designing APIs, writing endpoint handlers, or defining API contracts."
---

# API Design

> **Version**: 1.3.0 | **Last updated**: 2026-02-14

## Purpose

API design as a contract discipline. APIs are the public surface of your system — they must be consistent, predictable, and evolvable. A well-designed API serves both humans and machines, enabling independent evolution of clients and servers.

---

## REST Conventions

**Resource naming**: plural nouns, kebab-case. Resources are nouns, not verbs. Example: `/api/v1/user-accounts/{id}`, `/api/v1/user-accounts/{id}/invoices`.

**HTTP verbs**:

| Verb | Purpose | Idempotent | Response |
|------|---------|------------|----------|
| GET | Read resource(s) | Yes | 200 with body |
| POST | Create resource | No | 201 with Location header |
| PUT | Full replace | Yes | 200 or 204 |
| PATCH | Partial update | No | 200 with updated resource |
| DELETE | Remove resource | Yes | 204 No Content |

**Status codes**:

| Code | Meaning | When to use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Malformed syntax, invalid JSON |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but insufficient permissions |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | State conflict (duplicate, version mismatch) |
| 422 | Unprocessable Entity | Valid syntax but failed validation |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unhandled server error |

---

## Versioning Strategy

URL-based versioning as default: `/api/v1/resources`. Header-based (`Accept: application/vnd.api.v2+json`) only for internal APIs when justified in an ADR.

Rules: MAJOR version in URL path. Minor and patch changes must be backward-compatible. Deprecation requires minimum 6-month notice for public APIs. Never remove a version without migration path.

---

## Request/Response Design

**Collections envelope**: every collection endpoint returns a consistent envelope.

**Pagination**: cursor-based as default (better performance at scale). Offset-based acceptable for small datasets or admin UIs.

**Filtering**: query parameters with clear naming: `?status=active&createdAfter=2026-01-01`. **Sorting**: `?sort=createdAt:desc`.

```typescript
const PaginationMeta = z.object({
  total: z.number().int(),
  page: z.number().int(),
  pageSize: z.number().int(),
  cursor: z.string().optional(),
});

const PaginatedResponse = <T extends z.ZodType>(itemSchema: T) =>
  z.object({
    data: z.array(itemSchema),
    meta: PaginationMeta,
  });
```

---

## Error Response Format (RFC 7807)

All error responses use the Problem Details JSON format. Consistent structure across every endpoint.

```typescript
const ProblemDetail = z.object({
  type: z.string().url(),
  title: z.string(),
  status: z.number().int(),
  detail: z.string().optional(),
  instance: z.string().optional(),
  traceId: z.string().optional(),
});
```

Example response: `{ "type": "https://api.example.com/errors/validation", "title": "Validation Error", "status": 422, "detail": "Field 'amount' must be positive", "traceId": "req_abc123" }`.

---

## GraphQL — When to Use

Use GraphQL when clients need flexible queries (mobile vs web with different data needs), aggregation from multiple services in a single call, or reduction of over-fetching. GraphQL is NOT a replacement for REST — it is a complement. If the API is simple CRUD with predictable access patterns, REST is simpler. Record the choice in an ADR.

---

## Backward Compatibility Rules

| Change | Breaking? | Action Required |
|--------|-----------|-----------------|
| Adding a field to response | No | None |
| Removing a field from response | Yes | Deprecation period, MAJOR bump |
| Changing a field type | Yes | MAJOR bump, ADR |
| Adding optional query parameter | No | None |
| Changing URL structure | Yes | MAJOR bump, ADR |
| Adding a new endpoint | No | None |

All breaking changes require a MAJOR version bump, an ADR documenting the rationale, and a migration guide.

---

## Deprecation Policy

Public APIs: minimum 6 months notice. Internal APIs: minimum 3 months. Deprecated endpoints return `Deprecation: true` and `Sunset: <date>` headers. Deprecation announced in release notes, API docs, and changelog. Deprecated endpoints log usage to track migration progress.

---

## Rate Limiting

Every public API has rate limiting. Return `429 Too Many Requests` with `Retry-After` header (seconds until retry is allowed). Rate limits documented in API docs and returned in response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`. Different limits per authentication tier (anonymous < authenticated < premium).

---

## Idempotency Keys

For non-idempotent operations (POST), clients send an `Idempotency-Key` header. Server stores the key with the result and returns the cached result on retry.

```typescript
// Idempotency middleware
async function idempotencyMiddleware(req: Request, res: Response, next: NextFunction) {
  if (req.method !== 'POST') return next();

  const key = req.headers['idempotency-key'] as string;
  if (!key) return next(); // Optional: make mandatory for specific endpoints

  const cached = await redis.get(`idempotency:${req.auth.tenantId}:${key}`);
  if (cached) {
    const { status, body } = JSON.parse(cached);
    return res.status(status).json(body);
  }

  // Intercept response to cache it
  const originalJson = res.json.bind(res);
  res.json = (body: unknown) => {
    redis.set(
      `idempotency:${req.auth.tenantId}:${key}`,
      JSON.stringify({ status: res.statusCode, body }),
      { EX: 86400 }, // 24hr TTL
    );
    return originalJson(body);
  };

  next();
}
```

Client usage: `POST /invoices` with `Idempotency-Key: <client-generated-UUID>`. Safe to retry on network failure — same key returns same response.

---

## Async API Patterns

Not all operations complete synchronously. Patterns for long-running operations:

### Webhooks

For server-to-client notifications. Client registers a callback URL, server POSTs events to it.

**Rules**: sign webhook payloads (HMAC-SHA256), include timestamp to prevent replay, retry with exponential backoff (3 attempts), client must respond 2xx within 5s.

### Server-Sent Events (SSE)

For real-time updates to browser clients. Simpler than WebSockets, works through proxies and CDNs.

```typescript
app.get('/api/v1/tenants/:tenantId/events', authMiddleware, (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    Connection: 'keep-alive',
  });

  const unsubscribe = eventBus.subscribe(req.auth.tenantId, (event) => {
    res.write(`event: ${event.type}\ndata: ${JSON.stringify(event.data)}\n\n`);
  });

  req.on('close', unsubscribe);
});
```

### Long-Running Operations

For operations taking > 5s (report generation, data export):

```
POST /api/v1/tenants/{id}/reports → 202 Accepted
  Location: /api/v1/tenants/{id}/reports/rpt_123
  Body: { "id": "rpt_123", "status": "processing", "estimatedCompletion": "2026-02-09T10:05:00Z" }

GET /api/v1/tenants/{id}/reports/rpt_123 → 200 OK
  Body: { "id": "rpt_123", "status": "completed", "downloadUrl": "..." }
```

---

## Bulk Operations

For batch create/update/delete:

```typescript
// POST /api/v1/tenants/{id}/invoices/bulk
const BulkCreateRequest = z.object({
  items: z.array(CreateInvoiceSchema).max(100), // Hard limit to prevent abuse
});

// Response includes per-item results
const BulkCreateResponse = z.object({
  results: z.array(z.object({
    index: z.number(),
    status: z.enum(['created', 'failed']),
    id: z.string().optional(),
    error: ProblemDetail.optional(),
  })),
  summary: z.object({ created: z.number(), failed: z.number() }),
});
```

Return 207 Multi-Status when some items succeed and others fail.

---

## File Upload

Use signed URLs for direct-to-storage upload (bypass API server for large files):

```typescript
// Step 1: Client requests upload URL
// POST /api/v1/tenants/{id}/uploads → 200 { uploadUrl, fileId }
const { url } = await storage.bucket(bucket).file(fileId).getSignedUrl({
  action: 'write',
  expires: Date.now() + 15 * 60 * 1000, // 15 min
  contentType: req.body.contentType,
});

// Step 2: Client uploads directly to Cloud Storage using signed URL
// Step 3: Client confirms upload
// POST /api/v1/tenants/{id}/uploads/{fileId}/confirm
```

---

## API Gateway & BFF

**API Gateway**: single entry point for all API traffic. Handles: routing, rate limiting, authentication, request logging. Use Cloud Endpoints, Apigee, or Kong.

**Backend for Frontend (BFF)**: a lightweight API layer tailored to a specific client (web BFF, mobile BFF). Aggregates calls to backend services, shapes responses for the client's needs. One BFF per client type — don't share a BFF across web and mobile.

---

## OpenAPI-First Workflow

Write the OpenAPI spec before implementation. Generate TypeScript types from the spec. Validate request/response against the spec in integration tests. Publish interactive docs via Swagger UI or Redoc.

```yaml
openapi: 3.1.0
info:
  title: User Accounts API
  version: 1.0.0
paths:
  /api/v1/user-accounts:
    get:
      summary: List user accounts
      parameters:
        - name: page
          in: query
          schema: { type: integer, default: 1 }
      responses:
        '200':
          description: Paginated list of user accounts
```

---

## API Lifecycle Governance

Without governance, APIs proliferate without oversight, creating inconsistency, duplication, and uncontrolled breaking changes.

### Lifecycle Stages

| Stage | Stability | Header | Rules |
|-------|-----------|--------|-------|
| **Draft** | None | `X-API-Stage: draft` | Internal only, no stability guarantees, may change without notice |
| **Beta** | Low | `X-API-Stage: beta` | External access allowed, deprecation risk, breaking changes with 30-day notice |
| **Stable** | High | (none needed) | Full backward compatibility commitment, breaking changes require MAJOR bump |
| **Deprecated** | Frozen | `Deprecation: true`, `Sunset: <date>` | No new features, migration guide required, sunset date published |
| **Retired** | N/A | N/A | Endpoint returns `410 Gone` with migration pointer |

### Approval Process

New API or breaking change requires an Architecture Review:
- Lightweight: async review of OpenAPI diff + ADR for rationale
- Reviewer checklist: naming consistency, backward compatibility, security implications, performance budget
- For breaking changes: migration guide + consumer notification required before merge

### API Registry

Central catalog of all APIs with: owner team, lifecycle stage, version, SLO targets, consumer list. Can be as simple as a YAML file in the repo:

```yaml
# api-registry.yml
apis:
  - name: user-accounts
    owner: platform-team
    stage: stable
    version: v1
    slo:
      latency_p95_ms: 200
      availability: 99.9%
    consumers: [invoice-ui, admin-portal, mobile-app]
  - name: analytics
    owner: data-team
    stage: beta
    version: v1
    consumers: [admin-portal]
```

### Consumer Tracking

Know who depends on your API before making changes. Use API keys or client registration to track consumers. Before any breaking change, the registry tells you exactly who will be affected.

**Anti-pattern**: API that stays in "beta" forever to avoid backward compatibility obligations. If an API has production consumers, it's effectively stable — label it as such and commit to compatibility.

---

## Breaking Change Detection in CI

Breaking changes that slip through undetected cause production incidents for API consumers. Automated detection is the only reliable gate.

### Tooling

Use `oasdiff` or `optic` in CI to compare the current OpenAPI spec against the main branch baseline:

```yaml
# .github/workflows/api-check.yml
- name: Check for breaking API changes
  run: |
    # Compare current spec against main branch
    git show origin/main:openapi.yaml > /tmp/base-spec.yaml
    npx oasdiff breaking /tmp/base-spec.yaml openapi.yaml
  continue-on-error: false
```

### What Is Detected

| Change | Breaking? | CI Action |
|--------|-----------|-----------|
| Removed endpoint | Yes | Block PR |
| Removed response field | Yes | Block PR |
| Changed field type | Yes | Block PR |
| Required field added to request | Yes | Block PR |
| Changed URL structure | Yes | Block PR |
| New optional field in response | No | Pass |
| New optional parameter | No | Pass |
| New endpoint | No | Pass |

### CI Gate Behavior

Breaking change detected → pipeline fails → developer must either:
1. **Fix the breaking change** (make it additive instead), or
2. **Bump MAJOR version** + write ADR + add migration guide + notify consumers

### Schema Evolution for Events

The same principle applies to event schemas. Use JSON Schema diff or Avro compatibility checks in CI. Cross-reference: `event-driven-architecture/SKILL.md`.

**Anti-pattern**: relying on manual review to catch breaking changes. Humans miss subtle breaks like type narrowing (`string` → `string enum`), optional-to-required transitions, and response field removals in nested objects.

---

## Event Schema Versioning

Event schemas evolve just like REST APIs, but without the same tooling discipline. A breaking event schema change is worse than a breaking API change because events are consumed asynchronously — consumers discover the break at processing time, not at call time.

### Compatibility Rules

| Direction | Meaning | Goal |
|-----------|---------|------|
| **Backward compatible** | New consumer reads old events | Always required |
| **Forward compatible** | Old consumer reads new events | Strongly recommended |
| **Full compatibility** | Both directions | Ideal target |

### Safe vs Breaking Changes

| Change | Safe? | Notes |
|--------|-------|-------|
| Add optional field | Yes | Consumers ignore unknown fields |
| Add new event type | Yes | Consumers subscribe to types they care about |
| Remove field | **No** | Consumers reading that field will break |
| Rename field | **No** | Equivalent to remove + add |
| Change field type | **No** | Deserialization fails |
| Change event type name | **No** | Consumers won't receive events |

### Schema Registry

Central schema store where every event type has a versioned schema. Options:
- **Confluent Schema Registry** (for Kafka-based systems)
- **`schemas/` directory** in the repo with CI validation (lightweight, fits most teams)

```
schemas/
  events/
    invoice.created.v1.json
    invoice.created.v2.json     # Breaking change → new version
    invoice.paid.v1.json
```

### Evolution Strategy

- **Additive-only changes** on the same version (add optional fields, add new event types)
- **Breaking changes** → new event type name with version suffix (e.g., `invoice.created.v2`)
- **Migration period**: publish both v1 and v2 during transition. Set sunset date for v1.
- Consumers migrate to v2 during the migration period. After sunset, stop publishing v1.

Cross-reference: `event-driven-architecture/SKILL.md` for event design patterns and delivery guarantees.

**Anti-pattern**: changing event schema without notifying consumers. This is a silent contract break — consumers discover it when deserialization fails in production, not in CI.

---

## API Performance Contracts

An API without a latency target is an API that will eventually be too slow. Performance must be a contractual property, not an afterthought.

### Per-Endpoint SLO

Every endpoint has a latency target (p95) and throughput target documented in the OpenAPI spec or service README:

```yaml
# OpenAPI extension for performance SLO
paths:
  /api/v1/users/{id}:
    get:
      x-performance-slo:
        latency_p95_ms: 100
        latency_p99_ms: 500
        throughput_rps: 1000
      summary: Get user by ID
```

### Performance Budget

| Endpoint Type | p95 Latency Budget | Rationale |
|---------------|-------------------|-----------|
| Simple CRUD (single entity) | < 100ms | Direct DB lookup, minimal logic |
| List with pagination | < 200ms | Query + serialization |
| Aggregation / join | < 500ms | Multiple DB queries or service calls |
| Report generation | Async (202) | Too slow for synchronous — use long-running operation pattern |

### Monitoring Integration

Performance SLOs feed into alerting. Breach of API performance contract triggers an alert:

```yaml
# Prometheus alert for API latency SLO breach
- alert: ApiLatencySloBreached
  expr: |
    histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{handler="/api/v1/users/:id"}[5m])) by (le))
    > 0.1
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "GET /api/v1/users/:id p95 latency exceeds 100ms SLO"
    runbook: "https://wiki.internal/runbooks/api-latency"
```

### Contract Testing for Performance

Performance contract tests run during the **nightly gate** (not on every PR — too slow and noisy). Fail the pipeline if p95 latency exceeds the target by >20%:

```typescript
import { describe, it, expect } from 'vitest';

describe('API Performance Contracts', () => {
  it('GET /api/v1/users/:id responds within 100ms p95', async () => {
    const durations: number[] = [];
    for (let i = 0; i < 100; i++) {
      const start = performance.now();
      await fetch(`${BASE_URL}/api/v1/users/user_${i}`);
      durations.push(performance.now() - start);
    }
    durations.sort((a, b) => a - b);
    const p95 = durations[Math.floor(durations.length * 0.95)];
    expect(p95).toBeLessThan(120); // 100ms target + 20% tolerance
  });
});
```

Cross-reference: `observability/SKILL.md` for SLO-based alerting, `performance-testing/SKILL.md` for load testing with k6.

**Anti-pattern**: API with no latency target that degrades 10x over 6 months without anyone noticing. By the time users complain, the technical debt is massive.

---

## Anti-Patterns

- **Verbs in URLs**: `/api/getUsers` — use `GET /api/v1/users` instead
- **Inconsistent naming**: mixing camelCase and snake_case in response bodies — pick one (camelCase for JSON)
- **200 with error body**: returning HTTP 200 with `{ "error": "..." }` — use proper status codes
- **Unpaginated collections**: returning all records without pagination — always paginate
- **Breaking changes without version bump**: silent contract changes break clients
- **Exposing internals**: database IDs, table structures, or stack traces in responses

---

## For Claude Code

When generating APIs: REST with resource-oriented URLs, Zod validation on all inputs, RFC 7807 error responses, paginated collections with cursor support, OpenAPI spec generated from code or code generated from spec. Always include rate limiting middleware. Generate contract tests for every public endpoint. Include `tenantId` in multi-tenant API paths (`/api/v1/tenants/{tenantId}/resources`). Use typed error factories for consistent Problem Detail responses. Assign lifecycle stages to new APIs (start at Draft or Beta, never skip to Stable without review). Add breaking change detection (oasdiff) to CI pipeline — block PRs that break the OpenAPI contract without a MAJOR version bump. For event schemas, enforce additive-only evolution on the same version and use versioned event type names for breaking changes. Define per-endpoint performance SLOs (p95 latency target) in the OpenAPI spec and wire them to observability alerts.

---

*Internal references*: `authn-authz/SKILL.md`, `testing-implementation/SKILL.md`, `technical-documentation/SKILL.md`, `security-by-design/SKILL.md`, `event-driven-architecture/SKILL.md`, `observability/SKILL.md`, `performance-testing/SKILL.md`
