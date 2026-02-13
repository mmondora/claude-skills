---
name: "WebSocket Engineer"
description: "Real-time communication with WebSocket and Socket.IO, scaling, and presence patterns."
cluster: "architecture-patterns"
---

# WebSocket Engineer

> **Version**: 1.0.0 | **Last updated**: 2026-02-13

## Purpose

Provide guidance for building real-time bidirectional communication systems using WebSockets and Socket.IO, including horizontal scaling, presence tracking, room management, and production-grade reliability patterns.

---

## When to Use

- Building WebSocket servers (Socket.IO, ws, uWebSockets.js)
- Implementing real-time features (chat, notifications, live updates, collaborative editing)
- Scaling WebSocket infrastructure horizontally with Redis pub/sub
- Setting up presence systems and room management
- Choosing between WebSockets, SSE, and long polling

## Core Workflow

1. **Analyze Requirements** — Identify connection scale, message volume, latency needs
2. **Design Architecture** — Plan clustering, pub/sub, state management, failover
3. **Implement** — Build WebSocket server with authentication, rooms, events
4. **Scale** — Configure Redis adapter, sticky sessions, load balancing
5. **Monitor** — Track connections, latency, throughput, error rates

---

## Protocol Fundamentals

### Connection Lifecycle

The WebSocket handshake upgrades an HTTP connection to a persistent, full-duplex channel. States: `CONNECTING` -> `OPEN` -> `CLOSING` -> `CLOSED`. Always handle all states explicitly.

### Close Codes

| Code | Meaning | Action |
|------|---------|--------|
| 1000 | Normal closure | Clean disconnect |
| 1001 | Going away | Client navigating away |
| 1006 | Abnormal closure | No close frame, trigger reconnection |
| 1008 | Policy violation | Auth failure |
| 4000-4999 | Application-specific | Define custom codes for your domain |

---

## Server Implementation

### Socket.IO with TypeScript

```typescript
import { Server } from "socket.io";
import { createAdapter } from "@socket.io/redis-adapter";
import { createClient } from "redis";

interface ServerToClientEvents {
  message: (data: { roomId: string; content: string; sender: string }) => void;
  presence: (data: { userId: string; status: "online" | "offline" }) => void;
}

interface ClientToServerEvents {
  joinRoom: (roomId: string, cb: (ack: { ok: boolean }) => void) => void;
  sendMessage: (data: { roomId: string; content: string }, cb: (ack: { ok: boolean }) => void) => void;
}

async function createSocketServer(httpServer: HttpServer): Promise<Server> {
  const io = new Server<ClientToServerEvents, ServerToClientEvents>(httpServer, {
    cors: { origin: getAllowedOrigins(), credentials: true },
    pingInterval: 25_000,
    pingTimeout: 20_000,
    maxHttpBufferSize: 1e6,
  });

  // Redis adapter for horizontal scaling
  const pub = createClient({ url: process.env.REDIS_URL });
  const sub = pub.duplicate();
  await Promise.all([pub.connect(), sub.connect()]);
  io.adapter(createAdapter(pub, sub));

  // Authentication middleware
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error("AUTHENTICATION_REQUIRED"));
    try {
      socket.data.user = await verifyToken(token);
      next();
    } catch {
      next(new Error("INVALID_TOKEN"));
    }
  });

  return io;
}
```

### Event Handlers

```typescript
io.on("connection", (socket) => {
  const userId = socket.data.user.id;

  socket.on("joinRoom", async (roomId, callback) => {
    if (!(await checkRoomAccess(userId, roomId))) return callback({ ok: false });
    await socket.join(roomId);
    socket.to(roomId).emit("presence", { userId, status: "online" });
    callback({ ok: true });
  });

  socket.on("sendMessage", async (data, callback) => {
    const message = { roomId: data.roomId, content: data.content, sender: userId };
    await persistMessage(message);
    io.to(data.roomId).emit("message", message);
    callback({ ok: true });
  });

  socket.on("disconnect", (reason) => {
    logger.info({ userId, reason }, "client disconnected");
    broadcastPresence(io, userId, "offline");
  });
});
```

---

## Client Implementation

### Reconnection with Exponential Backoff

```typescript
import { io, Socket } from "socket.io-client";

function createSocket(token: string): Socket {
  const socket = io(WS_URL, {
    auth: { token },
    reconnection: true,
    reconnectionAttempts: 10,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 30_000,
    randomizationFactor: 0.5,
    transports: ["websocket"],
  });

  socket.on("connect", () => {
    rejoinRooms(socket);
    flushMessageQueue(socket);
  });

  socket.on("connect_error", (err) => {
    if (err.message === "INVALID_TOKEN") refreshTokenAndReconnect(socket);
  });

  return socket;
}
```

