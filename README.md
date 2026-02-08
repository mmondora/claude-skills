# claude-skills

An operational knowledge system for [Claude Code](https://claude.ai/claude-code) — 23 skills that guide Claude in generating enterprise-grade software.

Not a boilerplate. Not a template. A system of conventions, patterns, and guardrails that Claude Code consults **before** writing code, infrastructure, tests, or documentation.

## What's Inside

```
claude-skills/
  claude-skills.zip           # Packaged skills (ready to install)
  scripts/install-skills.sh   # Installer script
  skills/                     # Source skill files (markdown)
  CLAUDE.md                   # Master configuration for this repo
```

## Skills Catalog (23 skills)

### Foundations
| Skill | What it covers |
|-------|----------------|
| `architecture-decision-records` | ADR governance, format (9 sections), lifecycle, review process |

### Cloud & Infrastructure
| Skill | What it covers |
|-------|----------------|
| `infrastructure-as-code` | Terraform/Pulumi, state management, modularity, drift detection |
| `finops` | Unit economics, right-sizing, GCP free tier, budget alerts |
| `containerization` | Docker multi-stage, distroless, security scanning, Cloud Run |
| `observability` | Structured logging, 4 golden signals, distributed tracing, SLO-based alerting, readiness checklist |

### Security & Compliance
| Skill | What it covers |
|-------|----------------|
| `security-by-design` | OWASP Top 10, supply chain guard, dependency review, SBOM/provenance, secrets, zero trust |
| `compliance-privacy` | GDPR, data residency, audit trail, retention, compliance assessment framework, evidence pack |
| `authn-authz` | Firebase Auth, JWT, RBAC/ABAC, multi-tenant isolation |

### Testing & Quality
| Skill | What it covers |
|-------|----------------|
| `testing-strategy` | Test pyramid, coverage rules, what to test and what not to |
| `testing-implementation` | Vitest, Testing Library, XCTest, Playwright, contract testing |
| `performance-testing` | k6 load/stress/soak/spike tests, SLO validation |
| `security-testing` | SAST, DAST, container/IaC scanning, severity policy, exception process |
| `quality-gates` | 6 formal gates (tests, static, security, performance, reliability, docs) with PASS/FAIL |

### Delivery & Release
| Skill | What it covers |
|-------|----------------|
| `cicd-pipeline` | 8-stage CI, CD deploy patterns (canary/blue-green), branching strategy, GitHub Actions |
| `release-management` | SemVer, Keep a Changelog, multi-audience release notes, rollback, change management, hotfix |
| `feature-management` | Feature flags, progressive rollout, A/B testing, kill switches |
| `production-readiness-review` | GO/NO-GO framework, 7-area NFR checklist, PRR output document |

### Documentation & Diagrams
| Skill | What it covers |
|-------|----------------|
| `technical-documentation` | README structure, runbooks, API docs, onboarding guides |
| `diagrams` | C4 model, sequence/ERD/state diagrams, Mermaid-first |
| `architecture-communication` | Architecture reviews, stakeholder communication, architecture doc structure |

### Data Architecture
| Skill | What it covers |
|-------|----------------|
| `data-modeling` | Firestore/PostgreSQL schemas, multi-tenant isolation, RLS, migrations |
| `event-driven-architecture` | CloudEvents, Pub/Sub, schema evolution, idempotency, DLQ |
| `caching-search` | Cache-aside/write-through, Redis, PostgreSQL FTS, Elasticsearch |

## Installation

### Quick Install

```bash
git clone <this-repo> claude-skills
./claude-skills/scripts/install-skills.sh /path/to/your/project
```

This does two things:
1. Unpacks all 23 skills into `your-project/.claude/skills/`
2. Adds a skill reference table to `your-project/CLAUDE.md` (creates it if missing)

### Options

```bash
# Install skills only, don't touch CLAUDE.md
./scripts/install-skills.sh /path/to/project --no-patch

# Overwrite existing skills (update to latest)
./scripts/install-skills.sh /path/to/project --force

# Both
./scripts/install-skills.sh /path/to/project --force --no-patch
```

### Manual Install

If you prefer:

```bash
# Unzip directly into your project
unzip claude-skills.zip -d /path/to/your/project/
```

This creates `.claude/skills/<skill-name>/SKILL.md` for each skill.

## How It Works

Claude Code automatically loads skills from `.claude/skills/` based on context. When you ask Claude to:

- **Set up CI/CD** — it reads `cicd-pipeline` and `quality-gates`
- **Write a Dockerfile** — it reads `containerization` and `security-by-design`
- **Design a database schema** — it reads `data-modeling` and `compliance-privacy`
- **Prepare for production** — it reads `production-readiness-review` and `observability`

You can also invoke skills directly with `/<skill-name>` in Claude Code.

## Technology Stack

The skills are opinionated about the following stack (configurable per-project via ADR):

| Layer | Default |
|-------|---------|
| Backend | Node.js + TypeScript (strict), Fastify, Drizzle/Prisma, Zod |
| Frontend | React or Vue 3 + TypeScript, Tailwind, Zustand/Pinia |
| iOS | Swift + SwiftUI, MVVM, Swift Concurrency |
| Database | Firestore (prototype) → PostgreSQL (production) |
| Cloud | GCP-first (Cloud Run, Pub/Sub, Secret Manager) |
| IaC | Terraform or Pulumi |
| CI/CD | GitHub Actions |
| Observability | OpenTelemetry → Cloud Monitoring/Trace |

## Principles

These skills enforce:

1. **Traceability** — every decision has a recorded "why" (ADR)
2. **Multi-tenancy by default** — tenant isolation in every layer
3. **Cost-awareness** — FinOps is an architectural attribute
4. **Observability over debugging** — the system tells its own story
5. **Quality as emergent property** — automated gates, not manual reviews
6. **Code for humans** — a junior developer must understand it on first read

## Project Structure

```
skills/                    # Source markdown files (canonical)
  adr.md
  architecture-comms.md
  authn-authz.md
  caching-search.md
  cicd.md
  compliance.md
  containers.md
  data-modeling.md
  diagrams.md
  event-driven.md
  feature-management.md
  finops.md
  iac.md
  implementation.md
  observability.md
  performance.md
  production-readiness.md
  quality-gates.md
  release.md
  security.md
  security-testing.md
  strategy.md
  technical-docs.md
.claude/skills/            # Claude Code native format (auto-generated)
  <skill-name>/SKILL.md
claude-skills.zip          # Packaged for distribution
scripts/install-skills.sh  # Installer
CLAUDE.md                  # Master config
```

## Contributing

Skills follow the same quality standards they teach:

- Edit source files in `skills/` (canonical source)
- Each skill has a frontmatter with `version` and `last-updated`
- Changes follow conventional commits
- A skill that's too large gets split; one that's too small gets merged

## License

MIT
