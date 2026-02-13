---
name: microservices-patterns
cluster: architecture-patterns
description: "Microservices patterns for service decomposition, inter-service communication, and operational concerns. Bounded contexts, database per service, CQRS, API gateway, distributed tracing, and resilience. Use when designing service boundaries, choosing communication patterns, or operating distributed systems."
---

# Microservices Patterns

> **Version**: 1.3.0 | **Last updated**: 2026-02-13

## Purpose

Microservices architecture as a set of deliberate decomposition and communication patterns. Services are organized around business capabilities, own their data, and communicate through well-defined contracts. The goal is independent deployability and team autonomy — not small services for their own sake.

---

## Service Decomposition

### Bounded Context Identification

Services align with DDD bounded contexts. A bounded context is a boundary within which a domain model is consistent and a ubiquitous language applies. Identify bounded contexts by mapping domain events: where the language changes, the boundary lives.

**Heuristics for finding boundaries**:
- Different teams talk about the same concept differently (an "order" means different things to billing vs shipping)
- A change in one area should not require a change in another
- Data ownership is clear — one service is the source of truth for a given entity

**Domain event mapping**: list all domain events, group them by the aggregate that produces them. Each group is a candidate bounded context.

```
Bounded Context: Invoicing
  Events: invoice.created, invoice.sent, invoice.paid, invoice.overdue
  Owns: invoices, line items, payment terms

Bounded Context: Identity
  Events: user.registered, user.suspended, user.role-changed
  Owns: users, roles, permissions, sessions
```

### Autonomy Principle

Each service owns its data and its deployment pipeline. No service can directly access another service's database. No shared libraries that contain business logic (shared infrastructure libraries are acceptable). A service must be deployable independently without coordinating with other teams.

### Size Heuristic

A service is the right size when a single team (5-8 people) can understand it fully, it can be rewritten in two weeks if needed, it has a clear, single responsibility that maps to a business capability, and its API surface is small enough to document on one page.

---

## Inter-Service Communication

### Decision Matrix

| Criterion | Synchronous (REST/gRPC) | Asynchronous (Events) |
|-----------|------------------------|----------------------|
| Client needs immediate response | Yes | No |
| Operation can be eventually consistent | No | Yes |
| High throughput, low latency (internal) | gRPC | Events for fire-and-forget |
| Public-facing API | REST | Webhooks for notifications |
| Complex multi-step workflow | Orchestration (sync calls) | Choreography (events) |
| Failure isolation required | No (caller affected) | Yes (producer unaffected) |

### Synchronous: REST and gRPC

**REST** for public APIs and simple internal queries. Follow conventions from `api-design/SKILL.md`.

**gRPC** for internal service-to-service calls with high throughput requirements. Benefits: strong typing via Protocol Buffers, HTTP/2 multiplexing, streaming support, code generation for client and server.

```typescript
// Generated gRPC TypeScript client usage
import { UserServiceClient } from './generated/user-service';

async function getUser(userId: string): Promise<User> {
  const client = new UserServiceClient('user-service:50051', grpc.credentials.createInsecure());
  return new Promise((resolve, reject) => {
    client.getUser({ userId }, (error, response) => {
      if (error) reject(new ServiceCallError('user-service', 'GetUser', error));
      else resolve(response);
    });
  });
}
```

### Asynchronous: Events and Commands

**Events** (notification of something that happened): use for decoupled communication where the producer does not care who consumes the event. See `event-driven-architecture/SKILL.md` for CloudEvents format, outbox pattern, and saga patterns.

**Commands** (instruction to do something): use for directed async communication where a specific service must act. Commands are point-to-point, not broadcast.

```typescript
// Event: "this happened" — any number of consumers
await publishEvent('invoicing.invoice.created', invoiceData, context);

// Command: "do this" — one specific consumer
await publishCommand('payments.charge', { invoiceId, amount }, context);
```

---

## Database per Service

Each service owns its database. No shared databases. This is non-negotiable for service autonomy.

### Data Duplication Strategy

When service B needs data owned by service A, service B subscribes to events from A and maintains a local read-optimized copy. Data duplication is acceptable — it is the cost of autonomy and independent scalability.

