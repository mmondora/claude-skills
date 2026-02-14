---
name: fitness-functions
cluster: functional-architecture
description: "Architecture fitness functions as automated quality attribute guardrails. Taxonomy, implementation patterns, catalog template, evolutionary governance. Use when defining architectural guardrails, automating NFR validation, or building architecture health dashboards."
---

# Architecture Fitness Functions

> **Version**: 1.0.0 | **Last updated**: 2026-02-14

## Purpose

Fitness functions are automated, objective measures of how well the architecture meets its intended quality attributes — the architectural equivalent of unit tests for structure. Without fitness functions, architecture degrades silently through entropy and well-intentioned shortcuts. With them, degradation is detected and reported automatically, enabling the architecture to evolve under controlled pressure rather than rot. Concept from Neal Ford, Rebecca Parsons, and Patrick Kua's *Building Evolutionary Architectures*.

---

## Fitness Function Taxonomy

Classify every fitness function along four dimensions:

| Dimension | Option A | Option B | Example |
|-----------|----------|----------|---------|
| **Trigger** | Triggered (runs in CI on event) | Continuous (runs in production) | Triggered: lint on PR. Continuous: SLO burn rate alert |
| **Scope** | Atomic (single characteristic) | Holistic (composite of multiple) | Atomic: cyclomatic complexity. Holistic: production readiness score |
| **Target** | Static (code, config, IaC) | Dynamic (runtime behavior) | Static: dependency graph analysis. Dynamic: latency percentiles |
| **Cadence** | Per-commit / Per-deploy | Periodic (daily, weekly) | Per-commit: secret scan. Periodic: chaos experiment suite |

A function is fully classified by its 4-tuple: e.g., `(triggered, atomic, static, per-commit)` for a complexity gate, or `(continuous, holistic, dynamic, periodic)` for a weekly architecture health score.

---

## Fitness Functions by Quality Attribute

Mapped to ISO 25010 quality characteristics. Each function specifies its cadence.

### Performance Efficiency

| Function | Cadence | Type |
|----------|---------|------|
| Latency p95 < SLO target | Continuous | Dynamic |
| Benchmark regression detection (> 10% slower than baseline) | Per-deploy | Dynamic |
| Bundle size budget (frontend) | Per-commit | Static |

### Reliability

| Function | Cadence | Type |
|----------|---------|------|
| SLO burn rate within error budget | Continuous | Dynamic |
| Chaos experiment pass rate >= 100% | Periodic (weekly/monthly) | Dynamic |
| Circuit breaker coverage (all external calls wrapped) | Per-commit | Static |
| Graceful degradation paths tested | Per-deploy | Dynamic |

### Security

| Function | Cadence | Type |
|----------|---------|------|
| Dependency vulnerability scan (critical = 0) | Per-commit | Static |
| OWASP ZAP baseline scan (0 high/critical) | Per-deploy | Dynamic |
| Secret detection (0 findings) | Per-commit | Static |
| Container image CVE scan | Per-deploy | Static |

### Maintainability

| Function | Cadence | Type |
|----------|---------|------|
| Cyclomatic complexity per function <= threshold | Per-commit | Static |
| Afferent/efferent coupling within bounds | Per-commit | Static |
| API breaking change detection (OpenAPI diff) | Per-commit | Static |
| Dependency freshness (no deps > N major versions behind) | Periodic (weekly) | Static |

### Compatibility

| Function | Cadence | Type |
|----------|---------|------|
| Contract test pass rate (100%) | Per-deploy | Dynamic |
| Backward compatibility check (schema, API) | Per-commit | Static |
| Database migration reversibility | Per-commit | Static |

### Portability

| Function | Cadence | Type |
|----------|---------|------|
| Container image multi-platform build (amd64, arm64) | Per-deploy | Static |
| No cloud-provider SDK in domain layer | Per-commit | Static |

---

## Fitness Function Implementation

### Static Fitness Functions (CI)

**Architecture linting with dependency-cruiser** — enforce layer boundaries and dependency direction in TypeScript projects:

```javascript
// .dependency-cruiser.cjs
module.exports = {
  forbidden: [
    {
      name: 'no-domain-to-infra',
      comment: 'Domain layer must not import from infrastructure',
      severity: 'error',
      from: { path: '^src/features/.+/.*\\.(service|types|schema)\\.' },
      to: { path: '^src/infra/' },
    },
    {
      name: 'no-circular-features',
      comment: 'Feature modules must not have circular dependencies',
      severity: 'error',
      from: { path: '^src/features/([^/]+)/' },
      to: { path: '^src/features/([^/]+)/', pathNot: '$1' },
    },
    {
      name: 'no-route-to-repository',
      comment: 'Routes must go through services, never call repositories directly',
      severity: 'error',
      from: { path: '\\.routes\\.' },
      to: { path: '\\.repository\\.' },
    },
  ],
};
```

**Coupling metrics** — Robert Martin's package instability (I = Ce / (Ca + Ce)). Stable packages (I near 0) should be abstract; unstable packages (I near 1) should be concrete. Violation: a concrete stable package blocks evolution. Enforce via CI script that parses import graphs and fails if any package violates the Stable Abstractions Principle.

