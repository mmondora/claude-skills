---
name: quality-gates
description: "Formal quality gates that block releases. Tests, static quality, security, performance, reliability, documentation gates with PASS/FAIL verdicts. Use when configuring CI quality checks or evaluating release readiness."
---

# Quality Gates

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

## Purpose

Formal, automated gates that block releases when quality or engineering standards are not met. Gates produce a PASS/FAIL verdict — there is no "maybe."

---

## When Gates Are Evaluated

- **PR gate**: on every pull request before merge
- **Main gate**: on CI completion after merge to main
- **Release gate**: on release candidate pipeline
- **Deploy gate**: before production deployment

---

## Gate Definitions

### 1. Tests Gate

| Check | Threshold | Blocking |
|-------|-----------|----------|
| Unit tests | 100% pass | Yes |
| Integration tests | 100% pass | Yes |
| Branch coverage — domain layer | >= 80% | Yes |
| Branch coverage — application layer | >= 70% | Yes |
| Branch coverage — global | >= 70% | Yes |
| Coverage regression | no drop > 2% from main (see formula below) | Yes |
| Flaky tests | zero in release pipeline | Yes |
| Contract tests | 100% pass | Yes (release gate) |

Flaky test policy: a test that fails intermittently is quarantined (moved to a separate suite), tracked with a ticket, and has 1 sprint to be fixed or deleted.

**Coverage regression formula**:
```
regression = PR_branch_coverage - main_branch_coverage
if regression < -2.0:
    FAIL("Coverage dropped by {regression}% — threshold is -2%")
```
Coverage is measured as branch coverage percentage. Main branch baseline is stored as a CI artifact and updated on each merge to main.

### 2. Static Quality Gate

| Check | Threshold | Blocking |
|-------|-----------|----------|
| ESLint / SwiftLint | zero errors | Yes |
| TypeScript strict typecheck | zero errors | Yes |
| Formatting (Prettier) | zero diff | Yes |
| Complexity (cyclomatic) | per-function max configurable (default 15) | Warning |

Autoformat policy: CI may auto-format and commit, or fail if diff exists — configured per project.

### 3. Security Gate

| Check | Threshold | Blocking |
|-------|-----------|----------|
| Secret detection | zero findings | Yes |
| SAST (Semgrep) — Critical/High | zero findings | Yes |
| Dependency audit — Critical | zero findings | Yes |
| Dependency audit — High | zero or exception approved | Yes |
| Container scan — Critical | zero findings | Yes (deploy gate) |

Exception process: a High finding may be accepted with a documented exception (justification, compensating controls, expiry date, owner). See `security-testing.md`.

### 4. Performance Gate

| Check | Threshold | Blocking |
|-------|-----------|----------|
| Baseline performance tests | no regression > 10% from baseline | Yes (release gate) |
| Response time p95 | < SLO target | Warning |
| Memory usage | no leak detected in soak test | Yes (release gate) |

Performance tests run on release candidates, not on every PR (too slow).

### 5. Reliability Gate

| Check | Threshold | Blocking |
|-------|-----------|----------|
| API contract tests | 100% pass | Yes (release gate) |
| Backward compatibility | no breaking change without MAJOR bump | Yes |
| Schema migration | backward-compatible (additive only) | Yes |

### 6. Documentation Gate

| Check | Threshold | Blocking |
|-------|-----------|----------|
| Release notes draft | exists for release events | Yes (release gate) |
| ADR | required for architectural changes | Yes (PR gate) |
| CHANGELOG | updated for notable changes | Warning |

---

## Gate Output Format

```
============================================
QUALITY GATE REPORT — v1.4.0-rc.1
============================================
Tests ................ PASS  (coverage: 78.3%, +0.5%)
Static Quality ....... PASS  (0 errors, 2 warnings)
Security ............. PASS  (0 critical, 0 high, 3 medium)
Performance .......... PASS  (p95: 142ms, baseline: 148ms)
Reliability .......... PASS  (contracts: 47/47, compatibility: OK)
Documentation ........ PASS  (release notes: present, ADR: n/a)
--------------------------------------------
OVERALL: PASS — ready for production deploy
============================================
```

When a gate fails:

```
Security ............. FAIL
  BLOCKING: npm audit found 1 critical vulnerability
    - CVE-2026-1234 in lodash@4.17.20 (prototype pollution)
    - Fix: upgrade to lodash@4.17.22
    - Owner suggestion: @backend-team
```

---

## Gate Configuration

Gates are configured per-project in a `quality-gates.yaml` (or equivalent in CI):

```yaml
gates:
  tests:
    unit: { pass: true }
    coverage:
      domain: 80
      application: 70
      global: 70
      max-regression: 2
    flaky: { tolerance: 0 }
  static:
    lint: { pass: true }
    typecheck: { pass: true }
    format: { pass: true }
  security:
    secrets: { pass: true }
    sast: { block-on: [critical, high] }
    dependencies: { block-on: [critical] }
  performance:
    regression-threshold: 10
    slo-target-p95-ms: 500
  reliability:
    contracts: { pass: true }
    backward-compat: { pass: true }
  documentation:
    release-notes: { required-for: release }
    adr: { required-for: architectural-change }
```

---

## Anti-Patterns

- **"Green build" without meaningful tests**: 100% pass on 5 trivial tests is not a quality gate
- **Ignoring flaky tests**: a flaky test is a broken test — quarantine and fix within 1 sprint
- **Shipping without contract tests for public APIs**: internal APIs break silently, external APIs break customers
- **Manual override without audit trail**: if a gate is bypassed, who bypassed it and why must be recorded
- **Too many warnings, never fixed**: warnings that accumulate become noise — set a threshold and enforce

---

## For Claude Code

When generating CI pipelines: include quality gates as explicit steps with clear PASS/FAIL output, configure thresholds in a dedicated config file, generate the gate report format shown above. When a gate fails, suggest the specific fix and owner.

---

*Internal references*: `cicd.md`, `testing-strategy.md`, `security-testing.md`, `release.md`
