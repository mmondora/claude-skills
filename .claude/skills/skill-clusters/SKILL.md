---
name: skill-clusters
cluster: foundations
description: "Skill cluster index and loader. Maps clusters to their constituent skills, enabling bulk loading by domain. Use when users request skills by cluster name (e.g., 'load foundations', 'fammi la security')."
---

# Skill Clusters

> **Version**: 1.2.0 | **Last updated**: 2026-02-13

## Purpose

Central index of skill clusters for bulk loading. When a user requests skills by cluster or domain name, consult this file to identify which skills to load together. Supports English and Italian aliases.

---

## Cluster Map

### foundations — Foundations (Principles & Governance)

Skills:
- `architecture-decision-records/SKILL.md` — ADR governance, format, lifecycle
- `prompt-architect/SKILL.md` — Prompt engineering frameworks (CO-STAR, RISEN, TIDD-EC, etc.)

**When to load**: architectural governance, decision recording, prompt engineering.

### cloud-infrastructure — Cloud & Infrastructure

Skills:
- `infrastructure-as-code/SKILL.md` — Terraform/Pulumi, state management, modularity
- `finops/SKILL.md` — Cost modeling, unit economics, budget alerts
- `containerization/SKILL.md` — Docker multi-stage, distroless, security scanning
- `observability/SKILL.md` — Logging, metrics, tracing, SLI/SLO/SLA
- `terraform-test/SKILL.md` — Terraform test files, run blocks, assertions, mocking
- `terraform-style-guide/SKILL.md` — Terraform HCL style conventions and best practices

**When to load**: cloud setup, infrastructure provisioning, cost optimization, monitoring, Terraform.

### security-compliance — Security & Compliance

Skills:
- `security-by-design/SKILL.md` — OWASP, supply chain, SBOM, zero trust
- `compliance-privacy/SKILL.md` — GDPR, data residency, audit trail, retention
- `authn-authz/SKILL.md` — OAuth2/OIDC, RBAC/ABAC, multi-tenant auth
- `owasp-security/SKILL.md` — OWASP Top 10:2025, ASVS 5.0, agentic AI security
- `differential-review/SKILL.md` — Security-focused differential review of code changes

**When to load**: security reviews, compliance assessments, auth implementation, code audits.

### testing-quality — Testing & Quality

Skills:
- `testing-strategy/SKILL.md` — Test pyramid, coverage rules, flaky test policy
- `testing-implementation/SKILL.md` — Vitest, MSW, Playwright, XCTest patterns
- `performance-testing/SKILL.md` — k6 load testing, SLO validation
- `security-testing/SKILL.md` — SAST, DAST, dependency/container scanning
- `quality-gates/SKILL.md` — Release-blocking gates, PASS/FAIL verdicts
- `property-based-testing/SKILL.md` — Property-based testing across languages and smart contracts

**When to load**: test writing, quality assessment, CI gate configuration, property-based testing.

### delivery-release — Delivery & Release

Skills:
- `cicd-pipeline/SKILL.md` — GitHub Actions, 8-stage CI, deploy patterns
- `release-management/SKILL.md` — SemVer, changelog, rollback, hotfix
- `feature-management/SKILL.md` — Feature flags, progressive rollout, kill switches
- `production-readiness-review/SKILL.md` — GO/NO-GO framework, NFR checklist
- `incident-management/SKILL.md` — Severity levels, postmortems, MTTD/MTTR
- `chaos-engineer/SKILL.md` — Chaos experiments, failure injection, resilience testing

**When to load**: CI/CD setup, release process, incident response, feature rollout, resilience.

### documentation-diagrams — Documentation & Diagrams

Skills:
- `technical-documentation/SKILL.md` — README/runbook templates, API docs
- `diagrams/SKILL.md` — C4, sequence, deployment, ERD — Mermaid-first
- `architecture-communication/SKILL.md` — ADR presentation, stakeholder communication

**When to load**: documentation writing, diagram creation, architecture reviews.

### data-architecture — Data Architecture

Skills:
- `data-modeling/SKILL.md` — Schema design, Drizzle migrations, multi-tenant isolation
- `event-driven-architecture/SKILL.md` — CloudEvents, Pub/Sub, saga patterns
- `caching-search/SKILL.md` — Redis, PostgreSQL FTS, cache key design
- `database-optimizer/SKILL.md` — Query optimization, execution plans, index design

**When to load**: database design, event systems, caching strategy, query optimization.

### architecture-patterns — Architecture & Patterns

Skills:
- `api-design/SKILL.md` — REST conventions, versioning, pagination, RFC 7807, OpenAPI-first
- `microservices-architect/SKILL.md` — Service decomposition, DDD, saga patterns, service mesh
- `legacy-modernizer/SKILL.md` — Strangler fig pattern, incremental migration, tech debt reduction

**When to load**: API design, microservices architecture, system modernization, distributed systems.

### ai-applications — AI & Applications

Skills:
- `rag-architect/SKILL.md` — RAG systems, vector databases, semantic search, document retrieval

**When to load**: RAG implementation, vector search, knowledge-grounded AI applications.

### green-software — Green Software & Sustainability

Skills:
- `green-software-principles/SKILL.md` — GSF principles, carbon/energy/hardware efficiency, measurement
- `carbon-aware-architecture/SKILL.md` — Time/spatial shifting, demand shaping, Carbon Aware SDK
- `sci-measurement/SKILL.md` — SCI per ISO/IEC 21031:2024, energy measurement, CI integration
- `sustainability-impact-assessment/SKILL.md` — Impact assessment, green PRR, GSF Maturity Matrix

**When to load**: sustainability assessment, carbon-aware design, green software, environmental impact.

---

## Aliases

Use these aliases to match user requests to clusters:

| Alias (EN) | Alias (IT) | Cluster |
|------------|------------|---------|
| foundations, governance, principles | fondamenta, governance, principi | `foundations` |
| cloud, infrastructure, infra, terraform | cloud, infrastruttura, terraform | `cloud-infrastructure` |
| security, compliance, auth, owasp | sicurezza, compliance, autenticazione | `security-compliance` |
| testing, quality, tests, property-based | test, qualita, testing | `testing-quality` |
| delivery, release, deploy, CI/CD, chaos | rilascio, deploy, pipeline | `delivery-release` |
| docs, documentation, diagrams | documentazione, diagrammi | `documentation-diagrams` |
| data, database, events, caching, optimizer | dati, database, eventi, cache | `data-architecture` |
| api, architecture, microservices, legacy | api, architettura, microservizi | `architecture-patterns` |
| ai, rag, vector, embeddings | ai, rag, vettori, embeddings | `ai-applications` |
| green, sustainability, carbon, SCI | green, sostenibilità, carbonio, SCI | `green-software` |

---

## For Claude Code

When a user requests a cluster (e.g., "load the security skills", "fammi la foundations", "carica testing & quality"):

1. Match the request to a cluster using the alias table above
2. Read all skills listed under that cluster
3. Apply the combined knowledge when generating output
4. If the request is ambiguous, list matching clusters and ask for clarification

When a user says "load all skills" or "carica tutto", load all 10 clusters sequentially by priority: foundations → security-compliance → testing-quality → delivery-release → cloud-infrastructure → data-architecture → architecture-patterns → ai-applications → green-software → documentation-diagrams.

---

## Anti-Patterns

- Loading all clusters when only one is needed — increases context without benefit
- Ignoring the cluster field in skill frontmatter — use it for filtering and grouping
- Hardcoding cluster membership — always read from skill frontmatter as source of truth

---

*Internal references*: `architecture-decision-records/SKILL.md`, `prompt-architect/SKILL.md`
