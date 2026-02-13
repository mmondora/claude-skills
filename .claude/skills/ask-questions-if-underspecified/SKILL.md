---
name: Ask Questions If Underspecified
description: Clarify underspecified requirements before implementation.
cluster: foundations
---

# Ask Questions If Underspecified

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Avoid wrong work by identifying underspecified requirements and asking targeted clarifying questions before implementation begins. The goal is to ask the minimum set of questions needed to eliminate ambiguity, not to interrogate every detail.

---

## When to Apply

Use this process when a request has **multiple plausible interpretations** or when key details are unclear across any of these dimensions:

- **Objective:** what should change vs. stay the same
- **Done criteria:** acceptance criteria, examples, edge cases
- **Scope:** which files, components, or users are in or out
- **Constraints:** compatibility, performance, style, dependencies
- **Environment:** language/runtime versions, OS, build/test runner
- **Safety:** data migration, rollout/rollback, risk level

If multiple plausible interpretations exist, treat the request as underspecified.

## When NOT to Apply

Do not ask questions when:

- The request is already clear and unambiguous
- A quick, low-risk discovery read (configs, existing patterns, docs) can answer the missing details
- The question can be answered by inspecting the codebase

---

## Process

### 1. Assess Specification Completeness

After reading the request and exploring relevant code, determine whether the dimensions above are sufficiently clear to proceed without risk of wrong work.

### 2. Ask Must-Have Questions First

Ask **1-5 questions** in the first pass. Prioritize questions that eliminate whole branches of work.

Make questions easy to answer:

- **Short and numbered** -- optimize for scannability
- **Multiple-choice** when possible -- reduce cognitive load
- **Suggest defaults** -- mark recommended choices clearly
- **Include a fast path** -- e.g., "Reply `defaults` to accept all recommended choices"
- **Separate must-know from nice-to-know** if that reduces friction

Example format:

```text
Before I start, a few questions:

1) Scope?
   a) Minimal change (recommended)
   b) Refactor while touching the area
   c) Not sure - use recommended

2) Compatibility target?
   a) Current project defaults (recommended)
   b) Also support older versions: <specify>

Reply with: defaults (or 1a 2b, etc.)
```

### 3. Pause Before Acting

Until must-have answers arrive:

- **Do not** run commands, edit files, or produce plans that depend on unknowns
- **Do** perform clearly labeled, low-risk discovery (inspect repo structure, read configs) if it does not commit to a direction

If explicitly asked to proceed without answers:

1. State assumptions as a short numbered list
2. Ask for confirmation before proceeding

### 4. Confirm Interpretation

Once answers arrive, restate the requirements in 1-3 sentences including key constraints and what success looks like, then begin work.

---

## Question Templates

- "Before I start, I need: (1) ..., (2) ..., (3) .... If you don't care about (2), I'll assume ...."
- "Which of these should it be? A) ... B) ... C) ... (pick one)"
- "What would you consider 'done'? For example: ..."
- "Any constraints I must follow (versions, performance, style, deps)? If none, I'll target existing project defaults."

---

## Anti-Patterns

- Asking questions that could be answered by reading existing code or configs
- Asking open-ended questions when multiple-choice would eliminate ambiguity faster
- Asking more than 5 questions in the first pass (information overload)
- Proceeding with unstated assumptions when the risk of wrong work is high
- Refusing to proceed when the request is sufficiently clear

---

## Common Mistakes

### Over-questioning clear requests
- **Problem:** Asking 5 questions about a task that has one obvious interpretation
- **Fix:** If it is clear, proceed. This skill is for genuinely ambiguous situations.

### Under-questioning risky changes
- **Problem:** Making assumptions about data migrations or breaking changes
- **Fix:** When safety/reversibility is unclear, always ask.

### Burying the question in paragraphs
- **Problem:** Long explanation before the actual question
- **Fix:** Lead with the question. Add context below if needed.

---

*Internal references*: `writing-plans/SKILL.md`, `architecture-decision-records/SKILL.md`
