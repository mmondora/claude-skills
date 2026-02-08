---
name: release-management
description: "Release management with automated SemVer, changelog generation, release notes, rollback strategies, and hotfix workflow. Use when configuring releases, writing changelogs, planning rollbacks, or handling hotfixes."
---

# Release Management

## Purpose

Release management with automated SemVer, generated changelogs, multi-audience release notes, rollback strategy, change management coordination, and hotfix workflow.

---

## SemVer Automation

Version bump derived automatically from conventional commits since last tag. Tools: `standard-version`, `semantic-release`, or `release-please` (GitHub-native).

### Mapping Rules

| Commit type | Version bump | Notes |
|---|---|---|
| `feat:` | MINOR | New backward-compatible feature |
| `fix:` | PATCH | Bug fix |
| `perf:` | PATCH | Performance improvement (no behavior change) |
| `BREAKING CHANGE:` or `feat!:` | MAJOR | Breaking change |
| `docs:`, `chore:`, `refactor:` | no bump | Included in next release |

### Product Policy Overlay

- **Internal shared services** consumed by multiple teams: treated as public API (stricter SemVer, require ADR for MAJOR)
- **Core services**: compatibility-first — breaking changes require ADR, migration plan, deprecation timeline
- **API/schema contract changes**: require explicit scope and breaking marker in commit

### SemVer Workflow

Merge to main → CI verifies (see `quality-gates.md`) → tool analyzes commits → bumps version in package.json → generates CHANGELOG.md → creates git tag → creates GitHub Release with release notes.

### Risk Assessment (for MAJOR bumps)

Every MAJOR version bump includes: consumer impact analysis (who is affected), migration complexity estimate, rollback feasibility assessment. Documented in release notes.

---

## CHANGELOG.md

Follow the **Keep a Changelog** standard. Auto-generated from conventional commits.

### Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- ...

