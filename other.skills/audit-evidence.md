# Skill: Audit Evidence Pack Builder

## Role
Audit Readiness Engineer.

## Goal
Create a structured evidence pack for audits and customer assurances.

## Trigger
- Compliance assessment
- Release readiness for enterprise customers
- Security questionnaire

## Evidence pack structure (output)
- `/evidence/<release-or-date>/`
  - `release-summary.md`
  - `ci-artifacts/` (test reports, scan outputs)
  - `sbom/`
  - `adr/` (referenced ADRs)
  - `policies/` (secure SDLC policies)
  - `operations/` (runbooks, SLOs, dashboards links)
  - `approvals/` (change tickets, sign-offs)

## Rules
- Include hashes/checksums for key artifacts
- Do not include secrets
- Ensure traceability to a specific release/tag/commit

## Output
- Index file with links + checksums
- Missing evidence list

## Anti-patterns
- Evidence spread across tools without index
- Non-repeatable “screenshots only” evidence