```typescript
// Order service maintains a local copy of product data via events
async function handleProductUpdated(event: DomainEvent<ProductData>): Promise<void> {
  await db.insert(localProducts)
    .values({ productId: event.data.productId, name: event.data.name, price: event.data.price, updatedAt: new Date(event.time) })
    .onConflictDoUpdate({
      target: localProducts.productId,
      set: { name: event.data.name, price: event.data.price, updatedAt: new Date(event.time) },
    });
}
```

### Cross-Service Queries

Never join across service databases. Two patterns:

**API Composition**: the caller queries multiple services and merges the results. Simple but introduces runtime coupling.

**CQRS Read Model**: a dedicated query service subscribes to events from multiple services and builds a denormalized read model optimized for the query. Preferred for complex cross-domain queries.

---

## CQRS (Command Query Responsibility Segregation)

Separate the write model (processes commands, enforces invariants, emits domain events) from the read model (projects events into query-optimized views).

### When to Use CQRS

- Read and write workloads have very different scaling needs (high read/write asymmetry)
- Query requirements are complex (multiple aggregations, joins across contexts)
- Different consumers need different views of the same data

### When to Avoid CQRS

- Simple CRUD with predictable access patterns — CQRS adds unnecessary complexity
- The domain has no meaningful invariants to protect on the write side
- The team is small and the system is young — start simple, evolve to CQRS when needed

### Implementation

```typescript
// Write side: command handler enforces business rules
async function handleCreateInvoice(command: CreateInvoiceCommand): Promise<string> {
  const tenant = await tenantRepository.findById(command.tenantId);
  if (!tenant.isActive) throw new BusinessRuleError('TENANT_INACTIVE', 'Cannot create invoice for inactive tenant');

  const invoice = Invoice.create(command);
  await invoiceRepository.save(invoice);

  // Emit domain event for read side projection
  await publishEvent('invoicing.invoice.created', invoice.toEventData(), command.context);
  return invoice.id;
}

// Read side: projection builds denormalized view
async function projectInvoiceCreated(event: DomainEvent<InvoiceCreatedData>): Promise<void> {
  await db.insert(invoiceReadModel).values({
    invoiceId: event.data.invoiceId,
    tenantId: event.tenantid,
    customerName: event.data.customerName,
    totalAmount: event.data.amount.value,
    currency: event.data.amount.currency,
    status: 'draft',
    createdAt: new Date(event.time),
  });
}

// Query side: optimized reads against denormalized model
async function listInvoices(tenantId: string, filters: InvoiceFilters): Promise<PaginatedResult<InvoiceView>> {
  return db
    .select()
    .from(invoiceReadModel)
    .where(and(
      eq(invoiceReadModel.tenantId, tenantId),
      filters.status ? eq(invoiceReadModel.status, filters.status) : undefined,
    ))
    .orderBy(desc(invoiceReadModel.createdAt))
    .limit(filters.pageSize)
    .offset(filters.page * filters.pageSize);
}
```

---

## Service Discovery and Load Balancing

### Cloud-Native Service Discovery

On Cloud Run and Kubernetes, service discovery is handled by the platform. **Cloud Run**: services addressable by URL, use service-to-service authentication with IAM. **Kubernetes**: services addressable by DNS (`http://<service>.<namespace>.svc.cluster.local`), use Service resources for load balancing.

### Health Checks

Every service exposes three health endpoints:

```typescript
// Liveness (/healthz): is the process alive? Failure triggers restart.
app.get('/healthz', (_req, res) => res.status(200).json({ status: 'alive' }));

// Readiness (/readyz): can the service handle traffic? Failure removes from load balancer.
app.get('/readyz', async (_req, res) => {
  const dbOk = await checkDatabaseConnection();
  const cacheOk = await checkCacheConnection();
  const status = dbOk && cacheOk ? 200 : 503;
  res.status(status).json({ status: status === 200 ? 'ready' : 'not ready', checks: { db: dbOk, cache: cacheOk } });
});

// Startup (/startupz): has initialization finished? Failure delays liveness checks.
app.get('/startupz', (_req, res) => {
  res.status(serviceInitialized ? 200 : 503).json({ status: serviceInitialized ? 'started' : 'starting' });
});
```

---

## API Gateway Pattern

### Single Entry Point

An API gateway sits between external clients and internal services. It handles cross-cutting concerns so individual services do not have to.

**Responsibilities**: request routing to the correct backend service, authentication and token validation, rate limiting per client/tier, request/response transformation, TLS termination, request logging and correlation ID injection.

### Backend for Frontend (BFF)

