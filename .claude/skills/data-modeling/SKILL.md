---
name: data-modeling
cluster: data-architecture
description: "Schema design, multi-tenant data isolation, and migration management. Firestore and PostgreSQL patterns, RLS, UUID v7 conventions. Use when designing database schemas, writing migrations, or implementing multi-tenant data access."
---

# Data Modeling & Storage

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

Schema design, multi-tenant data isolation strategies, and migration management. Database-agnostic in principles, with specific guidance for Firestore and PostgreSQL.

---

## Schema Design

### Firestore (document-oriented)

Think in terms of queries, not normalization. Data model is optimized for read patterns. Denormalization is normal and expected.

Collection structure: `tenants/{tenantId}/invoices/{invoiceId}`. The tenantId in the path guarantees natural isolation with Firestore Security Rules.

Rules: documents < 1MB (Firestore limit), avoid unbounded arrays (use subcollections), one document per "read unit" (if you always read invoice + line items together, consider embedded; if you read items separately, use subcollection).

### PostgreSQL (relational)

Third normal form as starting point, denormalize only on measured bottlenecks. Every table has: `id` (UUID v7 — chronologically sortable), `tenant_id` (FK, indexed, present in every query), `created_at`, `updated_at` (automatic timestamps).

Row-Level Security (RLS) for tenant isolation at database level:

```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoices
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
```

### Indexing Strategy

Create indexes for: every foreign key column, every column in WHERE clauses, columns used in ORDER BY with LIMIT. Use composite indexes for multi-column filters (tenant_id + status is more useful than separate indexes on each).

```sql
-- Covering index for common query pattern
CREATE INDEX idx_invoices_tenant_status_created
  ON invoices (tenant_id, status, created_at DESC);

-- Partial index for active records only
CREATE INDEX idx_invoices_tenant_active
  ON invoices (tenant_id, created_at DESC)
  WHERE status NOT IN ('void', 'deleted');
```

Monitor with `pg_stat_user_indexes` — drop unused indexes (they slow writes for no read benefit).

### Firestore Composite Indexes

Firestore requires explicit composite indexes for queries combining equality and range filters:

```
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "invoices",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

Commit `firestore.indexes.json` to repo. Deploy with `firebase deploy --only firestore:indexes`.

### Connection Pooling

For PostgreSQL with Cloud Run (many short-lived connections): use pgBouncer or Cloud SQL Auth Proxy with connection pooling.

```typescript
// Drizzle + pg with pool configuration
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,              // per-instance pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

export const db = drizzle(pool);
```

Rule of thumb: `max_connections = (Cloud Run max instances × pool size per instance) + headroom`. Never exceed PostgreSQL `max_connections` (default 100).

### Time Zone Handling

Store all timestamps as UTC (`timestamptz` in PostgreSQL). Convert to user's time zone only at presentation layer. Never use `timestamp without time zone` for user-facing data.

---

## Multi-Tenant Data Isolation

### Patterns by Isolation Level

**Shared database, shared schema (row-level)**: one database, one schema, tenant_id on every row. Minimum cost, maximum density. Risk: code bugs can expose cross-tenant data. Mitigation: RLS in PostgreSQL, Security Rules in Firestore, automated isolation tests.

**Shared database, schema-per-tenant**: one database, one PostgreSQL schema per tenant. Stronger isolation, more complex schema management. Good compromise for B2B SaaS with tens-to-hundreds of tenants.

**Database-per-tenant**: maximum isolation, maximum cost. For enterprise clients with strict regulatory requirements. High operational complexity.

Choice depends on risk profile and tenant count. Record in ADR.

---

## Migration Strategy

### Principles

**Forward-only**: every migration is a step forward. Never modify already-applied migrations. If correction is needed, create a new migration.

**Backward-compatible**: every migration must be compatible with the code version currently in production. Enables zero-downtime deploys.

**Column removal example** (backward-compatible): Release N: stop writing to column, continue reading (fallback). Release N+1: stop reading. Release N+2: remove column from database.

**Expand/Contract example** (renaming a column):
```sql
-- Release N (expand): add new column, backfill
ALTER TABLE invoices ADD COLUMN recipient_name VARCHAR(255);
UPDATE invoices SET recipient_name = customer_name WHERE recipient_name IS NULL;

-- Release N+1: application reads from recipient_name, writes to both
-- Release N+2 (contract): drop old column
ALTER TABLE invoices DROP COLUMN customer_name;
```

### Outbox Table Pattern

For reliable event publishing alongside database writes (see `event-driven-architecture/SKILL.md`):

```sql
CREATE TABLE outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_type VARCHAR(100) NOT NULL,  -- e.g. 'invoice'
  aggregate_id UUID NOT NULL,
  event_type VARCHAR(100) NOT NULL,      -- e.g. 'invoicing.invoice.created'
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ              -- NULL until published
);

