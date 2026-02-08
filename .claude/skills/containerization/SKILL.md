---
name: containerization
description: "Docker best practices for cloud-native applications. Multi-stage builds, distroless images, security scanning, non-root users, Cloud Run orchestration. Use when writing Dockerfiles, configuring container builds, or deploying to Cloud Run/GKE."
---

# Containerization

## Purpose

Best practices for Docker in cloud-native context. Secure, lightweight, and reproducible images.

---

## Dockerfile Best Practices

**Multi-stage build** always. Stage 1: build (with devDependencies). Stage 2: runtime (only production dependencies and compiled artifact).

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
RUN addgroup -g 1001 -S appgroup && adduser -u 1001 -S appuser -G appgroup
USER appuser
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

**Base images**: `node:22-alpine` for build, `gcr.io/distroless/nodejs22-debian12` for runtime (when possible — distroless has no shell, more secure). Alpine as fallback.

**Layer caching**: COPY package.json and npm ci before COPY of source code. Dependency layer is cached when only code changes.

**Non-root user**: never run as root in the container. Create a dedicated user with UID > 1000.

**.dockerignore**: exclude node_modules, .git, .env, test/, docs/, *.md. Build context must be minimal.

---

## Security Scanning

**Vulnerability scanning**: automatic image scanning in CI with Trivy or Grype. Block deploy on CRITICAL vulnerabilities. WARNING for HIGH (with fix deadline).

**No secrets in Dockerfile**: never COPY .env files or secrets. Use runtime environment variables or secret manager mounts.

**Version pinning**: `FROM node:22.11-alpine`, not `FROM node:latest`. Digest pinning (`FROM node@sha256:...`) for maximum reproducibility in production.

---

## Container Orchestration

**Cloud Run** as default. Configuration: concurrency (requests per instance), min/max instances, CPU allocation (always-on vs request-only), memory limits, startup/liveness probes.

**GKE** only when needed: stateful workloads, GPU, advanced scheduling, service mesh. GKE complexity is a cost — justify in ADR.

---

## For Claude Code

When generating Dockerfiles: multi-stage, non-root user, alpine or distroless, .dockerignore, optimized layer caching. Include health check endpoint in CMD or HEALTHCHECK instruction.

---

*Internal references*: `cloud-architecture.md`, `security.md`, `cicd.md`
