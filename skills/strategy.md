---
skill: testing-strategy
version: 1.0.0
last-updated: 2026-02-08
domain: testing-quality
depends-on: [architectural-principles]
---

# Testing Strategy

## Purpose

A testing strategy that produces real confidence, not cosmetic coverage. The right test at the right level, with minimum effort for maximum signal.

---

## Test Pyramid — Revisited

The classic pyramid (many unit, fewer integration, very few E2E) is a starting point, not dogma. In cloud-native applications with many services, integration and contract tests have more value than unit tests on trivial logic.

**Unit test**: for pure domain logic (entities, value objects, calculations, validations). Fast, isolated, deterministic. Not for code that's just wiring (route → service → repository with zero logic).

**Integration test**: for assembled system behavior (API endpoint with real database or test container, event handler with real messaging). This is where real bugs are found.

**Contract test**: for interfaces between services. The producer verifies it respects the contract, the consumer verifies it can handle the producer's responses. Pact or schema-based contracts (OpenAPI).

**E2E test**: for critical business flows (login → create invoice → send → verify status). Few, slow, fragile. Only for flows that, if broken, block the business.

---

## Coverage Rules

**Branch coverage > line coverage.** 100% line coverage with 0% branch coverage means you tested the happy path and ignored all errors.

**Targets**: 80% branch coverage on domain layer, 70% on application layer, 50% on infra layer (tested more through integration than unit). Global target: 70%.

**Zero coverage acceptable on**: generated code, configuration, trivial glue code, pure TypeScript types.

**Coverage as signal, not goal.** If you have 90% coverage and bugs still pass, the tests are wrong (testing implementation, not behavior). If you have 60% and no bugs pass, maybe 60% is sufficient.

---

## What to Test (priority order)

Business rules (domain invariants, calculations, state machines), error handling (what happens when DB is down, input is invalid, tenant doesn't exist), security boundaries (authentication, authorization, tenant isolation), integrations (external APIs, database, messaging), critical UI flows (E2E only for business-critical flows).

---

## What NOT to Test

Getters/setters without logic. Framework code (React render, Express routing). Internal implementation (call order, private variables). Mock on mock on mock (if the test has more mocks than assertions, it's testing the mock framework, not the code).

---

## Tests as Documentation

Every test suite has a name describing behavior, not implementation. `describe('InvoiceCreation')` with `it('rejects negative amounts')`, not `describe('createInvoice function')` with `it('calls repository.save')`.

---

## For Claude Code

When generating tests: domain tests with pure input/output (no mocks when possible), integration tests with real database (in-memory or test container), error case tests (not just happy path), descriptive behavior names. Do not generate tests that verify internal implementation.

---

*Internal references*: `testing-implementation.md`, `performance-testing.md`, `security-testing.md`
