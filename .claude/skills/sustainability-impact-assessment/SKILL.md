---
name: sustainability-impact-assessment
description: "Sustainability governance council for software projects. Impact assessment framework, green PRR checklist, sustainability review process, GSF Maturity Matrix self-assessment, broader impact (social, environmental, economic). Use before major releases, architecture reviews, or when evaluating the broader impact of software decisions."
---

# Sustainability Impact Assessment

> **Version**: 1.0.0 | **Last updated**: 2026-02-11

## Purpose

This skill defines the governance framework — the "council" — for sustainability and broader impact assessment in software projects. Just as security and compliance have formal review gates, sustainability deserves a structured assessment process. This is not just carbon — it is a holistic view of the impact software has on people, planet, and prosperity.

**References**: [Green Software Foundation](https://greensoftware.foundation/) | [GSF Maturity Matrix](https://greensoftware.foundation/projects/) | [B Corp Assessment](https://www.bcorporation.net/) | [ISO 14001](https://www.iso.org/iso-14001-environmental-management.html)

---

## The Three Pillars of Impact

Sustainability in software is not only about carbon. Following the model of triple bottom line (and aligned with mondora's B Corp DNA), every project should consider three pillars:

### 1. Environmental Impact (Planet)

Carbon emissions, energy consumption, hardware lifecycle, e-waste, water usage of datacenters. Measured primarily through the SCI score (see `sci-measurement/SKILL.md`) and green software patterns (see `carbon-aware-architecture/SKILL.md`).

### 2. Social Impact (People)

Accessibility, digital inclusion, labor conditions in the supply chain, user well-being, privacy as a right (not a feature), algorithmic fairness, impact on communities.

### 3. Economic Impact (Prosperity)

Fair value distribution, support for local economies, open-source contribution, knowledge sharing, sustainable business models, cost transparency for users and stakeholders.

---

## Sustainability Impact Assessment (SIA) Process

### When to Run a SIA

- New project inception (before first line of code)
- Major architecture change with infrastructure impact
- New service going to production (alongside PRR — see `production-readiness-review/SKILL.md`)
- Quarterly review for existing production services
- Before major cloud provider or region change
- When introducing AI/ML workloads

### Who Participates

| Role | Responsibility |
|------|---------------|
| **Tech Lead** | Presents architecture and infrastructure choices |
| **Sustainability Champion** | Reviews against GSF principles and SCI metrics |
| **Product Owner** | Validates social impact and user well-being considerations |
| **SRE / Platform** | Validates operational sustainability (scaling, regions, efficiency) |
| **Optional: B Corp / Impact Officer** | Reviews alignment with broader organizational impact commitments |

---

## SIA Checklist

### A. Environmental Assessment

#### A1. Carbon & Energy

- [ ] SCI score calculated for the current release (see `sci-measurement/SKILL.md`)
- [ ] SCI trend tracked — is it decreasing vs the previous release?
- [ ] Deployment region selected considering carbon intensity (see `carbon-aware-architecture/SKILL.md`)
- [ ] Energy efficiency patterns applied: caching, compression, lazy evaluation, efficient serialization
- [ ] Serverless / scale-to-zero configured for non-production environments
- [ ] Container images optimized (multi-stage, distroless/alpine, <150MB)
- [ ] CI/CD pipeline uses caching and minimal build matrix

#### A2. Hardware & E-Waste

- [ ] Software runs on current AND previous-generation hardware
- [ ] Frontend supports progressive enhancement (works on older browsers/devices)
- [ ] No unnecessary hardware upgrades required for users
- [ ] ARM64 support enabled (lower embodied carbon per compute unit)

#### A3. Data & Storage

- [ ] Data minimization principle applied (collect only what is needed)
- [ ] Retention policies configured — data is not stored indefinitely
- [ ] Cold storage lifecycle for archival data
- [ ] Database queries optimized (proper indexing, no full scans in hot paths)

### B. Social Assessment

#### B1. Accessibility & Inclusion

- [ ] WCAG 2.1 AA compliance for all user-facing interfaces
- [ ] Internationalization (i18n) support for target markets
- [ ] Performance budget ensures the application works on low-bandwidth connections
- [ ] Content available without JavaScript for core functionality (progressive enhancement)

#### B2. Privacy & User Well-Being

- [ ] Privacy by design: data minimization, purpose limitation, consent management
- [ ] GDPR compliance verified (see `compliance-privacy/SKILL.md`)
- [ ] No dark patterns in UX (forced opt-ins, confusing unsubscribe flows, manipulative design)
- [ ] Algorithmic fairness reviewed for AI/ML features (bias assessment)
- [ ] User notification fatigue considered — no unnecessary interruptions

#### B3. Supply Chain & Labor

- [ ] Open-source dependencies audited for license compliance
- [ ] No dependencies on projects with known exploitative labor practices
- [ ] Cloud provider evaluated for labor practices and environmental commitments
- [ ] Accessibility of documentation and contribution process for open-source components

### C. Economic Assessment

#### C1. Value Distribution

- [ ] Cost-per-user/tenant documented and transparent (see `finops/SKILL.md`)
- [ ] Pricing model fair and proportional to value delivered
- [ ] Open-source components contributed back when possible
- [ ] Knowledge shared through documentation, blog posts, or conference talks

#### C2. Sustainable Business Model

- [ ] Total cost of ownership documented (infra + maintenance + support)
- [ ] Revenue model does not depend on user data exploitation
- [ ] Vendor lock-in minimized through abstraction layers (cloud-agnostic)
- [ ] Business continuity plan considers the sustainability of third-party services

---

## SIA Output Document

```markdown
# Sustainability Impact Assessment: [Project/Service] — [Date]

## Decision: PASS / CONDITIONAL PASS / NEEDS IMPROVEMENT

## Participants
- [names and roles]

## Summary
[2-3 sentences on overall sustainability posture]

## SCI Scorecard
| Metric | Current | Previous | Trend |
|--------|---------|----------|-------|
| SCI Score | [X gCO2eq/R] | [Y gCO2eq/R] | [↓ improved / → stable / ↑ regressed] |
| Energy (E) | [X kWh/month] | | |
| Carbon Intensity (I) | [X gCO2eq/kWh] | | |
| Deployment Region | [region] | | CI: [X gCO2eq/kWh] |
| Functional Unit (R) | [per X] | | |

## Environmental Assessment
| Area | Status | Notes |
|------|--------|-------|
| Carbon & Energy | PASS / PARTIAL / NEEDS WORK | ... |
| Hardware & E-Waste | PASS / PARTIAL / NEEDS WORK | ... |
| Data & Storage | PASS / PARTIAL / NEEDS WORK | ... |

## Social Assessment
| Area | Status | Notes |
|------|--------|-------|
| Accessibility & Inclusion | PASS / PARTIAL / NEEDS WORK | ... |
| Privacy & User Well-Being | PASS / PARTIAL / NEEDS WORK | ... |
| Supply Chain & Labor | PASS / PARTIAL / NEEDS WORK | ... |

## Economic Assessment
| Area | Status | Notes |
|------|--------|-------|
| Value Distribution | PASS / PARTIAL / NEEDS WORK | ... |
| Sustainable Business Model | PASS / PARTIAL / NEEDS WORK | ... |

## Actions
| Action | Owner | Priority | Deadline |
|--------|-------|----------|----------|
| ... | ... | ... | ... |

## Sustainability Commitments
[How this project contributes to organizational climate commitments.
Mechanism: elimination / avoidance / removal.]
```

---

## Green PRR Extension

The Production Readiness Review (see `production-readiness-review/SKILL.md`) should include a **Section 10: Sustainability Readiness**:

### 10. Sustainability Readiness

- [ ] SCI score calculated and baselined
- [ ] Deployment region carbon intensity documented
- [ ] Scale-to-zero configured for non-production
- [ ] Container image size < 150MB (alpine) or < 80MB (distroless)
- [ ] Data retention policies automated
- [ ] SCI tracking integrated in CI pipeline
- [ ] Carbon metrics exported to observability dashboard
- [ ] Sustainability Impact Assessment completed (if new service)

---

## GSF Maturity Matrix Self-Assessment

Run this self-assessment quarterly per project:

### Level 1 — Ad Hoc

| Question | Answer |
|----------|--------|
| Does the team know what SCI is? | Yes / No |
| Has anyone completed the GSF training? | Yes / No |
| Is there any sustainability-related measurement? | Yes / No |

If any answer is "No" → **Level 1**. Action: schedule GSF training, assign Sustainability Champion.

### Level 2 — Aware

| Question | Answer |
|----------|--------|
| Is the deployment region's carbon intensity known? | Yes / No |
| Has the team calculated an initial SCI estimate? | Yes / No |
| Are basic energy efficiency patterns applied (caching, compression)? | Yes / No |
| Is sustainability mentioned in at least one ADR? | Yes / No |

If all "Yes" → **Level 2**. Action: integrate SCI into CI, adopt carbon-aware patterns.

### Level 3 — Practiced

| Question | Answer |
|----------|--------|
| Is SCI measured per release? | Yes / No |
| Are carbon-aware patterns systematically applied? | Yes / No |
| Is "Sustainability Impact" a standard section in ADRs? | Yes / No |
| Has a Sustainability Impact Assessment been conducted? | Yes / No |
| Are carbon metrics in the observability dashboard? | Yes / No |

If all "Yes" → **Level 3**. Action: set carbon budgets, automate regression detection.

### Level 4 — Optimized

| Question | Answer |
|----------|--------|
| Is SCI tracked as a quality gate (build fails on regression)? | Yes / No |
| Are carbon budgets per service defined and enforced? | Yes / No |
| Is time-shifting or spatial-shifting active for batch workloads? | Yes / No |
| Does the project contribute to organizational climate commitments? | Yes / No |
| Is the SIA review conducted quarterly? | Yes / No |

If all "Yes" → **Level 4**. Action: maintain, share knowledge, contribute patterns to GSF catalog.

---

## Sustainability in the SDLC

Sustainability is not a phase — it is woven through the entire software development lifecycle:

| SDLC Phase | Sustainability Action |
|-----------|---------------------|
| **Requirements** | Include sustainability as a non-functional requirement. Define carbon budget. |
| **Design** | Run SIA at inception. Choose green patterns. Document in ADR. |
| **Implementation** | Apply energy efficiency patterns. Minimize dependencies. Efficient algorithms. |
| **Testing** | Performance tests double as energy budgets. Measure CI pipeline carbon. |
| **Deployment** | Carbon-aware region selection. Scale-to-zero for non-prod. SCI baseline. |
| **Operations** | Track SCI in dashboard. Monitor trends. Quarterly SIA review. |
| **Decommission** | Clean up resources. Delete unused data. Update carbon accounting. |

---

## Impact Reporting Template

For B Corp alignment and stakeholder communication:

```markdown
# Impact Report: [Project/Service] — [Quarter/Year]

## Environmental
- **SCI Score**: [X gCO2eq/R] (trend: [↓/→/↑] vs previous quarter)
- **Estimated Annual Emissions**: [X kgCO2eq]
- **Emission Reductions Achieved**: [actions taken and their impact]
- **Green Patterns Applied**: [list of GSF patterns in use]
- **Deployment Regions**: [regions and their carbon intensity]

## Social
- **Accessibility Score**: [WCAG level achieved]
- **Users on Low-Bandwidth**: [% served with acceptable performance]
- **Privacy**: [GDPR status, data minimization actions]
- **Open-Source Contributions**: [PRs, issues, maintainership]

## Economic
- **Unit Cost Transparency**: [cost per user/tenant]
- **Vendor Lock-In Score**: [high/medium/low with justification]
- **Knowledge Shared**: [docs published, talks given, blog posts]

## Next Quarter Goals
- [specific, measurable sustainability goals]
```

---

## Anti-Patterns

- **"Impact is marketing's job"**: impact begins with architecture. Marketing reports it; engineers create it.
- **"Sustainability = carbon only"**: carbon is essential but not sufficient. Social and economic impact matter equally.
- **"SIA is a checkbox exercise"**: if the SIA does not produce actions, it is theater. Every SIA must end with concrete, owned action items.
- **"We'll add accessibility later"**: accessibility retrofits are expensive and incomplete. Design for inclusion from day one.
- **"B Corp is for non-tech"**: tech companies are among the largest employers and resource consumers. Impact governance is a competitive advantage.
- **"Our scale is too small to matter"**: habits formed at small scale become culture at large scale. Start now.

---

## For Claude Code

When preparing architecture reviews or production readiness: generate the SIA checklist pre-populated with actual project data, identify missing sustainability items, suggest concrete fixes for each gap. When creating new projects: include sustainability as a non-functional requirement from the start, suggest SCI measurement setup alongside observability, include the "Sustainability Impact" section in ADR templates. When reviewing existing projects: run the Maturity Matrix self-assessment and suggest the path to the next level.

---

*Internal references*: `green-software-principles/SKILL.md`, `sci-measurement/SKILL.md`, `carbon-aware-architecture/SKILL.md`, `production-readiness-review/SKILL.md`, `compliance-privacy/SKILL.md`, `finops/SKILL.md`, `architecture-decision-records/SKILL.md`, `quality-gates/SKILL.md`
