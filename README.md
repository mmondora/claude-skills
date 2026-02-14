# claude-skills

An operational knowledge system for [Claude Code](https://claude.ai/claude-code) — 26 skills that guide Claude in generating enterprise-grade software.

Not a boilerplate. Not a template. A system of conventions, patterns, and guardrails that Claude Code consults **before** writing code, infrastructure, tests, or documentation.

## What's Inside

```
claude-skills/
  .claude/skills/                        # 27 Claude Code skills (one per directory)
  skills/                                # Symlink → .claude/skills/ (for easy browsing)
  .githooks/pre-commit                   # Auto-updates README.md on commit
  scripts/install-from-github.sh         # Remote installer (downloads from GitHub)
  scripts/update-skills.sh               # Remote updater (pulls latest, updates changed)
  scripts/install-skills.sh              # Local installer (from zip)
  scripts/build-zip.sh                   # Builds versioned distribution zip
  scripts/generate-readme.sh             # Skills catalog → README.md
  scripts/claude-skills-<version>.zip    # Distribution package
  CLAUDE.md                              # Master configuration
```

## Skills Catalog (68 skills)

<!-- SKILLS_START -->

### Foundations
| Skill | What it covers |
|-------|----------------|
| `architecture-decision-records` | Architecture Decision Records governance and format. ADR lifecycle, review process, when to write an ADR |
| `ask-questions-if-underspecified` | description: Clarify underspecified requirements before implementation. |
| `prompt-architect` | Analyzes and transforms prompts using 8 research-backed frameworks (CO-STAR, RISEN, RISE-IE, RISE-IX, TIDD-EC, RTF, Chain of Thought, Chain of Density). Provides framework recommendations, asks targeted questions, and structures prompts for maximum effectiveness |
| `skill-clusters` | Skill cluster index and loader. Maps clusters to their constituent skills, enabling bulk loading by domain |

### Cloud & Infrastructure
| Skill | What it covers |
|-------|----------------|
| `containerization` | Docker best practices for cloud-native applications. Multi-stage builds, distroless images, security scanning, non-root users, Cloud Run orchestration |
| `finops` | Cloud cost management as an architectural discipline. Unit economics, right-sizing, GCP free tier optimization, budget alerts, serverless-first |
| `infrastructure-as-code` | Infrastructure as Code with Terraform and Pulumi. State management, modularity, drift detection, secrets handling |
| `observability` | Logging, metrics, and tracing with OpenTelemetry. Structured JSON logs, 4 golden signals, distributed tracing, SLO-based alerting |
| `terraform-style-guide` | description: Generate Terraform HCL code following HashiCorp's official style conventions and best practices |
| `terraform-test` | description: Comprehensive guide for writing and running Terraform tests |

### Security & Compliance
| Skill | What it covers |
|-------|----------------|
| `authn-authz` | Authentication and authorization patterns for multi-tenant applications. Firebase Auth, JWT tokens, RBAC/ABAC, tenant isolation guards |
| `compliance-privacy` | GDPR compliance and privacy as architectural constraints. Data minimization, right to be forgotten, data residency, audit trails, retention policies |
| `differential-review` | description: > |
| `owasp-security` | description: Use when reviewing code for security vulnerabilities, implementing authentication/authorization, handling user input, or discussing web application security. Covers OWASP Top 10:2025, ASVS 5.0, and Agentic AI security (2026). |
| `security-by-design` | Security as a design property, not an added layer. OWASP Top 10, supply chain security, secrets management, zero trust |

### Testing & Quality
| Skill | What it covers |
|-------|----------------|
| `performance-testing` | Performance testing with k6 for SLO validation. Load, stress, soak, and spike tests |
| `property-based-testing` | description: Provides guidance for property-based testing across multiple languages and smart contracts |
| `quality-gates` | Formal quality gates that block releases. Tests, static quality, security, performance, reliability, documentation gates with PASS/FAIL verdicts |
| `security-testing` | Automated security testing in CI. SAST, DAST, dependency scanning, authorization testing, secret detection |
| `testing-implementation` | Concrete test tooling and patterns for TypeScript and Swift. Vitest, Testing Library, XCTest, Playwright, contract testing |
| `testing-strategy` | Testing strategy that produces real confidence. Test pyramid, coverage rules, what to test and what not to test |
| `verification-before-completion` | description: No completion claims without fresh verification evidence. |

### Delivery & Release
| Skill | What it covers |
|-------|----------------|
| `chaos-engineer` | Chaos engineering for resilience validation. Experiment design, blast radius control, failure injection, game days, continuous chaos in CI/CD |
| `cicd-pipeline` | CI/CD pipeline design with GitHub Actions. Pipeline stages, caching, environments, blue-green and canary deployments |
| `executing-plans` | description: Execute implementation plans in batches with feedback checkpoints. |
| `feature-management` | Feature flags, progressive rollout, A/B testing, and kill switches. Flag types, hygiene, implementation patterns |
| `finishing-a-development-branch` | description: Complete feature branches safely with structured options. |
| `incident-management` | Incident response process from detection to postmortem. Severity levels, communication templates, blameless postmortems, incident metrics |
| `production-readiness-review` | Production readiness GO/NO-GO framework. NFR checklist covering availability, scalability, observability, security, compliance |
| `release-management` | Release management with automated SemVer, changelog generation, release notes, rollback strategies, and hotfix workflow |
| `using-git-worktrees` | description: Set up isolated git worktree workspaces for feature development. |
| `writing-plans` | description: Break requirements into TDD-based micro-task implementation plans. |

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
| `database-optimizer` | Database performance optimization for PostgreSQL and MySQL. Query analysis, execution plans, index design, partitioning, connection pooling, lock contention |
| `event-driven-architecture` | Event-driven systems with CloudEvents and GCP Pub/Sub. Event design, schema evolution, delivery guarantees, idempotency, eventual consistency |

### Architecture & Patterns
| Skill | What it covers |
|-------|----------------|
| `api-design` | API design conventions for REST and GraphQL. Resource naming, versioning, pagination, error responses (RFC 7807), OpenAPI-first workflow, backward compatibility |
| `error-handling-resilience` | Error handling and resilience patterns for distributed systems. Typed errors, circuit breakers, retry with backoff, bulkheads, timeout budgets, graceful degradation and shutdown |
| `legacy-modernizer` | Incremental migration strategies for legacy systems. Strangler fig pattern, branch by abstraction, characterization testing, zero-downtime migration |
| `microservices-architect` | Service decomposition and distributed system design. Domain-driven design, bounded contexts, inter-service communication, data ownership, resilience patterns, service mesh |
| `microservices-patterns` | Microservices patterns for service decomposition, inter-service communication, and operational concerns. Bounded contexts, database per service, CQRS, API gateway, distributed tracing, and resilience |

### AI & Applications
| Skill | What it covers |
|-------|----------------|
| `rag-architect` | Retrieval-Augmented Generation system design. Vector databases, embedding models, chunking strategies, hybrid search, reranking, RAG evaluation |

### Mobile & Native
| Skill | What it covers |
|-------|----------------|
| `apple-compliance-audit` | Apple App Store compliance audit for iOS apps covering Info.plist, entitlements, privacy manifests, App Store Review Guidelines, HIG, security, and submission readiness |
| `ios-app-audit` | Comprehensive production audit for iOS apps covering security, App Store compliance, privacy, reliability, performance, accessibility, and code quality |
| `ios-gui-assessment` | Audit iOS SwiftUI/UIKit projects for GUI consistency, native Apple control usage, HIG conformance, deprecated API detection, OS version compatibility, and accessibility |

### Green Software & Sustainability
| Skill | What it covers |
|-------|----------------|
| `carbon-aware-architecture` | Carbon-aware design patterns from the Green Software Foundation. Time shifting, spatial shifting, demand shaping, Carbon Aware SDK, carbon-aware CI/CD, region selection |
| `green-software-principles` | Green Software Foundation principles as an architectural discipline. Carbon efficiency, energy efficiency, carbon awareness, hardware efficiency, measurement, climate commitments |
| `sci-measurement` | Software Carbon Intensity (SCI) measurement per ISO/IEC 21031:2024. SCI formula, energy measurement, carbon intensity data, embodied carbon, functional units, CI integration |
| `sustainability-impact-assessment` | Sustainability governance council for software projects. Impact assessment framework, green PRR checklist, sustainability review process, GSF Maturity Matrix self-assessment, broader impact (social, environmental, economic) |

### Uncategorized
| Skill | What it covers |
|-------|----------------|
| `architecture-review-facilitation` | Architecture review governance and facilitation. Divulgative, decisional, and lightweight review types. Requestor preparation, facilitation guide, outcome recording |
| `architecture-risk-assessment` | Architectural risk identification, assessment, and mitigation. Risk register, assumption mapping, dependency analysis, failure mode analysis |
| `architecture-stakeholder-communication` | Strategic architecture communication for non-technical stakeholders. Executive briefs, architecture pitches, technical risk translation, simplified visualization |
| `fitness-functions` | Architecture fitness functions as automated quality attribute guardrails. Taxonomy, implementation patterns, catalog template, evolutionary governance |
| `functional-analysis` | Functional analysis bridging business requirements to architecture. Domain analysis, event storming, use case specification, bounded context mapping |
| `graphql-architect` | GraphQL schema design, Apollo Federation, DataLoader patterns, and query optimization. |
| `insecure-defaults` | Detects fail-open insecure defaults — hardcoded secrets, weak auth, permissive security — that allow apps to run insecurely in production. |
| `integration-design` | Integration design for cross-boundary communication. Pattern catalog, contract-first design, anti-corruption layers, data consistency across boundaries |
| `kubernetes-specialist` | Kubernetes workloads, networking, security hardening, Helm, and GitOps. |
| `nfr-specification` | Non-functional requirements specification using ISO 25010 quality model. Quality attribute scenarios (SEI method), NFR elicitation, prioritization, and validation |
| `platform-architecture` | Platform thinking and capability mapping. Self-service APIs, thin vs thick platform, Team Topologies alignment, golden paths, platform health metrics |
| `pypict-claude-skill` | Pairwise and combinatorial test case design using PICT models. |
| `sharp-edges` | Identifies error-prone APIs, dangerous configurations, and footgun designs that enable security mistakes through poor developer ergonomics. |
| `systematic-debugging` | Root-cause-first debugging methodology with four-phase investigation process. |
| `trade-off-analysis` | Systematic trade-off analysis for architectural decisions. Structured evaluation method, weighted scoring, reversibility assessment, cost-of-change estimation |
| `websocket-engineer` | Real-time communication with WebSocket and Socket.IO, scaling, and presence patterns. |

<!-- SKILLS_END -->

## Community Skills (1,300+ skills)

In addition to the 26 curated skills above, this repo includes **community-contributed
skills** from the open-source ecosystem. These are kept in their original format in
the `community/` directory.

See [community/README.md](community/README.md) for the full catalog, installation
instructions, and license information.

### Highlights

| Source | Skills | Focus | License |
|--------|--------|-------|---------|
| [obra/superpowers](https://github.com/obra/superpowers) | 14 | TDD, debugging, collaboration, planning | MIT |
| [anthropics/skills](https://github.com/anthropics/skills) | 16 | Docs, design, dev tools (official) | Anthropic |
| [trailofbits/skills](https://github.com/trailofbits/skills) | 52 | Security analysis, fuzzing, code auditing | CC-BY-SA-4.0 |
| [jeffallan/claude-skills](https://github.com/jeffallan/claude-skills) | 66 | Full-stack dev, 30+ frameworks | MIT |
| [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | 149 | Bioinformatics, chemistry, ML | MIT |
| [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 939 | Service automations (Slack, Airtable...) | No license |
| + 14 more repos | ~64 | Various | See [LICENSES.md](community/LICENSES.md) |

### Copyright

Community skills are copyright their respective authors and distributed under their
original licenses. See [community/LICENSES.md](community/LICENSES.md) for full details.

## Installation

### Install from GitHub (recommended)

No clone needed — downloads skills directly from GitHub into your project:

```bash
# Download the script
curl -sLO https://raw.githubusercontent.com/mmondora/claude-skills/main/scripts/install-from-github.sh
chmod +x install-from-github.sh

# Install all 27 curated skills
./install-from-github.sh /path/to/your/project

# Install only specific clusters
./install-from-github.sh /path/to/your/project --cluster security-compliance
./install-from-github.sh /path/to/your/project --cluster testing-quality --cluster delivery-release

# See available clusters
./install-from-github.sh --list-clusters
```

This does three things:
1. Downloads curated skills from GitHub (only those with a `cluster:` field)
2. Installs them into `your-project/.claude/skills/`, merging with any existing skills
3. Adds (or updates) a cluster-grouped skill reference table in `your-project/CLAUDE.md`

#### Available Clusters

| Cluster | Skills |
|---------|--------|
| `foundations` | architecture-decision-records, prompt-architect, skill-clusters |
| `cloud-infrastructure` | infrastructure-as-code, finops, containerization, observability |
| `security-compliance` | security-by-design, compliance-privacy, authn-authz |
| `testing-quality` | testing-strategy, testing-implementation, performance-testing, security-testing, quality-gates |
| `delivery-release` | cicd-pipeline, release-management, feature-management, production-readiness-review, incident-management |
| `documentation-diagrams` | technical-documentation, diagrams, architecture-communication |
| `data-architecture` | data-modeling, event-driven-architecture, caching-search |
| `api-integration` | api-design |

#### Options

```bash
# Overwrite existing skills (update to latest)
./install-from-github.sh /path/to/project --force

# Install skills only, don't touch CLAUDE.md
./install-from-github.sh /path/to/project --no-patch

# Use a different branch
./install-from-github.sh /path/to/project --branch develop

# Use a fork
./install-from-github.sh /path/to/project --repo your-user/claude-skills
```

### Updating Skills

Already installed skills and want the latest versions? Use the updater:

```bash
# Update all curated skills to latest
./scripts/update-skills.sh /path/to/your/project

# Preview what would change without applying
./scripts/update-skills.sh /path/to/your/project --dry-run

# Update from a specific branch
./scripts/update-skills.sh /path/to/your/project --branch develop
```

The updater compares local vs remote content, then:
- **Installs** skills that are missing locally (`[new]`)
- **Overwrites** skills whose content has changed (`[updated]`)
- **Skips** skills that are already up to date (`[current]`)
- Updates the skill catalog in `CLAUDE.md`

If `.claude/skills/` doesn't exist yet, it performs a fresh install (same as `install-from-github.sh`).

#### Options

```bash
# Skip CLAUDE.md patching
./scripts/update-skills.sh /path/to/project --no-patch

# Use a fork
./scripts/update-skills.sh /path/to/project --repo your-user/claude-skills
```

### Install from Local Clone

If you prefer working from a local clone:

```bash
git clone <this-repo> claude-skills
./claude-skills/scripts/install-skills.sh /path/to/your/project
```

Options: `--force` (overwrite), `--no-patch` (skip CLAUDE.md), `--no-hooks` (skip pre-commit hook).

### Manual Install

```bash
# Unzip directly into your project
unzip claude-skills.zip -d /path/to/your/project/
```

This creates `.claude/skills/<skill-name>/SKILL.md` for each skill.

### Install Community Skills

```bash
# Install a single community skill
cp -r community/skills/obra-superpowers/brainstorming /path/to/project/.claude/skills/

# Install all skills from a source
cp -r community/skills/obra-superpowers/* /path/to/project/.claude/skills/

# Install curated + community skills via installer
./scripts/install-skills.sh /path/to/project --include-community
```

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
  <skill-name>/SKILL.md      #   Each skill has YAML frontmatter with name, cluster, description
.githooks/
  pre-commit                 # Auto-updates README.md before each commit
scripts/
  install-from-github.sh     # Remote installer (downloads from GitHub, supports --cluster)
  update-skills.sh           # Remote updater (pulls latest, updates changed, --dry-run)
  install-skills.sh          # Local installer (from zip)
  generate-readme.sh         # Regenerates skills catalog in README.md
CLAUDE.md                    # Master configuration
README.md                    # Auto-updated project documentation
```

## Contributing

Skills follow the same quality standards they teach:

- Edit skill files in `.claude/skills/<skill-name>/SKILL.md`
- Each skill has YAML frontmatter with `name`, `cluster`, and `description`
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
