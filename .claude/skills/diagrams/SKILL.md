---
name: diagrams
description: "Architectural diagrams as code using Mermaid and C4 model. System context, container, component, sequence, ERD, and state diagrams. Use when creating architecture diagrams, documenting flows, or visualizing system design."
---

# Diagrams & Visualization

> **Version**: 1.0.0 | **Last updated**: 2026-02-08

## Purpose

Architectural diagrams as code. Mermaid as primary format (renderable in GitHub, IDEs, docs), PlantUML as fallback for complex cases. C4 model as the reference framework.

---

## C4 Model

Four zoom levels, from highest to lowest. Not all are needed — use the levels that communicate the necessary concept.

### Level 1 — System Context

Who uses the system and what it interacts with. External actors (users, third-party systems), the system as a black box, main relationships. **When to use**: for non-technical stakeholders, high-level documentation, onboarding.

### Level 2 — Container

The "containers" (not Docker — applications, databases, message brokers) composing the system. Frontend, backend, database, message queue. **When to use**: for the technical team, infrastructure decisions, architecture reviews.

```mermaid
graph TB
    subgraph "Invoice Platform"
        WebApp["Web App<br/>React + TypeScript"]
        API["API Service<br/>Node.js + Fastify"]
        Worker["Event Worker<br/>Cloud Run Job"]
        DB[("Firestore")]
        PubSub["Pub/Sub"]
    end
    WebApp -->|"REST/JSON"| API
    API -->|"Read/Write"| DB
    API -->|"Publish events"| PubSub
    PubSub -->|"Subscribe"| Worker
    Worker -->|"Read/Write"| DB
```

### Level 3 — Component

Internal components of a container. Modules, services, layers. Useful for complex services.

### Level 4 — Code

Classes and interfaces. Rarely useful as a static diagram — code is the best documentation at this level.

---

## Diagram Types

### Sequence Diagram

For interaction flows between components. Use for: API flows, event-driven flows, saga/choreography, authentication flows.

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Auth as Firebase Auth
    participant DB as Firestore
    Client->>Auth: Sign in
    Auth-->>Client: JWT Token
    Client->>API: POST /invoices (+ JWT)
    API->>Auth: Verify token
    API->>DB: Save invoice
    API-->>Client: 201 Created
```

### Entity Relationship Diagram

For data models. Firestore is schema-less but documents have an implicit structure that must be documented.

```mermaid
erDiagram
    TENANT ||--o{ USER : has
    TENANT ||--o{ INVOICE : owns
    USER ||--o{ INVOICE : creates
    INVOICE ||--|{ LINE_ITEM : contains
    INVOICE }o--|| INVOICE_STATUS : has

    TENANT {
        uuid id PK
        string name
        string plan
        timestamp created_at
    }
    USER {
        uuid id PK
        uuid tenant_id FK
        string email
        string role
    }
    INVOICE {
        uuid id PK
        uuid tenant_id FK
        uuid created_by FK
        string status
        decimal total_amount
        string currency
        timestamp created_at
    }
    LINE_ITEM {
        uuid id PK
        uuid invoice_id FK
        string description
        decimal amount
        int quantity
    }
```

### Deployment Diagram

For infrastructure and deployment topology:

```mermaid
graph TB
    subgraph "GCP — europe-west1"
        subgraph "Cloud Run"
            API["API Service<br/>2 instances min"]
            Worker["Event Worker<br/>0 instances min"]
        end
        subgraph "Data"
            FS[("Firestore<br/>Native mode")]
            Redis["Memorystore<br/>Redis 7"]
        end
        subgraph "Messaging"
            PS["Pub/Sub"]
            DLQ["Dead Letter Queue"]
        end
        subgraph "Security"
            SM["Secret Manager"]
            IAM["Cloud IAM"]
        end
    end
    subgraph "External"
        CDN["Cloud CDN"]
        LB["Cloud Load Balancer"]
        Users["Users"]
    end
    Users --> CDN --> LB --> API
    API --> FS
    API --> Redis
    API --> PS
    PS --> Worker
    PS --> DLQ
    Worker --> FS
    API --> SM
```

### State Diagram

For state machines (invoice status, order status, entity lifecycle).

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Sent: send()
    Sent --> Paid: markPaid()
    Sent --> Overdue: pastDueDate
    Overdue --> Paid: markPaid()
    Sent --> Void: void()
    Draft --> Void: void()
    Paid --> [*]
    Void --> [*]
```

---

## Principles

**Diagram as code**: Mermaid or PlantUML in the repo, versioned with git. Never PNG/JPG images as source (not modifiable, not diffable).

**One diagram, one concept**: if a diagram tries to show everything, it shows nothing. Each diagram answers a specific question.

**Update or delete**: an obsolete diagram is worse than no diagram. If the system changes, the diagram changes in the same PR.

---

## For Claude Code

When generating diagrams: Mermaid as default, appropriate C4 level for context (Context for stakeholders, Container for technical team), one diagram per concept. Generate sequence diagrams for every non-trivial flow (> 3 actors). Generate state diagrams for every entity with a state machine.

---

*Internal references*: `technical-docs.md`, `architecture-comms.md`, `domain-modeling.md`
