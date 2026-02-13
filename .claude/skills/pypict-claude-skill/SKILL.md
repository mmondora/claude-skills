---
name: "Combinatorial Testing"
description: "Pairwise and combinatorial test case design using PICT models."
cluster: "testing-quality"
---

# Combinatorial Testing

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Provide a systematic approach to designing test cases using pairwise independent combinatorial testing (PICT). Combinatorial testing reduces test suite size by 80-90% compared to exhaustive testing while covering all two-way parameter interactions. This skill covers parameter identification, PICT model generation, constraint definition, and test case formatting.

---

## When to Apply

- Features, functions, or systems with multiple input parameters
- Configuration testing with many possible combinations
- API endpoints with multiple query parameters, headers, and body fields
- Web forms with multiple fields and validation rules
- Systems with conditional logic across multiple dimensions
- Any scenario where exhaustive testing is infeasible but interaction coverage is needed

---

## Workflow

### Step 1: Analyze Parameters

From requirements or code, identify:

- **Parameters**: input variables, configuration options, environmental factors
- **Values**: possible values per parameter (apply equivalence partitioning and boundary analysis)
- **Constraints**: business rules, technical limitations, dependencies between parameters
- **Expected outcomes**: what should happen for different combinations

Example analysis for a login function:

| Parameter | Values | Rationale |
|-----------|--------|-----------|
| Credentials | Valid, Invalid | Equivalence classes |
| TwoFactorAuth | Enabled, Disabled | Feature toggle |
| RememberMe | Checked, Unchecked | Boolean option |
| PreviousFailures | 0, 2, 3, 5 | Boundary at rate-limit threshold (3) |

### Step 2: Build the PICT Model

Structure the model with clear parameter names, well-defined value sets, and documented constraints:

```
# Authentication parameters
Credentials:      Valid, Invalid
TwoFactorAuth:    Enabled, Disabled
RememberMe:       Checked, Unchecked
PreviousFailures: 0, 2, 3, 5

# Business rules
# Rate limiting activates at 3 failures
IF [PreviousFailures] >= 3 THEN [Credentials] = "Valid";
```

**Model syntax rules:**

- Parameters defined as `Name: Value1, Value2, Value3`
- Constraints use `IF [Param] = "Value" THEN [Param] <> "Value";`
- Constraints must end with semicolons
- Parameter names in constraints use square brackets: `[ParameterName]`
- Negative (invalid) test values prefixed with tilde: `~InvalidValue`
- Comments use `#` prefix

**Constraint operators:**

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equals | `[OS] = "Windows"` |
| `<>` | Not equals | `[Browser] <> "IE"` |
| `>`, `<`, `>=`, `<=` | Comparison | `[Count] >= 3` |
| `IN` | Set membership | `[Type] IN {A, B, C}` |
| `AND`, `OR`, `NOT` | Logical | `[A] = "X" AND [B] = "Y"` |
| `LIKE` | Pattern match | `[Name] LIKE "test*"` |

### Step 3: Generate Test Cases

Save the model to a file and generate cases using one of:

