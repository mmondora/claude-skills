---
name: "Kubernetes Specialist"
description: "Kubernetes workloads, networking, security hardening, Helm, and GitOps."
cluster: "cloud-infrastructure"
---

# Kubernetes Specialist

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Guide the design and implementation of production-grade Kubernetes workloads with proper security hardening, networking, storage, Helm packaging, and GitOps delivery patterns.

---

## When to Apply

- Deploying workloads (Deployments, StatefulSets, DaemonSets, Jobs, CronJobs)
- Configuring networking (Services, Ingress, NetworkPolicies)
- Managing configuration and secrets (ConfigMaps, Secrets, external secret operators)
- Setting up persistent storage (PV, PVC, StorageClasses, CSI drivers)
- Creating or maintaining Helm charts
- Implementing GitOps delivery with ArgoCD or Flux
- Troubleshooting cluster and workload issues

---

## Core Workflow

1. **Analyze requirements** -- understand workload characteristics, scaling needs, security requirements, and SLOs
2. **Design architecture** -- choose workload types, networking patterns, storage solutions, and isolation boundaries
3. **Implement manifests** -- create declarative YAML with resource limits, health checks, and labels
4. **Secure** -- apply RBAC, NetworkPolicies, Pod Security Standards, and least privilege
5. **Package** -- wrap in Helm charts or Kustomize overlays for reusability
6. **Deliver** -- deploy via GitOps pipeline with progressive rollout
7. **Validate** -- verify deployments, test failure scenarios, confirm security posture

---

## Workload Types

| Kind | Use When |
|------|----------|
| **Deployment** | Stateless services, rolling updates, horizontal scaling |
| **StatefulSet** | Ordered startup, stable network identities, persistent volumes per replica |
| **DaemonSet** | Node-level agents (log collectors, monitoring, CNI plugins) |
| **Job** | Run-to-completion batch tasks |
| **CronJob** | Scheduled batch tasks |

Choose the narrowest workload type that fits. Prefer Deployments unless state ordering or node affinity is required.

---

## Networking

### Services

- Use `ClusterIP` for internal traffic (default).
- Use `NodePort` only for development or on-prem bare-metal.
- Use `LoadBalancer` sparingly; prefer Ingress for HTTP(S).
- Use headless services (`clusterIP: None`) for StatefulSets that need stable DNS per pod.

### Ingress

- Use a single Ingress controller (NGINX, Traefik, or cloud-native) per cluster.
- Terminate TLS at the Ingress with cert-manager for automatic certificate rotation.
- Use path-based or host-based routing to consolidate external endpoints.

### NetworkPolicies

Default-deny ingress and egress per namespace, then allow only required traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: my-app
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

Add targeted allow rules for each service pair. Never leave a namespace without a NetworkPolicy.

---

## Security Hardening

### RBAC

- Create dedicated ServiceAccounts per workload -- never use the `default` ServiceAccount.
- Use Roles/RoleBindings (namespaced) over ClusterRoles/ClusterRoleBindings.
- Grant the minimum verbs and resource groups required.
- Audit RBAC periodically with `kubectl auth can-i --list`.

### Pod Security Standards

Apply the `restricted` profile as baseline via Pod Security Admission:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted
```

Key container-level settings:

```yaml
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
  seccompProfile:
    type: RuntimeDefault
```

### Secrets Management

- Never store secrets in ConfigMaps or plain environment variables.
- Use Kubernetes Secrets with encryption at rest enabled.
- Prefer external secret operators (External Secrets Operator, Sealed Secrets) backed by a vault (HashiCorp Vault, GCP Secret Manager, AWS Secrets Manager).
- Rotate secrets automatically; never embed in container images.

---

## Resource Management

Every container must declare requests and limits:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

- Set requests based on observed P95 usage.
- Set CPU limits cautiously (or omit to avoid throttling) -- memory limits are mandatory.
- Use Vertical Pod Autoscaler (VPA) in recommendation mode to right-size.
- Use Horizontal Pod Autoscaler (HPA) based on CPU, memory, or custom metrics.
- Apply LimitRanges and ResourceQuotas per namespace to prevent noisy-neighbor issues.

---

## Health Checks

Every workload must include:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 15
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 5
```

- **Liveness**: restarts the container if it deadlocks. Keep it cheap.
- **Readiness**: removes from Service endpoints during initialization or overload.
- **Startup**: gives slow-starting containers time before liveness kicks in.

---

## Helm Charts

### Chart Structure

```
my-chart/
  Chart.yaml          # name, version, appVersion, dependencies
  values.yaml         # default configuration
  values-prod.yaml    # environment overlay
  templates/
    deployment.yaml
    service.yaml
    ingress.yaml
    networkpolicy.yaml
    serviceaccount.yaml
    _helpers.tpl       # named templates
  tests/
    test-connection.yaml
```

### Best Practices

- Pin chart and dependency versions explicitly.
- Use `{{ include }}` and named templates in `_helpers.tpl` for DRY manifests.
- Validate with `helm lint`, `helm template`, and `helm test`.
- Store charts in an OCI-compliant registry (Harbor, GitHub Container Registry).
- Never use `helm install --set` in production -- all values go through values files committed to Git.

---

## GitOps Delivery

### Principles

- Git is the single source of truth for cluster desired state.
- Changes are applied by pull request, reviewed, then automatically synced.
- Drift is detected and reconciled automatically.
- No manual `kubectl apply` in production.

### ArgoCD Pattern

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    targetRevision: main
    path: environments/production/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Progressive Delivery

Use Argo Rollouts or Flagger for canary and blue-green deployments:
- Canary: shift traffic incrementally (5% -> 25% -> 50% -> 100%) with automated analysis.
- Blue-green: spin up new version in parallel, switch traffic after validation.
- Integrate with Prometheus metrics for automated rollback on error-rate spikes.

---

## Service Mesh Basics

Consider a service mesh (Istio, Linkerd) when you need:
- Mutual TLS (mTLS) between all services without application changes.
- Fine-grained traffic management (retries, timeouts, circuit breaking, traffic splitting).
- Distributed tracing injection at the infrastructure layer.

Start with Linkerd for simplicity. Use Istio when advanced traffic policies or multi-cluster networking is required. Avoid a service mesh if the cluster has fewer than five services.

---

## Labeling Convention

Apply consistent labels to all resources:

```yaml
metadata:
  labels:
    app.kubernetes.io/name: my-app
    app.kubernetes.io/version: "1.2.0"
    app.kubernetes.io/component: api
    app.kubernetes.io/part-of: platform
    app.kubernetes.io/managed-by: helm
```

Labels enable filtering, monitoring dashboards, cost attribution, and NetworkPolicy selectors.

---

## For Claude Code

When generating Kubernetes manifests:
- Always include resource requests/limits, health checks, and a dedicated ServiceAccount.
- Always generate a NetworkPolicy alongside Deployments.
- Use the `restricted` Pod Security Standard unless the workload requires specific capabilities (document why).
- Pin image tags to digests or immutable tags -- never use `latest`.
- Prefer Helm charts over raw manifests for anything beyond a single resource.
- Include RBAC resources when the workload accesses the Kubernetes API.

---

*Internal references*: `containerization/SKILL.md`, `infrastructure-as-code/SKILL.md`, `observability/SKILL.md`
