---
name: technical-documentation
description: "Documentation as a living artifact. README structure, architecture docs, runbooks, API docs, onboarding guides. Use when creating project documentation, writing runbooks, or generating API documentation."
---

# Technical Documentation

> **Version**: 1.2.0 | **Last updated**: 2026-02-09

## Purpose

Documentation as a living artifact, not a formality. Covers architecture docs, runbooks, API docs, and onboarding guides. Documentation that nobody reads is worse than no documentation (it creates the illusion of being informed).

---

## Documentation Types

### README.md (per project/service)

Answers: what it is, how to start it, how to test it, how to deploy it. A new developer must be able to set up and first-run in < 30 minutes following only the README.

Structure: name and description (1-2 sentences), prerequisites (runtime, tools, access), local setup (step by step, copy-pasteable), main commands (dev, test, build, deploy), architecture (link to diagram or brief description), links to deeper documentation.

#### README Template

```markdown
# [Service Name]

[One-sentence description of what this service does and who it serves.]

## Prerequisites

- Node.js >= 22 (LTS)
- Docker & Docker Compose
- GCP CLI (`gcloud`) — authenticated
- Access to [relevant GCP project]

## Quick Start

```bash
# Clone and install
git clone <repo-url>
cd <service-name>
npm ci

# Start local dependencies (Firestore emulator, Pub/Sub emulator)
docker compose up -d

# Run in development mode
npm run dev

# Verify it's working
curl http://localhost:3000/health
```

## Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start in development mode with hot reload |
| `npm test` | Run unit and integration tests |
| `npm run test:coverage` | Run tests with coverage report |
| `npm run build` | Build for production |
| `npm run lint` | Run linter |
| `npm run typecheck` | Run TypeScript type checking |

## Architecture

[Brief description or link to C4 diagram in `docs/architecture/`]

## API Documentation

[Link to OpenAPI spec or Swagger UI URL]

## Related Documentation

- [Architecture Overview](docs/architecture/overview.md)
- [Runbook](docs/runbook.md)
- [ADRs](adr/)
```

### Architecture Docs

Documents describing system design at different detail levels. Live in `docs/architecture/`. Use the C4 model (Context, Container, Component, Code) to structure levels. Don't document every detail — document decisions and boundaries. Code documents itself for implementation details.

### Runbook

Operational guide for managing the service in production. Per service: how to verify it's healthy, what to do if it's down, how to check logs, how to rollback, escalation contacts.

Written for someone on-call at 3 AM who doesn't know the service in detail. Must be clear, step-by-step, with copy-pasteable commands.

#### Runbook Template

```markdown
# Runbook: [Service Name]

## Service Overview
- **Team**: [team name]
- **On-call**: [rotation link]
- **Dashboard**: [link]
- **Logs**: [Cloud Logging filter link]

## Health Check

```bash
# Check service health
curl https://[service-url]/health

# Check Cloud Run status
gcloud run services describe [service-name] --region=[region] --format='value(status.conditions)'
```

## Common Issues

### Service returning 5xx errors
1. Check logs: `gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" --limit=50`
2. Check dependencies: [DB health, Pub/Sub health, external APIs]
3. If recent deploy: rollback — `gcloud run services update-traffic [SERVICE] --to-revisions=[PREV]=100`
4. Escalate if unresolved after 15 minutes

### High latency (p99 > SLO)
1. Check dashboard for saturation metrics (CPU, memory, connections)
2. Check for recent traffic spike
3. Scale up if needed: increase max-instances
4. Check for slow DB queries in logs

## Rollback

```bash
# List recent revisions
gcloud run revisions list --service=[service-name] --region=[region]

# Rollback to previous revision
gcloud run services update-traffic [service-name] --to-revisions=[previous-revision]=100 --region=[region]
```

