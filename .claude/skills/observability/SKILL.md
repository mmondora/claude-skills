---
name: observability
description: "Logging, metrics, and tracing with OpenTelemetry. Structured JSON logs, 4 golden signals, distributed tracing, SLO-based alerting. Use when instrumenting services, setting up monitoring, configuring alerts, or debugging production issues."
---

# Observability

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

## Alerting

**Alert on symptoms, not causes.** Alert on "latency p99 > 2s" (symptom), not "CPU > 80%" (cause that might not have impact). Alerts must be actionable: the recipient knows what to do.

**SLO-based alerting**: define Service Level Objectives (e.g., "99.9% of requests completed in < 500ms") and alert when error budget is being exhausted. More effective than static threshold alerts.

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

*Internal references*: `production-readiness.md`, `security.md`, `cicd.md`
