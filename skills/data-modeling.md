---
skill: data-modeling
version: 1.0.0
last-updated: 2026-02-08
domain: data-architecture
depends-on: [architectural-principles, domain-modeling, compliance]
---

# Data Modeling & Storage

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

### Tooling

For PostgreSQL: Drizzle Kit or Prisma Migrate (consistent with chosen ORM). Migration files versioned in repo, executed in CI/CD.

For Firestore: no traditional migrations. Use idempotent data migration scripts. Version implicit schema in a `schema-version.ts` file with Zod validation.

---

## Backup & Recovery

Firestore: automatic daily backup (export to Cloud Storage). Point-in-time recovery with PITR (if enabled).

PostgreSQL: automatic Cloud SQL backup (daily, 7-day retention default — extend for production). Point-in-time recovery. Periodic restore test (monthly) — an untested backup is not a backup.

---

## For Claude Code

When generating schemas: tenant_id on every entity (Firestore: in collection path, PostgreSQL: indexed column), UUID v7 for IDs, automatic timestamps, backward-compatible migrations. Generate Zod validation for Firestore document schemas. Generate RLS policies for multi-tenant PostgreSQL.

---

*Internal references*: `domain-modeling.md`, `compliance.md`, `event-driven.md`
