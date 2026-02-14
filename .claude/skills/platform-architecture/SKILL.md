---
name: platform-architecture
cluster: functional-architecture
description: "Platform thinking and capability mapping. Self-service APIs, thin vs thick platform, Team Topologies alignment, golden paths, platform health metrics. Use when designing platform capabilities, defining team-platform boundaries, or establishing platform governance."
---

# Platform Architecture

> **Version**: 1.0.0 | **Last updated**: 2026-02-14

## Purpose

Platform thinking shifts from building products to building the foundation that enables products to be built. A platform provides capabilities (not features) that product teams consume through well-defined interfaces. The platform architect's job is to maximize team autonomy while maintaining system coherence: enable without constrain. A well-designed platform makes the right thing easy and the wrong thing hard — without blocking either.

---

## Platform Capability Mapping

Capability mapping is the foundation of platform design. Follow this method:

1. **Capability inventory**: catalog what product teams build repeatedly. Interview stream-aligned teams, audit shared libraries, scan for duplicated infrastructure code. If three or more teams solve the same problem independently, it is a platform candidate.

2. **Classify by value**: **differentiating** capabilities create competitive advantage (recommendation engine, pricing logic) — these stay with product teams. **Commodity** capabilities are identical across products (authentication, logging, deployment) — these belong on the platform.

3. **Group into domains**: organize commodity capabilities into coherent domains. Standard domains: identity & access, data infrastructure, integration & messaging, observability & monitoring, deployment & runtime, compliance & governance, developer experience.

4. **Define maturity per capability**:

| Maturity Level | Description | Example |
|----------------|-------------|---------|
| **Not offered** | Teams solve it themselves | Custom log shipping per service |
| **Manual** | Platform team does it on request (ticket) | Manual database provisioning |
| **Self-service API** | Teams consume via API/CLI without platform team involvement | `platform db create --engine postgres --tier standard` |
| **Fully automated** | Zero-touch, policy-driven, embedded in golden paths | Database provisioned automatically on service creation |

Target: every commodity capability at self-service API or above within 12 months. Manual is a temporary state, never a destination.

---

## Platform Capability Map Template

### Capability Domains

| Domain | Capability | Maturity | Interface | Consumers | Owner |
|--------|-----------|----------|-----------|-----------|-------|
| Identity | SSO/OIDC | Fully automated | SDK + API | All services | Platform - Identity |
| Identity | RBAC management | Self-service API | Admin API + CLI | Product teams | Platform - Identity |
| Data | Database provisioning | Self-service API | CLI + Terraform module | All services | Platform - Data |
| Data | Schema migration | Self-service API | CI pipeline plugin | All services | Platform - Data |
| Deployment | Container runtime | Fully automated | Dockerfile + manifest | All services | Platform - Runtime |
| Deployment | CI/CD pipelines | Self-service API | Template catalog | All services | Platform - DevEx |
| Observability | Logging | Fully automated | SDK (auto-instrumented) | All services | Platform - Observability |
| Observability | Alerting | Self-service API | Alert-as-code YAML | All services | Platform - Observability |
| Compliance | Audit trail | Fully automated | SDK (auto-captured) | Regulated services | Platform - Compliance |

### Capability Roadmap

| Quarter | Capability | Current Maturity | Target Maturity | Investment |
|---------|-----------|-----------------|----------------|------------|
| Q1 | Database provisioning | Manual | Self-service API | 2 engineers, 6 weeks |
| Q2 | Secret management | Not offered | Self-service API | 1 engineer, 4 weeks |
| Q3 | Feature flags | Manual | Fully automated | 1 engineer, 3 weeks |

### Adoption Metrics

| Capability | Adoption Rate | Active Consumers | Avg Time-to-Consume | Satisfaction |
|-----------|--------------|-----------------|---------------------|-------------|
| SSO/OIDC | 100% | 24 services | < 1 hour | 4.6/5 |
| Database provisioning | 78% | 18 services | 2 hours | 3.8/5 |
| CI/CD templates | 65% | 15 services | 4 hours | 3.5/5 |

---

## Platform API Boundary Design

### Self-Service First

Every platform capability is consumed through an API, SDK, CLI, or declarative configuration. Product teams never file tickets to use platform capabilities. If a capability requires human intervention from the platform team, it is not yet a platform capability — it is a service request.

**Design principles**:

