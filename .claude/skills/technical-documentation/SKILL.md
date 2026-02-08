---
name: technical-documentation
description: "Documentation as a living artifact. README structure, architecture docs, runbooks, API docs, onboarding guides. Use when creating project documentation, writing runbooks, or generating API documentation."
---

# Technical Documentation

## Purpose

Documentation as a living artifact, not a formality. Covers architecture docs, runbooks, API docs, and onboarding guides. Documentation that nobody reads is worse than no documentation (it creates the illusion of being informed).

---

## Documentation Types

### README.md (per project/service)

Answers: what it is, how to start it, how to test it, how to deploy it. A new developer must be able to set up and first-run in < 30 minutes following only the README.

Structure: name and description (1-2 sentences), prerequisites (runtime, tools, access), local setup (step by step, copy-pasteable), main commands (dev, test, build, deploy), architecture (link to diagram or brief description), links to deeper documentation.

### Architecture Docs

Documents describing system design at different detail levels. Live in `docs/architecture/`. Use the C4 model (Context, Container, Component, Code) to structure levels. Don't document every detail — document decisions and boundaries. Code documents itself for implementation details.

### Runbook

Operational guide for managing the service in production. Per service: how to verify it's healthy, what to do if it's down, how to check logs, how to rollback, escalation contacts.

Written for someone on-call at 3 AM who doesn't know the service in detail. Must be clear, step-by-step, with copy-pasteable commands.

### API Documentation

Generated from OpenAPI spec (code-first). Published as interactive page (Swagger UI or Redoc). Includes: endpoint descriptions, request/response schemas, examples, error codes, required authentication.

### Onboarding Guide

For new team members. Covers: business context (what the product does), high-level architecture (C4 Context diagram), tech stack and why, how to navigate the code, processes (PR, review, deploy), who to ask what.

---

## Principles

**Docs-as-code**: documentation lives in the repo, versioned with git, reviewed in PRs. If code changes, the PR must update related docs.

**Write for the reader, not for yourself**: whoever reads in 6 months doesn't have your context. Write for that person.

**Less is more**: short, updated documentation > exhaustive, obsolete documentation. Every doc page has a maintenance cost.

**Automated where possible**: API docs from OpenAPI, CHANGELOG from commits, diagrams from code (Mermaid). Less manual docs = less obsolete docs.

---

## For Claude Code

When generating documentation: README for every new project/service, JSDoc/TSDoc for public APIs, update README if changes affect setup or commands. Never generate generic documentation — every document has a target reader and specific context.

---

*Internal references*: `diagrams.md`, `architecture-comms.md`, `api-design.md`
