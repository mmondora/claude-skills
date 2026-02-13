---
name: error-handling-resilience
cluster: architecture-patterns
description: "Error handling and resilience patterns for distributed systems. Typed errors, circuit breakers, retry with backoff, bulkheads, timeout budgets, graceful degradation and shutdown. Use when building fault-tolerant services, handling failures across service boundaries, or implementing resilience infrastructure."
---

# Error Handling & Resilience Patterns

> **Version**: 1.3.0 | **Last updated**: 2026-02-13

## Purpose

Resilience is an architectural property, not an afterthought. Distributed systems fail partially and unpredictably -- the question is never "will it fail?" but "how will it behave when it does?" This skill defines patterns for classifying errors, containing failures, degrading gracefully, and recovering automatically.

---

## Error Classification

Errors fall into two dimensions: **domain vs infrastructure** and **user-facing vs technical**.

**Domain errors**: validation failures, business rule violations, resource conflicts. Expected and meaningful to the caller. **Infrastructure errors**: network timeouts, database connection lost, disk full. Operational -- never leak implementation details.

### Typed Errors with Discriminated Unions

```typescript
type DomainError =
  | { kind: 'validation'; field: string; message: string }
  | { kind: 'not-found'; resource: string; id: string }
  | { kind: 'conflict'; resource: string; reason: string }
  | { kind: 'forbidden'; action: string; reason: string };

type InfrastructureError =
  | { kind: 'timeout'; dependency: string; durationMs: number }
  | { kind: 'circuit-open'; dependency: string }
  | { kind: 'unavailable'; dependency: string; cause: string };

type AppError = DomainError | InfrastructureError;
```

### RFC 7807 Problem Detail Factory

```typescript
import { z } from 'zod';

const ProblemDetail = z.object({
  type: z.string().url(), title: z.string(), status: z.number().int(),
  detail: z.string().optional(), instance: z.string().optional(), traceId: z.string().optional(),
});

function createProblemDetail(error: DomainError, traceId: string, baseUrl: string): z.infer<typeof ProblemDetail> {
  const base = (kind: string, title: string, status: number, detail: string) =>
    ({ type: `${baseUrl}/errors/${kind}`, title, status, detail, traceId });
  switch (error.kind) {
    case 'validation': return base('validation', 'Validation Error', 422, `Field '${error.field}': ${error.message}`);
    case 'not-found': return base('not-found', 'Resource Not Found', 404, `${error.resource} '${error.id}' not found`);
    case 'conflict': return base('conflict', 'Resource Conflict', 409, error.reason);
    case 'forbidden': return base('forbidden', 'Forbidden', 403, `Cannot ${error.action}: ${error.reason}`);
  }
}
```

Infrastructure errors always map to 503 Service Unavailable. Never expose dependency names, connection strings, or stack traces to API consumers.

---

## Circuit Breaker Pattern

Prevents cascading failures by stopping calls to a failing dependency. Three states:

| State | Behavior | Transition |
|-------|----------|------------|
| **Closed** | Requests pass through; failures counted | Failure count exceeds threshold -> Open |
| **Open** | Requests fail immediately without calling dependency | Timer expires -> Half-Open |
| **Half-Open** | Limited probe requests allowed | Probe succeeds -> Closed; Probe fails -> Open |

```typescript
import { Counter, Gauge } from 'prom-client';
type CircuitState = 'closed' | 'open' | 'half-open';

const stateGauge = new Gauge({ name: 'circuit_breaker_state', help: 'State (0=closed,1=open,2=half-open)', labelNames: ['dependency'] });
const transitionCounter = new Counter({ name: 'circuit_breaker_transitions_total', help: 'State transitions', labelNames: ['dependency', 'from', 'to'] });

class CircuitBreaker {
  private state: CircuitState = 'closed';
  private failureCount = 0;
  private lastFailureTime = 0;

  constructor(private readonly dep: string, private readonly opts: {
    failureThreshold: number; resetTimeoutMs: number;
  }) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() - this.lastFailureTime > this.opts.resetTimeoutMs) this.transition('half-open');
      else throw { kind: 'circuit-open' as const, dependency: this.dep };
    }
    try {
      const result = await fn();
      if (this.state === 'half-open') this.transition('closed');
      this.failureCount = 0;
      return result;
    } catch (error) {
      this.failureCount++;
      this.lastFailureTime = Date.now();
      if (this.failureCount >= this.opts.failureThreshold) this.transition('open');
      throw error;
    }
  }

  private transition(to: CircuitState): void {
    transitionCounter.inc({ dependency: this.dep, from: this.state, to });
    this.state = to;
    if (to === 'closed') this.failureCount = 0;
    stateGauge.set({ dependency: this.dep }, { closed: 0, open: 1, 'half-open': 2 }[to]);
  }
}
```

