---
name: observability
cluster: cloud-infrastructure
description: "Logging, metrics, and tracing with OpenTelemetry. Structured JSON logs, 4 golden signals, distributed tracing, SLO-based alerting. Use when instrumenting services, setting up monitoring, configuring alerts, or debugging production issues."
---

# Observability

> **Version**: 1.4.0 | **Last updated**: 2026-02-14

## Purpose

The system tells its own story. Logging, metrics, and tracing are architectural tools that make system behavior visible, understandable, and diagnosable without attaching a debugger.

---

## Three Pillars

### Logging (what happened)

Structured JSON logs. Every entry: timestamp ISO-8601, level (debug/info/warn/error), message, service name, correlation ID, tenant ID, structured contextual data.

**Levels**: `debug` only in dev (never in prod — too much volume), `info` for significant business operations, `warn` for handled anomalies (retry, fallback, rate limit hit), `error` for failures requiring attention.

**Never log**: credentials, tokens, PII (email, phone, address — only if strictly necessary and with masking), full request payloads (only at debug level).

**Correlation ID**: propagated via HTTP header (`X-Request-Id`), included in events, passed to every log. Enables tracing a single operation across all services.

#### Structured Logger Setup

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  formatters: {
    level: (label) => ({ level: label }), // 'info' not 30
  },
  serializers: {
    err: pino.stdSerializers.err,
    req: (req) => ({
      method: req.method,
      url: req.url,
      correlationId: req.headers['x-request-id'],
    }),
  },
  redact: {
    paths: ['req.headers.authorization', 'body.password', 'body.token', '*.email', '*.phone'],
    censor: '[REDACTED]',
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});
```

#### PII Redaction

Automatically redact sensitive fields. Configure redaction paths at logger creation, not per-log-call. Common patterns to redact: authorization headers, passwords, tokens, emails, phone numbers, IP addresses (depending on jurisdiction).

#### Log Sampling

In high-throughput services, log sampling prevents storage explosion:
- `error`: always log (100%)
- `warn`: always log (100%)
- `info`: sample at 10-50% in production for high-volume endpoints
- `debug`: never in production (use dynamic log levels for temporary debugging)

Configure sampling per endpoint — health check endpoints at 0%, business operations at 100%.

### Metrics (how it's going)

Aggregated numeric metrics. Four types: counter (how many — request count, error count), gauge (how much right now — active connections, queue size), histogram (distribution — latency, payload size), summary (client-computed percentiles).

**Mandatory per-service metrics**: request rate (req/s per endpoint), error rate (4xx, 5xx per endpoint), latency (p50, p95, p99 per endpoint), saturation (CPU, memory, connections, event loop lag). These are Google SRE's "4 golden signals." With these, you can diagnose most problems.

### Tracing (why it's slow)

Distributed tracing to follow a request across multiple services. Each service creates a span, spans are linked in a trace. Trace ID propagated between services via W3C Trace Context header.

---

## OpenTelemetry

**OpenTelemetry (OTel)** as the single standard for all three pillars. Vendor-agnostic: instrument code with OTel SDK, export to any backend (Cloud Trace, Jaeger, Datadog, Grafana). Auto-instrumentation for HTTP frameworks and databases (OTel plugins), manual instrumentation for significant business operations.

```typescript
// otel-init.ts — MUST be imported before any other module
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter(),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter(),
  }),
  instrumentations: [getNodeAutoInstrumentations()],
  serviceName: process.env.SERVICE_NAME ?? 'unknown-service',
});

sdk.start();
process.on('SIGTERM', () => sdk.shutdown());
```

Manual span creation for business operations:

```typescript
import { trace } from '@opentelemetry/api';
const tracer = trace.getTracer('invoice-service');