- **Opinionated defaults + escape hatches**: provide a "just works" path for 80% of cases, with explicit override mechanisms for the remaining 20%. The default database is PostgreSQL 16 on a standard tier with automated backups. Teams can override engine, tier, backup policy, and region.
- **Backward compatibility**: platform APIs follow the same versioning and deprecation rules as external APIs. Breaking changes require a migration path and a deprecation window (minimum 90 days). See `api-design/SKILL.md`.
- **Transparency**: every platform capability publishes SLOs (availability, latency, error rate). SLO dashboards are public to all consumers. SLO breaches trigger the same incident process as production services.
- **Discoverability**: a service catalog (Backstage, Port, or custom) lists all platform capabilities with documentation, API reference, examples, and current SLO status.

### API Contract Example

```yaml
# platform-capability: database-provisioning
# interface: CLI + Terraform module + REST API
openapi: 3.1.0
paths:
  /v1/databases:
    post:
      summary: Provision a new database instance
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [name, engine, tier]
              properties:
                name: { type: string, pattern: "^[a-z][a-z0-9-]{2,62}$" }
                engine: { type: string, enum: [postgres, mysql] }
                tier: { type: string, enum: [dev, standard, premium] }
                region: { type: string, default: "us-central1" }
      responses:
        "202":
          description: Provisioning initiated
          headers:
            Location: { schema: { type: string } }
            Retry-After: { schema: { type: integer } }
```

Async provisioning: return 202 with a `Location` header pointing to the status endpoint. Never block the caller while infrastructure provisions.

---

## Thin Platform vs Thick Platform

| Dimension | Thin Platform | Thick Platform |
|-----------|--------------|----------------|
| **What it provides** | Infrastructure primitives (compute, storage, networking) | Composed capabilities (deploy service, provision data store, configure observability) |
| **Coupling** | Low — teams assemble their own stack | Higher — teams depend on platform opinions |
| **Cognitive load** | Higher — teams must understand primitives | Lower — teams consume curated experiences |
| **Flexibility** | Maximum — any combination of primitives | Constrained — works best on the golden path |
| **Platform team size** | Smaller — less surface area to maintain | Larger — more capabilities to support |
| **Onboarding speed** | Slower — teams build their own toolchain | Faster — productive on day one |

### Recommended: Thin Core + Thick Optional Layers

Build a thin core of infrastructure primitives that is always stable and rarely changes. Layer thick, opinionated capabilities on top that teams can adopt voluntarily. Product teams choose: use the thick layer for speed, or compose from thin primitives for control.

**Decision criteria for core vs optional**:

| Criterion | Core (mandatory) | Optional (thick layer) |
|-----------|-----------------|----------------------|
| Security and compliance requirements | Always core | — |
| Used by >90% of services | Core | — |
| Used by 50-90% of services | — | Strong candidate |
| Used by <50% of services | — | Optional or not offered |
| Requires deep domain expertise | — | Complicated subsystem team |
| Changes frequently based on product needs | — | Keep optional, iterate fast |

---

## Team Topologies for Platform

Apply Team Topologies to structure platform organization.

### Team Types

**Platform team** (owns the platform): small (6-10 engineers), focused on reliability, API quality, and developer experience. Measures success by consumer adoption and satisfaction, not by features shipped. Treats product teams as customers.

**Enabling team** (temporary engagement): embedded with a stream-aligned team for a bounded period (2-6 weeks) to help adopt a platform capability, migrate from a legacy tool, or build a missing integration. Disbands when the engagement goal is met. Never becomes a permanent dependency.

**Stream-aligned team** (platform consumers): builds and operates product features. Spends <10% of effort on platform integration. If platform integration consistently exceeds 10%, the platform has a usability problem. Stream-aligned teams provide feedback through surveys, office hours, and PRs to platform repos.

**Complicated subsystem team** (deeply specialized): owns a capability requiring specialist knowledge (ML inference infrastructure, real-time data pipelines, cryptographic services). Exposes the capability through a simplified API that stream-aligned teams consume without needing the specialist knowledge.

### Interaction Modes

| Mode | When | Duration |
|------|------|----------|
| **X-as-a-Service** | Platform capability is mature and self-service | Ongoing — the default mode |
| **Collaboration** | Building a new capability or migrating a complex system | Time-boxed (weeks, not months) |
| **Facilitating** | Helping teams adopt a capability or change practices | Time-boxed via enabling team |

The goal is to maximize X-as-a-Service interactions. Every collaboration engagement should end with a self-service interface.