### Offline Message Queue

Queue messages during disconnection. Flush on reconnect, discarding messages older than a TTL.

```typescript
const messageQueue: QueuedMessage[] = [];

function sendMessage(socket: Socket, data: MessageData): void {
  if (socket.connected) {
    socket.emit("sendMessage", data, handleAck);
  } else {
    messageQueue.push({ data, timestamp: Date.now() });
  }
}
```

---

## Scaling and Infrastructure

### Horizontal Scaling

WebSocket connections are stateful. Use sticky sessions (IP hash or cookie) so clients reach the same node. The Redis adapter synchronizes events across Socket.IO instances.

**nginx configuration:**

```nginx
upstream websocket_servers {
    ip_hash;
    server ws-node-1:3000;
    server ws-node-2:3000;
}

server {
    location /socket.io/ {
        proxy_pass http://websocket_servers;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400s;
    }
}
```

---

## Presence System

Track user online/offline status across a horizontally scaled cluster using Redis hashes with TTL-based expiry:

```typescript
class PresenceManager {
  constructor(private readonly redis: RedisClient) {}

  async setOnline(userId: string, serverId: string): Promise<void> {
    await this.redis.hSet(`presence:${userId}`, serverId, Date.now().toString());
    await this.redis.expire(`presence:${userId}`, 60);
  }

  async setOffline(userId: string, serverId: string): Promise<void> {
    await this.redis.hDel(`presence:${userId}`, serverId);
  }

  async isOnline(userId: string): Promise<boolean> {
    return (await this.redis.hLen(`presence:${userId}`)) > 0;
  }
}
```

---

## Rooms and Namespaces

Use **rooms** to scope message delivery. A client can be in multiple rooms. Use **namespaces** to separate concerns (e.g., `/chat`, `/notifications`), each with its own middleware.

```typescript
socket.join(`project:${projectId}`);
socket.to(`project:${projectId}`).emit("update", payload); // exclude sender
io.to(`project:${projectId}`).emit("update", payload);     // include sender
```

---

## When to Choose WebSockets

| Use Case | Technology | Reason |
|----------|-----------|--------|
| Bidirectional real-time (chat, gaming) | WebSocket | Full-duplex, low latency |
| Server-push only (feeds, notifications) | SSE | Simpler, auto-reconnect, HTTP/2 compatible |
| Infrequent updates (<1/min) | Long polling or SSE | WebSocket overhead not justified |
| Binary streaming (audio/video) | WebSocket or WebRTC | Binary frame support |

---

## Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
|-------------|---------|------------------|
| No authentication | Anyone can connect and listen | Authenticate in handshake middleware |
| Broadcasting secrets | Sensitive data sent to all clients | Filter events per-user authorization |
| Memory-only state | State lost on restart or scale | Redis or external store for rooms, presence |
| No heartbeat | Dead connections consume resources | Ping/pong with timeout, clean up stale connections |
| Unbounded messages | Large payloads crash servers | Set `maxHttpBufferSize`, validate size |
| No reconnection | Clients drop on network blip | Exponential backoff with jitter, message queue |

---

## Monitoring

| Metric | Purpose |
|--------|---------|
| Active connections (per node, total) | Capacity planning, detect leaks |
| Message throughput (msg/sec) | Load awareness, scaling trigger |
| Message latency (p50/p95/p99) | SLO compliance |
| Reconnection rate | Detect instability |
| Error rate by event type | Identify failing handlers |
| Redis adapter lag | Cross-node delivery health |

---

## Constraints

### MUST

- Authenticate connections before allowing event handling
- Implement automatic reconnection with exponential backoff and jitter
- Use sticky sessions for load-balanced deployments
- Handle all connection states explicitly
- Implement heartbeat/ping-pong to detect dead connections
- Use rooms or namespaces for message scoping
- Queue messages during disconnection for delivery on reconnect

### MUST NOT

- Skip connection authentication
- Broadcast sensitive data to unauthorized clients
- Store connection state only in memory without clustering strategy
- Ignore connection limit planning and load testing
- Mix WebSocket and HTTP on same port without proper proxy config
- Forget connection cleanup on disconnect
- Deploy without load testing concurrent connection capacity

---

## For Claude Code

When generating WebSocket code:

1. Always include authentication middleware in the server setup
2. Provide both server and client implementations together
3. Include Redis adapter configuration for any multi-node deployment
4. Add reconnection logic with exponential backoff on the client side
5. Define typed event interfaces (TypeScript) for all server/client events
6. Include presence management when the feature involves user status

*Internal references*: `api-design/SKILL.md`, `event-driven-architecture/SKILL.md`