## [1.3.0] - 2026-02-08
### Added
- **invoices**: PDF export for invoices (#142)
- **auth**: Sign in with Apple support (#138)
### Changed
- **dashboard**: improved loading performance for large datasets (#143)
### Fixed
- **invoices**: VAT calculation for mixed rates (#145)
### Security
- **deps**: updated express to 4.19.0 (CVE-2026-1234)
### Breaking Changes
- **api**: removed deprecated endpoint GET /api/v1/users (use /api/v2/users) (#140)
```

### Mandatory Sections

Added, Changed, Deprecated, Removed, Fixed, Security. Only include sections that have entries.

### Rules

- **Unreleased section must always exist** — accumulates changes between releases
- Every release entry has: date, version, link to release notes (if separate)
- Breaking changes duplicated in: CHANGELOG, release notes, and ADR (if architectural)
- Each entry is traceable to a PR or commit
- No duplicates, no vague entries ("various improvements")

---

## Release Notes — Multi-Audience Model

Release notes differ from CHANGELOG. Three output types, each for a different audience:

### 1. Customer-Facing Release Notes

Written for end users. Non-technical language, focus on value.

**Mandatory sections**: Highlights (top 3-5), New Features, Improvements, Bug Fixes, Known Limitations (if any), Breaking Changes (with action required), Availability/Rollout Notes (if progressive).

**Style rules**: plain language, no implementation details. Use verbs that convey value ("Enable", "Improve", "Reduce", "Fix"). Each bullet: what changed + who benefits + any action required.

### 2. Ops Release Notes (SRE/Support)

Written for operations and support teams.

**Mandatory sections**: Deployment window and dependencies, Migration steps (DB/schema/config), Monitoring checklist (dashboards, alerts, SLOs to watch), Rollback plan reference, Support playbook changes, Feature flags and kill-switches.

### 3. Developer Notes (API/SDK consumers — optional)

Written for API consumers and SDK users.

**Sections**: API changes summary (OpenAPI/AsyncAPI diff), SDK changes and version constraints, Deprecations and timelines.

### Mapping from Commits to Notes

| Commit type | Customer Notes | Ops Notes | Dev Notes |
|---|---|---|---|
| `feat:` | New Features | If operational impact | API changes |
| `fix:` | Bug Fixes | If operational impact | If API behavior changes |
| `perf:` | Improvements | Monitoring changes | — |
| `refactor:` | Only if user-visible | If operational impact | Internal |
| `docs:` | Omit | Omit | Keep |
| `chore/build/ci:` | Omit | If delivery impact | Omit |
| `BREAKING CHANGE:` | Breaking Changes | Migration steps | Breaking Changes |

---

## Change Management

For major or high-risk releases, coordinate beyond the engineering team:

### Pre-Release Checklist

- [ ] Change ticket exists for major/high-risk releases
- [ ] Stakeholders notified: Support, Ops, Security, Product
- [ ] Maintenance window defined (if downtime expected)
- [ ] Backout/rollback plan attached to the change record
- [ ] Communication templates prepared (status page, customer notification)
- [ ] Support team briefed on new features and known issues

### Communication Plan

- **Internal**: Slack/Teams notification with link to release notes (Ops version)
- **External (if customer-facing)**: status page update, email/in-app notification
- **Breaking changes**: advance notice (minimum 2 weeks for external APIs)

---

## Rollback Strategy

### Cloud Run (Stateless Services)

Revision-based rollback. Every deploy creates a revision. Rollback = redirect traffic to previous revision. Time: seconds.

**Rollback trigger criteria**: SLO breach (error rate spike, latency p99 > threshold), critical bug reported, data integrity concern.

**Rollback Time Objective (RTO)**: defined per service (default: < 5 minutes).

### Database Migrations

Every migration has a **tested rollback script**. Migrations are always backward-compatible (additive).

**Expand/Contract pattern** for breaking schema changes:
1. Release N: add new column/table (expand) — old code ignores it
2. Release N+1: migrate code to use new structure, backfill data
3. Release N+2: remove old column/table (contract) — only after all consumers migrated

Never add and remove in the same release.

### Feature Flags

For risky features, rollback is disabling the flag. No deploy needed. Kill switch responds in seconds.

### Rollback Steps Checklist (copy-pastable)

```
1. Confirm rollback decision (who decided, why)
2. Check for schema incompatibility (forward-only migrations?)
   - If yes: use feature flag kill-switch instead
   - If no: proceed with version rollback
3. Execute rollback:
   - Cloud Run: gcloud run services update-traffic [SERVICE] --to-revisions=[PREV_REV]=100
   - Feature flag: disable flag in Remote Config / flag service
4. Verify rollback: check health endpoint, error rate, latency
5. Notify stakeholders: Ops, Support, Product
6. Create incident ticket if rollback was due to production issue
7. Post-mortem within 48 hours
```

### Risks That Prevent Rollback

| Risk | Mitigation |
|------|------------|
| Schema incompatibility (new migration breaks old code) | Expand/contract pattern — always |
| Data written in new format | Dual-write during migration window |
| External API consumers on new version | Maintain old version for deprecation period |
| Feature flag state inconsistency | Feature flag service is source of truth, not code |

---

## Hotfix

Hotfix = critical production fix that can't wait for next release.

**Workflow**: branch from production tag → fix → PR with accelerated review (1 reviewer minimum) → merge and deploy → cherry-pick to main.

A hotfix is a PATCH version. Generates a CHANGELOG entry and a dedicated release. Hotfix release notes always include: what broke, impact, what was fixed, who is affected.

---

## For Claude Code

When configuring release management: `release-please` or `semantic-release` in GitHub Actions, conventional commits enforced with commitlint in pre-commit hook, auto-generated CHANGELOG following Keep a Changelog. Generate release notes in multi-audience format. Suggest backward-compatible migrations and rollback scripts for every migration. Include change management checklist for major releases.

---

*Internal references*: `cicd.md`, `feature-management.md`, `quality-gates.md`, `adr.md`