---

## Platform Governance

### Inner Source Model

Platform code is open to the organization. Product teams contribute via pull requests. Platform team reviews for consistency, security, and backward compatibility. Contribution guidelines are explicit: coding standards, test requirements, API design rules, and documentation expectations. Accepted PRs are maintained by the platform team going forward.

### Platform Advisory Board

Monthly meeting: platform team leads + representative from each consuming domain. Agenda: review adoption metrics, prioritize the capability roadmap, discuss pain points, approve breaking changes. Decisions are recorded as ADRs (see `architecture-decision-records/SKILL.md`). The board advises; the platform team owns the final decision.

### Golden Paths

A golden path is the recommended, supported way to accomplish a common task. Golden paths are documented, tested, and maintained by the platform team. They are recommendations, not mandates — teams can deviate, but they own the operational burden of deviation.

**Examples**: "Create a new service" golden path includes repo template, CI/CD pipeline, observability instrumentation, database provisioning, and deployment manifest. "Add a new API endpoint" golden path includes OpenAPI spec generation, validation middleware, and contract test setup.

### Paved Roads

A paved road is a pre-built, tested, and supported implementation that teams use as-is. Paved roads are more opinionated than golden paths. Examples: a standard CI pipeline that all services use, a base Docker image with security scanning built in, a Terraform module for standard infrastructure patterns.

**Golden path vs paved road**: a golden path is a documented route; a paved road is a built route. Golden paths guide, paved roads carry.

---

## Platform Health Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Developer satisfaction** | >4.0/5.0 | Quarterly survey (NPS + CSAT) |
| **Time-to-first-deploy** | <1 day | Measure from repo creation to first production deploy |
| **Platform adoption rate** | >80% of eligible services | Count services using platform capability / total eligible |
| **Support ticket volume** | Decreasing quarter-over-quarter | Track tickets per capability per quarter |
| **Lead time impact** | Platform consumers deploy 2x faster | Compare deploy frequency: platform users vs non-users |
| **Golden path adherence** | >70% of new services | Automated check: does new service match golden path template? |
| **Mean time to onboard** | <4 hours for standard service | Measure from "I want a new service" to "service handles traffic" |

Track these metrics publicly. Publish a monthly platform health report. If developer satisfaction drops below 3.5 or time-to-first-deploy exceeds 2 days, treat it as a P1 incident.

---

## Anti-Patterns

- **Ticket-driven platform**: requiring product teams to file tickets for routine operations means the platform is a bottleneck, not an enabler — every routine operation must be self-service
- **Mandatory everything**: forcing all teams onto platform capabilities regardless of fit creates resentment and workarounds — mandate security and compliance only, recommend everything else
- **Platform as gatekeeper**: using platform control to block teams rather than enable them — the platform exists to accelerate, not to govern
- **Invisible platform tax**: platform integration consuming >10% of stream-aligned team effort without acknowledgment — measure and publicize integration cost, then reduce it
- **Build-it-and-they-will-come**: shipping capabilities without user research, documentation, or onboarding support — treat platform capabilities as products with their own adoption funnels
- **Permanent collaboration mode**: platform and product teams collaborating indefinitely instead of transitioning to X-as-a-Service — every collaboration engagement needs a defined end state
- **Golden path without maintenance**: documented golden paths that rot because nobody updates them when dependencies change — golden paths are products, not documents

---

## For Claude Code

When designing platform capabilities: start with a capability inventory by cataloging what product teams build repeatedly, classify each as differentiating or commodity, and only platformize commodity capabilities. Define every platform capability as a self-service API — if it requires a ticket, it is not ready. Use the thin core + thick optional layers pattern: mandate security and compliance, recommend everything else. Structure platform teams using Team Topologies: small platform team focused on API quality, enabling teams for temporary adoption support, stream-aligned teams as consumers. Generate platform capability maps using the template with maturity levels, and always include adoption metrics. When defining platform API boundaries, apply the same versioning and backward compatibility rules as external APIs. Include golden path templates for common operations (new service, new API, new data store). Track developer satisfaction, time-to-first-deploy, and adoption rate as primary health metrics. Record platform strategy decisions in ADRs.

---

*Internal references*: `api-design/SKILL.md`, `nfr-specification/SKILL.md`, `fitness-functions/SKILL.md`, `architecture-review-facilitation/SKILL.md`, `microservices-patterns/SKILL.md`
