---
name: observability
cluster: cloud-infrastructure
description: "Logging, metrics, and tracing with OpenTelemetry. Structured JSON logs, 4 golden signals, distributed tracing, SLO-based alerting. Use when instrumenting services, setting up monitoring, configuring alerts, or debugging production issues."
---

# Observability

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

The system tells its own story. Logging, metrics, and tracing are architectural tools that make system behavior visible, understandable, and diagnosable without attaching a debugger.

---

## Three Pillars

### Logging (what happened)

Structured JSON logs. Every entry: timestamp ISO-8601, level (debug/info/warn/error), message, service name, correlation ID, tenant ID, structured contextual data.

**Levels**: `debug` only in dev (never in prod — too much volume), `info` for significant business operations, `warn` for handled anomalies (retry, fallback, rate limit hit), `error` for failures requiring attention.

**Never log**: credentials, tokens, PII (email, phone, address — only if strictly necessary and with masking), full request payloads (only at debug level).

**Correlation ID**: propagated via HTTP header (`X-Request-Id`), included in events, passed to every log. Enables tracing a single operation across all services.

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

## Anti-Patterns

- **"We'll add monitoring later"**: if it's not observable at launch, incidents will be diagnosed blind
- **Alerts without runbooks**: an alert that nobody knows how to respond to is worse than no alert (it's noise)
- **Logging PII**: audit trail should capture who/what/when, application logs should not contain personal data
- **100% trace sampling in production**: expensive and unnecessary — sample 1-10% for normal traffic, 100% for errors
- **Dashboard without audience**: a dashboard nobody looks at is wasted effort — each dashboard serves a specific operational question

---

## For Claude Code

When generating services: include OpenTelemetry setup in the entrypoint, structured logging with pino + correlation ID, metrics for the 4 golden signals, spans for business operations. Don't log PII. Configure SLO-based alerts, not threshold-based. Generate observability readiness checklist populated with actual service configuration when preparing for production.

---

*Internal references*: `production-readiness-review/SKILL.md`, `security-by-design/SKILL.md`, `cicd-pipeline/SKILL.md`
