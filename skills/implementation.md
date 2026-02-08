---
skill: testing-implementation
version: 1.0.0
last-updated: 2026-02-08
domain: testing-quality
depends-on: [testing-strategy]
---

# Test Implementation

## Purpose

Concrete tooling and patterns for implementing tests on every stack: TypeScript (backend/frontend), Swift (iOS).

---

## TypeScript — Backend

**Runner**: Vitest (default — Vite-compatible, fast, native ESM) or Jest (legacy, larger ecosystem).

**Unit test**: Vitest with native assertions. Mock with `vi.mock()` only for external dependencies (database, API). Prefer dependency injection + manual test doubles over mock frameworks.

```typescript
describe('Money', () => {
  it('adds two amounts with same currency', () => {
    const a = Money.create(100, 'EUR');
    const b = Money.create(50, 'EUR');
    expect(a.add(b)).toEqual(Money.create(150, 'EUR'));
  });
  it('rejects addition with different currencies', () => {
    const eur = Money.create(100, 'EUR');
    const usd = Money.create(50, 'USD');
    expect(() => eur.add(usd)).toThrow('Currency mismatch');
  });
});
```

**Integration test**: Vitest + supertest for HTTP. Database: Firestore emulator or testcontainers for PostgreSQL. Clean setup/teardown per test suite.

**Contract test**: Pact for contract testing between services. Consumer defines expectations, producer verifies. Pact files are shared CI artifacts.

---

## TypeScript — Frontend

**Component test**: Vitest + Testing Library (React Testing Library or Vue Testing Library). Test behavior from the user's perspective (click, input, visible output), not internal implementation (state, hook calls).

```typescript
describe('InvoiceForm', () => {
  it('shows validation error for empty amount', async () => {
    render(<InvoiceForm onSubmit={vi.fn()} />);
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));
    expect(screen.getByText(/amount is required/i)).toBeInTheDocument();
  });
});
```

**E2E**: Playwright (default — multi-browser, fast, modern API) or Cypress. Critical flows only. Page Object Model for maintainability. Stable tests: use data-testid for selectors, not CSS classes.

---

## Swift — iOS

**Unit test**: XCTest. Mock via protocols and test implementations (no external mock frameworks — Swift doesn't need them thanks to protocols).

```swift
final class WineCellarViewModelTests: XCTestCase {
    func test_loadWines_populatesWinesList() async {
        let mockRepo = MockWineRepository(wines: [.sampleBarolo, .sampleChianti])
        let vm = WineCellarViewModel(repository: mockRepo)
        await vm.loadWines()
        XCTAssertEqual(vm.wines.count, 2)
        XCTAssertFalse(vm.isLoading)
    }
}
```

**UI test**: XCUITest for critical E2E flows. SwiftUI previews as first-level visual verification (not a substitute for tests, but a rapid complement).

---

## Cross-Stack Patterns

**Arrange-Act-Assert**: structure every test in three clear sections. One logical assertion per test.

**Test data factory**: helper functions producing realistic test data with sensible defaults and easy overrides.

```typescript
function buildInvoice(overrides: Partial<Invoice> = {}): Invoice {
  return {
    id: 'inv_test_001', tenantId: 't_test',
    amount: Money.create(100, 'EUR'), status: 'draft',
    createdAt: new Date('2026-01-15'), ...overrides,
  };
}
```

**No interdependent tests**: every test is independent. Execution order doesn't matter. State is reset between tests.

---

## For Claude Code

When generating tests: one test file per significant production file, AAA structure, test data factories for reusable data, explicit error case tests, names describing expected behavior. For frontend: Testing Library (user behavior), never test internal component implementation.

---

*Internal references*: `testing-strategy.md`, `backend-architecture.md`, `frontend-architecture.md`, `ios-architecture.md`
