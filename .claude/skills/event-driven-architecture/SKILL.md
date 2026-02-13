---
name: event-driven-architecture
cluster: data-architecture
description: "Event-driven systems with CloudEvents and GCP Pub/Sub. Event design, schema evolution, delivery guarantees, idempotency, eventual consistency. Use when designing event systems, publishing/consuming events, or implementing async workflows."
---

# Event-Driven Architecture

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

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

## Pub/Sub Publisher & Subscriber Examples

### Publisher

```typescript
import { PubSub } from '@google-cloud/pubsub';
import { v7 as uuidv7 } from 'uuidv7';

const pubsub = new PubSub();

async function publishEvent<T>(topicName: string, type: string, data: T, context: EventContext): Promise<string> {
  const event: DomainEvent<T> = {
    specversion: '1.0',
    id: uuidv7(),
    type,
    source: '/services/invoice-api',
    time: new Date().toISOString(),
    datacontenttype: 'application/json',
    tenantid: context.tenantId,
    correlationid: context.correlationId,
    causationid: context.causationId ?? context.correlationId,
    data,
  };

  const messageId = await pubsub.topic(topicName).publishMessage({
    json: event,
    orderingKey: context.tenantId, // Order by tenant
  });

  logger.info({ eventType: type, messageId, tenantId: context.tenantId }, 'Event published');
  return messageId;
}
```

### Subscriber with Idempotency

```typescript
import { Message } from '@google-cloud/pubsub';

const processedEvents = new Set<string>(); // In production: use Redis or DB

async function handleMessage(message: Message): Promise<void> {
  const event: DomainEvent = JSON.parse(message.data.toString());

  // Idempotency check — skip already-processed events
  if (await isAlreadyProcessed(event.id)) {
    logger.info({ eventId: event.id }, 'Duplicate event — skipping');
    message.ack();
    return;
  }

  try {
    await processEvent(event);
    await markAsProcessed(event.id);
    message.ack();
  } catch (error) {
    logger.error({ eventId: event.id, error }, 'Event processing failed');
    message.nack(); // Will retry (up to DLQ threshold)
  }
}

async function isAlreadyProcessed(eventId: string): Promise<boolean> {
  // Redis: SETNX with TTL, or DB lookup
  const exists = await redis.get(`processed:${eventId}`);
  return exists !== null;
}

async function markAsProcessed(eventId: string): Promise<void> {
  await redis.set(`processed:${eventId}`, '1', { EX: 86400 }); // 24h TTL
}
```

---

## Transactional Outbox Pattern

The dual-write problem: writing to both database and message broker is not atomic. If the app crashes between the two writes, data is inconsistent.

**Solution**: write the event to an `outbox` table in the same database transaction as the business data. A separate process reads and publishes unpublished events.

```typescript
// Write business data + outbox entry in one transaction
async function createInvoice(data: CreateInvoiceInput, context: EventContext): Promise<Invoice> {
  return db.transaction(async (tx) => {
    const invoice = await tx.insert(invoices).values(data).returning();

    await tx.insert(outbox).values({
      aggregateType: 'invoice',
      aggregateId: invoice.id,
      eventType: 'invoicing.invoice.created',
      payload: { invoiceId: invoice.id, tenantId: data.tenantId, amount: data.amount },
    });

    return invoice;
  });
}

// Outbox poller (runs on schedule or CDC)
async function publishOutboxEvents(): Promise<number> {
  const unpublished = await db
    .select()
    .from(outbox)
    .where(isNull(outbox.publishedAt))
    .orderBy(outbox.createdAt)
    .limit(100);

  for (const event of unpublished) {
    await publishEvent(event.eventType, event.payload, { tenantId: event.payload.tenantId });
    await db.update(outbox).set({ publishedAt: new Date() }).where(eq(outbox.id, event.id));
  }

  return unpublished.length;
}
```

For the outbox table schema, see `data-modeling/SKILL.md`.

