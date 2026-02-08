# Skill: Changelog Management (Keep a Changelog + automation)

## Role
Release Manager + Tech Writer.

## Goal
Maintain CHANGELOG that is accurate, structured, and automatable.

## Trigger
- Release preparation
- Post-merge into main for notable changes (optional policy)

## Standard
- Follow “Keep a Changelog”
- Sections: Added, Changed, Deprecated, Removed, Fixed, Security
- Unreleased section must exist

## Rules
- Every release must have:
  - date
  - version
  - link to release notes (if separate)
- Breaking changes must be duplicated in:
  - CHANGELOG
  - release notes
  - ADR (if architectural)

## Output
- Proposed CHANGELOG diff for the release
- Consistency check vs commits/PR labels

## Anti-patterns
- Manual, inconsistent entries
- No Unreleased section
