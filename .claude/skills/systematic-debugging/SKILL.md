---
name: "Systematic Debugging"
description: "Root-cause-first debugging methodology with four-phase investigation process."
cluster: "testing-quality"
---

# Systematic Debugging

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Provide a structured, repeatable debugging methodology that finds root causes before attempting fixes. Random fixes waste time, mask underlying issues, and introduce new bugs. This skill defines a four-phase process that applies to any technical issue: test failures, production bugs, performance problems, build failures, and integration issues.

---

## Core Principle

Find root cause before attempting fixes. Symptom fixes are failure.

If the root cause investigation (Phase 1) is not complete, no fix should be proposed. Systematic debugging is faster than guess-and-check thrashing, even under time pressure.

---

## When to Apply

Use for any technical issue:

- Test failures and unexpected behavior
- Production bugs and performance degradation
- Build and CI/CD failures
- Integration and environment issues
- Data inconsistencies and race conditions
- Memory leaks and resource exhaustion

Especially critical when:

- Under time pressure (emergencies make guessing tempting)
- A "quick fix" seems obvious
- Multiple fix attempts have already failed
- The issue is not fully understood

---

## The Four Phases

Complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

Before attempting any fix:

**1. Read error messages carefully.** Do not skip past errors or warnings. Read stack traces completely. Note line numbers, file paths, and error codes. Error messages often contain the exact solution.

**2. Reproduce consistently.** Determine the exact steps to trigger the issue. If it happens intermittently, gather more data instead of guessing. A bug that cannot be reproduced cannot be verified as fixed.

**3. Check recent changes.** Review `git diff` and recent commits. Look for new dependencies, configuration changes, and environmental differences. The cause is often in what changed most recently.

**4. Gather evidence in multi-component systems.** For systems with multiple layers (CI pipeline, API chain, microservices), add diagnostic instrumentation at each component boundary before proposing fixes:

```bash
# Layer 1: Entry point
echo "=== Input data at entry: ==="
echo "AUTH_TOKEN: ${AUTH_TOKEN:+SET}${AUTH_TOKEN:-UNSET}"

# Layer 2: Processing
echo "=== State at processing layer: ==="
echo "Request payload: $(cat request.json | jq .)"

# Layer 3: Output
echo "=== Response from downstream: ==="
curl -v "$DOWNSTREAM_URL" 2>&1 | head -20
```

Run once to collect evidence showing where the data flow breaks. Then investigate the specific failing component.

**5. Trace data flow backward.** When the error is deep in the call stack, trace backward: where does the bad value originate? What called this function with the bad value? Keep tracing until the source is found. Fix at source, not at symptom.

### Phase 2: Pattern Analysis

**1. Find working examples.** Locate similar working code in the same codebase. What works that is similar to what is broken?

**2. Compare against references.** If implementing a known pattern, read the reference implementation completely. Do not skim.

**3. Identify differences.** List every difference between working and broken code, however small. Do not assume any difference is irrelevant.

**4. Understand dependencies.** Identify what other components, settings, configuration, and environment assumptions the code relies on.

### Phase 3: Hypothesis and Testing

**1. Form a single hypothesis.** State it clearly: "The root cause is X because evidence Y shows Z." Be specific, not vague.

**2. Test minimally.** Make the smallest possible change to test the hypothesis. Change one variable at a time. Do not fix multiple things at once.

**3. Verify before continuing.** If the hypothesis is confirmed, proceed to Phase 4. If not, form a new hypothesis. Do not layer additional fixes on top of a failed attempt.

### Phase 4: Implementation

**1. Create a failing test case.** Write the simplest possible automated reproduction. This test must fail before the fix and pass after.

**2. Implement a single fix.** Address the root cause identified in previous phases. One change at a time. No "while I'm here" improvements or bundled refactoring.

**3. Verify the fix.** Confirm the new test passes, no existing tests broke, and the original issue is resolved.

**4. Escalation rule: three failed fixes.** If three or more fix attempts have failed, stop and question the architecture:

- Each fix reveals new shared state, coupling, or problems in different places
- Fixes require massive refactoring to implement
- Each fix creates new symptoms elsewhere

These patterns indicate an architectural problem, not a code bug. Discuss the fundamental approach before attempting further fixes.

---

## Evidence-Based Debugging Checklist

Use this checklist to verify the process is being followed:

| Phase | Checkpoint | Completed? |
|-------|-----------|------------|
| 1 | Error messages read completely | |
| 1 | Issue reproduced consistently | |
| 1 | Recent changes reviewed | |
| 1 | Evidence gathered at component boundaries | |
| 2 | Working example identified for comparison | |
| 2 | Differences between working/broken listed | |
| 3 | Single hypothesis stated with evidence | |
| 3 | Minimal test performed (one variable) | |
| 4 | Failing test case written | |
| 4 | Single fix applied to root cause | |
| 4 | All tests passing after fix | |

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Correct Approach |
|-------------|-------------|-----------------|
| "Quick fix now, investigate later" | Symptom fixes mask root cause and accumulate debt | Complete Phase 1 before any fix |
| "Try changing X and see" | Untested changes introduce new bugs | Form hypothesis, test minimally |
| "Multiple changes at once" | Cannot isolate what worked; causes regressions | One variable at a time |
| "Skip the test, manually verify" | Manual verification does not persist; regressions return | Automated failing test first |
| "It's probably X" without evidence | Assumption-based fixes have ~40% success rate | Gather evidence, trace data flow |
| "One more fix attempt" after 2+ failures | Pattern of repeated failures signals architectural issue | Stop at 3 and question fundamentals |
| "Issue is simple, skip the process" | Simple issues have root causes too; process is fast for simple bugs | Follow all four phases regardless |

---

## When Investigation Reveals No Root Cause

If systematic investigation determines the issue is environmental, timing-dependent, or external:

1. Document what was investigated and ruled out
2. Implement appropriate defensive handling (retry with backoff, timeout, clear error message)
3. Add monitoring and structured logging for future investigation
4. Record the investigation in the issue tracker for context

Note: most "no root cause" conclusions result from incomplete investigation. Revisit Phase 1 evidence before accepting this outcome.

---

## Debugging Across Distributed Systems

When the issue spans multiple services or processes:

- **Correlation IDs**: trace a single request across all services using a shared correlation ID in structured logs
- **Timeline reconstruction**: build a chronological sequence of events across services using timestamps from logs and traces
- **Isolation testing**: verify each service independently with known-good inputs before investigating cross-service interactions
- **State inspection**: check intermediate state stores (databases, caches, queues) for consistency at each step

---

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand what fails and why |
| **2. Pattern** | Find working examples, compare, identify differences | Differences between working/broken listed |
| **3. Hypothesis** | Form theory with evidence, test minimally | Hypothesis confirmed or replaced |
| **4. Implementation** | Create failing test, single fix, verify | Root cause fixed, all tests pass |

---

## For Claude Code

When debugging issues during development:

1. **Always complete Phase 1** before suggesting any code changes
2. **Show evidence** — include error messages, stack traces, and relevant log output in analysis
3. **State hypotheses explicitly** — "The root cause appears to be X because Y"
4. **Propose minimal fixes** — one change at a time, targeting root cause not symptoms
5. **Include a test** — every fix proposal includes a test that reproduces the original failure
6. **Escalate architectural concerns** — if the investigation reveals systemic issues beyond the immediate bug, flag them

---

*Internal references*: `testing-strategy/SKILL.md`, `testing-implementation/SKILL.md`, `quality-gates/SKILL.md`