CREATE INDEX idx_outbox_unpublished ON outbox (created_at) WHERE published_at IS NULL;
```

A poller or CDC (Change Data Capture) reads unpublished rows and publishes to Pub/Sub, then marks `published_at`. This guarantees atomicity between the database write and the event publish.

### Tooling

For PostgreSQL: Drizzle Kit or Prisma Migrate (consistent with chosen ORM). Migration files versioned in repo, executed in CI/CD.

### Drizzle Migration Example

```typescript
// drizzle/schema/invoices.ts
import { pgTable, uuid, varchar, decimal, timestamp, index } from 'drizzle-orm/pg-core';

export const invoices = pgTable('invoices', {
  id: uuid('id').primaryKey().defaultRandom(),   // UUID v7 preferred
  tenantId: uuid('tenant_id').notNull(),
  invoiceNumber: varchar('invoice_number', { length: 50 }).notNull(),
  customerName: varchar('customer_name', { length: 255 }).notNull(),
  totalAmount: decimal('total_amount', { precision: 12, scale: 2 }).notNull(),
  currency: varchar('currency', { length: 3 }).notNull().default('EUR'),
  status: varchar('status', { length: 20 }).notNull().default('draft'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdx: index('idx_invoices_tenant').on(table.tenantId),
  tenantStatusIdx: index('idx_invoices_tenant_status').on(table.tenantId, table.status),
}));

// Generate migration: npx drizzle-kit generate
// Apply migration: npx drizzle-kit migrate
```

### UUID v7 Generation

UUID v7 is chronologically sortable (timestamp-based), making it ideal for primary keys with B-tree indexes:

```typescript
import { uuidv7 } from 'uuidv7';

// Usage in entity creation
const invoice = {
  id: uuidv7(),  // e.g., '01903c6a-7e4b-7000-8000-4b6a3f2e1d0c'
  tenantId: context.tenantId,
  // ...
};
```

UUID v7 advantages over v4: sortable by creation time (better index locality), no need for separate `created_at` index for ordering, and compatible with all UUID-accepting systems.

For Firestore: no traditional migrations. Use idempotent data migration scripts. Version implicit schema in a `schema-version.ts` file with Zod validation.

---

## Backup & Recovery

Firestore: automatic daily backup (export to Cloud Storage). Point-in-time recovery with PITR (if enabled).

PostgreSQL: automatic Cloud SQL backup (daily, 7-day retention default — extend for production). Point-in-time recovery. Periodic restore test (monthly) — an untested backup is not a backup.

---

## Anti-Patterns

- **Entity-Attribute-Value (EAV) tables**: `key/value` rows instead of proper columns destroy type safety, query performance, and indexing. Use JSONB columns for truly dynamic attributes.
- **God tables**: one table with 50+ columns covering multiple domains. Split by bounded context.
- **Soft deletes everywhere**: `deleted_at IS NULL` on every query is error-prone and bloats tables. Use soft deletes only when audit or undo requires it. Otherwise, hard delete with audit log.
- **Missing tenant_id in indexes**: every query in a multi-tenant system filters by `tenant_id` — if it's not in the index, it's a full scan.
- **No migration testing**: migrations that work on empty databases but fail on production data. Test migrations against a production-like dataset.

---

## DDD Concepts for Data Modeling

### Aggregates

An aggregate is a cluster of domain objects treated as a unit for data changes. The aggregate root is the entry point. Example: `Invoice` is the aggregate root, `LineItem` is part of the aggregate. External entities reference only the aggregate root ID, never internal entities.

### Bounded Contexts

Each bounded context has its own data model. The same real-world concept (e.g., "User") may have different representations in different contexts. Don't force a single shared schema across contexts — use context mapping (events, APIs) instead.

### Value Objects

Immutable objects defined by their attributes, not identity. Example: `Money(100, 'EUR')` — two Money objects with the same amount and currency are equal. Store as embedded columns, not separate tables:

```typescript
// Value object in Drizzle schema
const invoices = pgTable('invoices', {
  // ... other fields
  amountValue: decimal('amount_value', { precision: 12, scale: 2 }).notNull(),
  amountCurrency: varchar('amount_currency', { length: 3 }).notNull(),
});
```

---

## For Claude Code

When generating schemas: tenant_id on every entity (Firestore: in collection path, PostgreSQL: indexed column), UUID v7 for IDs, automatic timestamps, backward-compatible migrations. Generate Zod validation for Firestore document schemas. Generate RLS policies for multi-tenant PostgreSQL.

---

*Internal references*: `compliance-privacy/SKILL.md`, `event-driven-architecture/SKILL.md`, `authn-authz/SKILL.md`
