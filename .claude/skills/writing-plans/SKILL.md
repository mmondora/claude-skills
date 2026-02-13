---
name: Writing Plans
description: Break requirements into TDD-based micro-task implementation plans.
cluster: delivery-release
---

# Writing Plans

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Create comprehensive implementation plans that break requirements into bite-sized, TDD-driven micro-tasks. Plans assume the implementor has zero codebase context, documenting every file path, command, and expected outcome. Each step targets 2-5 minutes of work following a strict red-green-commit cycle.

---

## Plan Document Structure

Every plan starts with a header providing essential context:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

Save plans to: `docs/plans/YYYY-MM-DD-<feature-name>.md`

---

## Task Granularity

Each step is one atomic action (2-5 minutes):

1. **Write the failing test** - one step
2. **Run it to confirm it fails** - one step
3. **Implement minimal code to pass** - one step
4. **Run tests to confirm they pass** - one step
5. **Commit** - one step

Do not combine steps. Each step has a clear expected outcome that can be verified.

---

## Task Template

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts:123-145`
- Test: `tests/exact/path/to/file.test.ts`

**Step 1: Write the failing test**

` ` `typescript
test('specific behavior description', () => {
  const result = functionUnderTest(input);
  expect(result).toEqual(expected);
});
` ` `

**Step 2: Run test to verify it fails**

Run: `npx vitest tests/path/file.test.ts -t "specific behavior"`
Expected: FAIL with "functionUnderTest is not defined"

**Step 3: Write minimal implementation**

` ` `typescript
export function functionUnderTest(input: InputType): OutputType {
  return expected;
}
` ` `

**Step 4: Run test to verify it passes**

Run: `npx vitest tests/path/file.test.ts -t "specific behavior"`
Expected: PASS

**Step 5: Commit**

` ` `bash
git add tests/path/file.test.ts src/path/file.ts
git commit -m "feat(scope): add specific feature"
` ` `
```

---

## Plan Quality Checklist

Every plan must include:

- **Exact file paths** for every file to create, modify, or test
- **Complete code** in each step (not "add validation logic")
- **Exact commands** with expected output for verification
- **References to documentation** the implementor may need to consult
- **Dependency order** between tasks (which tasks must complete first)

Principles to follow throughout: DRY, YAGNI, TDD, frequent commits.

---

## Execution Handoff

After saving the plan, present execution options:

```
Plan saved to `docs/plans/<filename>.md`. Execution options:

1. **Batch execution** - Execute tasks in batches of 3 with feedback checkpoints
2. **Task-by-task** - Execute one task at a time with review after each
3. **Manual** - Hand off the plan for manual implementation

Which approach?
```

For batch execution, follow the process described in the executing-plans skill.

---

## Common Mistakes

### Vague steps
- **Problem:** "Add error handling" gives no guidance on what or how
- **Fix:** Write the exact code, exact test, exact expected behavior

### Missing verification commands
- **Problem:** Implementor does not know how to confirm a step worked
- **Fix:** Every step includes the command to run and the expected output

### Steps too large
- **Problem:** A single step that takes 20 minutes and touches 5 files
- **Fix:** Break into atomic actions, each with one verification point

### No dependency order
- **Problem:** Task 5 requires Task 3's output but nothing says so
- **Fix:** State prerequisites explicitly at the top of each task

---

## Anti-Patterns

- Writing plans without reading the existing codebase first
- Assuming tool versions or project structure without checking
- Planning features that duplicate existing functionality
- Skipping the test step ("we'll add tests later")
- Creating monolithic tasks that resist TDD decomposition

---

*Internal references*: `executing-plans/SKILL.md`, `verification-before-completion/SKILL.md`, `testing-strategy/SKILL.md`, `using-git-worktrees/SKILL.md`
