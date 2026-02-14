---
name: database-optimizer
cluster: data-architecture
description: "Database performance optimization for PostgreSQL and MySQL. Query analysis, execution plans, index design, partitioning, connection pooling, lock contention. Use when investigating slow queries, designing index strategies, tuning database configuration, or resolving performance bottlenecks."
---

# Database Optimizer

> **Version**: 1.3.0 | **Last updated**: 2026-02-14

## Purpose

Database performance is the foundation of application performance — most latency originates in the data layer. Systematic optimization using execution plans and metrics prevents the two failure modes: premature optimization without measurement, and reactive firefighting after users notice slowness.

---

## Query Analysis Workflow

Always start with measurement. Never optimize based on intuition.

```sql
-- Step 1: Identify slow queries from pg_stat_statements
SELECT query, mean_exec_time, calls, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Step 2: Analyze execution plan
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT i.id, i.amount, t.name
FROM invoices i
JOIN tenants t ON t.id = i.tenant_id
WHERE i.tenant_id = 'tenant_abc'
  AND i.status = 'overdue'
  AND i.created_at > NOW() - INTERVAL '90 days'
ORDER BY i.created_at DESC
LIMIT 50;
```

**Key signals in EXPLAIN output:**

| Signal | Meaning | Action |
|--------|---------|--------|
| Seq Scan on large table | Missing index | Add targeted index |
| Nested Loop with high rows | Bad join strategy | Check join columns are indexed |
| Sort with external merge | Insufficient work_mem | Increase work_mem or add index matching ORDER BY |
| Hash Join batches > 0 | Insufficient work_mem | Increase work_mem for session |
| Rows estimated vs actual diverge | Stale statistics | Run ANALYZE on table |

---

## Index Design

Rules: index columns in WHERE, JOIN, ORDER BY. Composite index column order matters — **most selective column first**.

```sql
-- Composite index for multi-tenant queries (tenant_id first for isolation)
CREATE INDEX CONCURRENTLY idx_invoices_tenant_status_created
ON invoices (tenant_id, status, created_at DESC);

-- Partial index for filtered queries (smaller, faster)
CREATE INDEX CONCURRENTLY idx_invoices_overdue
ON invoices (tenant_id, created_at)
WHERE status = 'overdue';

-- Covering index to avoid table heap lookup
CREATE INDEX CONCURRENTLY idx_invoices_covering
ON invoices (tenant_id, status) INCLUDE (amount, created_at);
```

**Index type selection:**

| Type | Use Case | Example |
|------|----------|---------|
| B-tree | Equality, range, sorting (default) | `WHERE tenant_id = $1 AND created_at > $2` |
| GIN | Full-text search, JSONB, arrays | `WHERE tags @> ARRAY['urgent']` |
| GiST | Geometric, range types, nearest-neighbor | `WHERE location <-> point(x,y) < 1000` |
| BRIN | Large tables with natural ordering (time-series) | `WHERE created_at BETWEEN $1 AND $2` on append-only table |

**Monitor unused indexes** — they slow writes for zero benefit:

```sql
SELECT indexrelname, idx_scan, pg_size_pretty(pg_relation_size(indexrelid))
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## Connection Pooling

Each PostgreSQL connection costs ~10MB RAM. Use PgBouncer or application-level pooling for > 50 concurrent connections.

**Pool size formula:** `pool_size = max(10, vCPU * 2)`

```typescript
// Drizzle ORM with connection pool (Node.js)
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: Math.max(10, Number(process.env.VCPU_COUNT ?? 2) * 2),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

export const db = drizzle(pool);
```

---

## Partitioning

Partition when table exceeds **100M rows** or **50GB**. Partitioning improves query performance (partition pruning), maintenance (VACUUM per partition), and data lifecycle (drop old partitions instantly).

```sql
-- Range partition by date for time-series data
CREATE TABLE events (
  id         UUID DEFAULT gen_random_uuid(),
  tenant_id  UUID NOT NULL,
  event_type TEXT NOT NULL,
  payload    JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE events_2026_01 PARTITION OF events
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE events_2026_02 PARTITION OF events
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

-- For multi-tenant isolation: list partition by tenant_id
CREATE TABLE tenant_data (
  id        UUID DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL,
  data      JSONB
) PARTITION BY LIST (tenant_id);

CREATE TABLE tenant_data_abc PARTITION OF tenant_data
  FOR VALUES IN ('tenant_abc');
```

---

## Lock Contention

| Issue | Symptom | Fix |
|-------|---------|-----|
| Long transactions | `pg_stat_activity` shows idle in transaction | Set `idle_in_transaction_session_timeout = 30s` |
| Missing index on FK | Seq Scan during CASCADE DELETE | Add index on FK column |
| DDL during traffic | ACCESS EXCLUSIVE lock blocks all queries | Use `CONCURRENTLY`, run during low traffic |
| Hot rows | Multiple transactions updating same row | Redesign schema or use advisory locks |
| Lock queue buildup | Queries waiting behind DDL lock | Set `lock_timeout = 5s` to fail fast |

**Diagnose active locks:**

```sql
SELECT blocked.pid, blocked.query, blocking.pid AS blocking_pid, blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_locks bl ON bl.pid = blocked.pid
JOIN pg_locks kl ON kl.locktype = bl.locktype AND kl.relation = bl.relation AND kl.pid != bl.pid
JOIN pg_stat_activity blocking ON blocking.pid = kl.pid
WHERE NOT bl.granted;
```

---

## Anti-Patterns

1. **Optimizing without measuring** — adding indexes or rewriting queries without EXPLAIN ANALYZE baseline is guessing, not engineering
2. **Over-indexing** — every index slows writes and consumes storage; unused indexes (check `pg_stat_user_indexes`) are pure cost
3. **SELECT \*** — fetches all columns including BLOBs, prevents covering index optimization; always specify needed columns
4. **Missing CONCURRENTLY** — `CREATE INDEX` without `CONCURRENTLY` locks the table for writes; on a 100M row table this means minutes of downtime
5. **N+1 queries** — loading 100 invoices then issuing 100 queries for tenant names; use JOINs or batch loading
6. **Ignoring VACUUM** — dead tuples accumulate, table bloat grows, sequential scans slow down; configure autovacuum aggressively for high-write tables
7. **Connection pool exhaustion** — application opens connections without pooling; each PostgreSQL connection costs ~10MB RAM; use PgBouncer for > 50 concurrent connections

---

## For Claude Code

When optimizing database queries: always start with `EXPLAIN (ANALYZE, BUFFERS)` output before suggesting changes. Generate composite indexes with most selective column first, use `CONCURRENTLY` for production index creation, use partial indexes for filtered queries. Never generate `SELECT *` — always specify columns. For multi-tenant queries, ensure `tenant_id` is the leading column in every composite index. Generate connection pool configuration with pool size formula `max(10, vCPU * 2)`. When partitioning, use range partition by date for time-series data, list partition by `tenant_id` for multi-tenant isolation. Include `pg_stat_statements` setup for query monitoring. Always check for unused indexes before adding new ones.

*Internal references*: `data-modeling/SKILL.md`, `observability/SKILL.md`, `performance-testing/SKILL.md`, `caching-search/SKILL.md`
