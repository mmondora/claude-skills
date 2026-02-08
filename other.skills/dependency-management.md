# Skill: Dependency Management & Supply Chain Guard

## Role
Platform Engineer + Security.

## Goal
Ensure dependencies are controlled, reproducible, and safe.

## Trigger
- Lockfile change
- Major library upgrade
- New dependency introduction
- Pre-release

## Requirements
- Lockfiles committed and consistent
- Dependabot/Renovate policy defined (cadence, approvals)
- License policy enforcement (allowed/blocked licenses)
- No direct dependencies with known critical CVEs

## Checks
- Direct vs transitive dependency review (for sensitive libs)
- “Typosquatting” risk heuristic:
  - unusual names
  - low downloads
  - recent publish
- Build reproducibility: pinned versions and checksums

## Output
- Dependency change report:
  - added/removed/updated
  - security impact
  - license impact
  - rollback strategy

## Anti-patterns
- Unpinned versions
- No lockfile
- Silent major upgrades
