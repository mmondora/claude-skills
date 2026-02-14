# Skill Gap Analysis

> **Date**: 2026-02-14
> **Scope**: 58 curated skills (excluding `skill-clusters`)
> **Standard**: Golden template requiring YAML frontmatter (name, cluster, description with trigger phrases), Version line, Purpose section, core content sections with code examples, Anti-Patterns section (min 5 items), For Claude Code section, Internal references line.

---

## Gap Categories

| Code | Meaning |
|------|---------|
| `STRUCTURAL` | Non-standard structure (e.g., "Role Definition" instead of "Purpose") |
| `MISSING_SECTION` | Required section entirely absent |
| `WEAK_SECTION` | Section exists but thin or vague |
| `FRONTMATTER` | Description field issues (missing trigger phrases, etc.) |
| `CODE` | Missing code examples where the domain warrants them |
| `CROSS_REF` | Missing or stale internal references line |
| `ANTI_PATTERNS` | Anti-Patterns section missing or fewer than 5 items |
| `CLAUDE_CODE` | For Claude Code section missing or vague |

---

## Summary

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 6 | Stub/specialist format, need structural overhaul |
| MODERATE | 9 | Missing 1-3 required sections |
| MINOR | 12 | Missing Anti-Patterns section only |
| AT STANDARD | 31 | No gaps detected |

**Total gaps across all skills: 52**

---

## CRITICAL (6 skills)

These skills use a community "specialist" format (Role Definition, Core Workflow, Reference Guide, Constraints, Output Templates, Knowledge Reference) instead of the standard format. They all need: Purpose section, Anti-Patterns section, For Claude Code section, code examples, and proper internal references.

### 1. chaos-engineer

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `STRUCTURAL` | Uses "Role Definition" instead of "Purpose" section |
| 2 | `MISSING_SECTION` | No Anti-Patterns section |
| 3 | `MISSING_SECTION` | No For Claude Code section |
| 4 | `CODE` | No code examples (chaos experiment configs, Litmus YAML, etc.) |
| 5 | `CROSS_REF` | Has references but format may not match standard internal refs line |

### 2. database-optimizer

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `STRUCTURAL` | Uses "Role Definition" instead of "Purpose" section |
| 2 | `MISSING_SECTION` | No Anti-Patterns section |
| 3 | `MISSING_SECTION` | No For Claude Code section |
| 4 | `CODE` | No code examples (EXPLAIN plans, index DDL, query rewrites) |
| 5 | `CROSS_REF` | Has references but format may not match standard internal refs line |

### 3. kubernetes-specialist

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `STRUCTURAL` | Uses "Role Definition" instead of "Purpose" section |
| 2 | `MISSING_SECTION` | No Anti-Patterns section |
| 3 | `MISSING_SECTION` | No For Claude Code section |
| 4 | `CODE` | No code examples (manifests, Helm values, NetworkPolicy YAML) |
| 5 | `CROSS_REF` | Has references but format may not match standard internal refs line |

### 4. legacy-modernizer

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `STRUCTURAL` | Uses "Role Definition" instead of "Purpose" section |
| 2 | `MISSING_SECTION` | No Anti-Patterns section |
| 3 | `MISSING_SECTION` | No For Claude Code section |
| 4 | `CODE` | No code examples (strangler fig proxy config, migration scripts) |
| 5 | `CROSS_REF` | No internal references line |
| 6 | `CROSS_REF` | Should reference: `event-driven-architecture/SKILL.md`, `data-modeling/SKILL.md` |

### 5. microservices-architect

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `STRUCTURAL` | Uses "Role Definition" instead of "Purpose" section |
| 2 | `MISSING_SECTION` | No Anti-Patterns section |
| 3 | `MISSING_SECTION` | No For Claude Code section |
| 4 | `CODE` | No code examples (service decomposition, saga orchestrator, mesh config) |
| 5 | `CROSS_REF` | No internal references line |
| 6 | `CROSS_REF` | Should reference: `event-driven-architecture/SKILL.md`, `api-design/SKILL.md`, `microservices-patterns/SKILL.md` |

### 6. rag-architect

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `STRUCTURAL` | Uses "Role Definition" instead of "Purpose" section |
| 2 | `MISSING_SECTION` | No Anti-Patterns section |
| 3 | `CODE` | No code examples (embedding pipelines, vector queries, retrieval chains) |
| 4 | `CROSS_REF` | No internal references line |
| 5 | `WEAK_SECTION` | For Claude Code equivalent is just "Output Templates" -- too narrow |

