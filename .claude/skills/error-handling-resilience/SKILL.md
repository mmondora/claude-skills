---
name: error-handling-resilience
cluster: architecture-patterns
description: "Error handling and resilience patterns for distributed systems. Typed errors, circuit breakers, retry with backoff, bulkheads, timeout budgets, graceful degradation and shutdown. Use when building fault-tolerant services, handling failures across service boundaries, or implementing resilience infrastructure."
---

# Error Handling & Resilience Patterns

> **Version**: 1.4.0 | **Last updated**: 2026-02-14

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

## Dead Letter Queue (DLQ) Pattern

In event-driven systems, a poisoned message that consistently fails processing creates an infinite retry loop that blocks the entire queue. DLQ isolates toxic messages so healthy messages continue flowing.

### When to Route to DLQ

Route a message to DLQ when: max retry count exceeded, deserialization failure (message is not valid JSON/protobuf), schema validation failure (message structure doesn't match expected schema). Never route to DLQ on transient errors (network timeout, temporary unavailability) — those should retry with backoff.

### DLQ Message Envelope

The DLQ entry wraps the original message with error metadata for diagnosis and replay:

```typescript
interface DlqEntry<T = unknown> {
  originalMessage: T;
  metadata: {
    sourceQueue: string;
    failedAt: string;          // ISO-8601
    attemptCount: number;
    maxAttempts: number;
    lastError: string;
    errorCode: string;
    correlationId: string;
    tenantId: string;
  };
}

async function routeToDlq<T>(
  message: T,
  sourceQueue: string,
  error: Error,
  context: { attemptCount: number; maxAttempts: number; correlationId: string; tenantId: string },
): Promise<void> {
  const entry: DlqEntry<T> = {
    originalMessage: message,
    metadata: {
      sourceQueue,
      failedAt: new Date().toISOString(),
      attemptCount: context.attemptCount,
      maxAttempts: context.maxAttempts,
      lastError: error.message,
      errorCode: error.name,
      correlationId: context.correlationId,
      tenantId: context.tenantId,
    },
  };

  await dlqPublisher.publish(entry);
  dlqDepthGauge.inc({ queue: sourceQueue });
  logger.warn({ ...entry.metadata }, 'Message routed to DLQ');
}
```

### DLQ Monitoring and Reprocessing

- **Alert when DLQ depth > 0** — every DLQ message represents a failure that needs human attention
- **Dashboard**: DLQ depth over time, message age (oldest unprocessed), messages per source queue
- **Reprocessing strategy**: manual review → identify and fix root cause → replay from DLQ. Never auto-replay without a fix — you'll just re-poison the queue
- **Retention**: DLQ messages retained for 14 days minimum (configurable per compliance requirements)

**Anti-pattern**: using DLQ as a trash bin without monitoring. Messages rot silently, representing lost business operations that nobody investigates.

---

## Saga Compensation

In distributed transactions spanning multiple services, when step N fails, steps 1..N-1 must be undone. Without explicit compensation, the system is left in an inconsistent state where some services committed and others didn't.

### Compensation vs Rollback

Compensation is a *semantic undo*, not a database rollback. A payment refund is not the same as deleting the payment record — it's a new business operation that reverses the effect. Compensation must account for the fact that the world may have changed since the original operation.

### Saga Orchestrator

```typescript
interface SagaStep<TContext> {
  name: string;
  execute: (ctx: TContext) => Promise<TContext>;
  compensate: (ctx: TContext) => Promise<void>;
}

class SagaOrchestrator<TContext> {
  private readonly completedSteps: SagaStep<TContext>[] = [];

  constructor(
    private readonly sagaName: string,
    private readonly steps: SagaStep<TContext>[],
    private readonly logger: Logger,
  ) {}

  async run(initialContext: TContext): Promise<TContext> {
    let ctx = initialContext;

    for (const step of this.steps) {
      try {
        this.logger.info({ saga: this.sagaName, step: step.name }, 'Executing saga step');
        ctx = await step.execute(ctx);
        this.completedSteps.push(step);
      } catch (error) {
        this.logger.error({ saga: this.sagaName, step: step.name, err: error }, 'Saga step failed, compensating');
        await this.compensate(ctx);
        throw new SagaError(this.sagaName, step.name, error instanceof Error ? error : new Error(String(error)));
      }
    }

    return ctx;
  }

  private async compensate(ctx: TContext): Promise<void> {
    // Compensate in reverse order (LIFO)
    for (const step of [...this.completedSteps].reverse()) {
      try {
        this.logger.info({ saga: this.sagaName, step: step.name }, 'Compensating saga step');
        await step.compensate(ctx);
      } catch (error) {
        // Compensation failure is critical — log and continue compensating remaining steps
        this.logger.error({ saga: this.sagaName, step: step.name, err: error }, 'Compensation failed — manual intervention required');
      }
    }
  }
}

class SagaError extends Error {
  constructor(public readonly saga: string, public readonly failedStep: string, public readonly cause: Error) {
    super(`Saga '${saga}' failed at step '${failedStep}': ${cause.message}`);
    this.name = 'SagaError';
  }
}
```

### Usage Example

```typescript
const createOrderSaga = new SagaOrchestrator('create-order', [
  {
    name: 'reserve-inventory',
    execute: async (ctx) => { ctx.reservationId = await inventoryService.reserve(ctx.items); return ctx; },
    compensate: async (ctx) => { await inventoryService.releaseReservation(ctx.reservationId); },
  },
  {
    name: 'charge-payment',
    execute: async (ctx) => { ctx.paymentId = await paymentService.charge(ctx.amount); return ctx; },
    compensate: async (ctx) => { await paymentService.refund(ctx.paymentId); },
  },
  {
    name: 'create-shipment',
    execute: async (ctx) => { ctx.shipmentId = await shippingService.create(ctx.address); return ctx; },
    compensate: async (ctx) => { await shippingService.cancel(ctx.shipmentId); },
  },
], logger);
```

### Key Rules

- **Idempotent compensations**: compensating actions must be safe to retry (use idempotency keys)
- **Compensation ordering**: always reverse order of execution (LIFO) — undo the last thing first
- **Persistent execution log**: in production, persist the saga state to a database so compensation can resume after a crash
- **Timeout**: each step has a timeout; saga-level timeout ensures the entire transaction doesn't hang

**Anti-pattern**: compensations that assume the original state still exists. Between the original operation and the compensation, other operations may have modified the state. Compensations must be defensive and handle "already compensated" or "state changed" gracefully.

---

## Adaptive Load Shedding

Under extreme load, a service must protect itself by rejecting low-priority work before it degrades for everyone. Load shedding is self-preservation — distinct from rate limiting (which is per-client fairness).

### Load Signals

No single signal is sufficient. Combine multiple indicators:

```typescript
interface LoadSignals {
  cpuUtilization: number;       // 0-1, from os.loadavg() or cgroup metrics
  eventLoopLagMs: number;       // measured via setTimeout(0) delta or perf_hooks
  activeRequests: number;       // currently in-flight requests
  latencyTrendMs: number;       // rolling p95 latency over last 30s
}

type Priority = 'critical' | 'normal' | 'deferrable';

function assessLoad(signals: LoadSignals): 'healthy' | 'elevated' | 'critical' {
  const score =
    (signals.cpuUtilization > 0.8 ? 1 : 0) +
    (signals.eventLoopLagMs > 100 ? 1 : 0) +
    (signals.activeRequests > 500 ? 1 : 0) +
    (signals.latencyTrendMs > 1000 ? 1 : 0);

  if (score >= 3) return 'critical';
  if (score >= 2) return 'elevated';
  return 'healthy';
}
```

### Priority Classification

| Priority | Examples | Shed when |
|----------|----------|-----------|
| **Critical** | Health checks, authentication, readiness probes | Never |
| **Normal** | Business operations (CRUD, queries) | Load is `critical` |
| **Deferrable** | Reports, exports, analytics, batch jobs | Load is `elevated` or `critical` |

### Load Shedding Middleware

```typescript
import { Counter } from 'prom-client';

const shedCounter = new Counter({
  name: 'http_requests_shed_total',
  help: 'Requests shed due to load',
  labelNames: ['priority', 'endpoint'],
});

function loadSheddingMiddleware(getSignals: () => LoadSignals, getPriority: (req: Request) => Priority) {
  return (req: Request, res: Response, next: NextFunction) => {
    const priority = getPriority(req);
    const load = assessLoad(getSignals());

    if (priority === 'critical') return next(); // never shed critical

    if (load === 'critical' && priority === 'normal') {
      shedCounter.inc({ priority, endpoint: req.route?.path ?? req.path });
      logger.warn({ path: req.path, load, priority }, 'Request shed — critical load');
      return res.status(503).set('Retry-After', '30').json({
        type: 'https://api.example.com/errors/load-shedding',
        title: 'Service Overloaded',
        status: 503,
        detail: 'Service is under heavy load. Please retry after the indicated delay.',
      });
    }

    if (load !== 'healthy' && priority === 'deferrable') {
      shedCounter.inc({ priority, endpoint: req.route?.path ?? req.path });
      logger.warn({ path: req.path, load, priority }, 'Request shed — deferrable during elevated load');
      return res.status(503).set('Retry-After', '60').json({
        type: 'https://api.example.com/errors/load-shedding',
        title: 'Service Overloaded',
        status: 503,
        detail: 'Deferrable operations are temporarily unavailable. Please retry later.',
      });
    }

    next();
  };
}
```

### Response

- HTTP 503 with `Retry-After` header (seconds)
- Structured log with shed reason, priority, and load state
- Metric counter for shed requests (by priority and endpoint)
- Dashboard: shed rate over time, correlated with load signals

**Anti-pattern**: shedding based on a single signal. A CPU spike alone is not enough — a GC pause can spike CPU without actual overload. Combine CPU with event loop lag, active request count, and latency trend for reliable detection.

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

When generating services: define typed error discriminated unions at the domain level, never use raw `throw new Error()` with string messages. Create RFC 7807 error factories for all HTTP error responses. Wrap external dependency calls with circuit breaker and retry logic. Set explicit timeouts on all outbound calls -- never rely on defaults. Implement graceful shutdown with SIGTERM handler, readiness probe integration, and connection draining. Use bulkheads when calling two or more external dependencies. Every resilience mechanism must emit metrics and structured logs. Generate error boundary middleware translating domain errors to Problem Detail responses. Never generate empty catch blocks or catch-and-log-only without re-throwing. For event-driven services, implement DLQ routing with structured error metadata and monitoring alerts. For distributed transactions, use saga orchestrator with explicit compensation steps in reverse order. Under load, implement adaptive load shedding middleware with multi-signal detection and priority-based rejection.

---

*Internal references*: `observability/SKILL.md`, `api-design/SKILL.md`, `event-driven-architecture/SKILL.md`