async function createInvoice(data: CreateInvoiceInput) {
  return tracer.startActiveSpan('createInvoice', async (span) => {
    span.setAttribute('tenant.id', data.tenantId);
    try {
      const result = await invoiceRepo.save(data);
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
      throw error;
    } finally { span.end(); }
  });
}
```

---

## SLI / SLO / SLA

**SLI (Service Level Indicator)**: a quantitative measure of service behavior. Examples: request latency (p95), error rate, availability percentage. SLIs are the raw measurements — objective, measurable, automated.

**SLO (Service Level Objective)**: a target value for an SLI. "99.9% of requests complete in < 500ms." SLOs are internal engineering targets — aggressive enough to ensure good user experience, achievable enough not to be ignored.

**SLA (Service Level Agreement)**: a contractual commitment to customers, with consequences for breach. SLAs are always looser than SLOs (e.g., SLO = 99.9%, SLA = 99.5%). If you only alert on SLA breach, you've already lost — alert on SLO breach to fix before SLA is impacted.

**Error budget**: the inverse of SLO. If SLO = 99.9% availability, error budget = 0.1% downtime per month (~43 minutes). When error budget is exhausted, stop releasing features and focus on reliability.

### Error Budget Policy

| Budget Consumed | Action |
|----------------|--------|
| < 50% | Normal development velocity, ship features |
| 50-80% | Caution — no risky deployments, increase monitoring |
| 80-100% | Feature freeze — reliability work only |
| 100% (exhausted) | Full stop — all engineering on reliability until budget recovers |

Error budget resets monthly. Track in SLO dashboard. Product and engineering jointly own the budget.

---

## Alerting

**Alert on symptoms, not causes.** Alert on "latency p99 > 2s" (symptom), not "CPU > 80%" (cause that might not have impact). Alerts must be actionable: the recipient knows what to do.

**SLO-based alerting**: define Service Level Objectives (e.g., "99.9% of requests completed in < 500ms") and alert when error budget is being exhausted. More effective than static threshold alerts.

### Prometheus Alert Rule Example

```yaml
# prometheus/alerts/slo-alerts.yml
groups:
  - name: slo-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) > 0.001
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "Error rate exceeds SLO (> 0.1%)"
          description: "Current error rate: {{ $value | humanizePercentage }}"
          runbook: "https://wiki.internal/runbooks/high-error-rate"

      - alert: HighLatencyP99
        expr: |
          histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
          > 2
        for: 5m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "p99 latency exceeds 2s SLO"
          runbook: "https://wiki.internal/runbooks/high-latency"