A BFF is a lightweight API layer tailored to a specific client type. Each client (web, mobile, third-party) gets its own BFF that aggregates and shapes data from backend services.

```typescript
// Web BFF: aggregates data for the dashboard view
app.get('/api/web/v1/dashboard', authMiddleware, async (req, res) => {
  const tenantId = req.auth.tenantId;

  // Parallel calls to backend services
  const [invoices, payments, customers] = await Promise.all([
    invoiceService.getRecentInvoices(tenantId, { limit: 5 }),
    paymentService.getPaymentSummary(tenantId),
    customerService.getActiveCount(tenantId),
  ]);

  // Shape response for web dashboard
  res.json({
    recentInvoices: invoices.map(toInvoiceSummary),
    paymentSummary: payments,
    activeCustomers: customers.count,
  });
});
```

**Rules**: one BFF per client type. Do not share a BFF across web and mobile — their data needs diverge over time. BFFs contain only aggregation and transformation logic, never business rules.

---

## Distributed Tracing

### Correlation ID Propagation

Every request entering the system receives a correlation ID. This ID is propagated through every synchronous call and every async event. All logs, metrics, and traces reference this ID.

```typescript
import { context, trace, propagation } from '@opentelemetry/api';

// Middleware: extract or create correlation ID, attach to OpenTelemetry span
function tracingMiddleware(req: Request, _res: Response, next: NextFunction): void {
  const correlationId = req.headers['x-correlation-id'] as string ?? generateCorrelationId();
  req.correlationId = correlationId;

  const span = trace.getTracer('api-gateway').startSpan(`${req.method} ${req.path}`);
  span.setAttribute('correlation.id', correlationId);
  span.setAttribute('tenant.id', req.auth?.tenantId ?? 'anonymous');
  next();
}

// Propagate OpenTelemetry context when calling downstream services
async function callService(url: string, options: RequestInit): Promise<Response> {
  const headers: Record<string, string> = {};
  propagation.inject(context.active(), headers);
  return fetch(url, { ...options, headers: { ...options.headers, ...headers } });
}
```

### Trace Sampling Strategy

Not every request needs a full trace. Sampling strategies:

| Strategy | When to Use |
|----------|-------------|
| Always sample | Development and staging environments |
| Rate-based (e.g., 10%) | High-traffic production services |
| Error-based (100% on error) | Always trace failed requests for debugging |
| Tail-based | Sample based on outcome — trace slow or errored requests after completion |

For detailed instrumentation patterns, see `observability/SKILL.md`.

---

## Anti-Patterns

- **Distributed monolith**: services that must be deployed together, share a database, or have tight synchronous coupling — you get the complexity of microservices with none of the benefits
- **Shared database**: two services reading from or writing to the same database tables — breaks autonomy, creates hidden coupling, makes independent deployment impossible
- **Chatty services**: a single user request triggers 10+ inter-service calls — indicates wrong service boundaries. Redesign to reduce cross-service communication
- **Synchronous chains**: service A calls B, which calls C, which calls D — latency compounds, failure cascades. Use async events or restructure boundaries
- **Nano-services**: services so small they have no meaningful business logic — increases operational overhead without benefit. A service should represent a business capability, not a single function
- **Entity services**: services organized around database entities (UserService, ProductService) rather than business capabilities (Identity, Catalog) — leads to anemic services that are just CRUD wrappers
- **Shared business logic libraries**: a library containing domain logic used by multiple services — creates hidden coupling. Shared infrastructure (logging, auth middleware) is acceptable; shared domain logic is not

---

## For Claude Code

When designing microservices: start by identifying bounded contexts through domain event mapping before drawing service boundaries. Default to async communication via events; use sync calls only when the caller needs an immediate response. Every service gets its own database — no exceptions. Include health check endpoints (liveness, readiness, startup) in every service. Propagate correlation IDs through all synchronous calls and async events. Use the API Gateway pattern for external traffic and BFF for client-specific aggregation. Generate gRPC definitions for internal high-throughput communication, REST for public APIs. When cross-service queries are needed, implement CQRS with event-sourced read models rather than direct cross-service API calls. Always include circuit breaker and retry logic in synchronous service-to-service calls. Document service boundaries and communication patterns in an ADR.

---

*Internal references*: `event-driven-architecture/SKILL.md`, `api-design/SKILL.md`, `error-handling-resilience/SKILL.md`, `observability/SKILL.md`
