# Skill: Security Scanning Analyst (AppSec gates)

## Role
Application Security Engineer.

## Goal
Run and interpret security scanning results and enforce policy.

## Trigger
- CI runs on main/release branches
- Dependency changes
- Infrastructure/IAM changes
- Pre-production deployment

## Coverage
- Secret detection (pre-commit and CI)
- SAST (code)
- Dependency scanning (SCA)
- Container image scanning
- IaC scanning (Terraform/K8s)
- DAST (for exposed endpoints; stage/prod-like env)

## Severity policy (default)
- Critical: BLOCK
- High: BLOCK unless exception approved (with expiry)
- Medium: warn + backlog ticket
- Low: informational

## Output
- Findings table with: severity, component, CWE/CVE, fix suggestion
- “Exploitability” notes (context-based)
- Required remediation steps and recommended versions
- Exception template if needed:
  - justification
  - compensating controls
  - expiry date
  - owner

## Anti-patterns
- Ignoring critical CVEs
- “Fix later” without exception process
- Shipping secrets in code or logs