## Escalation
- **L1**: On-call engineer (this runbook)
- **L2**: Team lead — [name, contact]
- **L3**: Platform team — [contact]
```

### API Documentation

Generated from OpenAPI spec (code-first). Published as interactive page (Swagger UI or Redoc). Includes: endpoint descriptions, request/response schemas, examples, error codes, required authentication.

#### API Docs Generation Setup

```typescript
// In Fastify — auto-generate OpenAPI from route schemas
import fastifySwagger from '@fastify/swagger';
import fastifySwaggerUi from '@fastify/swagger-ui';

app.register(fastifySwagger, {
  openapi: {
    info: { title: 'Invoice API', version: '1.0.0' },
    servers: [{ url: '/api/v1' }],
    components: {
      securitySchemes: {
        bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      },
    },
  },
});

app.register(fastifySwaggerUi, { routePrefix: '/docs' });
```

### Onboarding Guide

For new team members. Covers: business context (what the product does), high-level architecture (C4 Context diagram), tech stack and why, how to navigate the code, processes (PR, review, deploy), who to ask what.

---

## Principles

**Docs-as-code**: documentation lives in the repo, versioned with git, reviewed in PRs. If code changes, the PR must update related docs.

**Write for the reader, not for yourself**: whoever reads in 6 months doesn't have your context. Write for that person.

**Less is more**: short, updated documentation > exhaustive, obsolete documentation. Every doc page has a maintenance cost.

**Automated where possible**: API docs from OpenAPI, CHANGELOG from commits, diagrams from code (Mermaid). Less manual docs = less obsolete docs.

---

## Documentation Review Checklist

- [ ] README allows setup in < 30 minutes without asking questions
- [ ] All commands are copy-pasteable (no placeholders without explanation)
- [ ] Architecture diagrams match current implementation
- [ ] Runbook tested by someone who didn't write it
- [ ] API docs match actual endpoint behavior (verified by contract tests)
- [ ] No stale links (internal or external)
- [ ] Sensitive information (credentials, internal URLs) not present
- [ ] Target audience is clear (developer, ops, product)

---

## Docs Testing

Automate documentation quality checks in CI:

### Link Checking

```yaml
# In CI — check for broken links
- name: Check documentation links
  uses: lycheeverse/lychee-action@v1
  with:
    args: --verbose --no-progress '**/*.md'
    fail: true
```

### Docs Linting

Use markdownlint for consistent formatting:

```yaml
- name: Lint markdown
  uses: DavidAnson/markdownlint-cli2-action@v14
  with:
    globs: 'docs/**/*.md'
```

### Hosting Options

| Option | Best For | Cost |
|--------|----------|------|
| GitHub Pages | Open source, simple docs | Free |
| Docusaurus | Developer docs with versioning | Self-hosted |
| Backstage | Internal developer portal | Self-hosted |
| Notion/Confluence | Non-technical stakeholders | Paid |

Rule: developer docs live in the repo (docs-as-code). Business/product docs may live in Notion/Confluence — but link from the repo README.

---

## Anti-Patterns

- **Documentation as afterthought**: docs written months after code — they'll be incomplete and inaccurate
- **Copy-paste without context**: copying templates without filling in specifics — generic docs are worse than no docs
- **Documentation as ceremony**: creating docs to "check a box" without intent to maintain — creates false confidence
- **Internal-only knowledge**: "everyone knows how this works" — until the person who knows leaves
- **Screenshot-heavy docs**: screenshots become stale immediately — prefer text, commands, and code
- **No ownership**: documentation without a maintainer becomes stale — every doc has an owner

---

## For Claude Code

When generating documentation: README for every new project/service, JSDoc/TSDoc for public APIs, update README if changes affect setup or commands. Never generate generic documentation — every document has a target reader and specific context. Generate runbook templates for production services. Include API docs generation setup with OpenAPI.

---

*Internal references*: `diagrams/SKILL.md`, `architecture-communication/SKILL.md`, `api-design/SKILL.md`
