---
name: containerization
description: "Docker best practices for cloud-native applications. Multi-stage builds, distroless images, security scanning, non-root users, Cloud Run orchestration. Use when writing Dockerfiles, configuring container builds, or deploying to Cloud Run/GKE."
---

# Containerization

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

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

### Distroless Runtime Example

For maximum security — no shell, no package manager, no OS utilities in the final image:

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && cp -R node_modules /prod_modules
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Distroless runtime
FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /prod_modules ./node_modules
COPY --from=builder /app/package.json ./
USER 1001
EXPOSE 3000
CMD ["dist/main.js"]
```

### HEALTHCHECK Instruction

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://localhost:3000/health').then(r => { if (!r.ok) process.exit(1) })"]
```

Note: Cloud Run manages its own health checks via startup/liveness probes — `HEALTHCHECK` is useful for Docker Compose and standalone Docker deployments.

---

## Security Scanning

**Vulnerability scanning**: automatic image scanning in CI with Trivy or Grype. Block deploy on CRITICAL vulnerabilities. WARNING for HIGH (with fix deadline).

```yaml
# GitHub Actions — container scan step
- name: Build container image
  run: docker build -t ${{ env.IMAGE }} .

- name: Scan container image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.IMAGE }}'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Upload scan results
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```

**No secrets in Dockerfile**: never COPY .env files or secrets. Use runtime environment variables or secret manager mounts.

**Version pinning**: `FROM node:22.11-alpine`, not `FROM node:latest`. Digest pinning (`FROM node@sha256:...`) for maximum reproducibility in production.

---

## Docker Compose for Local Development

```yaml
# docker-compose.yml
services:
  api:
    build:
      context: .
      target: builder  # Use build stage for hot reload
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - FIRESTORE_EMULATOR_HOST=firestore:8080
      - PUBSUB_EMULATOR_HOST=pubsub:8085
    volumes:
      - ./src:/app/src  # Hot reload
    depends_on:
      - firestore
      - pubsub

  firestore:
    image: google/cloud-sdk:slim
    command: gcloud emulators firestore start --host-port=0.0.0.0:8080
    ports:
      - "8080:8080"

  pubsub:
    image: google/cloud-sdk:slim
    command: gcloud beta emulators pubsub start --host-port=0.0.0.0:8085
    ports:
      - "8085:8085"
```

---

## Image Size Optimization

| Technique | Impact |
|-----------|--------|
| Multi-stage build | Removes build tools and devDependencies from final image |
| Alpine base | ~5MB vs ~100MB for Debian |
| Distroless base | ~20MB, no shell/utilities, smallest attack surface |
| `.dockerignore` | Reduces build context, prevents accidental inclusion |
| `npm ci --only=production` | Excludes devDependencies from runtime |
| Minimize layers | Combine RUN commands with `&&` to reduce layer count |

Target: production Node.js images < 150MB (alpine), < 80MB (distroless).

### Multi-Arch Build

For ARM64 (Cloud Run supports it, lower cost) + AMD64 compatibility:

```bash
# Build and push multi-arch image
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ${REGISTRY}/${IMAGE}:${TAG} \
  --push .
```

---

## Container Orchestration

**Cloud Run** as default. Configuration: concurrency (requests per instance), min/max instances, CPU allocation (always-on vs request-only), memory limits, startup/liveness probes.

**GKE** only when needed: stateful workloads, GPU, advanced scheduling, service mesh. GKE complexity is a cost — justify in ADR.

---

## Anti-Patterns

- **Running as root**: default Docker user is root — always create and switch to a non-root user
- **Using `latest` tag**: non-reproducible builds — always pin specific versions
- **Secrets in image layers**: even deleted files remain in earlier layers — use multi-stage or secrets mounts
- **Fat images**: including build tools, test files, docs in production image — multi-stage solves this
- **No `.dockerignore`**: sending entire repo as build context including `.git`, `node_modules`, `.env`
- **No health check**: container has no way to signal it's unhealthy — include health check endpoint
- **Single-stage builds**: mixing build and runtime — always use multi-stage

---

## For Claude Code

When generating Dockerfiles: multi-stage, non-root user, alpine or distroless, .dockerignore, optimized layer caching. Include health check endpoint in CMD or HEALTHCHECK instruction. Generate docker-compose.yml for local development with GCP emulators. Include Trivy scan step in CI pipeline.

---

*Internal references*: `infrastructure-as-code/SKILL.md`, `security-by-design/SKILL.md`, `cicd-pipeline/SKILL.md`
