---
name: Finishing a Development Branch
description: Complete feature branches safely with structured options.
cluster: delivery-release
---

# Finishing a Development Branch

> **Version**: 1.1.0 | **Last updated**: 2026-02-14

## Purpose

Guide the completion of feature branch work by verifying tests, presenting structured integration options, executing the chosen workflow, and cleaning up worktrees. This ensures branches are completed safely with no broken merges, no accidental deletions, and no orphaned worktrees.

---

## Process

### Step 1: Verify Tests

Before presenting any options, run the full test suite:

```bash
npm test    # or pytest, cargo test, go test ./...
```

**If tests fail:** report failures and stop. Do not proceed to options until tests pass.

**If tests pass:** continue to Step 2.

### Step 2: Determine Base Branch

Identify the branch this feature was based on:

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Confirm with the user if uncertain: "This branch diverged from `main` -- is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. All tests passing. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (handle it later)
4. Discard this work
```

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
# Run tests on merged result
<test command>
# If tests pass, delete feature branch
git branch -d <feature-branch>
```

Then proceed to cleanup (Step 5).

#### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<what changed and why>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Then proceed to cleanup (Step 5).

#### Option 3: Keep As-Is

Report: "Keeping branch `<name>`. Worktree preserved at `<path>`."

Do **not** clean up the worktree.

#### Option 4: Discard

Require explicit confirmation before deleting:

```
This will permanently delete:
- Branch: <name>
- All commits since diverging from <base-branch>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation. Then:

```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then proceed to cleanup (Step 5).

### Step 5: Clean Up Worktree

For Options 1, 2, and 4, check if work was done in a worktree and remove it:

```bash
# Check if in a worktree
git worktree list

# Remove the worktree
git worktree remove <worktree-path>
```

For Option 3, keep the worktree intact.

---

## Quick Reference

| Option | Merges | Pushes | Keeps Worktree | Deletes Branch |
|--------|--------|--------|----------------|----------------|
| 1. Merge locally | Yes | No | No | Yes (safe) |
| 2. Create PR | No | Yes | No | No |
| 3. Keep as-is | No | No | Yes | No |
| 4. Discard | No | No | No | Yes (force) |

---

## Common Mistakes

### Skipping test verification before options
- **Problem:** Merge broken code or create a failing PR
- **Fix:** Always verify tests before presenting options

### Open-ended completion questions
- **Problem:** "What should I do next?" leads to ambiguity
- **Fix:** Present exactly 4 structured options

### No confirmation for discard
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

### Cleaning up worktree for Option 3
- **Problem:** User said "keep as-is" but worktree was removed
- **Fix:** Only clean up worktrees for Options 1, 2, and 4

### Merging without post-merge verification
- **Problem:** Merge succeeds but introduces test failures
- **Fix:** Run tests on the merged result before deleting the branch

---

## Anti-Patterns

- Proceeding with any option while tests are failing
- Force-pushing without explicit user request
- Deleting branches without confirmation
- Skipping post-merge test verification
- Leaving orphaned worktrees after completion

---

## For Claude Code

When finishing a development branch: always run the full test suite before presenting options — never proceed with failing tests. Present exactly 4 structured options (merge locally, create PR, keep as-is, discard). For merge: pull the latest base branch, merge, run tests on merged result, then delete the feature branch. For PR: push with `-u` flag and create via `gh pr create`. For discard: require explicit typed confirmation before deleting. Clean up worktrees for all options except "keep as-is". Never force-push without explicit user request.

---

*Internal references*: `using-git-worktrees/SKILL.md`, `executing-plans/SKILL.md`, `verification-before-completion/SKILL.md`
