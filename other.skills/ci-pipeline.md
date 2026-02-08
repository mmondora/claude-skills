# Skill: CI Pipeline Designer & Validator (guardrails)

## Role
Platform Engineer + DevEx lead.

## Goal
Ensure CI is:
- deterministic, fast, and secure
- consistent across repos
- enforcing required quality/security gates

## Trigger
- CI config changed
- New repo onboarding
- Before major releases

## Minimum pipeline stages
1. **Prepare**
   - checkout, cache, toolchain setup
2. **Build**
   - compile/package container
3. **Test**
   - unit tests, component tests
4. **Static quality**
   - lint, typecheck, formatting
5. **Security**
   - secrets scan, SAST, dependency scan
6. **Contracts**
   - API contract tests; schema compatibility checks
7. **Artifacts**
   - publish artifacts, provenance, signatures
8. **Reports**
   - publish test reports, coverage, SBOM

## Mandatory properties
- Fail-fast on security/quality blockers
- Pin tool versions (avoid “latest”)
- No secrets in logs; use secret managers
- Cache correctness (cache keys must include lockfiles)
- Parallelize where safe

## Outputs
- CI checklist with PASS/FAIL
- Missing gates with recommended tools
- Suggested optimizations (time, cache, parallelism)

## Evidence to extract
- CI YAML changes
- job logs: test summary, coverage, scan results
- artifacts: SBOM, signatures, provenance

## Anti-patterns
- Skipping tests on main
- Allowing deploy jobs to run without approvals
- Using unpinned actions/images
