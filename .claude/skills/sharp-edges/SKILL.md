---
name: "Sharp Edges"
description: "Identifies error-prone APIs, dangerous configurations, and footgun designs that enable security mistakes through poor developer ergonomics."
cluster: "security-compliance"
---

# Sharp Edges Analysis

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Evaluates whether APIs, configurations, and interfaces are resistant to developer misuse. Identifies designs where the "easy path" leads to insecurity. The core principle is the **pit of success**: secure usage should be the path of least resistance. If developers must understand cryptography, read documentation carefully, or remember special rules to avoid vulnerabilities, the API has failed.

---

## Scope

### When This Skill Applies

- Reviewing API or library design decisions
- Auditing configuration schemas for dangerous options
- Evaluating cryptographic API ergonomics
- Assessing authentication/authorization interfaces
- Reviewing any code that exposes security-relevant choices to developers

### Exclusions

- Implementation bugs (use standard code review)
- Business logic flaws (use domain-specific analysis)
- Performance optimization (different concern)

---

## Sharp Edge Categories

### 1. Algorithm/Mode Selection Footguns

APIs that let developers choose algorithms invite choosing wrong ones.

**The JWT Pattern** (canonical example):
- Header specifies algorithm: attacker can set `"alg": "none"` to bypass signatures
- Algorithm confusion: RSA public key used as HMAC secret when switching RS256 to HS256
- Root cause: letting untrusted input control security-critical decisions

**Detection patterns:**
- Function parameters like `algorithm`, `mode`, `cipher`, `hash_type`
- Enums/strings selecting cryptographic primitives
- Configuration options for security mechanisms

```php
// DANGEROUS: allows crc32, md5, sha1
hash($algorithm, $password); // BAD: accepts "crc32"

// SAFE: no choice exposed
password_hash($password, PASSWORD_DEFAULT);
```

### 2. Dangerous Defaults

Defaults that are insecure, or zero/empty values that disable security.

**The OTP Lifetime Pattern:**
```python
# What happens when lifetime=0?
def verify_otp(code, lifetime=300):  # 300 seconds default
    if lifetime == 0:
        return True  # OOPS: 0 means "accept all"?
        # Or does it mean "expired immediately"?
```

**Detection patterns:**
- Timeouts/lifetimes that accept 0 (infinite? immediate expiry?)
- Empty strings that bypass checks
- Null values that skip validation
- Boolean defaults that disable security features
- Negative values with undefined semantics

**Questions to ask:**
- What happens with `timeout=0`? `max_attempts=0`? `key=""`?
- Is the default the most secure option?
- Can any default value disable security entirely?

### 3. Primitive vs. Semantic APIs

APIs that expose raw bytes instead of meaningful types invite type confusion.

```php
// Libsodium (primitives): bytes are bytes
sodium_crypto_box($message, $nonce, $keypair);
// Easy to: swap nonce/keypair, reuse nonces, use wrong key type

// Halite (semantic): types enforce correct usage
Crypto::seal($message, new EncryptionPublicKey($key));
// Wrong key type = type error, not silent failure
```

**The comparison footgun:**
```go
// Timing-safe comparison looks identical to unsafe
if hmac == expected { }           // BAD: timing attack
if hmac.Equal(mac, expected) { }  // Good: constant-time
// Same types, different security properties
```

**Detection patterns:**
- Functions taking `bytes`, `string`, `[]byte` for distinct security concepts
- Parameters that could be swapped without type errors
- Same type used for keys, nonces, ciphertexts, signatures

### 4. Configuration Cliffs

One wrong setting creates catastrophic failure, with no warning.

```yaml
# One typo = disaster
verify_ssl: fasle  # Typo silently accepted as truthy?

# Magic values
session_timeout: -1  # Does this mean "never expire"?

# Dangerous combinations accepted silently
auth_required: true
bypass_auth_for_health_checks: true
health_check_path: "/"  # Oops
```

```php
// Sensible default doesn't protect against bad callers
public function __construct(
    public string $hashAlgo = 'sha256',  // Good default...
    public int $otpLifetime = 120,       // ...but accepts md5, 0, etc.
) {}
```

**Detection patterns:**
- Boolean flags that disable security entirely
- String configs that are not validated
- Combinations of settings that interact dangerously
- Environment variables that override security settings
- Constructor parameters with sensible defaults but no validation

### 5. Silent Failures

Errors that do not surface, or success that masks failure.

```python
# Silent bypass
def verify_signature(sig, data, key):
    if not key:
        return True  # No key = skip verification?!

# Return value ignored
signature.verify(data, sig)  # Throws on failure
crypto.verify(data, sig)     # Returns False on failure
# Developer forgets to check return value
```

