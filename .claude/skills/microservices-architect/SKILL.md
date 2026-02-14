---
name: microservices-architect
cluster: architecture-patterns
description: "Service decomposition and distributed system design. Domain-driven design, bounded contexts, inter-service communication, data ownership, resilience patterns, service mesh. Use when decomposing monoliths, defining service boundaries, designing distributed transactions, or establishing observability across services."
---

# Microservices Architect

> **Version**: 1.3.0 | **Last updated**: 2026-02-14

## Purpose

Microservices architecture is a means to organizational scalability — independent teams deploying independent services. Without disciplined decomposition, teams build distributed monoliths: all the complexity of distribution with none of the autonomy benefits.

---

## Service Decomposition

**Bounded contexts** from domain-driven design are the primary decomposition tool. A bounded context is a boundary within which a domain model is consistent. Each microservice owns exactly one bounded context.

**Decision table — split vs keep together**:

| Signal | Split | Keep Together |
|--------|-------|---------------|
| Different business capabilities | Yes | — |
| Different change cadences | Yes | — |
| Shared data model, change together | — | Yes |
| Shared transactional boundary | — | Yes |
| Independent scaling requirements | Yes | — |
| Different team ownership | Yes | — |
| < 3 entities in the context | — | Yes (too small) |
| > 15 entities in the context | Yes (too big) | — |

**Key rule**: if two capabilities share the same data model and change together, they belong in the same service. Splitting them creates a distributed monolith with synchronous coupling and shared-schema pain.

**Event Storming** as discovery technique: identify domain events first, then group commands and aggregates into bounded contexts. The boundaries emerge from the domain, not from technical layers.

---

## Inter-Service Communication

| Pattern | Use When | Latency | Coupling |
|---------|----------|---------|----------|
| REST/HTTP | Synchronous query, simple CRUD, external APIs | Low | High |
| gRPC | High-throughput, low-latency, internal services | Very low | Medium |
| Async Events | Cross-aggregate side effects, eventual consistency | Variable | Low |
| Request-Reply (via queue) | Async with response needed, decoupled command | Medium | Low |

**Default**: async events for cross-service communication. Synchronous calls only when the caller cannot proceed without the response.

```typescript
// gRPC client with deadline and circuit breaker
import { credentials, Metadata } from '@grpc/grpc-js';
import { InventoryServiceClient } from './generated/inventory_grpc_pb';

const client = new InventoryServiceClient(
  'inventory-service:50051',
  credentials.createInsecure(),
);

async function checkStock(productId: string, traceId: string): Promise<number> {
  const metadata = new Metadata();
  metadata.set('x-trace-id', traceId);
  const deadline = new Date(Date.now() + 5_000); // 5s timeout

  return new Promise((resolve, reject) => {
    client.getStock({ productId }, metadata, { deadline }, (err, response) => {
      if (err) return reject(new ServiceCallError('inventory', err.message));
      resolve(response.quantity);
    });
  });
}
```

---

## Data Ownership

**Database-per-service** is the default. Each service owns its data store and exposes data only through its API or published events. No service reads another service's database directly.

**Patterns for data spanning services**:

| Pattern | Use When | Consistency |
|---------|----------|-------------|
| API Composition | Query-time aggregation from 2-3 services | Strong (at query time) |
| CQRS Read Model | Complex queries across many services | Eventual |
| Event-Carried State Transfer | Service needs local copy of another's data | Eventual |

```typescript
// API composition — order details aggregated from multiple services
async function getOrderDetails(
  orderId: string,
  tenantId: string,
  traceId: string,
): Promise<OrderDetails> {
  const [order, customer, shipment] = await Promise.all([
    orderService.getOrder(orderId, { tenantId, traceId }),
    customerService.getCustomer(order.customerId, { tenantId, traceId }),
    shippingService.getShipment(orderId, { tenantId, traceId }),
  ]);

  return {
    ...order,
    customer: { name: customer.name, email: customer.email },
    shipment: shipment ?? null,
  };
}
```

**Event-carried state transfer**: when service B frequently needs data from service A, service B subscribes to A's domain events and maintains a local read-only projection. Eliminates runtime dependency on service A for reads.

---

## Distributed Transactions

