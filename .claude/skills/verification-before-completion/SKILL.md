---
name: Verification Before Completion
description: No completion claims without fresh verification evidence.
cluster: testing-quality
---

# Verification Before Completion

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Ensure that no claim of completion, success, or correctness is made without fresh verification evidence from the current session. This skill prevents false positives, broken commits, and eroded trust by requiring executable proof before any status assertion.

---

## The Rule

```
No completion claims without fresh verification evidence.
```

If you have not run the verification command in this interaction, you cannot claim it passes. Previous runs, assumptions, and confidence are not evidence.

---

## Verification Gate

Before claiming any status:

1. **Identify** -- What command proves this claim?
2. **Run** -- Execute the full command (not partial, not cached)
3. **Read** -- Check full output, exit code, and failure count
4. **Verify** -- Does the output confirm the claim?
   - If **no**: state the actual status with evidence
   - If **yes**: state the claim with evidence
5. **Then and only then** -- make the claim

Skipping any step invalidates the claim.

---

## Evidence Requirements by Claim Type

| Claim | Required Evidence | Insufficient |
|-------|-------------------|--------------|
| "Tests pass" | Test command output showing 0 failures | Previous run, "should pass" |
| "Linter clean" | Linter output showing 0 errors | Partial check, extrapolation |
| "Build succeeds" | Build command with exit code 0 | Linter passing, "logs look good" |
| "Bug fixed" | Original symptom test passes | "Code changed, should be fixed" |
| "Regression test works" | Red-green cycle verified | Test passes once without red phase |
| "Requirements met" | Line-by-line checklist verified | "Tests pass" alone |

---

## Verification Patterns

### Test Suite
```
Run test command -> Read output -> Confirm 0 failures -> Then claim "tests pass"
```

### Regression Test (TDD Red-Green)
```
Write test -> Run (PASS) -> Revert fix -> Run (MUST FAIL) -> Restore fix -> Run (PASS)
```
All three runs are required. A regression test that never failed proves nothing.

### Build
```
Run build command -> Confirm exit code 0 -> Then claim "build succeeds"
```

### Requirements Checklist
```
Re-read requirements -> Create checklist -> Verify each item -> Report gaps or completion
```

### Delegated Work
```
Agent reports success -> Check VCS diff -> Verify changes independently -> Report actual state
```

---

## Red Flags

Stop and verify if you notice any of these patterns:

- Using "should", "probably", or "seems to" about work status
- Expressing satisfaction before running verification ("Done!", "Fixed!")
- About to commit, push, or create a PR without running checks
- Relying on a previous run instead of a fresh one
- Trusting agent or subprocess reports without independent verification
- Thinking "the change is small, it must work"
- Any wording that implies success without having run verification

---

## When to Apply

Apply this gate **before**:

- Any claim of completion, success, or correctness
- Committing, pushing, or creating pull requests
- Moving to the next task in a plan
- Reporting status at a checkpoint
- Delegating completion status upstream

---

## Common Mistakes

### Claiming based on confidence
- **Problem:** "I'm confident this works" without running tests
- **Fix:** Confidence is not evidence. Run the command.

### Partial verification
- **Problem:** Ran linter but claimed build passes
- **Fix:** Each claim requires its own specific verification

### Stale evidence
- **Problem:** Tests passed 10 changes ago, claiming they still pass
- **Fix:** Re-run after every change that could affect the result

### Trusting subprocess reports
- **Problem:** Agent says "all tests pass" without checking
- **Fix:** Verify independently -- check the diff, run the tests

---

## Anti-Patterns

- Claiming completion to avoid running slow test suites
- Using "looks correct" as a substitute for execution
- Committing without running the project's check/test commands
- Skipping the red phase of a regression test
- Reporting partial verification as full verification

---

*Internal references*: `testing-strategy/SKILL.md`, `quality-gates/SKILL.md`, `executing-plans/SKILL.md`, `finishing-a-development-branch/SKILL.md`
