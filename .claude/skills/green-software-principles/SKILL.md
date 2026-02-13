---
name: green-software-principles
description: "Green Software Foundation principles as an architectural discipline. Carbon efficiency, energy efficiency, carbon awareness, hardware efficiency, measurement, climate commitments. Use when making any technical decision — every choice has a carbon cost."
cluster: green-software
---

# Green Software Principles

> **Version**: 1.0.0 | **Last updated**: 2026-02-11

## Purpose

Sustainability is a software architecture attribute, on the same level as performance, security, and cost. Every technical choice has a carbon impact — make it explicit, measurable, and reducible. This skill codifies the six principles of the Green Software Foundation (GSF) as operational guidance for software teams.

**Reference**: [Green Software Foundation](https://greensoftware.foundation/) — ISO/IEC 21031:2024 (SCI Specification)

---

## The Six Principles

The GSF defines six core principles. A green software practitioner applies all six, not just the convenient ones.

### 1. Carbon Efficiency

**Emit the least carbon possible per unit of work.**

Carbon efficiency is the north star. It is not about zero emissions (all software uses energy) — it is about minimizing the carbon emitted for each unit of value delivered. This is the software equivalent of fuel efficiency: same destination, less fuel.

Implications for architecture: prefer algorithms with lower computational complexity, avoid redundant computation, cache aggressively, batch where possible, eliminate dead code and unused features that still consume resources.

### 2. Energy Efficiency

**Use the least energy possible.**

Energy efficiency is the most direct lever. Less energy consumed means less carbon emitted, regardless of the energy source.

Implications: right-size infrastructure (do not over-provision), prefer serverless and scale-to-zero, optimize hot paths, reduce payload sizes, compress data in transit, minimize unnecessary network calls, use efficient serialization formats (Protocol Buffers over JSON where appropriate).

### 3. Carbon Awareness

**Do more when electricity is clean, do less when it is dirty.**

The carbon intensity of electricity varies by location and time. A kilowatt-hour consumed in Norway (hydro) emits far less CO2 than the same kWh in Poland (coal). Even within one grid, intensity fluctuates hourly based on the renewable mix.

Implications: schedule batch workloads when carbon intensity is low (time shifting), route computation to regions with cleaner grids (spatial shifting), reduce non-essential work during high-intensity periods (demand shaping). See `carbon-aware-architecture/SKILL.md` for patterns.

### 4. Hardware Efficiency

**Use the least embodied carbon possible.**

Embodied carbon is the CO2 emitted during manufacturing, transport, and disposal of hardware. For many software systems, especially client-side, embodied carbon exceeds operational carbon over the hardware lifecycle.

Implications: write software that runs well on older hardware (extend device lifespan), avoid unnecessary hardware upgrades, optimize for ARM where possible (lower embodied carbon per compute unit), design for heterogeneous hardware, support progressive enhancement in frontends.

### 5. Measurement

**What you cannot measure, you cannot improve.**

Without measurement there is no baseline, no trend, no accountability. The SCI (Software Carbon Intensity) score is the standard metric. See `sci-measurement/SKILL.md` for implementation.

Implications: instrument energy consumption, track carbon intensity per deployment region, calculate SCI score per release, include carbon metrics in dashboards alongside latency and error rate.

### 6. Climate Commitments

**Understand the exact mechanism of carbon reduction.**

Organizations make climate commitments: carbon neutral, net zero, science-based targets. Software teams must understand which mechanism their work supports: carbon elimination (abatement — the only way to reduce SCI), carbon avoidance (compensating), or carbon removal (neutralizing).

Implications: SCI reductions require actual emission elimination through energy efficiency, carbon awareness, and hardware efficiency. Offsets do not reduce SCI. Record the carbon reduction mechanism in ADRs for infrastructure decisions.

---

## Principles Applied to the Stack

| Layer | Principle Applied | Practical Action |
|-------|------------------|-----------------|
| **Frontend** | Energy + Hardware Efficiency | Reduce bundle size, lazy-load, progressive enhancement, support older devices |
| **Backend** | Energy + Carbon Efficiency | Optimize hot paths, efficient algorithms, cache, batch, eliminate dead code |
| **API** | Energy Efficiency | Minimize payload size, use compression, avoid over-fetching (pagination, field selection) |
| **Database** | Energy + Carbon Efficiency | Optimize queries, proper indexing, connection pooling, read replicas in clean regions |
| **Infrastructure** | All six principles | Serverless-first, scale-to-zero, right-size, carbon-aware scheduling, measure SCI |
| **CI/CD** | Carbon Awareness + Energy | Schedule non-urgent builds in low-intensity windows, cache aggressively, minimize build matrix |
| **AI/ML** | All six principles | Use pre-trained models, quantize, distill, train in low-carbon regions, measure SCI-AI |

---

## Green Software in ADRs

Every ADR with significant infrastructure or architectural impact must include a **"Sustainability Impact"** section:

```markdown
## Sustainability Impact

**Energy delta**: [estimated change in energy consumption vs current state]
**Carbon awareness**: [is the workload time-shiftable or location-shiftable?]
**Hardware impact**: [does this require new hardware or extend existing hardware lifespan?]
**SCI impact**: [estimated direction of SCI score — up, down, neutral — with reasoning]
**Trade-offs**: [sustainability vs other NFRs — performance, cost, developer experience]
```

This section does not need precise numbers at the ADR stage — directional analysis is sufficient. Precise measurement comes via `sci-measurement/SKILL.md`.

---

## The Green Software Maturity Matrix

The GSF Maturity Matrix provides a self-assessment across four levels:

| Level | Description | Characteristics |
|-------|------------|----------------|
| **1 — Ad hoc** | No systematic approach | No measurement, no awareness, reactive only |
| **2 — Aware** | Principles understood | Team trained, some measurement started, no systematic integration |
| **3 — Practiced** | Integrated in process | SCI measured, carbon-aware patterns applied, sustainability in ADRs |
| **4 — Optimized** | Continuous improvement | SCI tracked per release, carbon budgets enforced, green patterns standard |

Target: every project should reach Level 3 within 6 months of inception. Level 4 is the steady state for production systems.

---

## Integration with Existing Skills

Green software principles are cross-cutting. They do not replace existing skills — they add a sustainability lens to every decision:

| Existing Skill | Green Software Overlay |
|---------------|----------------------|
| `finops/SKILL.md` | Cost optimization often aligns with carbon optimization (less compute = less cost = less carbon) — but not always. Spot the divergences. |
| `containerization/SKILL.md` | Smaller images = less transfer energy. Multi-arch (ARM) = lower embodied carbon per compute unit. |
| `infrastructure-as-code/SKILL.md` | Scale-to-zero, right-sizing, region selection based on carbon intensity. |
| `performance-testing/SKILL.md` | Performance budgets are also energy budgets. Faster code uses less energy. |
| `production-readiness-review/SKILL.md` | PRR checklist should include sustainability readiness. |
| `observability/SKILL.md` | Carbon metrics belong in dashboards alongside latency, error rate, saturation. |

---

## Anti-Patterns

- **"Sustainability can wait"**: carbon debt compounds like technical debt — harder to fix later
- **"Offsets make us green"**: offsets do not reduce actual emissions. SCI only decreases through elimination.
- **"Green = slow"**: efficient code is often faster code. Sustainability and performance are usually aligned.
- **"We are too small to matter"**: unit economics apply — carbon per request matters at any scale, and habits formed at small scale persist at large scale.
- **"Measurement is too hard"**: start with estimates, refine over time. An imprecise SCI is infinitely better than no SCI.

---

## For Claude Code

When generating code and architecture: apply energy efficiency by default (prefer efficient algorithms, avoid unnecessary computation, minimize payload sizes), suggest carbon-aware alternatives when infrastructure choices involve region or scheduling, include sustainability considerations in ADRs, recommend SCI measurement as part of observability setup. Sustainability is not an optional add-on — it is an attribute of quality software.

---

*Internal references*: `sci-measurement/SKILL.md`, `carbon-aware-architecture/SKILL.md`, `sustainability-impact-assessment/SKILL.md`, `finops/SKILL.md`, `infrastructure-as-code/SKILL.md`, `observability/SKILL.md`