---

## Retry with Exponential Backoff

Not all errors are retryable. Classify before retrying.

| Category | Examples | Retryable? |
|----------|----------|------------|
| Transient | 503, ECONNRESET, timeout, rate-limited (429) | Yes |
| Permanent | 400, 401, 403, 404, 422 | No |
| Ambiguous | 500 | Retry once, then treat as permanent |

**Idempotency requirement**: retryable operations MUST be idempotent. POST needs `Idempotency-Key` header; PUT and DELETE are naturally idempotent. Never retry a non-idempotent mutation without an idempotency mechanism.

```typescript
async function withRetry<T>(fn: () => Promise<T>, opts: {
  maxRetries: number; baseDelayMs: number; maxDelayMs: number;
  isRetryable: (error: unknown) => boolean;
}): Promise<T> {
  let lastError: unknown;
  for (let attempt = 0; attempt <= opts.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt === opts.maxRetries || !opts.isRetryable(error)) throw error;
      const delay = Math.min(
        opts.baseDelayMs * Math.pow(2, attempt) + Math.random() * opts.baseDelayMs,
        opts.maxDelayMs,
      );
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
  throw lastError;
}
```

The jitter term (`Math.random() * baseDelayMs`) prevents thundering herd when many clients retry simultaneously. Without jitter, retries synchronize and overload the recovering dependency.

---

## Bulkhead Pattern

Isolates resources per dependency so that one failing dependency cannot exhaust shared resources and take down unrelated functionality. Semaphore-based implementation:

```typescript
class Bulkhead {
  private current = 0;
  private readonly queue: Array<() => void> = [];
  constructor(private readonly name: string, private readonly max: number) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.current >= this.max) await new Promise<void>((r) => this.queue.push(r));
    else this.current++;
    try { return await fn(); } finally {
      const next = this.queue.shift();
      if (next) next(); else this.current--;
    }
  }
}

// One bulkhead per external dependency
const paymentBulkhead = new Bulkhead('payment-gateway', 10);
const emailBulkhead = new Bulkhead('email-service', 5);
```

If the payment gateway saturates its 10 slots, email sending continues unaffected through its own isolated pool.

---

## Timeout Strategy

Every outbound call has a timeout. Timeouts follow a hierarchy -- outer timeouts are always larger than inner: `Client (30s) > Gateway (25s) > Service (20s) > Dependency (5s)`.

### Timeout Budget Pattern

A request enters the system with a total time budget. Each service subtracts its processing time and passes the remaining budget downstream via an `X-Deadline` header.

```typescript
function getTimeoutBudget(req: Request): number {
  const deadline = req.headers['x-deadline'] as string | undefined;
  if (deadline) return Math.max(new Date(deadline).getTime() - Date.now(), 0);
  return 20_000; // default 20s for requests without deadline
}

function propagateDeadline(req: Request, outbound: Record<string, string>): void {
  const deadline = req.headers['x-deadline'] as string | undefined;
  if (deadline) outbound['x-deadline'] = deadline;
}
```

If the remaining budget is less than the expected call duration, fail fast rather than making a call that will certainly time out.

---

## Graceful Degradation

When a dependency fails, degrade functionality rather than failing entirely. Strategies ordered by preference:

1. **Cached response**: return last known good value (acceptable for reads tolerant of staleness)
2. **Default value**: return a safe default (empty recommendations list, default configuration)
3. **Reduced functionality**: disable the failing feature, keep everything else working
4. **Kill switch**: use feature flags to instantly disable a feature without deployment

```typescript
async function getRecommendations(userId: string, featureFlags: FeatureFlags): Promise<Recommendation[]> {
  if (!featureFlags.isEnabled('recommendations-engine')) return []; // kill switch

  try {
    return await recommendationService.getForUser(userId);
  } catch (error) {
    logger.warn({ userId, error: error.message }, 'Recommendations unavailable, returning cached');
    const cached = await cache.get<Recommendation[]>(`recs:${userId}`);
    return cached ?? [];
  }
}
```

