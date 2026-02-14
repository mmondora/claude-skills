---
name: Executing Plans
description: Execute implementation plans in batches with feedback checkpoints.
cluster: delivery-release
---

# Executing Plans

> **Version**: 1.1.0 | **Last updated**: 2026-02-14

## Purpose

Execute a written implementation plan in controlled batches, stopping between batches for review and feedback. The process ensures critical review before starting, strict adherence to plan steps, and clear reporting at checkpoints.

---

## Process

### Step 1: Load and Review Plan

1. Read the plan file
2. Review critically -- identify gaps, ambiguities, or concerns
3. **If concerns exist:** raise them before starting implementation
4. **If no concerns:** proceed to execution

Do not start implementation if the plan has critical gaps. Ask for clarification rather than guessing.

### Step 2: Execute Batch

Default batch size: **3 tasks**.

For each task in the batch:

1. Follow each step exactly as written in the plan
2. Run all verification commands specified in the step
3. Confirm expected outcomes match actual outcomes
4. Commit as specified in the plan

### Step 3: Report at Checkpoint

When a batch completes, report:

- What was implemented (task numbers and brief description)
- Verification output (test results, build status)
- Any deviations from the plan and why
- Status: "Ready for feedback"

Wait for feedback before continuing. Do not start the next batch automatically.

### Step 4: Incorporate Feedback

Based on feedback:

- Apply requested changes
- Re-verify affected tasks
- Execute the next batch
- Repeat until all tasks are complete

### Step 5: Complete Development

After all tasks are complete and verified:

1. Run the full test suite to confirm nothing regressed
2. Follow the finishing-a-development-branch process to integrate the work

---

## When to Stop and Ask

Stop executing immediately when:

- **Blocker mid-batch:** missing dependency, unclear instruction, unexpected failure
- **Verification fails repeatedly:** the plan step may be incorrect
- **Plan contradicts codebase:** existing code does not match plan assumptions
- **Scope question:** implementation reveals the plan missed something significant

Ask for clarification rather than guessing. Do not force through blockers.

---

## When to Revisit the Plan

Return to plan review (Step 1) when:

- The plan is updated based on checkpoint feedback
- A fundamental approach change is needed
- Multiple tasks in a batch fail for the same structural reason

---

## Batch Execution Rules

| Rule | Rationale |
|------|-----------|
| Follow plan steps exactly | Prevents drift from reviewed design |
| Run all verification commands | Catches issues immediately |
| Do not skip failing verifications | Failures compound if ignored |
| Report between batches | Enables course correction |
| Never implement on main/master without consent | Protects the default branch |
| Stop when blocked | Guessing wastes more time than asking |

---

## Common Mistakes

### Skipping verification steps
- **Problem:** Assume code works because it "looks right"
- **Fix:** Run every verification command, read every output

### Auto-continuing past checkpoints
- **Problem:** Implement 10 tasks before getting feedback, requiring rework
- **Fix:** Stop after each batch, report, and wait

### Deviating from the plan silently
- **Problem:** Plan says one approach, implementation uses another
- **Fix:** If deviation is needed, report it at the checkpoint with rationale

### Guessing through blockers
- **Problem:** Wrong guess compounds into larger rework
- **Fix:** Stop, describe the blocker, ask for guidance

---

## Anti-Patterns

- Executing the entire plan without any checkpoints
- Treating the plan as a loose suggestion rather than a specification
- Continuing after test failures without investigating
- Making "improvements" to the plan during execution without reporting them

---

## For Claude Code

When executing implementation plans: review the plan critically before starting — raise gaps or concerns before implementing, not after. Execute in batches of 3 tasks by default. Follow each plan step exactly as written, run all verification commands, and confirm expected outcomes match. Report at every checkpoint (tasks completed, verification output, deviations, status). Never auto-continue past checkpoints — wait for user feedback. Stop immediately on blockers and ask for guidance instead of guessing. After all tasks complete, run the full test suite and follow `finishing-a-development-branch/SKILL.md` for integration.

---

*Internal references*: `writing-plans/SKILL.md`, `verification-before-completion/SKILL.md`, `finishing-a-development-branch/SKILL.md`, `using-git-worktrees/SKILL.md`