```

---

## Observability Readiness Checklist

Before any service goes to production (or after a significant behavioral change), verify:

### Signals

- [ ] **Logs**: structured JSON with correlation/trace IDs propagated
- [ ] **Logs**: no sensitive data (PII, credentials) in log output
- [ ] **Metrics**: RED/USE metrics exposed (request rate, error rate, duration, saturation)
- [ ] **Metrics**: business KPIs instrumented (if relevant)
- [ ] **Metrics**: SLO indicators defined (latency target, error rate target, availability target)
- [ ] **Traces**: distributed tracing enabled for critical paths
- [ ] **Traces**: sampling configured (not 100% in production — too expensive)

### Operational Readiness

- [ ] **Dashboards**: exist and linked in runbook (service overview, SLO burn-down, dependency health)
- [ ] **Alerts**: configured for SLO breaches (error budget consumption rate)
- [ ] **Alerts**: every alert has a linked runbook (alert without runbook = noise)
- [ ] **Runbook**: exists with first response steps for common failure scenarios
- [ ] **Ownership**: team name, on-call rotation, escalation path defined

### Verdict

- **PASS**: all items checked — service is observable and operable
- **FAIL**: missing items listed with owners and deadlines

### SLO Suggestions (defaults for new services)

| Indicator | Target | Measurement |
|-----------|--------|-------------|
| Availability | 99.9% | Successful responses / total requests |
| Latency (p95) | < 500ms | 95th percentile response time |
| Latency (p99) | < 2s | 99th percentile response time |
| Error rate | < 0.1% | 5xx responses / total responses |

Adjust targets based on service criticality. Document in service README.

---

## GCP Stack

Cloud Logging for logs (integrated with Cloud Run). Cloud Monitoring for metrics and alerts. Cloud Trace for distributed tracing. All compatible with OpenTelemetry export.

---

## Production Debugging

**Dynamic log levels**: change log level at runtime without redeployment. Implement via environment variable or config endpoint (protected, admin-only). Useful for increasing verbosity during incident investigation.

```typescript
// Dynamic log level via admin endpoint
app.post('/admin/log-level', requireRole('admin'), (req, res) => {
  const { level } = req.body; // 'debug' | 'info' | 'warn' | 'error'
  logger.level = level;
  res.json({ level: logger.level, expiresIn: '30m' });
  // Auto-revert after 30 minutes to prevent debug log floods
  setTimeout(() => { logger.level = 'info'; }, 30 * 60 * 1000);
});
```

**Cardinality management**: high-cardinality labels (user IDs, request IDs) in metrics cause storage explosion. Use labels with bounded values (HTTP method, status code, endpoint path template). For user-level analysis, use traces not metrics.

### Dashboard Design

Follow RED/USE methodology:

- **RED** (for request-driven services): Rate, Errors, Duration — one row per service
- **USE** (for resources): Utilization, Saturation, Errors — one row per resource (CPU, memory, connections)

Each dashboard answers one question. Service overview dashboard: "Is the service healthy right now?" SLO dashboard: "Are we burning error budget too fast?" Dependency dashboard: "Are our dependencies healthy?"

### Resilience Patterns Reference

Observability must cover resilience mechanisms:

| Pattern | What to Monitor | Alert On |
|---------|----------------|----------|
| Circuit breaker | State transitions (closed→open→half-open) | Stays OPEN > 5min |
| Retry | Retry count per operation | Retry rate > 20% |
| Bulkhead | Pool utilization per partition | Pool exhaustion |
| Timeout | Timeout rate per dependency | Timeout rate > 5% |
| Graceful degradation | Fallback activation count | Fallback active > 10min |

---

## Profiling

When metrics show high latency or resource consumption but don't reveal the cause, profiling identifies the exact code paths consuming CPU, memory, or event loop time.

### When to Profile

- p99 latency exceeds SLO but traces show no obvious slow dependency
- Memory usage grows over time (potential leak)
- CPU spikes during specific operations
- Event loop lag increases under load

### CPU Profiling

Node.js built-in profiler:

```bash
# Generate V8 CPU profile (60 seconds)
node --cpu-prof --cpu-prof-dir=./profiles app.js
# Analyze with Chrome DevTools or speedscope.app
```

For production: use `--prof` flag or continuous profiling tools (Grafana Pyroscope, Google Cloud Profiler) that sample with minimal overhead (< 2%).

### Memory Profiling

```bash
# Heap snapshot for memory leak investigation
node --heapsnapshot-signal=SIGUSR2 app.js
# Send signal to trigger snapshot: kill -USR2 <pid>
```

Heap snapshots capture object graph at a point in time. Compare two snapshots taken minutes apart to identify growing object types.

### Continuous Profiling in Production

Low-overhead sampling (1-5%) that runs continuously, enabling after-the-fact investigation:
- Google Cloud Profiler (GCP native, free)
- Grafana Pyroscope (self-hosted, supports Node.js, Go, Rust)
- Datadog Continuous Profiler (SaaS)

Continuous profiling replaces the need for "reproduce in staging" — production profiles capture real behavior.

---

## Event-Driven Observability

Distributed tracing works well for synchronous HTTP chains, but breaks down in async event-driven systems where a single event can fan out to multiple consumers with no direct call chain.

### Trace Context in Events

Embed W3C `traceparent` and `tracestate` in CloudEvents extensions so consumers can continue the trace started by the producer:

```typescript
import { context, propagation, trace, SpanStatusCode } from '@opentelemetry/api';

interface CloudEvent<T = unknown> {
  specversion: string;
  type: string;
  source: string;
  id: string;
  data: T;
  traceparent?: string;   // W3C Trace Context
  tracestate?: string;    // W3C Trace State
}

// Producer: inject trace context into event
function injectTraceContext<T>(event: CloudEvent<T>): CloudEvent<T> {
  const carrier: Record<string, string> = {};
  propagation.inject(context.active(), carrier);
  return {
    ...event,
    traceparent: carrier.traceparent,
    tracestate: carrier.tracestate,
  };
}

