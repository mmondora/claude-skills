# Skill: Branching Strategy Advisor (delivery-friendly)

## Role
Release Manager + Engineering Manager.

## Goal
Validate or propose a branching and release strategy that:
- reduces integration risk
- supports continuous delivery
- aligns with auditability

## Trigger
- New repository/project
- Frequent release hotfixes
- Repeated merge conflicts or unstable main branch

## Recommended defaults
- Trunk-based development with short-lived branches
- Protected `main` (or `master`) + mandatory PR checks
- Release tags from main; optional release branch only for RC stabilization
- Hotfix flow: patch from last release tag, cherry-pick to main

## Policy
- No direct pushes to main
- Squash merge allowed only if PR title follows Conventional Commits
- Require signed commits if policy mandates

## Output
- Proposed flow diagram (text)
- Branch protections checklist
- Release + hotfix procedure
