---
skill: cicd-pipeline
version: 1.1.0
last-updated: 2026-02-08
domain: delivery
depends-on: [architectural-principles, containers, testing-strategy, quality-gates]
---

# CI/CD Pipeline

## Purpose

CI/CD pipeline design with GitHub Actions. The pipeline is critical infrastructure — treat it as production code.

---

## CI Pipeline — Detailed Stages

### On Every PR

8 stages, ordered for fail-fast:

| # | Stage | Target Time | What |
|---|-------|-------------|------|
| 1 | **Prepare** | < 30s | Checkout, cache restore, toolchain setup |
| 2 | **Lint & Format** | < 30s | ESLint, Prettier, SwiftLint. Fail fast on style. |
| 3 | **Type Check** | < 1min | `tsc --noEmit`. Catch type errors early. |
| 4 | **Unit Test** | < 2min | Vitest/XCTest. Fast, isolated tests only. |
| 5 | **Integration Test** | < 5min | With emulator/testcontainer. Real dependencies. |
| 6 | **Security Scan** | < 2min | Secret detection, SAST (Semgrep), `npm audit`, IaC scan. |
| 7 | **Contract Tests** | < 2min | API contract tests, schema compatibility checks. |
| 8 | **Build** | < 3min | Verify project compiles and produces artifacts. |

**Target total: < 10 minutes.** If it exceeds 15, it's an architectural signal.

**Parallel execution**: stages 2-3 (lint + typecheck) can run in parallel. Stage 6 (security) can run in parallel with tests (4-5). Stage 7 can run in parallel with build (8).

### Mandatory Properties

- **Fail-fast** on security/quality blockers — don't waste CI minutes on a broken build
- **Pin tool versions**: avoid `latest` for actions and images (e.g., `actions/checkout@v4`, not `@main`)
- **No secrets in logs**: use secret managers, mask sensitive output
- **Cache correctness**: cache keys include lockfile hash (e.g., `hashFiles('**/package-lock.json')`)
- **Parallelism**: run independent stages in parallel where safe

---

## CD Pipeline — Safe Deployment

### On Merge to Main

All CI stages above, plus:

| # | Stage | What |
|---|-------|------|
| 9 | **Container Build** | Multi-stage Docker build (see `containers.md`) |
| 10 | **Artifact Push** | Push to Artifact Registry with provenance + SBOM |
| 11 | **Staging Deploy** | Automatic deploy to staging environment |
| 12 | **Smoke Test** | Health check + 3 critical user flows in staging |
| 13 | **Production Deploy** | Controlled deploy (manual approval or automatic canary) |

### Deployment Patterns

**Canary**: gradual traffic shift with metrics gate. Recommended for risky releases.
```
1% traffic → monitor 5 min → 10% → monitor 10 min → 50% → monitor 15 min → 100%
Automatic rollback if: error rate > SLO threshold at any stage
```

**Blue-Green**: instant switch, instant rollback. Default for stateless services on Cloud Run.
```
Deploy to green → smoke test green → switch traffic 100% → monitor
Rollback: switch traffic back to blue (seconds)
```

**Rolling**: only if backward compatible and safe. No traffic split, gradual replacement.

### Mandatory Deploy Checks

- [ ] Readiness/liveness probes present (`/health`, `/ready`)
- [ ] Resource limits/requests defined (CPU, memory)
- [ ] Config separated from code (12-factor: env vars, not config files)
- [ ] Secrets stored in Secret Manager (not env vars in CI)
- [ ] DB migrations: forward-only + safe rollout order (expand/contract)
- [ ] Rollback plan documented

### Gating Metrics (auto-rollback triggers)

| Metric | Threshold | Window |
|--------|-----------|--------|
| Error rate (5xx) | > 1% (or > SLO) | 5 min rolling |
| Latency p99 | > 2x baseline | 5 min rolling |
| Health check failures | > 0 | Immediate |

---

## Branching Strategy

**Trunk-based development** with short-lived feature branches.

### Rules

- Protected `main` branch — no direct pushes
- Feature branches: `feat/description`, `fix/description`, `chore/description`
- Squash merge allowed only if PR title follows Conventional Commits
- Branch lifetime: max 2-3 days (if longer, break into smaller PRs)

### Branch Protection Checklist

- [ ] Require PR review (minimum 1 reviewer)
- [ ] Require status checks to pass (CI pipeline)
- [ ] Require up-to-date branch before merging
- [ ] Require signed commits (if policy mandates)
- [ ] Disallow force push to main
- [ ] Auto-delete branches after merge

### Hotfix Flow

```
production tag (v1.3.0) → branch hotfix/critical-bug
  → fix → PR (accelerated: 1 reviewer)
  → merge to hotfix branch → tag v1.3.1 → deploy
  → cherry-pick fix to main
```

### Release Tags

Tags from main: `vX.Y.Z`. Optional release branch only for RC stabilization (`release/1.4.0`). Release branch is short-lived — merge back to main after release.

---

## GitHub Actions Conventions

```yaml
name: CI
on:
  pull_request:
    branches: [main]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: npm ci
      - run: npm test -- --coverage
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=high
      - uses: returntocorp/semgrep-action@v1
```

**Caching**: `actions/cache` for node_modules (key based on package-lock.json hash). **Secrets**: GitHub Secrets for sensitive values. Workload Identity Federation for GCP auth (no service account key JSON). **Matrix build**: for testing across Node.js versions or multi-platform if needed.

### CI Evidence Extraction

CI must produce artifacts usable for compliance evidence (see `compliance.md`):

- Test reports (JUnit XML or JSON)
- Coverage reports (lcov, JSON)
- Security scan results (SARIF, JSON)
- SBOM (CycloneDX/SPDX)
- Container image signatures and provenance

---

## Environments

**Development**: local (docker-compose with GCP emulators) or personal cloud environment. **Staging**: production replica with synthetic data. Automatic deploy on merge to main. Used for integration test, performance test, UAT. **Production**: controlled deploy (manual or canary). Active monitoring. Rollback available.

No PREPROD, no DEMO as permanent environments. For demos: feature flags + staging. For pre-prod validation: canary in production.

---

## For Claude Code

When generating pipelines: structure CI in parallel jobs where possible (lint and security in parallel), aggressive caching, target < 10 min, include all 8 CI stages, generate separate CD workflow with automatic staging deploy and controlled production deploy. Include artifact generation (test reports, SBOM) for compliance evidence. Configure branch protection rules.

---

*Internal references*: `containers.md`, `testing-strategy.md`, `feature-management.md`, `quality-gates.md`, `release.md`
