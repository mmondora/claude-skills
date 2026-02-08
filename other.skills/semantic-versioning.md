# Skill: Semantic Versioning Manager (SemVer + product policy)

## Role
Release Architect + Product Owner.

## Goal
Determine correct version bump and ensure it matches product policy.

## Trigger
- Release preparation
- After merge into release branch
- After API/schema contract changes

## Inputs
- Parsed Conventional Commits metadata for release range
- Contract diffs (OpenAPI/AsyncAPI/protobuf)
- DB migration list
- Deprecation notices
- Feature flag strategy (if any)

## Rules (SemVer)
### MAJOR
- Breaking API/contract change
- Breaking behavior change (even if API same)
- Schema change that breaks backward compatibility
- Removal of deprecated capability without maintained compatibility window

### MINOR
- New backward-compatible feature
- New optional fields, additive endpoints, additive events
- Backward-compatible behavior extension

### PATCH
- Bugfixes
- Performance improvements without behavior change
- Refactors that preserve external behavior

## Product policy overlay
- If service is internal only but shared across many consumers: treat as public API (stricter)
- For shared/core services: prefer **compatibility-first**; breaking changes require:
  - ADR
  - migration plan
  - deprecation timeline

## Output
- Proposed version: `X.Y.Z`
- Justification with evidence:
  - list of commits by type
  - list of breaking indicators
  - contract diff summary
- Risk assessment:
  - consumer impact
  - migration complexity
  - rollback feasibility

## Anti-patterns
- Bumping minor for breaking changes
- Ignoring schema/contract compatibility
- “Always patch” mentality for risky changes
