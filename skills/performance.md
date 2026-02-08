---
skill: performance-testing
version: 1.0.0
last-updated: 2026-02-08
domain: testing-quality
depends-on: [testing-strategy, backend-performance, observability]
---

# Performance Testing

## Purpose

Verify the system meets performance requirements under realistic load. Not benchmarking for its own sake — SLO validation.

---

## Test Types

**Load test**: verify behavior under expected load. Does the system handle 1000 req/s with p99 < 500ms? If yes, pass. If no, identify the bottleneck.

**Stress test**: increase load beyond expected to find the breaking point. At what load does the system degrade? How does it degrade (graceful vs crash)?

**Soak test**: constant load for extended periods (hours). Looking for memory leaks, connection leaks, gradual degradation.

**Spike test**: sudden load spike. How does autoscaling respond? How long to recover?

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

---

## SLO Validation

Performance tests validate defined SLOs: availability (99.9%), latency (p95 < 500ms, p99 < 1000ms for standard APIs), throughput (N req/s per service), error rate (< 0.1% under normal load). Tests fail if SLOs are not met. This is a CI gate for production releases.

---

## When to Run

In CI: lightweight load test (1 minute, reduced load) on every merge to main. Full test (5-10 minutes, full load) before every production release. Soak test: weekly in staging.

---

## For Claude Code

When generating performance tests: k6 scripts with realistic scenarios (not just GET on one endpoint), thresholds based on SLOs, ramp-up/ramp-down to simulate real traffic. Include response checks (not just latency).

---

*Internal references*: `testing-strategy.md`, `backend-performance.md`, `observability.md`