---

## MODERATE (9 skills)

These skills follow the standard format but are missing 1-3 required sections.

### 7. differential-review

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `ANTI_PATTERNS` | No dedicated Anti-Patterns section |
| 2 | `CLAUDE_CODE` | No For Claude Code section |
| 3 | `CROSS_REF` | No standard internal references line |

### 8. terraform-style-guide

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |
| 2 | `ANTI_PATTERNS` | No dedicated Anti-Patterns section |
| 3 | `CROSS_REF` | No internal references line; should reference `terraform-test/SKILL.md`, `infrastructure-as-code/SKILL.md` |

### 9. terraform-test

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |
| 2 | `ANTI_PATTERNS` | No dedicated Anti-Patterns section |
| 3 | `CROSS_REF` | No internal references line; should reference `terraform-style-guide/SKILL.md`, `infrastructure-as-code/SKILL.md` |

### 10. ask-questions-if-underspecified

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |

### 11. using-git-worktrees

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |
| 2 | `ANTI_PATTERNS` | No dedicated Anti-Patterns section |

### 12. verification-before-completion

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |

### 13. writing-plans

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |

### 14. executing-plans

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |

### 15. finishing-a-development-branch

| # | Gap Type | Detail |
|---|----------|--------|
| 1 | `CLAUDE_CODE` | No For Claude Code section |

---

## MINOR (12 skills)

These skills conform to the standard format but are missing a dedicated Anti-Patterns section (or have anti-pattern content that is not in the standard format).

| # | Skill | Note |
|---|-------|------|
| 16 | `authn-authz` | No Anti-Patterns section |
| 17 | `cicd-pipeline` | No Anti-Patterns section |
| 18 | `apple-compliance-audit` | No Anti-Patterns section |
| 19 | `diagrams` | No Anti-Patterns section |
| 20 | `ios-app-audit` | No Anti-Patterns section |
| 21 | `ios-gui-assessment` | No Anti-Patterns section |
| 22 | `owasp-security` | Has anti-patterns inline but no dedicated section |
| 23 | `property-based-testing` | No Anti-Patterns section |
| 24 | `pypict-claude-skill` | No Anti-Patterns section |
| 25 | `security-by-design` | No Anti-Patterns section |
| 26 | `sharp-edges` | Has anti-pattern content but not in standard section format |
| 27 | `testing-implementation` | No Anti-Patterns section |

---

## AT STANDARD (31 skills)

These skills meet all golden template requirements with no detected gaps.

- `api-design`
- `architecture-communication`
- `architecture-decision-records`
- `caching-search`
- `carbon-aware-architecture`
- `compliance-privacy`
- `containerization`
- `data-modeling`
- `error-handling-resilience`
- `event-driven-architecture`
- `feature-management`
- `finops`
- `graphql-architect`
- `green-software-principles`
- `incident-management`
- `infrastructure-as-code`
- `insecure-defaults`
- `microservices-patterns`
- `observability`
- `performance-testing`
- `production-readiness-review`
- `prompt-architect`
- `quality-gates`
- `release-management`
- `sci-measurement`
- `security-testing`
- `sustainability-impact-assessment`
- `systematic-debugging`
- `technical-documentation`
- `testing-strategy`
- `websocket-engineer`

---

## Remediation Priority

| Priority | Action | Skills | Effort |
|----------|--------|--------|--------|
| P0 | Structural overhaul to standard format | 6 CRITICAL skills | High -- full rewrite |
| P1 | Add For Claude Code section | 9 MODERATE skills | Medium -- new section per skill |
| P1 | Add Anti-Patterns section (min 5 items) | 6 MODERATE + 12 MINOR = 18 skills | Medium -- domain expertise needed |
| P2 | Add/fix internal references line | 8 skills (6 CRITICAL + 2 MODERATE) | Low -- reference lookup |
| P2 | Add code examples | 6 CRITICAL skills | Medium -- working examples needed |

**Estimated total effort**: 6 full rewrites (CRITICAL) + 18 Anti-Patterns sections + 9 For Claude Code sections + 8 cross-reference fixes + 6 code example additions.
