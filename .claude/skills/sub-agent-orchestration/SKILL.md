---
name: sub-agent-orchestration
cluster: foundations
description: "Multi-agent orchestration system for Claude Code. Four sub-agents (PO, Architect, EngMan, Dev) with pipeline collaboration, auto-routing, and per-project configuration. Use when processing any task to determine which agent perspective(s) to activate."
---

# Sub-Agent Orchestration

> **Version**: 1.0.0 | **Last updated**: 2026-02-14

## Purpose

This skill defines the runtime mechanics for Claude Code's multi-agent system. Four sub-agents — Product Owner, Architect, Engineering Manager, and Senior Developer — provide distinct professional perspectives. This skill governs agent selection, handoff, output assembly, and conflict resolution. For full agent profiles and behavioral rules, see `AGENTS.md` at the repo root.

---

## Auto-Routing Algorithm

When a task arrives without an explicit `@agent` prefix, evaluate in order:

```
INPUT: user_message

STEP 1 — Detect explicit prefix
  IF message starts with @po|@architect|@engman|@dev:
    ACTIVATE matched agent(s)
    STOP routing

STEP 2 — Keyword scan
  po_score       = count_matches(message, [requirements, user story, acceptance criteria,
                   priority, backlog, stakeholder, scope, MVP, feature definition,
                   product brief, value proposition])
  architect_score = count_matches(message, [architecture, NFR, non-functional, trade-off,
                    integration, API design, scalability, resilience, performance,
                    security architecture, platform, bounded context, service boundary,
                    ADR, fitness function, quality attribute])
  engman_score   = count_matches(message, [team, capacity, delivery, timeline, risk,
                   sprint, planning, process, migration effort, skill gap, onboarding,
                   hiring, coordination, rollout plan])
  dev_score      = count_matches(message, [implement, code, build, fix, refactor, test,
                   debug, PR, review, function, class, module, endpoint, migration,
                   dependency, package, lint, CI])

STEP 3 — Task pattern analysis
  IF task_is_about(WHAT to build):        po_score += 3
  IF task_is_about(HOW system structured): architect_score += 3
  IF task_is_about(WHO delivers WHEN):    engman_score += 3
  IF task_is_about(MAKING it work):       dev_score += 3

STEP 4 — Select agents
  scores = {po: po_score, architect: architect_score,
            engman: engman_score, dev: dev_score}
  max_score = max(scores.values())

  IF max_score == 0:
    ASK user: "This task could be approached from multiple angles.
              Should I focus on [requirements/architecture/delivery/implementation]?"

  IF multiple agents have score >= max_score * 0.7:
    ACTIVATE all high-scoring agents in pipeline order
  ELSE:
    ACTIVATE agent with highest score

STEP 5 — Filter by project config
  FOR each activated agent:
    IF agent is disabled in project config:
      ABSORB responsibilities into nearest active agent
```

---

## Agent Handoff Protocol

### Pipeline Execution

When multiple agents are active, execute in pipeline order: PO → Architect → EngMan → Dev. Each agent receives the output of all preceding agents as context.

### Loop-Back Mechanism

Any agent can request input from a previous agent when it discovers:
- **Missing requirements**: Dev or Architect discovers underspecified acceptance criteria → loop back to PO
- **Infeasible architecture**: EngMan discovers team cannot execute the proposed design → loop back to Architect
- **NFR conflict**: Dev discovers implementation violates a quality attribute → loop back to Architect
- **Scope drift**: Architect or Dev discovers work exceeds defined scope → loop back to PO

Loop-back format:

```markdown
### 🔄 Loop-back: @{{target}} ← @{{requester}}
**Reason**: {{why the loop-back is needed}}
**Question**: {{specific question or clarification needed}}
**Impact**: {{what is blocked until this is resolved}}
```

When a loop-back occurs, the target agent produces its response, and the pipeline resumes from that point forward.

### Handoff Rules

1. Each agent completes its section fully before handing off
2. Handoff includes a one-sentence summary of what the next agent should focus on
3. If an agent has nothing to contribute to the current task, it outputs `*No {{agent}} input required for this task.*` and the pipeline skips it
4. Loop-backs interrupt the pipeline — resolve the loop-back before continuing

---

## Deliverable Assembly

### Single-Agent Output

When only one agent is active, output uses that agent's deliverable format directly (no wrapper).

### Multi-Agent Output

When multiple agents contribute, assemble the output in this structure:

```markdown
# Task: {{task description}}

## 📋 PO Assessment
{{PO deliverable — requirements, acceptance criteria, scope}}

## 🏛️ Architecture Assessment
{{Architect deliverable — analysis, decision, trade-offs, diagrams, ADR}}

## 📊 Engineering Assessment
{{EngMan deliverable — delivery context, risks, effort, rollout plan}}

## 💻 Implementation
{{Dev deliverable — approach, code, tests, checklist}}

## 🔄 Cross-Agent Notes
{{Loop-backs, conflicts, open questions between agents}}
```

Omit sections for agents that were not activated. The Cross-Agent Notes section is only included when there are actual cross-agent issues.

---

## Configuration Loading

### Reading Project Configuration

Check for per-project agent configuration in this order:

1. Look for `<!-- claude-agents:begin -->` marker in the project's CLAUDE.md
2. Parse the `agents:` block within the markers
3. If no markers found, default to all agents active

### Parsing Rules

```
PARSE claude-agents block:
  FOR each line between markers:
    IF line matches "agents.{{name}}: false":
      DISABLE agent {{name}}
    IF line matches "agents.{{name}}.extra_triggers: \"...\"":
      ADD keywords to agent's trigger list

DEFAULT (no config found):
  po: true, architect: true, engman: true, dev: true
```

