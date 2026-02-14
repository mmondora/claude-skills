---
name: Using Git Worktrees
description: Set up isolated git worktree workspaces for feature development.
cluster: delivery-release
---

# Using Git Worktrees

> **Version**: 1.1.0 | **Last updated**: 2026-02-14

## Purpose

Create isolated git worktree workspaces for feature development, allowing work on multiple branches simultaneously without switching. This skill provides a systematic process for directory selection, safety verification, and baseline validation.

---

## Directory Selection Priority

Follow this order to determine where to create worktrees:

### 1. Check for Existing Directories

```bash
ls -d .worktrees 2>/dev/null    # Preferred (hidden)
ls -d worktrees 2>/dev/null     # Alternative
```

If found, use that directory. If both exist, `.worktrees` takes precedence.

### 2. Check Project Configuration

Check CLAUDE.md or project documentation for a worktree directory preference. If specified, use it.

### 3. Ask the User

If no directory exists and no project preference is set:

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. A global location outside the project

Which do you prefer?
```

---

## Safety Verification

### Project-Local Directories

Before creating a worktree in a project-local directory, verify it is git-ignored:

```bash
git check-ignore -q .worktrees 2>/dev/null
```

**If NOT ignored:** Add the directory to `.gitignore` and commit the change before proceeding. This prevents worktree contents from being accidentally tracked.

### Global Directories

No `.gitignore` verification needed -- the directory is outside the project.

---

## Creation Steps

### 1. Detect Project Name

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. Create Worktree

```bash
# Project-local
git worktree add .worktrees/$BRANCH_NAME -b $BRANCH_NAME

# Or global
git worktree add ~/worktrees/$project/$BRANCH_NAME -b $BRANCH_NAME
```

### 3. Install Dependencies

Auto-detect and run the appropriate setup:

```bash
# Node.js
[ -f package.json ] && npm install

# Python
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && poetry install

# Rust
[ -f Cargo.toml ] && cargo build

# Go
[ -f go.mod ] && go mod download
```

### 4. Verify Clean Baseline

Run the project's test suite to confirm the worktree starts in a passing state:

```bash
npm test    # or pytest, cargo test, go test ./...
```

- **Tests pass:** Report ready status with test count
- **Tests fail:** Report failures and ask whether to proceed or investigate

### 5. Report

```
Worktree ready at <full-path>
Branch: <branch-name>
Tests: <N> passing, 0 failures
Ready to implement <feature-name>
```

---

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check project config, then ask |
| Directory not ignored | Add to `.gitignore`, commit, then proceed |
| Tests fail during baseline | Report failures, ask before proceeding |
| No dependency file found | Skip dependency install |

---

## Worktree Cleanup

When work is complete, remove the worktree to avoid accumulation:

```bash
# List worktrees
git worktree list

# Remove a specific worktree
git worktree remove <worktree-path>

# Prune stale entries
git worktree prune
```

Cleanup is typically handled as part of the finishing-a-development-branch process.

---

## Common Mistakes

### Skipping ignore verification
- **Problem:** Worktree contents get tracked, polluting git status
- **Fix:** Always verify with `git check-ignore` before creating project-local worktrees

### Assuming directory location
- **Problem:** Creates inconsistency with project conventions
- **Fix:** Follow the priority order: existing directory, project config, then ask

### Proceeding with failing baseline tests
- **Problem:** Cannot distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission before continuing

### Hardcoding setup commands
- **Problem:** Breaks on projects using different toolchains
- **Fix:** Auto-detect from project files (package.json, Cargo.toml, etc.)

---

## Anti-Patterns

- **Unignored worktree directory** — worktree contents appear in `git status` and risk being committed; always verify with `git check-ignore` before creating project-local worktrees
- **Skipping baseline test verification** — starting work in a worktree with pre-existing test failures makes it impossible to distinguish new bugs from inherited ones
- **Worktree accumulation** — orphaned worktrees consume disk and create confusion; clean up after merging or discarding the branch
- **Worktree for trivial changes** — creating a worktree for a 5-minute fix adds overhead; use worktrees when you need to maintain two branches simultaneously
- **Hardcoded setup commands** — assuming `npm install` works for every project; auto-detect the toolchain from project files (package.json, Cargo.toml, go.mod)

---

## For Claude Code

When creating git worktrees: follow the directory selection priority (existing `.worktrees/` > `worktrees/` > project config > ask user). Always verify project-local directories are git-ignored before creating worktrees — add to `.gitignore` and commit if not. Auto-detect and run dependency installation based on project files (package.json, requirements.txt, Cargo.toml, go.mod). Run the project test suite to establish a clean baseline before starting work. Report the worktree path, branch name, and test status. Reference `finishing-a-development-branch/SKILL.md` for worktree cleanup after completion.

---

*Internal references*: `finishing-a-development-branch/SKILL.md`, `executing-plans/SKILL.md`, `writing-plans/SKILL.md`
