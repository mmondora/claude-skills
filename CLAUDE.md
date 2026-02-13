# CLAUDE.md — claude-skills

## Project Identity

This is a monorepo of **skills for Claude Code** designed to produce enterprise-grade software. It is not a boilerplate or template repository — it is an **operational knowledge system** that guides Claude Code in generating code, architecture, documentation, tests, and decisions consistent with professional standards.

Each skill is a standalone markdown file organized by domain. Claude Code must consult the relevant skills **before** generating any output.

---

## Philosophy

### Code Is for Humans

Every artifact produced — code, document, diagram, test — must be **readable, modifiable, and maintainable by a junior developer** without verbal explanations. If a junior cannot understand the code on first read, the code is wrong.

### Non-Negotiable Principles

1. **Traceability**: every decision has a recorded "why". Every commit tells what changed and why.
2. **Evolutionary coherence**: every choice must enable future evolution, not block it. Never optimize for today at the expense of tomorrow.
3. **Cost-aware**: FinOps is not an afterthought. Every infrastructure choice has an economic impact that must be explicit.
4. **Separation of concerns**: strategy ≠ architecture ≠ tactics. Do not mix levels.
5. **Multi-tenancy by design**: software is born multi-tenant. Single-tenant is a degenerate case, not the default.
6. **Cloud-native, cloud-agnostic**: design for the cloud, not for a specific cloud. GCP-first but with explicit abstraction layers.
7. **Observability over debugging**: the system tells its own story. If you need to attach a debugger in production, you've already lost.

### Quality as Emergent Property

Quality is not added after the fact with reviews and linting. It emerges from clear automated conventions, tests that document expected behavior, architecture that makes it hard to do the wrong thing, and short feedback loops (CI fails in <5 minutes).

---

## Technology Stack

### Backend
- **Runtime**: Node.js (LTS)
- **Language**: TypeScript (strict mode, no implicit `any`)
- **Framework**: per-project (Fastify preferred, Express acceptable, Hono for edge)
- **ORM/Query**: Drizzle ORM (type-safe, SQL-first) or Prisma for standard cases
- **Validation**: Zod (schema-first, shared between frontend and backend)

### Frontend Web
- **React + TypeScript**: complex applications, SPA/SSR
- **Vue.js 3 + TypeScript**: lighter applications or where the team has Vue expertise
- **Principle**: no framework is "better" — the choice is contextual and must be recorded in an ADR
- **State management**: Zustand (React), Pinia (Vue) — no Redux unless exceptionally justified
- **Styling**: Tailwind CSS as default, CSS Modules as alternative

### iOS / Native
- **Language**: Swift (current version)
- **UI Framework**: Pure SwiftUI — UIKit only for components not yet available in SwiftUI
- **Architecture**: MVVM with Swift Concurrency (async/await, Actor)
- **Local persistence**: SwiftData / Core Data, with optional sync via CloudKit or custom backend
- **Dependency management**: Swift Package Manager (SPM) — no CocoaPods, no Carthage

### Desktop (when needed)
- **Tauri + TypeScript** preferred (Rust backend, lighter footprint)
- **Electron + TypeScript** for cross-platform (last resort)
- **Native Swift** for macOS-only

### Database
- **Cloud default**: Firestore (Firebase) for prototyping and document-oriented workloads
- **Graduation path**: Cloud SQL (PostgreSQL) for relational workloads and advanced multi-tenancy
- **NewSQL**: CockroachDB when distributed SQL with global ACID guarantees is needed
- **Principle**: choose the database for the workload, not for familiarity. Record in ADR.

### Messaging & Events
- **Default**: GCP Pub/Sub
- **Format**: CloudEvents as standard envelope (multi-cloud portability)
- **Patterns**: event-driven with dead letter queue, retry with exponential backoff, mandatory idempotency
- **Abstraction**: never couple application code to the provider SDK — use adapter pattern

