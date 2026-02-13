---
name: "GraphQL Architect"
description: "GraphQL schema design, Apollo Federation, DataLoader patterns, and query optimization."
cluster: "architecture-patterns"
---

# GraphQL Architect

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Provide guidance for designing GraphQL schemas, implementing Apollo Federation architectures, building efficient resolvers with DataLoader, creating real-time subscriptions, and optimizing query performance.

---

## When to Use

- Designing GraphQL schemas and type systems
- Implementing Apollo Federation architectures
- Building resolvers with DataLoader optimization
- Creating real-time GraphQL subscriptions
- Optimizing query complexity and performance
- Setting up field-level authentication and authorization

## Core Workflow

1. **Domain Modeling** — Map business domains to GraphQL type system
2. **Schema Design** — Create types, interfaces, unions with federation directives
3. **Resolver Implementation** — Write efficient resolvers with DataLoader patterns
4. **Security Hardening** — Add query complexity limits, depth limiting, field-level auth
5. **Optimization** — Performance tune with caching, persisted queries, monitoring

---

## Schema Design

### Schema-First Approach

Define the schema in SDL before writing resolvers. The schema is the contract between frontend and backend teams.

```graphql
"""A registered user in the system."""
type User @key(fields: "id") {
  id: ID!
  email: String!
  displayName: String!
  role: UserRole!
  orders(first: Int = 10, after: String): OrderConnection!
}

enum UserRole { ADMIN MEMBER VIEWER }

"""Relay-style pagination for orders."""
type OrderConnection {
  edges: [OrderEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

### Naming Conventions

- **Types**: PascalCase (`UserAccount`, `OrderItem`)
- **Fields**: camelCase (`displayName`, `createdAt`)
- **Enums**: PascalCase type, UPPER_SNAKE_CASE values (`UserRole.ADMIN`)
- **Input types**: PascalCase with `Input` suffix (`CreateUserInput`)
- **Mutations**: verb-first camelCase (`createUser`, `updateOrder`)
- **Queries**: noun-based camelCase (`user`, `orders`, `searchProducts`)

### Nullable Field Patterns

Use non-nullable (`!`) as the default. Make fields nullable only when there is a legitimate reason the data may not exist. List fields should be non-nullable with non-nullable items (`[Item!]!`) — return an empty list rather than null.

### Relay-Style Pagination

Use cursor-based pagination for all list fields that can grow. Offset-based pagination breaks under concurrent writes and scales poorly.

---

## Resolvers and DataLoader

### The N+1 Problem

Without DataLoader, resolving a list of users with their orders produces N+1 database queries. DataLoader batches and deduplicates requests within a single tick. Create a new DataLoader per request to avoid cross-request caching.

```typescript
function createLoaders(db: Database) {
  return {
    userById: new DataLoader<string, User>(async (ids) => {
      const users = await db.users.findByIds([...ids]);
      const map = new Map(users.map((u) => [u.id, u]));
      return ids.map((id) => map.get(id) ?? new Error(`User ${id} not found`));
    }),
    ordersByUserId: new DataLoader<string, Order[]>(async (userIds) => {
      const orders = await db.orders.findByUserIds([...userIds]);
      const grouped = groupBy(orders, "userId");
      return userIds.map((id) => grouped[id] ?? []);
    }),
  };
}
```

### Resolver Pattern

Keep resolvers thin. Business logic belongs in service/domain layers, not in resolvers.

```typescript
const resolvers: Resolvers = {
  Query: {
    user: (_parent, { id }, ctx) => ctx.loaders.userById.load(id),
    users: (_parent, args, ctx) => ctx.services.users.list(args),
  },
  Mutation: {
    createUser: (_parent, { input }, ctx) => {
      ctx.auth.requireRole("ADMIN");
      return ctx.services.users.create(input);
    },
  },
};
```

---

## Apollo Federation

Each subgraph owns a business domain. Entities are shared across subgraphs using `@key` directives.

```graphql
# users subgraph
type User @key(fields: "id") {
  id: ID!
  email: String!
  displayName: String!
}

