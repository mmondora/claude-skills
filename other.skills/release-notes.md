# Skill: Release Notes Generator (Enterprise-grade)

## Role
Product Owner senior + Release Manager + Tech Writer.

## Goal
Generate release notes that:
- communicate user value and operational impact
- are accurate and traceable to PRs/issues/commits
- include risk notes, rollout instructions, and compatibility signals

## Trigger (when to run)
- A release tag is created (`vX.Y.Z`)
- A release candidate branch is cut
- A release pipeline is executed
- A GitHub/GitLab Release is being drafted

## Inputs (required)
- Commit list for the release range (preferably Conventional Commits)
- Merged PR list with titles + labels
- Issue tracker references (Jira/Linear/etc.) if present
- Feature flag list and rollout configuration (if any)
- Breaking changes indicators (API/schema/infrastructure)

## Outputs
1. **Customer-facing Release Notes** (non-technical)
2. **Ops Release Notes** (SRE/Support oriented)
3. **Developer Notes** (API/SDK consumers; optional)

## Mandatory sections
### Customer-facing
- Highlights (top 3–5)
- New features
- Improvements
- Bug fixes
- Known limitations (if any)
- Breaking changes (with action required)
- Availability/rollout notes (if progressive)

### Ops
- Deployment window and dependencies
- Migration steps (DB/schema/config)
- Monitoring checklist (dashboards, alerts, SLOs)
- Rollback plan reference
- Support playbook changes
- Feature flags and kill-switches

### Developer Notes (optional)
- API changes summary (OpenAPI/AsyncAPI diff)
- SDK changes and version constraints
- Deprecations and timelines

## Mapping rules (from commits/PRs to notes)
- `feat:` -> New features
- `fix:` -> Bug fixes
- `perf:` -> Improvements (performance)
- `refactor:` -> Improvements (internal; include only if user-visible impact)
- `docs:` -> usually omit from customer notes; keep in dev notes
- `chore/build/ci:` -> omit unless impacts delivery/compatibility
- `BREAKING CHANGE:` -> Breaking changes (must include action)

## Style rules
- Write in plain language; avoid implementation details
- Use verbs that convey value (“Enable”, “Improve”, “Reduce”, “Fix”)
- Each bullet: what changed + who benefits + any action required
- If uncertain, mark as **Needs confirmation** and list missing evidence

## Quality checks
- Every entry must be traceable (PR/issue link or commit hash reference)
- No duplicates
- Breaking changes include: impact, mitigation, rollback note, owner contact

## Anti-patterns
- Raw commit dump
- Vague statements (“Various improvements”)
- No mention of rollout strategy when feature flags are used
