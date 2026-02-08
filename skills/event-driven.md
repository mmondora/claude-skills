---
skill: event-driven-architecture
version: 1.0.0
last-updated: 2026-02-08
domain: data-architecture
depends-on: [domain-modeling, backend-patterns, cloud-architecture]
---

# Event-Driven Architecture

## Purpose

Design of event-driven systems with CloudEvents as standard format, GCP Pub/Sub as backbone, and patterns for guaranteeing consistency, idempotency, and event evolvability.

---

## Event Design

### Naming

`<domain>.<entity>.<action-past-tense>`. Examples: `invoicing.invoice.created`, `identity.user.suspended`, `billing.payment.received`. The name is an immutable fact — once published, it never changes.

### Structure (CloudEvents)

```typescript
interface DomainEvent<T = Record<string, unknown>> {
  specversion: '1.0';
  id: string;                    // UUID v7
  type: string;                  // e.g. 'invoicing.invoice.created'
  source: string;                // e.g. '/services/invoice-api'
  time: string;                  // ISO-8601
  datacontenttype: 'application/json';
  tenantid: string;              // CloudEvents extension
  correlationid: string;
  causationid: string;
  data: T;
}
```

### Fat Events vs Thin Events

**Fat event** (default): contains all data needed for autonomous processing. Consumer doesn't need to call back to producer.

**Thin event** (notification): contains only resource ID and change type. Consumer must GET for details. Use only when payload is very large (> 256KB) or when 10+ consumers have different data needs.

---

## Schema Evolution

Events are public contracts. Changing an event schema is like changing an API — requires compatibility.

**Compatibility rules**: adding fields is always safe (consumers ignore unknown fields), removing fields requires deprecation period (field becomes optional, then removed after all consumers update), changing a field's type is a breaking change (requires new event type).

**Schema registry**: Zod schema per event type, versioned in repo. Producer validates event before publishing. Consumer validates on receipt. Schema mismatch → dead letter queue, not crash.

```typescript
const InvoiceCreatedV1 = z.object({
  invoiceId: z.string(),
  tenantId: z.string(),
  amount: z.object({ value: z.number(), currency: z.string() }),
  createdBy: z.string(),
  lineItems: z.array(z.object({
    description: z.string(),
    amount: z.number(),
    quantity: z.number(),
  })),
});
```

---

## Delivery Guarantees

**At-least-once** (Pub/Sub default): message may be delivered multiple times. Consumer MUST be idempotent. Use event ID as idempotency key.

**Ordering**: Pub/Sub doesn't guarantee global order. If ordering is needed, use ordering key (e.g., tenantId) — messages with the same ordering key are delivered in order.

**Dead Letter Queue (DLQ)**: after N failed retries, message goes to DLQ for manual analysis. Configure alerts on DLQ — messages there require action.

---

## Eventual Consistency

In an event-driven system, consistency between services is eventual, not immediate. This is an architectural trade-off to communicate explicitly to the business.

**UI patterns for eventual consistency**: show "processing" state for async operations, use optimistic updates for immediate feedback, polling or WebSocket for updates when event is processed.

---

## For Claude Code

When generating events: CloudEvents format, Zod schema for validation, idempotency check in consumer, configured DLQ, ordering key if order matters. Generate producer and consumer as separate modules with independent tests.

---

*Internal references*: `domain-modeling.md`, `backend-patterns.md`, `cloud-architecture.md`, `data-modeling.md`