- **PICT CLI**: `pict model.txt` (install from [github.com/microsoft/pict](https://github.com/microsoft/pict))
- **pypict** (Python binding): `pip install pypict`
- **Online tools**: [pairwise.yuuniworks.com](https://pairwise.yuuniworks.com/)

Default generation uses order 2 (pairwise). For safety-critical systems, increase to order 3 or higher with `/o:3`.

### Step 4: Define Expected Outputs

For each generated test case, determine the expected outcome based on business requirements and code logic. Be specific:

| Specificity | Example |
|------------|---------|
| Good | "HTTP 401 with body `{error: 'invalid_credentials'}`" |
| Good | "Login succeeds, session created, redirect to `/dashboard`" |
| Bad | "Error" |
| Bad | "Works" |

### Step 5: Format the Test Suite

Present results as:

1. The PICT model (for reproducibility)
2. A markdown table of generated test cases with expected outputs
3. A summary with total case count, coverage level, and constraint count

---

## Common Patterns

### Web Form Testing

```
# Registration form
Name:     Valid, Empty, TooLong
Email:    Valid, Invalid, Empty
Password: Strong, Weak, Empty
Terms:    Accepted, NotAccepted

# Cannot register without accepting terms
IF [Terms] = "NotAccepted" THEN [Password] <> "Strong";
```

### API Endpoint Testing

```
# REST API coverage
HTTPMethod:     GET, POST, PUT, DELETE
Authentication: ValidToken, InvalidToken, Missing
ContentType:    JSON, XML, FormData
PayloadSize:    Empty, Small, Large

# GET requests have no body
IF [HTTPMethod] = "GET" THEN [PayloadSize] = "Empty";
# Large payloads only with JSON or FormData
IF [PayloadSize] = "Large" THEN [ContentType] IN {JSON, FormData};
```

### Configuration Matrix Testing

```
# Deployment configuration
Environment:  Dev, Staging, Production
CacheEnabled: True, False
LogLevel:     Debug, Info, Error
Database:     SQLite, PostgreSQL, MySQL

# Production constraints
IF [Environment] = "Production" THEN [LogLevel] <> "Debug";
IF [Database] = "SQLite" THEN [Environment] = "Dev";
```

---

## Parameter Design Guidelines

### Equivalence Partitioning

Group values into equivalence classes rather than testing every possible value:

| Raw Values | Partitioned | Rationale |
|-----------|------------|-----------|
| 1, 2, 3, ..., 100 | Small(1-10), Medium(11-50), Large(51-100) | Three classes cover behavior differences |
| "alice", "bob", ... | Valid, Empty, TooLong, SpecialChars | Four classes cover validation paths |

### Boundary Values

Include values at boundaries where behavior changes:

```
# Age-based access control (adult at 18, senior at 65)
Age: 0, 17, 18, 64, 65, 100

# File size limits (max 10MB)
FileSize: 0, 1KB, 9.9MB, 10MB, 10.1MB
```

### Negative Testing

Use the tilde prefix for values expected to produce errors:

```
# Amount field (valid range: 0-10000)
Amount: 0, 50, 10000, ~-1, ~10001, ~ABC
```

---

## Scaling Strategies

For large parameter spaces:

| Strategy | When to Use | Benefit |
|----------|------------|---------|
| Sub-models | Related parameter groups need different interaction strength | Groups tested at higher order, cross-group at order 2 |
| Suite splitting | Independent features with no parameter interaction | Smaller, focused test suites |
| Order increase | Safety-critical or high-risk combinations | `/o:3` covers all 3-way interactions |
| Constraint tightening | Many impossible combinations in the domain | Fewer invalid cases in output |

Sub-model syntax for grouping related parameters:

```
# High-order group (test all 3-way interactions)
{ PaymentMethod, Amount, Currency } @ 3

# Standard pairwise for the rest
ShippingMethod: Standard, Express
UserType: Guest, Registered
```

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| No test cases generated | Over-constrained model | Relax constraints; check for contradictions |
| Invalid combinations in output | Missing constraints | Add constraints for business rules |
| Too many test cases | Too many parameter values | Apply equivalence partitioning; use sub-models |
| Constraint syntax error | Missing semicolon or bracket | Constraints end with `;`; parameters use `[Name]` |

---

## Example: E-Commerce Checkout

**Requirements**: checkout flow with payment methods, shipping options, and user types. Guests cannot use bank transfer. Premium users get free express shipping.

**PICT Model:**

```
PaymentMethod:  CreditCard, PayPal, BankTransfer
ShippingMethod: Standard, Express, Overnight
UserType:       Guest, Registered, Premium

# Guests cannot use bank transfer
IF [UserType] = "Guest" THEN [PaymentMethod] <> "BankTransfer";
```

**Generated Test Cases:**

| # | PaymentMethod | ShippingMethod | UserType | Expected Output |
|---|--------------|----------------|----------|-----------------|
| 1 | CreditCard | Standard | Guest | Checkout succeeds, standard shipping fee applied |
| 2 | PayPal | Express | Guest | Checkout succeeds, express shipping fee applied |
| 3 | CreditCard | Overnight | Registered | Checkout succeeds, overnight shipping fee applied |
| 4 | BankTransfer | Standard | Registered | Checkout succeeds, bank transfer confirmation pending |
| 5 | PayPal | Standard | Premium | Checkout succeeds, standard shipping fee applied |
| 6 | CreditCard | Express | Premium | Checkout succeeds, express shipping free (premium) |
| 7 | BankTransfer | Express | Registered | Checkout succeeds, express shipping fee applied |
| 8 | PayPal | Overnight | Registered | Checkout succeeds, overnight shipping fee applied |
| 9 | BankTransfer | Overnight | Premium | Checkout succeeds, overnight shipping fee applied |

**Summary**: 9 test cases covering all pairwise interactions, 1 constraint applied, reduced from 27 exhaustive combinations.

---

## For Claude Code

When designing test cases with combinatorial testing:

1. **Identify parameters first** — analyze the function signature, API schema, or form fields to extract parameters and their value domains
2. **Apply equivalence partitioning** — do not enumerate all possible values; group into classes that exercise different code paths
3. **Include boundary values** — add values at boundaries where behavior changes (off-by-one, limits, thresholds)
4. **Document constraints** — every constraint has a comment explaining the business rule it represents
5. **Specify expected outputs precisely** — include HTTP status codes, error messages, or state changes, not just "pass/fail"
6. **Present the model for reproducibility** — always include the PICT model text so tests can be regenerated

---

*Internal references*: `testing-strategy/SKILL.md`, `testing-implementation/SKILL.md`, `property-based-testing/SKILL.md`
