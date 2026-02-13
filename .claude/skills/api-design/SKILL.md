---
name: api-design
cluster: architecture-patterns
description: "API design conventions for REST and GraphQL. Resource naming, versioning, pagination, error responses (RFC 7807), OpenAPI-first workflow, backward compatibility. Use when designing APIs, writing endpoint handlers, or defining API contracts."
---

# API Design

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

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

## Anti-Patterns

- **Verbs in URLs**: `/api/getUsers` — use `GET /api/v1/users` instead
- **Inconsistent naming**: mixing camelCase and snake_case in response bodies — pick one (camelCase for JSON)
- **200 with error body**: returning HTTP 200 with `{ "error": "..." }` — use proper status codes
- **Unpaginated collections**: returning all records without pagination — always paginate
- **Breaking changes without version bump**: silent contract changes break clients
- **Exposing internals**: database IDs, table structures, or stack traces in responses

---

## For Claude Code

When generating APIs: REST with resource-oriented URLs, Zod validation on all inputs, RFC 7807 error responses, paginated collections with cursor support, OpenAPI spec generated from code or code generated from spec. Always include rate limiting middleware. Generate contract tests for every public endpoint. Include `tenantId` in multi-tenant API paths (`/api/v1/tenants/{tenantId}/resources`). Use typed error factories for consistent Problem Detail responses.

---

*Internal references*: `authn-authz/SKILL.md`, `testing-implementation/SKILL.md`, `technical-documentation/SKILL.md`, `security-by-design/SKILL.md`