Every fallback activation MUST be logged and counted as a metric. A fallback active silently for days is a hidden outage.

---

## Graceful Shutdown

When a service receives SIGTERM, it must: stop accepting new requests, complete in-flight requests, close connections, flush pending writes, then exit.

```typescript
function setupGracefulShutdown(server: Server, resources: { close(): Promise<void> }[], logger: Logger): void {
  let shuttingDown = false;
  const shutdown = async (signal: string) => {
    if (shuttingDown) return;
    shuttingDown = true;
    logger.info({ signal }, 'Shutdown signal received');
    healthCheck.setReady(false);                                    // 1. Fail readiness probe
    await new Promise((r) => setTimeout(r, 5_000));                 // 2. Wait for LB to remove from pool
    server.close(async () => {                                      // 3. Drain in-flight requests
      for (const r of resources) {                                  // 4. Close resources
        try { await r.close(); } catch (err) { logger.error({ err }, 'Shutdown resource error'); }
      }
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 30_000);                      // 5. Force exit
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}
```

The 5-second delay after failing the readiness probe gives the load balancer time to stop routing traffic. Without it, requests arrive after the server stops accepting.

---

## Error Propagation Rules

1. **Never swallow errors.** An empty `catch` block is a bug. Every caught error is handled (fallback, retry, user-facing message) or re-thrown with added context.

2. **Wrap, don't replace.** Preserve the original error as `cause` to maintain the full chain for debugging.

```typescript
class ServiceError extends Error {
  constructor(message: string, public readonly code: string, public readonly cause?: Error) {
    super(message);
    this.name = 'ServiceError';
  }
}

async function createOrder(input: CreateOrderInput): Promise<Order> {
  try { return await orderRepository.save(input); }
  catch (error) {
    throw new ServiceError(`Failed to create order for tenant ${input.tenantId}`, 'ORDER_CREATION_FAILED',
      error instanceof Error ? error : new Error(String(error)));
  }
}
```

3. **Propagate correlation ID.** Every error log and response includes the `X-Request-Id` from the request, enabling tracing across services.

4. **Boundary translation.** At each service boundary, translate internal errors to the external format. `ServiceError` becomes RFC 7807 `ProblemDetail` at the HTTP boundary. Never expose internal codes, class names, or stack traces.

5. **Structured error logging.** Log errors as structured JSON: message, code, correlation ID, tenant ID, stack trace (error level only), dependency, duration.

```typescript
logger.error({
  err: error, correlationId: req.headers['x-request-id'],
  tenantId: req.auth.tenantId, operation: 'createOrder', durationMs: Date.now() - startTime,
}, 'Order creation failed');
```

---

## Anti-Patterns

- **Empty catch blocks**: swallowing errors silently hides failures until they cascade into larger outages -- every catch must handle or re-throw
- **Retry without backoff**: immediate retries amplify load on a struggling dependency and can turn a partial failure into a total one
- **Retry non-idempotent operations**: retrying a POST without an idempotency key risks duplicate side effects (double charges, duplicate records)
- **Timeout without budget**: setting the same timeout at every layer means inner timeouts expire while outer callers still wait, wasting resources on doomed requests
- **Circuit breaker without observability**: a breaker that opens silently provides no signal to operators -- always emit metrics on state transitions and alert when open
- **Catching generic `Error` and returning 500**: treating all errors as 500 loses the 4xx/5xx distinction, corrupting error rate SLOs

---

## For Claude Code

When generating services: define typed error discriminated unions at the domain level, never use raw `throw new Error()` with string messages. Create RFC 7807 error factories for all HTTP error responses. Wrap external dependency calls with circuit breaker and retry logic. Set explicit timeouts on all outbound calls -- never rely on defaults. Implement graceful shutdown with SIGTERM handler, readiness probe integration, and connection draining. Use bulkheads when calling two or more external dependencies. Every resilience mechanism must emit metrics and structured logs. Generate error boundary middleware translating domain errors to Problem Detail responses. Never generate empty catch blocks or catch-and-log-only without re-throwing.

---

*Internal references*: `observability/SKILL.md`, `api-design/SKILL.md`, `event-driven-architecture/SKILL.md`
