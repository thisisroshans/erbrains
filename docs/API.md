# API reference

Base URL: `http://localhost:3000` (see [`../api/README.md`](../api/README.md#setup)
for running it locally). All endpoints accept/return JSON. Errors are
`{ "error": "..." }` with a 4xx/5xx status — see
[ARCHITECTURE.md#error-handling](ARCHITECTURE.md#error-handling).
Interactive docs (Swagger UI) are served at `/docs` once the server is
running — generated from [`../api/openapi.js`](../api/openapi.js).

## Auth model

Every route below except `POST /auth/login` and the two `GET /products`
routes requires `Authorization: Bearer <token>`, where `<token>` is the
value `POST /auth/login` returns. The token is a signed JWT (7-day expiry,
`HS256`, see [`../api/utils/jwt.js`](../api/utils/jwt.js)) — see
[DECISIONS.md](DECISIONS.md#backend) for why a real JWT was worth building
even though the assignment explicitly allows mock auth.

Routes that also take a `userId` in the body/query verify it matches the
token's `userId` — a valid token for one user cannot read or act on
another user's data. Enforced by `requireAuth` (identity) +
`ensureSelf`/per-controller ownership checks (authorization) — see
[`../api/middleware/auth.js`](../api/middleware/auth.js) and
[ARCHITECTURE.md](ARCHITECTURE.md#backend-request-flow).

`POST /auth/login` is rate-limited (5 attempts / 15 minutes / IP) —
further attempts return `429`. Every other route requiring a token returns
`401` for a missing, malformed, expired, or tampered one.

```mermaid
sequenceDiagram
    participant C as Client
    participant A as Express (routes/controllers)
    participant M as Model (SQL)
    participant DB as PostgreSQL

    C->>A: POST /auth/login {email, password}
    A->>M: user.findByEmail / create
    M->>DB: SELECT / INSERT users
    DB-->>M: user row
    M-->>A: user
    A-->>C: 200 {token, user}

    C->>A: GET /cart?userId=X  (Authorization: Bearer token)
    A->>A: requireAuth: verify JWT signature + expiry -> req.auth.userId
    A->>A: ensureSelf: req.auth.userId === userId?
    alt mismatch
        A-->>C: 403 Cannot act on behalf of another user
    else expired/invalid signature
        A-->>C: 401 Missing or invalid authorization token
    else match
        A->>M: cart.findByUser(userId)
        M->>DB: SELECT cart_items JOIN products
        DB-->>M: rows
        M-->>A: cart + totalAmount
        A-->>C: 200 {items, totalAmount}
    end
```

## Ops

| Method | Path | Notes |
|---|---|---|
| GET | `/healthz` | Liveness probe. Public, no auth — a load balancer/orchestrator checking it has no token. Distinct from `/health/*` below (different top-level path, no collision). |

## Auth (public)

| Method | Path | Body | Notes |
|---|---|---|---|
| POST | `/auth/login` | `{ email, password, name? }` | Creates the user on first login (`name` optional, only used on creation), otherwise verifies the password against its bcrypt hash. Returns `{ token, user: { id, email, name } }`. Rate-limited. |
| POST | `/auth/logout` | — (auth required) | Stateless — no server-side session to destroy, doesn't blacklist the token. Exists for a complete REST surface (the assignment lists logout as a required auth feature); the real security boundary is the token's own 7-day expiry, not revocation. Always `200`. |

## Devices (auth required)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/devices` | `{ deviceId, name, userId }` | Upserts by `deviceId`, marks it `connected`. |
| GET | `/devices?userId=` | — | Lists devices for a user. |

## Health data (auth required)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/health/readings` | `{ userId, readings: [{ deviceId, heartRate, spo2, steps, timestamp }] }` | Batch upload. Returns `{ synced, duplicatesSkipped, results }`, where `results` is one `{ deviceId, timestamp, status: "synced" \| "duplicate" }` entry per input reading, same order — lets the client attribute outcome per reading instead of trusting the whole batch synced uniformly. Safe to retry — duplicates skipped via the DB unique constraint (see [DATABASE.md](DATABASE.md)), not client-side dedup. |
| GET | `/health/readings?userId=&page=&limit=` | — | Paginated, `limit` capped at 100. |
| GET | `/health/summary?userId=&period=daily\|weekly` | — | Aggregated min/max/avg heart rate, avg/min SpO₂, total steps over the last 7 days, bucketed by day or week — backs the History screen's charts server-side instead of shipping raw rows to the client. |

## Shopping — catalog (public)

| Method | Path | Query | Notes |
|---|---|---|---|
| GET | `/products` | `page`, `limit` (default 20, capped 100), `q` | Returns `{ data, page, limit, total }` — a paginated envelope, not a bare array. `q` is a case-insensitive name search (`ILIKE`). |
| GET | `/products/:id` | — | 404 if not found. |

## Shopping — cart & orders (auth required)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/cart` | `{ userId, productId, quantity }` | Adds a line item, or increments quantity if one already exists for that product (upsert on `UNIQUE (user_id, product_id)`). |
| GET | `/cart?userId=` | — | Items + computed `totalAmount`. |
| PATCH | `/cart/:id` | `{ quantity }` | Sets the line item to an exact quantity — the decrement counterpart to `POST /cart`'s increment-only upsert. 404 if `:id` isn't a cart item owned by the caller. |
| DELETE | `/cart/:id` | — | Removes the line item. 204 on success, 404 if not owned by the caller. |
| POST | `/orders` | `{ userId }` | Converts the current cart into an order inside a single DB transaction: validates stock (row-locked with `FOR UPDATE OF p` — concurrency-safe against a simultaneous checkout on the same product), snapshots prices into `order_items`, decrements stock, then empties the cart. `400` if the cart is empty, `409` if any line item exceeds available stock. |
| GET | `/orders?userId=` | — | Order history, each row including an `item_count` aggregated from `order_items`. |
| POST | `/orders/:id/cancel` | — | Cancels an order and restores the stock it reserved. Any status except `cancelled` is cancellable (there's no fulfillment step that would make a completed order un-cancellable). `404` if not found/not owned by the caller, `409` if already cancelled. |

## Worked example

```bash
# 1. Login — returns a JWT scoped to this user, expiring in 7 days
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@erbrains.io","password":"password123"}'
# -> { "token": "eyJhbGciOiJIUzI1NiIs...", "user": { "id": "12b8...", "email": "...", "name": "Jordan Lee" } }

# 2. Authenticated request — userId must match the token's userId
curl http://localhost:3000/cart?userId=12b8... \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."

# 3. Requesting a userId that doesn't match the token's -> 403 before any DB call
# { "error": "Cannot act on behalf of another user" }

# 4. An expired or tampered token -> 401 on any protected route
# { "error": "Missing or invalid authorization token" }
```

A ready-to-import Postman collection is at
[`../api/Wearable-Health-API.postman_collection.json`](../api/Wearable-Health-API.postman_collection.json)
(regenerate with `../api/generate-postman.ps1`). Run **POST /auth/login**
first — its test script populates the collection's `{{token}}` and
`{{userId}}` variables that every other request uses.

## Client consumption (Flutter)

`flutter/lib/core/data/datasources/remote/api_client.dart` is a 1:1 wrapper
around this API — one method per route above. A Dio interceptor attaches
`Authorization: Bearer <token>` from `TokenStorage` to every outgoing
request automatically; screens/controllers never touch the header
directly. See [ARCHITECTURE.md](ARCHITECTURE.md#flutter-request-flow).

A second interceptor reacts to a `401` on an *authenticated* request (a
JWT that expired mid-session, or the server's signing secret rotated) by
clearing the stored token and emitting on `ApiClient.onSessionExpired` —
`AuthController` listens for this and drops the app back to the login
screen, wiping local data the same way an explicit logout does. Login's
own `401` (wrong password) never triggers this, since that request never
had a token attached to begin with.
