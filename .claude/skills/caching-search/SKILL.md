---
name: caching-search
description: "Distributed caching and full-text search patterns. Cache-aside, write-through, invalidation strategies, Redis, PostgreSQL FTS, Elasticsearch. Use when adding caching layers, implementing search, or optimizing read-heavy workloads."
---

# Caching & Search

## Purpose

Patterns for distributed caching and full-text search. When to introduce them, how to manage them, how to invalidate them.

---

## Caching

### When to Introduce Cache

Cache is added complexity (invalidation, stale data, harder debugging). Introduce only when: there's a measured bottleneck (latency or query cost), the data is read much more than written (read/write ratio > 10:1), stale data tolerance is acceptable for the use case.

### Patterns

**Cache-Aside (Lazy Loading)**: application code manages the cache. Read: check cache → miss → query DB → write cache. Write: write DB → invalidate cache. Default for most cases.

**Write-Through**: code writes to both cache and DB. Cache is always up-to-date. Write overhead. Use when cache-DB consistency is critical.

**Write-Behind (Write-Back)**: code writes to cache, cache writes to DB async. Maximum write performance, risk of data loss if cache crashes. Use only for loss-tolerant data (analytics, non-critical counters).

### GCP Implementation

**Memorystore (Redis)**: managed distributed cache. For sessions, rate limiting, shared application cache between Cloud Run instances.

**In-memory (process)**: LRU Map for L1 local cache. For immutable or near-immutable data (configurations, feature flags). No additional infrastructure cost.

**Cloud CDN**: for cacheable HTTP responses. `Cache-Control: public, max-age=3600` for static resources. `Cache-Control: private, max-age=60` for user-specific API data.

### Invalidation

The hardest caching problem. Strategies: TTL-based (data expires after N seconds — simple, stale-tolerant), event-based (when a domain event indicates data changed, invalidate cache — more precise, more complex), version-based (data has a version, cache checks if version is current).

Rule: use TTL as baseline (every cache entry has a TTL), add active invalidation only where stale tolerance is low.

---

## Search

### When You Need a Search Engine

When database queries aren't enough: full-text search with relevance ranking, fuzzy matching and typo tolerance, faceted search (filter by category, price, date), search across unstructured documents.

### GCP Options

**Firestore query**: sufficient for simple filters and exact field search. Does not support full-text search.

**Cloud SQL (PostgreSQL) full-text search**: `tsvector` + `tsquery` for full-text search integrated in the relational database. Good compromise for moderate volume (< 10M documents). No additional infrastructure.

**Elasticsearch / OpenSearch**: for advanced search, high volume, custom scoring. Separate infrastructure. Use only when PostgreSQL FTS isn't enough.

**Typesense / Meilisearch**: lightweight, developer-friendly alternatives to Elasticsearch. Simpler to operate, less flexible. Good choice for product catalog search, documentation search.

### Multi-Tenant Search

tenant_id is always a mandatory filter in search queries. Never return cross-tenant results. If using Elasticsearch: one index per tenant (strong isolation) or tenant_id filter on every query (more efficient, less isolated — like row-level for databases).

---

## For Claude Code

When introducing caching: justify with performance metric, TTL on every entry, cache-aside as default, test that system works with empty cache (cold start). When introducing search: PostgreSQL FTS as first attempt, Elasticsearch only if insufficient. Always tenant_id filter.

---

*Internal references*: `backend-performance.md`, `data-modeling.md`, `cloud-architecture.md`