// Consumer: extract trace context and create child span
function processEvent<T>(event: CloudEvent<T>, handler: (data: T) => Promise<void>): Promise<void> {
  const carrier: Record<string, string> = {};
  if (event.traceparent) carrier.traceparent = event.traceparent;
  if (event.tracestate) carrier.tracestate = event.tracestate;

  const parentContext = propagation.extract(context.active(), carrier);
  const tracer = trace.getTracer('event-consumer');

  return context.with(parentContext, () =>
    tracer.startActiveSpan(`process ${event.type}`, async (span) => {
      span.setAttribute('cloudevent.type', event.type);
      span.setAttribute('cloudevent.source', event.source);
      span.setAttribute('cloudevent.id', event.id);
      try {
        await handler(event.data);
        span.setStatus({ code: SpanStatusCode.OK });
      } catch (error) {
        span.setStatus({ code: SpanStatusCode.ERROR, message: (error as Error).message });
        throw error;
      } finally {
        span.end();
      }
    }),
  );
}
```

### Fan-Out Tracing

When a single event triggers multiple consumers, each consumer creates a **child span linked to the producer's span**, not a new trace. This preserves end-to-end visibility across the entire event flow.

### Event Processing Spans

Every event consumption should produce a span covering: queue receive, message processing, and acknowledgment. Span attributes: event type, source, consumer group, processing duration, success/failure.

Cross-reference: `event-driven-architecture/SKILL.md` for CloudEvents format and delivery guarantees.

**Anti-pattern**: creating a new trace per event consumption. This breaks end-to-end visibility — you lose the connection between the original request and all downstream event processing.

---

## Observability Cost Management

Observability infrastructure can become 30-50% of the monitoring bill. Unchecked log volume and high-cardinality metrics are the main cost drivers.

### Log Tiering

| Tier | Retention | Indexing | Use Case |
|------|-----------|----------|----------|
| **Hot** | 7 days | Full queryable | Active debugging, real-time investigation |
| **Warm** | 30 days | Reduced indexing | Recent investigation, trend analysis |
| **Cold** | 90-365 days | Archive only | Compliance, audit, forensics |

Configure automatic tier transitions. Most log backends (Cloud Logging, Elasticsearch, Loki) support retention policies and tiered storage.

### Log Volume Controls

Beyond per-level sampling (already covered), set per-endpoint volume budgets:

```typescript
const endpointBudgets: Record<string, { maxPerMinute: number }> = {
  'GET /health': { maxPerMinute: 0 },           // Never log health checks
  'GET /api/v1/users': { maxPerMinute: 100 },   // Cap high-traffic endpoints
  'POST /api/v1/invoices': { maxPerMinute: 500 },
};
```

### Metrics Cardinality Budget

High-cardinality labels cause storage explosion. Set guardrails:

- **Max labels per metric**: 5 (anything beyond adds diminishing value)
- **Bounded label values**: label values must come from a known, bounded set (HTTP method, status code, endpoint template — NOT user IDs, request IDs)
- **Flag metrics with >1,000 unique label combinations** for review and potential reduction
- For user-level analysis, use traces — not metrics

### Trace Sampling Cost Model

| Traffic Type | Sampling Rate | Rationale |
|-------------|---------------|-----------|
| Errors (5xx) | 100% | Every error is worth investigating |
| Slow requests (>p95) | 100% | Tail latency reveals real issues |
| Successful requests | 1-10% | Statistical sampling is sufficient |
| Health checks | 0% | Pure noise |

Prefer **tail-based sampling** (decide after the request completes) over head-based sampling (decide before). Tail-based catches all errors and slow requests regardless of sampling rate.

### Cost Attribution

Tag observability resources (log buckets, metric storage, trace storage) by service and team for chargeback. Teams that produce excessive observability data should own the cost.

Cross-reference: `finops/SKILL.md` for cost management as an architectural discipline.

**Anti-pattern**: storing debug logs in production hot tier for "just in case." Costs 10x more than warm tier, used 0.1% of the time. Use dynamic log levels for temporary debugging instead.

---

## Synthetic Monitoring

Passive monitoring (metrics, logs) only tells you something is wrong after real users are affected. Synthetic probes detect issues before users do.

### Probe Types

| Probe | Frequency | What It Tests |
|-------|-----------|---------------|
| **Availability** | Every 30s | HTTP health check returns 200 |
| **Functional** | Every 5min | Full business operation end-to-end |
| **Latency** | Every 1min | Response time from external perspective |

### Functional Probe Example

```typescript
import { Counter, Histogram } from 'prom-client';

const probeSuccess = new Counter({ name: 'synthetic_probe_success_total', help: 'Successful probes', labelNames: ['probe'] });
const probeFailure = new Counter({ name: 'synthetic_probe_failure_total', help: 'Failed probes', labelNames: ['probe'] });
const probeDuration = new Histogram({ name: 'synthetic_probe_duration_seconds', help: 'Probe duration', labelNames: ['probe'] });