**Detection patterns:**
- Functions returning booleans instead of throwing on security failures
- Empty catch blocks around security operations
- Default values substituted on parse errors
- Verification functions that "succeed" on malformed input

### 6. Stringly-Typed Security

Security-critical values as plain strings enable injection and confusion.

```python
# Too easy to escalate
permissions = "read,write"
permissions += ",admin"

# Type-safe alternative
permissions = {Permission.READ, Permission.WRITE}
permissions.add(Permission.ADMIN)  # At least it's explicit
```

**Detection patterns:**
- SQL/commands built from string concatenation
- Permissions as comma-separated strings
- Roles/scopes as arbitrary strings instead of enums
- URLs constructed by joining strings

---

## Analysis Workflow

### Phase 1: Surface Identification

1. **Map security-relevant APIs**: authentication, authorization, cryptography, session management, input validation
2. **Identify developer choice points**: where can developers select algorithms, configure timeouts, choose modes?
3. **Find configuration schemas**: environment variables, config files, constructor parameters

### Phase 2: Edge Case Probing

For each choice point, ask:

- **Zero/empty/null**: What happens with `0`, `""`, `null`, `[]`?
- **Negative values**: What does `-1` mean? Infinite? Error?
- **Type confusion**: Can different security concepts be swapped?
- **Default values**: Is the default secure? Is it documented?
- **Error paths**: What happens on invalid input? Silent acceptance?

### Phase 3: Threat Modeling

Consider three adversaries:

1. **The Scoundrel**: Actively malicious developer or attacker controlling config. Can they disable security via configuration? Downgrade algorithms? Inject malicious values?

2. **The Lazy Developer**: Copy-pastes examples, skips documentation. Will the first example they find be secure? Is the path of least resistance secure? Do error messages guide toward secure usage?

3. **The Confused Developer**: Misunderstands the API. Can they swap parameters without type errors? Use the wrong key/algorithm/mode by accident? Are failure modes obvious or silent?

### Phase 4: Validate Findings

For each identified sharp edge:

1. **Reproduce the misuse**: write minimal code demonstrating the footgun
2. **Verify exploitability**: does the misuse create a real vulnerability?
3. **Check documentation**: is the danger documented? (documentation does not excuse bad design, but affects severity)
4. **Test mitigations**: can the API be used safely with reasonable effort?

If a finding seems questionable, return to Phase 2 and probe more edge cases.

---

## Severity Classification

| Severity | Criteria | Examples |
|----------|----------|----------|
| Critical | Default or obvious usage is insecure | `verify: false` default; empty password allowed |
| High | Easy misconfiguration breaks security | Algorithm parameter accepts "none" |
| Medium | Unusual but possible misconfiguration | Negative timeout has unexpected meaning |
| Low | Requires deliberate misuse | Obscure parameter combination |

---

## Anti-Patterns

**"It's documented"** -- Developers do not read docs under deadline pressure. Make the secure choice the default or only option.

**"Advanced users need flexibility"** -- Flexibility creates footguns. Most "advanced" usage is copy-paste. Provide safe high-level APIs and hide primitives.

**"It's the developer's responsibility"** -- Blame-shifting. The API designer created the footgun. Remove it or make it impossible to misuse.

**"Nobody would actually do that"** -- Developers do everything imaginable under pressure. Assume maximum developer confusion.

**"It's just a configuration option"** -- Config is code. Wrong configs ship to production. Validate configs and reject dangerous combinations.

**"We need backwards compatibility"** -- Insecure defaults cannot be grandfathered in. Deprecate loudly and force migration.

---

## Quality Checklist

Before concluding analysis:

- [ ] Probed all zero/empty/null edge cases
- [ ] Verified defaults are secure
- [ ] Checked for algorithm/mode selection footguns
- [ ] Tested type confusion between security concepts
- [ ] Considered all three adversary types
- [ ] Verified error paths do not bypass security
- [ ] Checked configuration validation
- [ ] Constructor parameters validated (not just defaulted)

---

## For Claude Code

When designing APIs: never expose algorithm selection as a parameter — choose the secure algorithm internally. Use typed wrappers (not raw strings or bytes) for security concepts like keys, tokens, and nonces. Validate all configuration at startup with Zod schemas; reject unknown values rather than using defaults. Make security-critical functions throw on failure rather than return booleans. Use discriminated unions or enums for permissions and roles, never plain strings. When a constructor accepts security parameters, validate them in the constructor body rather than relying on callers to provide safe values.

---

*Internal references*: `security-by-design/SKILL.md`, `owasp-security/SKILL.md`, `api-design/SKILL.md`
