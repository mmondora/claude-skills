---
name: authn-authz
description: "Authentication and authorization patterns for multi-tenant applications. Firebase Auth, JWT tokens, RBAC/ABAC, tenant isolation guards. Use when implementing login, protecting endpoints, managing roles, or enforcing tenant boundaries."
---

# Authentication & Authorization

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

## Purpose

Patterns for authentication and authorization in multi-tenant context. Firebase Auth as identity provider, JWT for tokens, RBAC/ABAC for permissions.

---

## Authentication (who you are)

### Firebase Auth

Firebase Auth as default identity provider. Supports: email/password, Google Sign-In, Apple Sign-In, OIDC/SAML for enterprise SSO. Advantages: zero infrastructure to manage, client SDKs for web and iOS, integrated with Firestore security rules.

### JWT Token Flow

Firebase Auth issues JWT (ID token) that the client sends as `Authorization: Bearer <token>` on every API request. Backend validates the token with Firebase Admin SDK (verifies signature, expiration, issuer).

Custom claims in JWT for role and tenant: `{ tenantId: "t_abc", role: "admin" }`. Custom claims are set server-side and propagated on next token refresh.

```typescript
async function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const decoded = await firebaseAdmin.auth().verifyIdToken(token);
    req.auth = { uid: decoded.uid, tenantId: decoded.tenantId, role: decoded.role };
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
```

### OAuth2 PKCE Flow (for public clients)

```mermaid
sequenceDiagram
    participant App as Client App
    participant Auth as Auth Server
    participant API as Resource API
    App->>App: Generate code_verifier + code_challenge
    App->>Auth: Authorization request + code_challenge
    Auth->>App: Authorization code
    App->>Auth: Token request + code_verifier
    Auth->>Auth: Verify: SHA256(code_verifier) == code_challenge
    Auth->>App: Access token + Refresh token
    App->>API: API request + Access token
    API->>API: Verify token
    API->>App: Response
```

PKCE (Proof Key for Code Exchange) prevents authorization code interception attacks. Required for all public clients (SPAs, mobile apps). The code_verifier is never sent over the network until the token exchange step.

### Token Revocation

When a user logs out, changes password, or is suspended:

```typescript
// Revoke all refresh tokens for a user
await firebaseAdmin.auth().revokeRefreshTokens(userId);

// In middleware: verify token was issued after last revocation
const decodedToken = await firebaseAdmin.auth().verifyIdToken(token, true); // checkRevoked = true
```

Note: ID tokens remain valid until expiration (up to 1 hour). For immediate effect, maintain a revocation list checked in middleware, or use short-lived tokens (recommended).

### Session Management

Token lifetime: ID token 1 hour (Firebase default, not modifiable), refresh token long-lived. Revocation: Firebase supports refresh token revocation (immediate user block). Backend must verify `auth_time` to detect tokens issued before revocation.

---

## Authorization (what you can do)

### RBAC (Role-Based Access Control)

Default for applications with well-defined roles. Typical roles: `owner` (full tenant access), `admin` (user and config management), `editor` (business data CRUD), `viewer` (read-only). Roles are hierarchical: owner > admin > editor > viewer.

### ABAC (Attribute-Based Access Control)

When RBAC isn't enough: permissions based on user, resource, and context attributes. Example: "an editor can modify only invoices they created" or "a user can access only their department's data." More flexible but more complex. Use only when pure RBAC is insufficient.

### Multi-Tenant Authorization

Fundamental rule: the tenant_id in the JWT token must match the tenant_id of the requested resource. This check is in middleware, before any business logic.

```typescript
function tenantGuard(req: Request, res: Response, next: NextFunction) {
  const tokenTenantId = req.auth.tenantId;
  const resourceTenantId = req.params.tenantId;
  if (tokenTenantId !== resourceTenantId) {
    return res.status(403).json({ error: 'Tenant mismatch' });
  }
  next();
}
```

No exceptions. No "super admin" bypassing tenant checks on normal APIs. Cross-tenant operations live in separate APIs with dedicated authorization.

---

## Service-to-Service Auth

Between microservices: IAM-based on Cloud Run (calling service has `roles/run.invoker`). Token issued automatically by GCP metadata server. No shared secrets, no hardcoded API keys.

For external services: API keys with rotation, scoped to minimum necessary permissions.

---

## For Claude Code

When generating endpoints: auth middleware on every route (never leave an endpoint without auth, not even for testing), tenant guard for multi-tenant resources, role check with decorator or specific middleware. Generate tests for: access without token (401), access to different tenant (403), access with insufficient role (403), authorized access (200).

---

*Internal references*: `security.md`, `api-design.md`, `compliance.md`
