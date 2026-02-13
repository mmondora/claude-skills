---
name: "Insecure Defaults"
description: "Detects fail-open insecure defaults — hardcoded secrets, weak auth, permissive security — that allow apps to run insecurely in production."
cluster: "security-compliance"
---

# Insecure Defaults Detection

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Finds **fail-open** vulnerabilities where applications run insecurely with missing or default configuration. Distinguishes exploitable defaults from fail-secure patterns that crash safely. Covers hardcoded secrets, weak authentication defaults, permissive access controls, and dangerous fallback values.

---

## Core Concept: Fail-Open vs. Fail-Secure

The fundamental distinction:

- **Fail-open (CRITICAL):** `SECRET = env.get('KEY') or 'default'` — App runs with a weak secret
- **Fail-secure (SAFE):** `SECRET = env['KEY']` — App crashes if the variable is missing

A fail-open default means an attacker does not need to exploit a vulnerability — they simply rely on the application running with its built-in insecure configuration.

---

## Scope

### When This Skill Applies

- Security audits of production applications (auth, crypto, API security)
- Configuration review of deployment files, IaC templates, Docker configs
- Code review of environment variable handling and secrets management
- Pre-deployment checks for hardcoded credentials or weak defaults

### Exclusions

Do not flag findings in:

- **Test fixtures** explicitly scoped to test environments (files in `test/`, `spec/`, `__tests__/`)
- **Example/template files** (`.example`, `.template`, `.sample` suffixes)
- **Development-only tools** (local Docker Compose for dev, debug scripts)
- **Documentation examples** in README or docs/ directories
- **Build-time configuration** that gets replaced during deployment
- **Crash-on-missing behavior** where the app refuses to start without proper config (fail-secure)

When in doubt, trace the code path to determine if the app runs with the default or crashes.

---

## Detection Patterns

### Fallback Secrets

Environment variables with insecure fallback values that allow the application to start without proper configuration.

```typescript
// VULNERABLE — app runs with a known, weak secret
const jwtSecret = process.env.JWT_SECRET || 'development-secret';
const apiKey = process.env.API_KEY ?? 'default-key-12345';

// SAFE — app crashes if secret is missing
const jwtSecret = process.env.JWT_SECRET!; // throws at runtime if undefined
// Better: validate at startup
const jwtSecret = z.string().min(32).parse(process.env.JWT_SECRET);
```

**Search patterns:** `getenv.*\) or ['"]`, `process\.env\.[A-Z_]+ \|\| ['"]`, `ENV\.fetch.*default:`

### Hardcoded Credentials

Credentials embedded directly in source code, even when intended as "temporary" or "development-only."

```python
# VULNERABLE — credentials in source
DATABASE_URL = os.getenv("DATABASE_URL", "postgres://admin:password123@localhost/mydb")
ADMIN_PASSWORD = "changeme"

# SAFE — no fallback for production-critical credentials
DATABASE_URL = os.environ["DATABASE_URL"]  # KeyError if missing
```

**Search patterns:** `password.*=.*['"][^'"]{8,}['"]`, `api[_-]?key.*=.*['"][^'"]+['"]`

### Fail-Open Security Flags

Boolean configuration where the default disables security.

```typescript
// VULNERABLE — security disabled by default
const authRequired = process.env.AUTH_REQUIRED !== 'true'; // default: false
const verifySSL = process.env.VERIFY_SSL || 'false';

// SAFE — security enabled by default
const authRequired = process.env.AUTH_REQUIRED !== 'false'; // default: true
const debugMode = process.env.DEBUG === 'true'; // default: false (secure)
```

**Search patterns:** `DEBUG.*=.*true`, `AUTH.*=.*false`, `CORS.*=.*\*`, `VERIFY.*=.*false`

### Weak Cryptographic Defaults

Default algorithms or parameters that use deprecated or weak cryptography.

```typescript
// VULNERABLE — weak hash as default
function hashPassword(password: string, algo = 'md5') {
  return crypto.createHash(algo).update(password).digest('hex');
}

// SAFE — strong algorithm, no developer choice
function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, { type: argon2.argon2id });
}
```