---

## Saga Patterns

For multi-step business processes spanning multiple services:

### Choreography (event-driven)

Each service listens for events and publishes its own. No central coordinator. Simpler but harder to track overall progress.

```
Order Created → [Payment Service] → Payment Processed → [Inventory Service] → Stock Reserved → [Shipping Service] → Shipment Scheduled
                                  → Payment Failed → [Order Service] → Order Cancelled (compensating action)
```

### Orchestration (command-driven)

A saga orchestrator sends commands and handles responses. Easier to understand and monitor, but introduces a single point of coordination.

```typescript
// Saga orchestrator
class CreateOrderSaga {
  async execute(order: Order): Promise<SagaResult> {
    try {
      await paymentService.charge(order.paymentDetails);
      await inventoryService.reserve(order.items);
      await shippingService.schedule(order.shippingAddress);
      return { status: 'completed' };
    } catch (error) {
      // Compensating actions in reverse order
      await shippingService.cancel(order.id).catch(logCompensationError);
      await inventoryService.release(order.items).catch(logCompensationError);
      await paymentService.refund(order.paymentDetails).catch(logCompensationError);
      return { status: 'compensated', error };
    }
  }
}
```

**Choose choreography** when: few steps (< 4), services are truly independent. **Choose orchestration** when: many steps, complex compensation logic, need visibility into saga state.

---

## Back-Pressure Handling

When a consumer can't keep up with the event rate:

- **Pub/Sub flow control**: configure `maxMessages` to limit concurrent processing per subscriber
- **Autoscaling consumers**: scale Cloud Run subscriber instances based on Pub/Sub message backlog
- **Rate limiting publisher**: if producer overwhelms consumers, add rate limiting at the source

```typescript
// Pub/Sub subscriber with flow control
const subscription = pubsub.subscription('invoice-events-sub', {
  flowControl: {
    maxMessages: 10,        // Process max 10 messages concurrently
    allowExcessMessages: false,
  },
  ackDeadline: 60,          // 60s to process before redelivery
});
```

---

## Event Replay

Ability to replay events for: new consumer bootstrap, bug fix reprocessing, data recovery.

Requirements: events stored durably (Pub/Sub retained messages or event store), consumers are idempotent (safe to replay), replay scoped by time range or event type.

Pub/Sub supports `seek` to replay messages from a snapshot or timestamp.

---

## Dead Letter Queue (DLQ) Configuration

```hcl
# Terraform — Pub/Sub topic with DLQ
resource "google_pubsub_subscription" "invoice_events" {
  name  = "invoice-events-sub"
  topic = google_pubsub_topic.invoice_events.name

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.invoice_events_dlq.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  ack_deadline_seconds = 60
}

resource "google_pubsub_topic" "invoice_events_dlq" {
  name = "invoice-events-dlq"
}
```

**DLQ monitoring**: alert when DLQ message count > 0. Every DLQ message represents a failed event that needs manual investigation or automated retry.

---

## Anti-Patterns

- **Dual writes without outbox**: writing to DB and publishing an event as separate operations — use the transactional outbox pattern
- **Synchronous event chains**: service A calls service B via event, then waits synchronously for the response — use request/reply pattern or direct API call instead
- **Unbounded retry**: retrying failed events forever without DLQ — always configure max delivery attempts
- **Event payload too large**: events > 256KB strain the message broker — use thin events with a reference for large data
- **Missing schema validation**: consuming events without validation — always validate with Zod on receipt

---

## For Claude Code

When generating events: CloudEvents format, Zod schema for validation, idempotency check in consumer, configured DLQ, ordering key if order matters. Use transactional outbox pattern for reliable event publishing. Generate producer and consumer as separate modules with independent tests. For multi-step workflows, document whether choreography or orchestration is used and why.

---

*Internal references*: `data-modeling/SKILL.md`, `observability/SKILL.md`, `infrastructure-as-code/SKILL.md`