async function invoiceProbe(apiClient: ApiClient, testTenantId: string): Promise<void> {
  const timer = probeDuration.startTimer({ probe: 'invoice-lifecycle' });
  try {
    // Create test invoice
    const invoice = await apiClient.post(`/api/v1/tenants/${testTenantId}/invoices`, {
      amount: 1, currency: 'EUR', description: 'Synthetic probe — safe to ignore',
      metadata: { synthetic: true },
    });

    // Verify it appears in list
    const list = await apiClient.get(`/api/v1/tenants/${testTenantId}/invoices?filter=id:${invoice.id}`);
    if (!list.data.some((i: { id: string }) => i.id === invoice.id)) throw new Error('Invoice not in list');

    // Clean up
    await apiClient.delete(`/api/v1/tenants/${testTenantId}/invoices/${invoice.id}`);

    probeSuccess.inc({ probe: 'invoice-lifecycle' });
  } catch (error) {
    probeFailure.inc({ probe: 'invoice-lifecycle' });
    logger.error({ err: error, probe: 'invoice-lifecycle' }, 'Synthetic probe failed');
    throw error;
  } finally {
    timer();
  }
}
```

### Probe Design Rules

- Use a **dedicated test tenant** — never pollute production data
- Probes must be **idempotent and self-cleaning** — clean up created resources
- Tag probe traffic with `synthetic: true` — **exclude from business metrics**
- Probe failure alerts have **higher priority** than metric-based alerts (they indicate real user impact)

**Anti-pattern**: synthetic probes that pollute production data. Always use a dedicated test tenant with automatic cleanup. Tag synthetic requests so they're excluded from business dashboards and SLO calculations.

---

## Alert Hygiene

Alert fatigue is the #1 killer of on-call effectiveness. Every unnecessary alert trains the team to ignore alerts.

### Alert-to-Incident Ratio

Target: **> 50%** of alerts should lead to human action. Below 30% means too many false positives — the on-call engineer is drowning in noise.

### Quarterly Alert Review

Every alert that hasn't fired in 90 days is reviewed:
- **Keep**: alert is still relevant, just hasn't triggered
- **Tune**: threshold is too sensitive or too loose — adjust
- **Delete**: alert is obsolete, duplicated, or no longer meaningful

### Alert Ownership

Every alert has an owning team. **Unowned alerts are deleted.** If nobody is responsible for responding to an alert, the alert is noise.

### Escalation Tiering

| Tier | Channel | Response Time | Examples |
|------|---------|---------------|----------|
| **P1** | Page (PagerDuty/Opsgenie) | Immediate | Service down, data loss risk, SLO breach |
| **P2** | Slack notification | 30 minutes | Degraded performance, elevated error rate |
| **P3** | Ticket (Jira/Linear) | Next business day | Non-critical anomaly, capacity warning |

### Runbook Requirement

**No alert without a linked runbook.** An alert without a runbook is noise — the on-call engineer sees a notification with no context on what to do. Every alert annotation must include a `runbook` URL.

### Metrics

Track alert volume per team per week. The trend should be **flat or decreasing**. An increasing trend means either the system is degrading or the alerts need tuning. Either way, action is required.

**Anti-pattern**: alerting on every possible metric "just in case." This creates a wall of noise that hides real incidents. Alert on symptoms (user-facing impact), not on every internal metric fluctuation.

---

## Anti-Patterns

- **"We'll add monitoring later"**: if it's not observable at launch, incidents will be diagnosed blind
- **Alerts without runbooks**: an alert that nobody knows how to respond to is worse than no alert (it's noise)
- **Logging PII**: audit trail should capture who/what/when, application logs should not contain personal data
- **100% trace sampling in production**: expensive and unnecessary — sample 1-10% for normal traffic, 100% for errors
- **Dashboard without audience**: a dashboard nobody looks at is wasted effort — each dashboard serves a specific operational question

---

## For Claude Code

When generating services: include OpenTelemetry setup in the entrypoint, structured logging with pino + correlation ID, metrics for the 4 golden signals, spans for business operations. Don't log PII. Configure SLO-based alerts, not threshold-based. Generate observability readiness checklist populated with actual service configuration when preparing for production. For event-driven services, propagate W3C trace context in CloudEvents extensions and create child spans in consumers. Apply log tiering (hot/warm/cold) and metrics cardinality budgets to control observability costs. Include synthetic monitoring probes for critical business flows using a dedicated test tenant. Enforce alert hygiene: every alert must have an owner, a linked runbook, and a response tier (P1/P2/P3).

---

*Internal references*: `production-readiness-review/SKILL.md`, `security-by-design/SKILL.md`, `cicd-pipeline/SKILL.md`, `error-handling-resilience/SKILL.md`