**Search patterns:** `MD5|SHA1|DES|RC4|ECB` in security contexts

### Permissive Access Defaults

Default configurations that grant broader access than necessary.

```yaml
# VULNERABLE — permissive defaults
cors:
  origin: "*"
permissions: "0777"
network_policy: "allow-all"

# SAFE — restrictive defaults
cors:
  origin: "https://app.example.com"
permissions: "0644"
network_policy: "deny-all"
```

### Debug Features Enabled by Default

Stack traces, introspection endpoints, or verbose error messages that leak information.

```typescript
// VULNERABLE — debug mode on by default
const debug = process.env.DEBUG !== 'false'; // true unless explicitly disabled

// SAFE — debug mode off by default
const debug = process.env.DEBUG === 'true'; // false unless explicitly enabled
```

---

## Verification Workflow

### Step 1: Search — Discover Insecure Defaults

Determine the language, framework, and project conventions. Search for patterns in `**/config/`, `**/auth/`, `**/database/`, and environment files. Tailor search approach based on discovery results. Focus on production-reachable code.

### Step 2: Verify — Trace Actual Behavior

For each match, trace the code path:

- When is this code executed? (Startup vs. runtime)
- What happens if the configuration variable is missing?
- Is there validation that enforces secure configuration?
- Does the application start and run, or does it crash?

### Step 3: Confirm — Assess Production Impact

Determine if the issue affects production:

| Scenario | Severity |
|----------|----------|
| Production config provides the variable, but code has fallback | Medium — code-level vulnerability, defense in depth failure |
| Production config missing or uses the insecure default | Critical — exploitable in production |
| Application crashes without proper config (fail-secure) | Not a finding — safe behavior |

### Step 4: Report — Document with Evidence

Every finding includes location, pattern, verification trace, production impact, and exploitation path:

```
Finding: Hardcoded JWT Secret Fallback
Location: src/auth/jwt.ts:15
Pattern: const secret = process.env.JWT_SECRET || 'default';

Verification: App starts without JWT_SECRET; secret used in jwt.sign() at line 42
Production Impact: Dockerfile missing JWT_SECRET environment variable
Exploitation: Attacker forges valid JWTs using 'default', gains unauthorized access
```

---

## Verification Checklist

| Category | Verify | Skip |
|----------|--------|------|
| Fallback secrets | App starts without env var? Secret used in crypto/auth? | Test fixtures, example files |
| Default credentials | Active in deployed config? No runtime override? | Disabled accounts, documentation examples |
| Fail-open security | Default is insecure (false/disabled/permissive)? | App crashes or default is secure |
| Weak crypto | Used for passwords, encryption, or tokens? | Checksums, non-security hashing |
| Permissive access | Default allows unauthorized access? | Explicitly configured with justification |
| Debug features | Enabled by default? Exposed in responses? | Logging-only, not user-facing |

---

## Anti-Patterns

**"It's just a development default"** — If it reaches production code paths, it is a finding. Development defaults must be isolated to development-only configuration files.

**"The production config overrides it"** — Verify the production config exists and is enforced. The code-level vulnerability remains if the config is ever missing.

**"This would never run without proper config"** — Prove it with a code trace. Many applications fail silently with defaults rather than crashing.

**"It's behind authentication"** — Defense in depth applies. A compromised session still exploits weak defaults.

**"We'll fix it before release"** — Document now. The secure pattern is to fail-secure from the start, not to add validation later.

---

## For Claude Code

When generating code: always use fail-secure patterns for secrets and credentials (crash on missing, never provide fallback values). Validate all security-critical configuration at startup with Zod schemas. Default boolean security flags to the secure state (auth enabled, debug disabled, SSL verification on). Never use weak cryptographic algorithms as defaults. Use `process.env.VAR!` or explicit validation rather than `process.env.VAR || 'fallback'` for any secret or security-sensitive configuration.

---

*Internal references*: `security-by-design/SKILL.md`, `owasp-security/SKILL.md`, `authn-authz/SKILL.md`
