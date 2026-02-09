---
name: performance-testing
description: "Performance testing with k6 for SLO validation. Load, stress, soak, and spike tests. Use when writing performance tests, defining SLO thresholds, or validating system behavior under load."
---

# Performance Testing

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

Verify the system meets performance requirements under realistic load. Not benchmarking for its own sake — SLO validation.

---

## Test Types

**Load test**: verify behavior under expected load. Does the system handle 1000 req/s with p99 < 500ms? If yes, pass. If no, identify the bottleneck.

**Stress test**: increase load beyond expected to find the breaking point. At what load does the system degrade? How does it degrade (graceful vs crash)?

**Soak test**: constant load for extended periods (hours). Looking for memory leaks, connection leaks, gradual degradation.

**Spike test**: sudden load spike. How does autoscaling respond? How long to recover?

---

## Load Profile Calculation

Convert business requirements to technical load parameters:

```
1. Expected users (daily active): 10,000
2. Peak concurrent users: ~10% of daily = 1,000
3. Actions per user per session: ~20
4. Average session duration: 10 min
5. Requests per action: ~3 (page + API + assets)

Peak RPS = (concurrent users × actions per session × requests per action) / (session duration in seconds)
         = (1,000 × 20 × 3) / 600
         = 100 RPS

Test target: 100 RPS sustained, 300 RPS spike (3x peak)
```

Always derive load from business metrics, not arbitrary numbers.

---

## Tooling

**k6** (default): JavaScript scripts, excellent performance (written in Go), CI integration, standard metrics output. Perfect for Node.js backends.

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '5m', target: 50 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('https://api.example.com/api/v1/tenants/t_test/invoices');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

### k6 Custom Business Metrics

```javascript
import { Counter, Trend } from 'k6/metrics';

const invoicesCreated = new Counter('invoices_created');
const invoiceCreationTime = new Trend('invoice_creation_time');

export default function () {
  const start = Date.now();
  const res = http.post(
    'https://api.example.com/api/v1/tenants/t_test/invoices',
    JSON.stringify({ amount: 100, currency: 'EUR' }),
    { headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${TOKEN}` } }
  );
  if (res.status === 201) {
    invoicesCreated.add(1);
    invoiceCreationTime.add(Date.now() - start);
  }
}
```

---

## Results Interpretation

### Key Percentiles

| Percentile | Meaning | Target |
|------------|---------|--------|
| p50 (median) | Half of requests are faster | Baseline behavior |
| p95 | 95% of requests are faster | Primary SLO target |
| p99 | Only 1% are slower | Worst-case user experience |
| max | Single slowest request | Often an outlier — don't optimize for max |

**Read k6 output**: focus on `http_req_duration` p95 and p99, `http_req_failed` rate, and `iterations` (throughput). If p95 is good but p99 is 10x worse, investigate tail latency (GC pauses, cold starts, connection pool exhaustion).

### Red Flags

- p99/p95 ratio > 3x: tail latency problem
- Error rate increases with load: resource exhaustion (connections, memory, CPU)
- Latency increases linearly with load: missing index or O(n) operation
- Latency jumps at specific threshold: hitting a limit (connection pool, instance max)

---

## SLO Validation

Performance tests validate defined SLOs: availability (99.9%), latency (p95 < 500ms, p99 < 1000ms for standard APIs), throughput (N req/s per service), error rate (< 0.1% under normal load). Tests fail if SLOs are not met. This is a CI gate for production releases.

---

## Database Performance Profiling

### EXPLAIN ANALYZE

Profile slow queries directly:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM invoices
WHERE tenant_id = 't_abc' AND status = 'sent'
ORDER BY created_at DESC
LIMIT 20;
```

Look for: sequential scans on large tables (missing index), high buffer reads (cold cache), nested loops on large result sets.

### pg_stat_statements

Enable for production query profiling:

```sql
-- Top 10 slowest queries by mean time
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

Review weekly. Any query > 100ms mean time needs investigation.

### Connection Pool Tuning

| Parameter | Guideline | Measurement |
|-----------|-----------|-------------|
| Pool size per instance | Start with 10, measure | `pg_stat_activity` active connections |
| Idle timeout | 30s for serverless, 300s for always-on | Connection churn rate |
| Statement timeout | 5s for API, 30s for batch | Query duration percentiles |
| Total max connections | instances × pool_size < pg max_connections | `max_connections` setting |

---

## Event-Driven Workload Testing

For Pub/Sub consumers: measure processing throughput, not just HTTP latency.

```javascript
// k6 test publishing events to Pub/Sub
import { check } from 'k6';
import http from 'k6/http';