# orders subgraph — extends the User entity
type User @key(fields: "id") {
  id: ID!
  orders(first: Int = 10, after: String): OrderConnection!
}
```

### Federation Directives

| Directive | Purpose |
|-----------|---------|
| `@key` | Define entity primary key for cross-subgraph resolution |
| `@external` | Mark a field as owned by another subgraph |
| `@requires` | Declare fields needed from other subgraphs before resolution |
| `@provides` | Declare which fields a resolver can provide for an entity |
| `@shareable` | Allow a field to be resolved by multiple subgraphs |
| `@override` | Migrate a field from one subgraph to another |

Every subgraph that defines an entity must implement a reference resolver:

```typescript
const resolvers = {
  User: {
    __resolveReference: (ref: { id: string }, ctx) =>
      ctx.loaders.userById.load(ref.id),
  },
};
```

---

## Security

### Query Complexity and Depth Limiting

Assign cost to fields and reject queries exceeding the threshold. Restrict nesting depth to prevent recursive abuse.

```typescript
import { createComplexityRule, simpleEstimator, fieldExtensionsEstimator } from "graphql-query-complexity";
import depthLimit from "graphql-depth-limit";

const server = new ApolloServer({
  schema,
  validationRules: [
    depthLimit(10),
    createComplexityRule({
      maximumComplexity: 1000,
      estimators: [fieldExtensionsEstimator(), simpleEstimator({ defaultComplexity: 1 })],
    }),
  ],
});
```

### Field-Level Authorization

Use directive-based auth with a policy layer. Never hardcode authorization logic in resolvers.

```graphql
directive @auth(requires: UserRole!) on FIELD_DEFINITION

type Query {
  users: UserConnection! @auth(requires: ADMIN)
  me: User! @auth(requires: VIEWER)
}
```

### Persisted Queries

In production, use automatic persisted queries (APQ) to reduce bandwidth and prevent arbitrary query execution.

---

## Performance Optimization

- **CDN/HTTP caching**: Use `Cache-Control` hints on types and fields for public data
- **DataLoader**: Per-request batching and deduplication (not cross-request)
- **Redis**: Cache expensive resolver results with appropriate TTL
- **Response caching**: Apollo Server response cache plugin for repeated identical queries

### Monitoring

| Metric | Purpose |
|--------|---------|
| Query complexity score | Detect expensive queries before they cause problems |
| Resolver duration (p50/p95/p99) | Identify slow resolvers |
| Error rate by operation | Catch resolver failures |
| Cache hit ratio | Validate caching effectiveness |

---

## Subscriptions

Use GraphQL subscriptions for real-time server-pushed updates. Back with a pub/sub system (Redis, GCP Pub/Sub) for horizontal scaling.

```graphql
type Subscription {
  orderStatusChanged(orderId: ID!): Order!
}
```

```typescript
const resolvers = {
  Subscription: {
    orderStatusChanged: {
      subscribe: (_parent, { orderId }, ctx) => {
        ctx.auth.requireOrderAccess(orderId);
        return ctx.pubsub.asyncIterator(`ORDER_STATUS.${orderId}`);
      },
    },
  },
};
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
|-------------|---------|------------------|
| REST-in-GraphQL | One mutation per CRUD op, no domain modeling | Design mutations around business operations (`placeOrder`) |
| God Query | Single query returning entire object graph | Pagination, field selection, complexity limits |
| Missing DataLoader | N+1 queries on every list resolution | DataLoader per request with proper batching |
| Schema-last | Writing resolvers first, schema second | Schema-first — the schema is the API contract |
| Nullable everything | All fields nullable "just in case" | Non-nullable by default, nullable only with justification |
| No complexity limits | Arbitrarily expensive queries allowed | Query complexity analysis + depth limiting |

---

## Constraints

### MUST

- Use schema-first design approach
- Implement DataLoader for all batched field resolution
- Add query complexity analysis and depth limiting
- Document all types and fields with SDL descriptions
- Follow GraphQL naming conventions (camelCase fields, PascalCase types)
- Use Relay-style cursor pagination for list fields
- Implement field-level authorization via directives or policy layer

### MUST NOT

- Create N+1 query problems
- Skip query depth limiting
- Expose internal implementation details in the schema
- Use REST patterns in GraphQL (CRUD mutations without domain modeling)
- Return null for non-nullable fields
- Skip error handling in resolvers
- Hardcode authorization logic in resolver functions

---

## For Claude Code

When generating GraphQL code:

1. Always define the schema (SDL) before writing resolvers
2. Include DataLoader setup in every resolver context
3. Add query complexity and depth limit configuration
4. Provide example queries and mutations for every new operation
5. Use TypeScript code generation (e.g., GraphQL Code Generator) for type safety
6. Structure resolvers by domain, not by GraphQL operation type

*Internal references*: `api-design/SKILL.md`