**Complexity gates** — fail the build if any function exceeds the configured cyclomatic complexity threshold (default 15). Use ESLint `complexity` rule or SonarQube quality profile.

### Dynamic Fitness Functions (Production)

SLO monitoring and error budget consumption are fitness functions. Reference `observability/SKILL.md` for implementation — do not duplicate alerting logic here. The fitness function perspective adds: when the error budget is exhausted, feature deployments halt until the budget recovers. This is the architectural governance mechanism, not just an alert.

**Performance regression detection**: compare rolling p95/p99 against the baseline established at last release. Alert when regression exceeds 10% sustained over 15 minutes.

### Holistic Fitness Functions

**Production readiness score**: composite of individual fitness functions weighted by criticality. Output a single 0-100 score. Components: security scan (25%), test coverage (20%), SLO compliance (20%), dependency freshness (10%), documentation completeness (10%), performance budget (15%). Score below 70 blocks release.

**Architecture health dashboard**: aggregate all fitness function results into a single view per service. Red/amber/green per quality attribute. Trend over time. Visible to the entire engineering organization.

---

## Fitness Function Catalog Template

Use this template to define each fitness function in the project's architecture documentation:

```markdown
### FF-NNN: [Function Name]

- **Quality attribute**: [ISO 25010 attribute]
- **Type**: triggered | continuous
- **Scope**: atomic | holistic
- **Target**: static | dynamic
- **Cadence**: per-commit | per-deploy | periodic (interval)
- **Metric**: [what is measured]
- **Threshold**: [pass/fail boundary]
- **Implementation**: [tool, script, or pipeline step]
- **Owner**: [team or role]
- **NFR reference**: [link to non-functional requirement]
- **Action on failure**: block-deploy | alert | warn
- **Exception process**: [how to request bypass, max duration]
```

---

## Evolutionary Architecture Governance

Fitness functions are the enforcement mechanism for architectural decisions:

1. **Every ADR creates fitness functions.** An ADR that says "we will use event-driven communication between bounded contexts" produces a static fitness function that detects synchronous cross-context calls and fails the build.

2. **Green functions can be tightened.** If complexity threshold is 15 and the codebase averages 6, tighten to 12. Ratchet toward higher quality. Never loosen a threshold without an ADR documenting why.

3. **Relaxing a threshold requires an ADR.** The ADR must state the reason, the new threshold, the compensating control, and the review date for re-tightening.

4. **Trends feed the architecture roadmap.** If coupling metrics trend upward over 3 sprints, schedule a refactoring initiative. The dashboard makes drift visible before it becomes a crisis.

5. **Fitness functions are versioned.** Changes to thresholds and rules follow the same review process as production code. Store function definitions in version control alongside the code they govern.

---

## Organizational Adoption

1. **Start with 3-5 high-impact functions.** Complexity gate, secret detection, and SLO burn rate cover the highest-risk areas with minimal setup.

2. **Make results visible.** Display fitness function dashboards in team areas and engineering all-hands. Visibility creates accountability.

3. **Block deploy, don't just warn.** A warning is a suggestion. A blocked deploy is governance. Start with warnings during adoption, then promote to blocking within one quarter.

4. **Teams propose new functions.** Any team can propose a new fitness function via ADR. The architecture guild reviews and approves. This distributes governance instead of centralizing it.

5. **Quarterly review.** Every quarter, review all fitness functions: are thresholds still appropriate? Are any functions permanently green (candidate for tightening) or permanently red (broken process, not architecture)?

---

## Anti-Patterns

- **Fitness function without automation**: a fitness function that requires manual evaluation is not a fitness function — it is a checklist item that will be skipped under pressure
- **Too many functions too early**: starting with 30 fitness functions overwhelms teams with noise and erodes trust — start with 3-5 and grow incrementally
- **Threshold set once, never adjusted**: static thresholds rot — a complexity limit of 15 set two years ago may be too generous for a mature codebase or too strict for a prototype
- **Warning-only mode forever**: functions that warn but never block become background noise — set a deadline to promote warnings to blocking gates
- **Measuring without acting**: dashboards that show red for weeks without action teach the organization to ignore fitness functions entirely
- **Duplicating quality gates**: fitness functions and quality gates are complementary, not identical — quality gates block releases, fitness functions track architectural evolution over time
- **Testing the tool, not the architecture**: a fitness function that checks "ESLint ran" instead of "no circular dependencies exist" measures process compliance, not architectural health

---

## For Claude Code

When generating architecture fitness functions: define each function using the catalog template with all fields populated. Implement static fitness functions as CI pipeline steps with dependency-cruiser configs for TypeScript layer boundaries and ESLint rules for complexity gates. Wire dynamic fitness functions to the observability stack — reference `observability/SKILL.md` for metrics and alerting patterns. Generate `quality-gates.yaml` entries that map fitness function thresholds to blocking CI checks. When an ADR is created, propose corresponding fitness functions that enforce the decision automatically. Always emit structured output (JSON or the gate report format from `quality-gates/SKILL.md`) so results are machine-parseable and dashboard-ready.

---

*Internal references*: `quality-gates/SKILL.md`, `observability/SKILL.md`, `production-readiness-review/SKILL.md`, `cicd-pipeline/SKILL.md`, `testing-strategy/SKILL.md`