The saga pattern replaces distributed ACID transactions. Each step has a compensating action that undoes its effect on failure.

| Aspect | Choreography | Orchestration |
|--------|-------------|---------------|
| Coordination | Each service reacts to events | Central orchestrator directs flow |
| Complexity | Simple for 2-3 steps | Better for 4+ steps |
| Visibility | Hard to trace full flow | Single place to see status |
| Coupling | Services know next step | Only orchestrator knows flow |
| Error handling | Compensating events | Orchestrator triggers compensation |
| Best for | Simple, linear flows | Complex flows with branching |

```typescript
// Saga orchestrator skeleton
interface SagaStep<TContext> {
  name: string;
  execute(ctx: TContext): Promise<void>;
  compensate(ctx: TContext): Promise<void>;
}

class SagaOrchestrator<TContext> {
  private steps: SagaStep<TContext>[] = [];
  private completed: SagaStep<TContext>[] = [];

  addStep(step: SagaStep<TContext>): this {
    this.steps.push(step);
    return this;
  }

  async run(ctx: TContext): Promise<void> {
    for (const step of this.steps) {
      try {
        await step.execute(ctx);
        this.completed.push(step);
      } catch (error) {
        await this.rollback(ctx);
        throw new SagaFailedError(step.name, error);
      }
    }
  }

  private async rollback(ctx: TContext): Promise<void> {
    for (const step of this.completed.reverse()) {
      await step.compensate(ctx).catch((err) =>
        logger.error({ step: step.name, err }, 'Compensation failed'),
      );
    }
  }
}
```

---

## Service Mesh & Observability

**When to use a service mesh** (Istio, Linkerd): more than 5 services with mTLS requirements, traffic management needs (canary, mirroring), or when you need consistent observability without modifying application code. Below 5 services, application-level libraries (circuit breakers, retries) are simpler.

**Correlation ID propagation**: every request entering the system gets a correlation ID (W3C `traceparent` header). Every service propagates this ID to downstream calls and includes it in log entries.

```typescript
// Correlation ID middleware
function correlationMiddleware(req: Request, _res: Response, next: NextFunction): void {
  const traceId = req.headers['traceparent']
    ?? `00-${crypto.randomUUID().replace(/-/g, '')}-${crypto.randomBytes(8).toString('hex')}-01`;
  req.traceId = traceId;
  next();
}
```

**Health checks**: every service exposes `/healthz` (liveness) and `/readyz` (readiness). Readiness checks verify downstream dependencies (database, cache). Liveness checks verify the process is running — never check dependencies in liveness probes.

---

## Anti-Patterns

- **Distributed monolith** — services that must deploy together defeat the purpose; if changing service A requires changing service B, they are one service
- **Shared database** — services reading/writing the same tables creates hidden coupling; use event-carried state transfer instead
- **Chatty interfaces** — N+1 calls between services; aggregate at the boundary, use batch endpoints or BFF
- **Synchronous chains** — A calls B calls C calls D synchronously; one slow service cascades into total failure
- **Entity services** — CRUD services per database table (UserService, OrderService) instead of bounded contexts with business capabilities
- **Missing circuit breakers** — every external call without a circuit breaker is an availability risk; one dependency down takes everything down
- **Premature decomposition** — splitting before understanding domain boundaries creates wrong boundaries that are expensive to fix

---

## For Claude Code

When designing microservices: apply DDD bounded contexts for service boundaries — never decompose by technical layer. Use database-per-service pattern with no shared tables. Generate gRPC for internal service communication, REST for external APIs. Implement saga pattern (prefer choreography for simple flows, orchestration for 4+ steps) for distributed transactions. Add circuit breakers on every external call with 5s timeout, 3 failure threshold. Include correlation ID middleware that propagates trace context via W3C headers. Never generate synchronous call chains deeper than 2 hops. Reference `microservices-patterns/SKILL.md` for implementation details, `event-driven-architecture/SKILL.md` for async patterns, `observability/SKILL.md` for distributed tracing, `api-design/SKILL.md` for API contracts.

---

*Internal references*: `microservices-patterns/SKILL.md`, `event-driven-architecture/SKILL.md`, `api-design/SKILL.md`, `observability/SKILL.md`