### Cloud & Infra
- **Primary**: Google Cloud Platform (GCP) — Cloud Run, Cloud Functions, GKE when necessary
- **Secondary**: AWS, Azure — code must run anywhere with adapter swap
- **IaC**: Terraform (multi-cloud) or Pulumi (TypeScript-native) — no ClickOps
- **Containers**: Docker multi-stage build, distroless or alpine images
- **CI/CD**: GitHub Actions as default

---

## Mandatory Conventions

### Git & Versioning

**Conventional Commits** — every commit follows:
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

Breaking changes: `BREAKING CHANGE:` footer or `!` after type.

**SemVer** (Semantic Versioning 2.0.0):
- MAJOR: breaking changes
- MINOR: new backward-compatible features
- PATCH: backward-compatible bug fixes
- Pre-release: `-alpha.N`, `-beta.N`, `-rc.N`

**Branching**: trunk-based development with short-lived feature branches. No long-lived branches. No GitFlow unless exceptionally justified (record in ADR why).

### Naming Conventions

- **Files and directories**: kebab-case (`user-service.ts`, `auth-middleware.ts`)
- **TypeScript classes/types**: PascalCase (`UserService`, `AuthMiddleware`)
- **TypeScript functions/variables**: camelCase (`getUserById`, `isAuthenticated`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_MS`)
- **Swift types**: PascalCase (`UserViewModel`, `WineCellar`)
- **Swift properties/methods**: camelCase (`fetchWines()`, `isLoading`)
- **Database tables**: snake_case (`user_accounts`, `tenant_settings`)
- **API endpoints**: kebab-case (`/api/v1/user-accounts`)
- **Environment variables**: UPPER_SNAKE_CASE (`DATABASE_URL`, `GCP_PROJECT_ID`)

### Code Organization

Every project follows a **feature/domain** structure, not a technical-layer structure:
```
src/
  features/
    users/
      users.routes.ts
      users.service.ts
      users.repository.ts
      users.schema.ts      # Zod schema
      users.types.ts       # TypeScript types derived from Zod
      users.test.ts
    invoices/
      ...
  shared/
    middleware/
    utils/
    types/
  infra/
    database/
    messaging/
    auth/
```

**Never** organize by technical layer (`controllers/`, `services/`, `repositories/` as top-level directories). Domain comes first.

### Error Handling

- **Never** empty `catch` blocks or catch with only `console.log`
- Typed errors with discriminated unions or custom classes extending `Error`
- Error boundary pattern: errors caught at module boundary, never deep inside
- Structured logging (JSON) with correlation ID for cross-service traceability
- User-facing errors separated from technical errors (never expose stack traces to users)

### Inline Documentation

- **JSDoc/TSDoc**: mandatory for public functions and exported types
- **Comments**: explain the *why*, not the *what*. If the code needs comments for the *what*, rewrite it.
- **README.md**: every project has one. Contains: what it is, how to start, how to test, how to deploy.
- **CHANGELOG.md**: auto-generated from conventional commits

---

## Available Skills

Each skill is a markdown file in `skills/`. Claude Code must read the skill **before** generating output in the corresponding domain. Skills are organized into clusters (the `cluster:` field in each skill's frontmatter). Use `skill-clusters/SKILL.md` to load all skills in a cluster at once.

### `foundations` — Foundations (Principles & Governance)
| Skill | Path | Covers |
|-------|------|--------|
| Architecture Decision Records | `architecture-decision-records/SKILL.md` | ADR governance, format, lifecycle, review process, filled example |
| Prompt Architect | `prompt-architect/SKILL.md` | Prompt engineering frameworks (CO-STAR, RISEN, RISE-IE, RISE-IX, TIDD-EC, RTF, Chain of Thought, Chain of Density) |

### `cloud-infrastructure` — Cloud & Infrastructure
| Skill | Path | Covers |
|-------|------|--------|
| Infrastructure as Code | `infrastructure-as-code/SKILL.md` | Terraform/Pulumi, state management, modularity, drift detection |
| FinOps | `finops/SKILL.md` | Cost modeling, unit economics, budget alerts, right-sizing |
| Containerization | `containerization/SKILL.md` | Docker multi-stage, distroless, security scanning, Docker Compose |
| Observability | `observability/SKILL.md` | Logging, metrics, tracing, SLI/SLO/SLA, Prometheus alerts |
| Terraform Test | `terraform-test/SKILL.md` | Test files, run blocks, assertions, mocking providers and data sources |
| Terraform Style Guide | `terraform-style-guide/SKILL.md` | HCL style conventions, naming, formatting, best practices |

### `security-compliance` — Security & Compliance
| Skill | Path | Covers |
|-------|------|--------|
| Security by Design | `security-by-design/SKILL.md` | OWASP, supply chain, dependency management, SBOM/provenance, secrets, zero trust |
| Compliance & Privacy | `compliance-privacy/SKILL.md` | GDPR, data residency, audit trail, data retention, assessment framework, evidence pack |
| Authentication & Authorization | `authn-authz/SKILL.md` | OAuth2/OIDC PKCE, RBAC/ABAC, multi-tenant auth, token revocation |
| OWASP Security | `owasp-security/SKILL.md` | OWASP Top 10:2025, ASVS 5.0, agentic AI security |
| Differential Review | `differential-review/SKILL.md` | Security-focused differential review of code changes, blast radius analysis |

### `testing-quality` — Testing & Quality
| Skill | Path | Covers |
|-------|------|--------|
| Testing Strategy | `testing-strategy/SKILL.md` | Test pyramid, coverage rules, test naming, flaky test policy |
| Test Implementation | `testing-implementation/SKILL.md` | Unit, integration, contract, E2E — Vitest, MSW, Playwright, XCTest |
| Performance Testing | `performance-testing/SKILL.md` | Load testing with k6, SLO validation, capacity planning, performance budgets |
| Security Testing | `security-testing/SKILL.md` | SAST, DAST (ZAP), dependency/container/IaC scanning, severity policy |
| Quality Gates | `quality-gates/SKILL.md` | Release-blocking gates, PASS/FAIL verdicts, coverage regression detection |
| Property-Based Testing | `property-based-testing/SKILL.md` | Property-based testing across languages and smart contracts |

### `delivery-release` — Delivery & Release
| Skill | Path | Covers |
|-------|------|--------|
| CI/CD Pipeline | `cicd-pipeline/SKILL.md` | 8-stage CI, CD deploy patterns, matrix builds, GitHub Actions |
| Release Management | `release-management/SKILL.md` | SemVer automation, changelog, multi-audience release notes, rollback, hotfix |
| Feature Management | `feature-management/SKILL.md` | Feature flags, progressive rollout, A/B testing, kill switches, dead flag cleanup |
| Production Readiness Review | `production-readiness-review/SKILL.md` | GO/NO-GO framework, NFR checklist, PRR output document |
| Incident Management | `incident-management/SKILL.md` | Severity levels, incident response process, postmortems, MTTD/MTTR |
| Chaos Engineer | `chaos-engineer/SKILL.md` | Chaos experiments, failure injection, resilience testing, game days |

### `documentation-diagrams` — Documentation & Diagrams
| Skill | Path | Covers |
|-------|------|--------|
| Technical Documentation | `technical-documentation/SKILL.md` | README/runbook templates, API docs generation, documentation review |
| Diagrams & Visualization | `diagrams/SKILL.md` | C4, sequence, deployment, ERD, state — Mermaid-first |
| Architecture Communication | `architecture-communication/SKILL.md` | ADR presentation, Architecture Review, stakeholder communication |

### `data-architecture` — Data Architecture
| Skill | Path | Covers |
|-------|------|--------|
| Data Modeling & Storage | `data-modeling/SKILL.md` | Schema design, Drizzle migrations, UUID v7, multi-tenant isolation |
| Event-Driven Architecture | `event-driven-architecture/SKILL.md` | CloudEvents, Pub/Sub, idempotency, schema evolution, saga patterns |
| Caching & Search | `caching-search/SKILL.md` | Redis, PostgreSQL FTS, cache key design, search indexing pipeline |
| Database Optimizer | `database-optimizer/SKILL.md` | Query optimization, execution plans, index design, partitioning |

### `architecture-patterns` — Architecture & Patterns
| Skill | Path | Covers |
|-------|------|--------|
| API Design | `api-design/SKILL.md` | REST conventions, versioning, pagination, RFC 7807 errors, OpenAPI-first |
| Microservices Architect | `microservices-architect/SKILL.md` | Service decomposition, DDD, saga patterns, service mesh, distributed tracing |
| Legacy Modernizer | `legacy-modernizer/SKILL.md` | Strangler fig pattern, incremental migration, technical debt reduction |

### `ai-applications` — AI & Applications
| Skill | Path | Covers |
|-------|------|--------|
| RAG Architect | `rag-architect/SKILL.md` | RAG systems, vector databases, semantic search, document retrieval |

### `green-software` — Green Software & Sustainability
| Skill | Path | Covers |
|-------|------|--------|
| Green Software Principles | `green-software-principles/SKILL.md` | GSF principles, carbon/energy/hardware efficiency, measurement, climate commitments |
| Carbon-Aware Architecture | `carbon-aware-architecture/SKILL.md` | Time/spatial shifting, demand shaping, Carbon Aware SDK, carbon-aware CI/CD |
| SCI Measurement | `sci-measurement/SKILL.md` | Software Carbon Intensity per ISO/IEC 21031:2024, energy measurement, CI integration |
| Sustainability Impact Assessment | `sustainability-impact-assessment/SKILL.md` | Impact assessment framework, green PRR, GSF Maturity Matrix, broader impact |

---

## How to Use This Repo

### For Claude Code

When you receive a task, follow this flow:

1. **Identify the domain**: does the task concern backend? frontend? infra? Often it spans multiple.
2. **Read the relevant skills**: open and read the skill markdown files before writing code.
3. **Apply conventions**: naming, structure, commit messages, error handling — everything must be consistent.
4. **Generate with traceability**: every generated file has a reason. Every non-obvious decision points to a principle or ADR.
5. **Test**: do not generate code without tests. If the task doesn't explicitly ask for tests, generate them anyway.
6. **Document**: JSDoc, updated README, CHANGELOG if it's a release.

### For Humans

This repo is also living documentation. The skills are written to be read by people, not just Claude. They can be used for onboarding new developers, as reference during code review, as a base for Architecture Reviews, and for team training and discussions.

---

## Rules for Claude Code

### MUST always:
- Read pertinent skills before generating output
- Use TypeScript strict mode (backend and frontend)
- Validate input with Zod schemas
- Handle errors explicitly (never `any`, never empty catch)
- Generate tests for every public function
- Use conventional commits for every suggested commit message
- Include JSDoc/TSDoc for public APIs
- Structure code by feature/domain, not by technical layer
- Use meaningful, self-explanatory names (no cryptic abbreviations)
- Generate code that a junior can read without help

### MUST NEVER:
- Use `any` in TypeScript (use `unknown` + type narrowing)
- Ignore errors or use empty catch blocks
- Hardcode credentials, URLs, or environment-specific configuration
- Generate code without tests
- Use dependencies without justification (every `npm install` has a "why")
- Generate obvious comments (`// increment counter` on `counter++`)
- Mix concerns (business logic in route handler, UI logic in data layer)
- Assume single-tenant unless explicitly requested
- Use `console.log` as logging strategy (use structured logger)
- Generate code that requires tribal knowledge to understand

---

## Meta: Skill Evolution

The skills themselves follow the principle of evolutionary coherence. Each skill has a header with `version` and `last-updated`. Changes to skills follow the same review process as code. Skills can reference each other but must not create circular dependencies. A skill that's too large gets split; one that's too small gets merged. This CLAUDE.md is the single source of truth for the skill map.

---

*Last revision: 2026-02-08*
*CLAUDE.md version: 1.1.0*

<!-- claude-skills:begin -->
## Installed Skills

The following Claude Code skills are installed in `.claude/skills/`. Claude will auto-load them based on context, or you can invoke them with `/<skill-name>`. Use `/skill-clusters` to load all skills in a cluster at once.

### Foundations
| Skill | Description |
|-------|-------------|
| `architecture-decision-records` | Architecture Decision Records governance and format. |
| `prompt-architect` | Analyzes and transforms prompts using 8 research-backed frameworks (CO-STAR, RISEN, RISE-IE, RISE-IX, TIDD-EC, RTF, Chain of Thought, Chain of Density). |
| `skill-clusters` | Skill cluster index and loader. |

### Cloud & Infrastructure
| Skill | Description |
|-------|-------------|
| `containerization` | Docker best practices for cloud-native applications. |
| `finops` | Cloud cost management as an architectural discipline. |
| `infrastructure-as-code` | Infrastructure as Code with Terraform and Pulumi. |
| `observability` | Logging, metrics, and tracing with OpenTelemetry. |
| `terraform-test` | Comprehensive guide for writing and running Terraform tests. |
| `terraform-style-guide` | Terraform HCL style conventions and best practices. |

### Security & Compliance
| Skill | Description |
|-------|-------------|
| `authn-authz` | Authentication and authorization patterns for multi-tenant applications. |
| `compliance-privacy` | GDPR compliance and privacy as architectural constraints. |
| `differential-review` | Security-focused differential review of code changes. |
| `owasp-security` | OWASP Top 10:2025, ASVS 5.0, and agentic AI security. |
| `security-by-design` | Security as a design property, not an added layer. |

### Testing & Quality
| Skill | Description |
|-------|-------------|
| `performance-testing` | Performance testing with k6 for SLO validation. |
| `property-based-testing` | Property-based testing across languages and smart contracts. |
| `quality-gates` | Formal quality gates that block releases. |
| `security-testing` | Automated security testing in CI. |
| `testing-implementation` | Concrete test tooling and patterns for TypeScript and Swift. |
| `testing-strategy` | Testing strategy that produces real confidence. |

### Delivery & Release
| Skill | Description |
|-------|-------------|
| `chaos-engineer` | Chaos experiments, failure injection, and resilience testing. |
| `cicd-pipeline` | CI/CD pipeline design with GitHub Actions. |
| `feature-management` | Feature flags, progressive rollout, A/B testing, and kill switches. |
| `incident-management` | Incident response process from detection to postmortem. |
| `production-readiness-review` | Production readiness GO/NO-GO framework. |
| `release-management` | Release management with automated SemVer, changelog generation, release notes, rollback strategies, and hotfix workflow. |

### Documentation & Diagrams
| Skill | Description |
|-------|-------------|
| `architecture-communication` | Communicating architectural decisions to stakeholders. |
| `diagrams` | Architectural diagrams as code using Mermaid and C4 model. |
| `technical-documentation` | Documentation as a living artifact. |

### Data Architecture
| Skill | Description |
|-------|-------------|
| `caching-search` | Distributed caching and full-text search patterns. |
| `data-modeling` | Schema design, multi-tenant data isolation, and migration management. |
| `database-optimizer` | Query optimization, execution plans, and index design. |
| `event-driven-architecture` | Event-driven systems with CloudEvents and GCP Pub/Sub. |

### Architecture & Patterns
| Skill | Description |
|-------|-------------|
| `api-design` | API design conventions for REST and GraphQL. |
| `legacy-modernizer` | Strangler fig pattern, incremental migration, and technical debt reduction. |
| `microservices-architect` | Service decomposition, DDD, saga patterns, and service mesh. |

### AI & Applications
| Skill | Description |
|-------|-------------|
| `rag-architect` | RAG systems, vector databases, semantic search, and document retrieval. |
<!-- claude-skills:end -->