### Absorption Rules

When an agent is disabled:

| Disabled Agent | Absorbed By | What Transfers |
|---------------|-------------|----------------|
| PO | Architect | Requirements clarity, scope validation |
| Architect | Dev | Technical decisions (lightweight, no formal ADR) |
| EngMan | Architect | Delivery risk assessment, effort estimation |
| Dev | *(invalid)* | Dev cannot be disabled — at least one implementation agent must be active |

---

## Skill Loading per Agent

Each agent loads specific skills when activated. Skills are loaded from `.claude/skills/`.

### Product Owner (`@po`)

| Skill | When |
|-------|------|
| `ask-questions-if-underspecified` | Always |
| `functional-analysis` | Domain analysis tasks |
| `architecture-stakeholder-communication` | Outward communication |
| `writing-plans` | Breaking down work |

### Architect (`@architect`)

| Skill | When |
|-------|------|
| `architecture-decision-records` | Always |
| `diagrams` | Always |
| `nfr-specification` | Quality attribute work |
| `architecture-review-facilitation` | Reviewing proposals |
| `trade-off-analysis` | Evaluating alternatives |
| `architecture-risk-assessment` | Risk assessment |
| `functional-analysis` | Domain analysis |
| `integration-design` | Integration design |
| `fitness-functions` | Architectural guardrails |
| `platform-architecture` | Platform capabilities |
| `architecture-stakeholder-communication` | Decision communication |
| Domain-specific | `api-design`, `microservices-patterns`, `event-driven-architecture`, `data-modeling`, `error-handling-resilience`, `observability`, `security-by-design` — loaded based on task domain |

### Engineering Manager (`@engman`)

| Skill | When |
|-------|------|
| `architecture-risk-assessment` | Delivery risk perspective |
| `production-readiness-review` | Go/no-go assessment |
| `incident-management` | Operational readiness |
| `release-management` | Release planning |
| `executing-plans` | Execution structuring |
| `quality-gates` | Delivery gates |

### Senior Developer (`@dev`)

| Skill | When |
|-------|------|
| All `testing-quality` cluster | Always |
| All `security-compliance` cluster | Always (secure coding) |
| `error-handling-resilience` | Always |
| `api-design` | API implementation |
| `data-modeling` | Database work |
| `containerization` | Docker work |
| `cicd-pipeline` | CI configuration |
| Technology-specific | iOS skills for Swift, etc. |

---

## Conflict Resolution Protocol

When agents produce contradictory recommendations:

### Detection

Conflicts are detected when:
- Architect proposes a design that EngMan flags as infeasible for the team
- PO scope boundaries conflict with Architect's technical requirements
- Dev identifies implementation issues with Architect's proposed design
- EngMan timeline conflicts with PO priority

### Resolution Steps

1. **Document both positions** with rationale and evidence
2. **Identify the decision dimension** — which agent OWNS this decision?
3. **OWNS agent decides** — the agent with ownership authority on that dimension makes the call
4. **Record the override** — the overridden position is documented as a risk

| Conflict Dimension | Decision Owner | Example |
|-------------------|---------------|---------|
| Business priority, scope | PO | "Feature X is higher priority than technical debt reduction" |
| Technical architecture | Architect | "Event-driven over synchronous, despite higher complexity" |
| Delivery timeline, team capacity | EngMan | "Phase 2 delayed by 2 weeks due to skill gap" |
| Implementation approach | Dev | "Use Drizzle ORM over raw SQL for this use case" |

### Escalation

If the conflict is fundamental — it blocks the task entirely and no agent has clear ownership — escalate to the user:

```markdown
### ⚠️ Agent Conflict — User Input Required
**Conflict**: {{description}}
**Position A** (@{{agent}}): {{position and rationale}}
**Position B** (@{{agent}}): {{position and rationale}}
**Why it matters**: {{impact on the task}}
**Recommendation**: {{if any agent has a recommendation}}
```

---

## Anti-Patterns

- **Agent for everything**: activating all four agents for a simple typo fix — match agent activation to task complexity
- **Ignoring loop-backs**: continuing the pipeline when a previous agent has flagged an issue — resolve loop-backs before proceeding
- **Agent theater**: generating all four agent sections with generic content to "look thorough" — if an agent has nothing to contribute, skip it
- **Overriding without recording**: an agent silently overriding another's recommendation — every override must be documented as a risk
- **Permanent multi-agent mode**: always running all agents regardless of task — single-agent activation is the common case, multi-agent is the exception

---

## For Claude Code

When processing any task: first check for explicit `@agent` prefix in the user's message. If present, activate only the named agent(s). If no prefix, run the auto-routing algorithm: scan for keywords, analyze task pattern, and select the agent(s) with the highest relevance score. For single-concern tasks, activate one agent. For cross-cutting tasks, activate multiple agents in pipeline order (PO → Architect → EngMan → Dev) and assemble output using the multi-agent template. Load the project's agent configuration from `<!-- claude-agents:begin -->` markers in CLAUDE.md — if absent, all agents are active. For each activated agent, load its skill set before generating output. When conflicts arise between agents, apply the OWNS-based resolution protocol: the agent that owns the decision dimension has final authority, and the override is recorded as a risk. Use loop-backs when any agent discovers gaps requiring input from a previous agent — resolve before continuing the pipeline. Never generate agent sections with generic filler — if an agent has nothing meaningful to contribute, skip it entirely.

---

*Internal references*: `ask-questions-if-underspecified/SKILL.md`, `architecture-decision-records/SKILL.md`, `functional-analysis/SKILL.md`
