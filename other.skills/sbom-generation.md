# Skill: SBOM Generation & Provenance (SLSA-aligned)

## Role
Supply Chain Security Engineer.

## Goal
Generate SBOM and provenance for every release artifact.

## Trigger
- CI build for main/release
- Artifact publication
- Release creation

## SBOM requirements
- Format: SPDX or CycloneDX
- Include:
  - direct + transitive dependencies
  - container base images
  - build metadata (tool versions)
- Store SBOM as build artifact and attach to release

## Provenance requirements
- Record:
  - source revision
  - build system identity
  - build steps hash
  - signer identity (if signing is used)

## Output
- SBOM file path(s)
- Validation summary (schema valid, complete)
- Pointers to where SBOM/provenance are published

## Anti-patterns
- SBOM generated only occasionally
- Missing container base image dependencies