export const options = {
  scenarios: {
    event_burst: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      stages: [
        { target: 100, duration: '1m' },   // Ramp to 100 events/s
        { target: 100, duration: '5m' },   // Sustain
        { target: 0, duration: '30s' },
      ],
    },
  },
  thresholds: {
    'http_req_duration{scenario:event_burst}': ['p(95)<200'],
  },
};

export default function () {
  const res = http.post(`${BASE_URL}/api/v1/events/test`, JSON.stringify({
    type: 'invoicing.invoice.created',
    data: { invoiceId: `inv_${Date.now()}`, amount: 100 },
  }), { headers: { 'Content-Type': 'application/json' } });
  check(res, { 'accepted': (r) => r.status === 202 });
}
```

Measure consumer lag (unacked messages in subscription) alongside publish rate. If lag grows, the consumer can't keep up — scale or optimize.

---

## Performance Budget

### Backend

| Metric | Budget | Measured By |
|--------|--------|-------------|
| API response time (p95) | < 500ms | k6 load test |
| API response time (p99) | < 1000ms | k6 load test |
| DB query time (p95) | < 100ms | APM / query logs |
| Event processing time (p95) | < 2000ms | Consumer metrics |

### Frontend (if applicable)

| Metric | Budget | Measured By |
|--------|--------|-------------|
| First Contentful Paint | < 1.5s | Lighthouse CI |
| Largest Contentful Paint | < 2.5s | Lighthouse CI |
| Total Blocking Time | < 200ms | Lighthouse CI |
| Cumulative Layout Shift | < 0.1 | Lighthouse CI |

---

## Capacity Planning

```
Required capacity = (peak RPS × safety margin) / (RPS per instance)

Example:
  Peak RPS: 100
  Safety margin: 2x (handle 2x peak)
  RPS per instance (measured via load test): 50
  Required instances at peak: (100 × 2) / 50 = 4 instances

Cloud Run config:
  min-instances: 1 (always warm)
  max-instances: 8 (2x required for burst)
  concurrency: 80 (per load test — adjust based on measured saturation)
```

---

## CI Integration

Lightweight performance smoke test on every PR (fast, catches regressions):

```yaml
# .github/workflows/perf-smoke.yml
- name: Start service
  run: docker compose up -d api

- name: Wait for healthy
  run: |
    for i in $(seq 1 30); do
      curl -sf http://localhost:3000/health && break || sleep 1
    done

- name: Run k6 smoke test
  uses: grafana/k6-action@v0.3
  with:
    filename: tests/perf/smoke.js
    flags: --duration 30s --vus 10

- name: Stop service
  run: docker compose down
```

Full load test runs on release candidates only (too slow for every PR).

---

## When to Run

In CI: lightweight load test (30 seconds, 10 VUs) on every merge to main. Full test (5-10 minutes, full load) before every production release. Soak test: weekly in staging.

---

## Anti-Patterns

- **Testing in dev environment**: performance results are meaningless unless environment matches production (resources, network, data volume)
- **No baseline**: running performance tests without a known baseline makes results uninterpretable — establish baseline first
- **Optimizing for max latency**: max is a single data point, usually an outlier — optimize for p95/p99
- **Arbitrary load targets**: "let's test with 10,000 users" without deriving from actual business metrics
- **No think time**: hammering the API without `sleep()` between requests doesn't simulate real users
- **Testing single endpoint**: real load is distributed across endpoints — test realistic scenarios

---

## For Claude Code

When generating performance tests: k6 scripts with realistic scenarios (not just GET on one endpoint), thresholds based on SLOs, ramp-up/ramp-down to simulate real traffic. Include response checks (not just latency). Add custom business metrics for domain-specific measurements. Include capacity planning notes in service documentation.

---

*Internal references*: `testing-strategy/SKILL.md`, `observability/SKILL.md`, `quality-gates/SKILL.md`
