# Skill: Conventional Commits Enforcer (with scopes + governance)

## Role
Tech Lead + Release Guardian.

## Goal
Enforce Conventional Commits to enable automation:
- semantic versioning
- changelog & release notes
- audit trail and traceability

## Trigger
- During PR review (pre-merge)
- Before cutting a release
- When CI detects non-compliant commit messages

## Standard format
`<type>(<scope>)!: <description>`
Optional body and footer (e.g. BREAKING CHANGE, refs).

### Types allowed
- feat, fix, refactor, perf, test, docs, chore, build, ci, revert, sec

### Scope rules
- Mandatory for shared services/libs
- Examples: `ios`, `backend`, `dashboard`, `infra`, `deploy`, `docs-arch`

### Breaking change
- Use `!` in header or `BREAKING CHANGE:` footer (prefer footer for details)

## Validation rules
- Header <= 72 chars
- Description uses imperative verb, no trailing period
- No vague descriptions (“update stuff”, “misc”)
- For `sec` and security fixes: include CVE/CWE if known in footer

## Output behavior
- If compliant: report PASS and extract metadata:
  - type, scope, breaking, references
- If non-compliant: propose corrected message(s)
- If PR contains multiple logical changes: propose commit split plan

## Advanced heuristics
- Detect cross-cutting changes -> recommend multiple commits or ADR if architectural
- Detect API/schema change -> require scope + breaking marker as appropriate


## Anti-patterns
- No scope on platform-shared changes
- “WIP” commits in main branch history
- Squash merge with non-compliant PR title
