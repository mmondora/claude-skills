# Skill: Quality Gates Evaluator (release blocking)

## Role
Engineering Excellence Lead.

## Goal
Decide PASS/FAIL for quality and engineering standards.

## Trigger
- CI completion on main
- Release candidate pipeline
- Pre-production deploy

## Gates (default)
### Tests
- Unit tests: PASS
- Coverage: >= threshold (configurable), no drop > allowed delta
- Flaky tests: zero tolerated in release pipeline

### Static Quality
- Lint/typecheck: PASS
- Formatting: PASS (or autoformat with fail if diff)

### Performance
- Baseline performance tests for critical endpoints
- No regression beyond allowed thresholds

### Reliability
- Contract tests PASS
- Backward compatibility checks PASS

### Documentation
- Release notes draft exists for release events
- ADR required for architectural changes

## Output
- PASS/FAIL overall
- Gate-by-gate status
- Blocking items with owner suggestions
- Quick fixes vs long fixes

## Anti-patterns
- “Green build” without meaningful tests
- Ignoring flaky tests
- Shipping without contract tests for public APIs
