# claude-skills

An operational knowledge system for [Claude Code](https://claude.ai/claude-code) — 25 skills that guide Claude in generating enterprise-grade software.

Not a boilerplate. Not a template. A system of conventions, patterns, and guardrails that Claude Code consults **before** writing code, infrastructure, tests, or documentation.

## What's Inside

```
claude-skills/
  .claude/skills/                        # 25 Claude Code skills (one per directory)
  skills/                                # Symlink → .claude/skills/ (for easy browsing)
  .githooks/pre-commit                   # Auto-updates README.md on commit
  scripts/build-zip.sh                   # Builds versioned distribution zip
  scripts/install-skills.sh              # Installs skills into a target project
  scripts/generate-readme.sh             # Skills catalog → README.md
  scripts/claude-skills-<version>.zip    # Distribution package
  CLAUDE.md                              # Master configuration
```

## Skills Catalog (25 skills)

<!-- SKILLS_START -->

### Foundations
| Skill | What it covers |
|-------|----------------|
| `architecture-decision-records` | Architecture Decision Records governance and format. ADR lifecycle, review process, when to write an ADR |

### Cloud & Infrastructure
| Skill | What it covers |
|-------|----------------|
| `containerization` | Docker best practices for cloud-native applications. Multi-stage builds, distroless images, security scanning, non-root users, Cloud Run orchestration |
| `finops` | Cloud cost management as an architectural discipline. Unit economics, right-sizing, GCP free tier optimization, budget alerts, serverless-first |
| `infrastructure-as-code` | Infrastructure as Code with Terraform and Pulumi. State management, modularity, drift detection, secrets handling |
| `observability` | Logging, metrics, and tracing with OpenTelemetry. Structured JSON logs, 4 golden signals, distributed tracing, SLO-based alerting |

### Security & Compliance
| Skill | What it covers |
|-------|----------------|
| `authn-authz` | Authentication and authorization patterns for multi-tenant applications. Firebase Auth, JWT tokens, RBAC/ABAC, tenant isolation guards |
| `compliance-privacy` | GDPR compliance and privacy as architectural constraints. Data minimization, right to be forgotten, data residency, audit trails, retention policies |
| `security-by-design` | Security as a design property, not an added layer. OWASP Top 10, supply chain security, secrets management, zero trust |

### Testing & Quality
| Skill | What it covers |
|-------|----------------|
| `performance-testing` | Performance testing with k6 for SLO validation. Load, stress, soak, and spike tests |
| `quality-gates` | Formal quality gates that block releases. Tests, static quality, security, performance, reliability, documentation gates with PASS/FAIL verdicts |
| `security-testing` | Automated security testing in CI. SAST, DAST, dependency scanning, authorization testing, secret detection |
| `testing-implementation` | Concrete test tooling and patterns for TypeScript and Swift. Vitest, Testing Library, XCTest, Playwright, contract testing |
| `testing-strategy` | Testing strategy that produces real confidence. Test pyramid, coverage rules, what to test and what not to test |

### Delivery & Release
| Skill | What it covers |
|-------|----------------|
| `cicd-pipeline` | CI/CD pipeline design with GitHub Actions. Pipeline stages, caching, environments, blue-green and canary deployments |
| `feature-management` | Feature flags, progressive rollout, A/B testing, and kill switches. Flag types, hygiene, implementation patterns |
| `incident-management` | Incident response process from detection to postmortem. Severity levels, communication templates, blameless postmortems, incident metrics |
| `production-readiness-review` | Production readiness GO/NO-GO framework. NFR checklist covering availability, scalability, observability, security, compliance |
| `release-management` | Release management with automated SemVer, changelog generation, release notes, rollback strategies, and hotfix workflow |

### Documentation & Diagrams
| Skill | What it covers |
|-------|----------------|
| `architecture-communication` | Communicating architectural decisions to stakeholders. Architecture Reviews, ADR presentation, stakeholder-adapted communication |
| `diagrams` | Architectural diagrams as code using Mermaid and C4 model. System context, container, component, sequence, ERD, and state diagrams |
| `technical-documentation` | Documentation as a living artifact. README structure, architecture docs, runbooks, API docs, onboarding guides |

### Data Architecture
| Skill | What it covers |
|-------|----------------|
| `caching-search` | Distributed caching and full-text search patterns. Cache-aside, write-through, invalidation strategies, Redis, PostgreSQL FTS, Elasticsearch |
| `data-modeling` | Schema design, multi-tenant data isolation, and migration management. Firestore and PostgreSQL patterns, RLS, UUID v7 conventions |
| `event-driven-architecture` | Event-driven systems with CloudEvents and GCP Pub/Sub. Event design, schema evolution, delivery guarantees, idempotency, eventual consistency |

### API & Integration
| Skill | What it covers |
|-------|----------------|
| `api-design` | API design conventions for REST and GraphQL. Resource naming, versioning, pagination, error responses (RFC 7807), OpenAPI-first workflow, backward compatibility |

<!-- SKILLS_END -->

## Installation

### Quick Install

```bash
git clone <this-repo> claude-skills
./claude-skills/scripts/install-skills.sh /path/to/your/project
```

This does two things:
1. Unpacks all 25 skills into `your-project/.claude/skills/`
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
.claude/skills/              # Claude Code skills (one directory per skill)
  <skill-name>/SKILL.md
.githooks/
  pre-commit                 # Auto-updates README.md before each commit
scripts/
  install-skills.sh          # Installer for target projects
  generate-readme.sh         # Regenerates skills catalog in README.md
CLAUDE.md                    # Master configuration
README.md                    # Auto-updated project documentation
```

## Contributing

Skills follow the same quality standards they teach:

- Edit skill files in `.claude/skills/<skill-name>/SKILL.md`
- Each skill has YAML frontmatter with `name` and `description`
- Changes follow conventional commits
- README.md is auto-updated on commit (via `.githooks/pre-commit`)
- A skill that's too large gets split; one that's too small gets merged

### Setup

After cloning, enable the git hooks:

```bash
git config core.hooksPath .githooks
```

This ensures README.md stays in sync with the skills catalog automatically.

## License

MIT
