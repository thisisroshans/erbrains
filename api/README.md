# Wearable Health & Shopping API

Backend for the *Wearable Health & Shopping* mobile app (ERBrains take-home
assignment). Node.js + Express + PostgreSQL.

Architecture, database schema, full API reference, and the reasoning
behind every technical decision live in [`../docs/`](../docs) — this
README only covers running the project locally. See in particular:
[`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md#backend) (MVC layering,
request-flow diagram, checkout transaction sequence diagram),
[`../docs/DATABASE.md`](../docs/DATABASE.md) (ERD + constraints),
[`../docs/API.md`](../docs/API.md) (full endpoint reference),
[`../docs/DECISIONS.md`](../docs/DECISIONS.md#backend) (trade-offs).
Interactive API docs are also served at `/docs` (Swagger UI, from
[`openapi.js`](openapi.js)) once the server is running.

## Setup

```bash
npm install
cp .env.example .env   # or edit the existing .env — see variables below
npm run db:migrate     # creates tables + applies migrations (idempotent, safe to re-run)
npm run db:seed        # inserts sample data (see below)
npm start               # http://localhost:3000
```

- `npm run db:migrate` runs [`database/schema.sql`](database/schema.sql) (the
  original idempotent baseline — safe to re-run against an existing
  database) and then applies any not-yet-applied files in
  [`database/migrations/`](database/migrations), tracked in a
  `schema_migrations` table. See [`../docs/DATABASE.md`](../docs/DATABASE.md)
  for why schema evolution moved from schema.sql's guarded-ALTER tail to
  numbered migration files.
- `npm run db:seed` runs [`database/seed.js`](database/seed.js) and is
  idempotent — re-running it does not duplicate the user, device, readings,
  or order.
- **Breaking change from an earlier pass**: passwords are now hashed with
  bcrypt instead of unsalted SHA-256 (see Major technical decisions below).
  A database seeded before this change has a demo user whose password will
  no longer verify — re-run `npm run db:migrate && npm run db:seed` (or
  start from a fresh database) to pick up the rehashed demo password.

`npm run db:seed` seeds:

- 5 sample products with placeholder `image_url` values ([`database/seed.sql`](database/seed.sql))
- demo user `demo@erbrains.io` / `password123` / name "Jordan Lee" — `POST /auth/login`
- demo device `FITRING-001` owned by that user
- ~3 days of health readings at 15-minute intervals, so `/health/readings` and
  `/health/summary` return non-trivial data immediately
- one completed order, so `/orders` isn't empty on first call

Environment variables (`.env`):

| Variable      | Purpose                        |
|---------------|---------------------------------|
| `PORT`        | HTTP port (default 3000)        |
| `DB_USER`     | PostgreSQL user                 |
| `DB_HOST`     | PostgreSQL host                 |
| `DB_NAME`     | Database name                   |
| `DB_PASSWORD` | PostgreSQL password              |
| `DB_PORT`     | PostgreSQL port (default 5432)  |
| `JWT_SECRET`  | Signs/verifies login tokens — required, the server throws on startup if unset. Any long random string in dev. |
| `CORS_ORIGIN` | Comma-separated allowed origins. Unset = wide open (fine for local dev against an emulator/simulator). |
| `LOG_LEVEL`   | `pino` log level (default `info`; tests set `silent`). |

A ready-to-import Postman collection is in [`Wearable-Health-API.postman_collection.json`](Wearable-Health-API.postman_collection.json)
(regenerate with `generate-postman.ps1`). Run **POST /auth/login** first — its test script
populates the collection's `{{token}}` and `{{userId}}` variables that every other request uses.
The interactive `/docs` (Swagger UI) is the other way to explore the API without Postman.

## Tests

```bash
npm test
```

Route handlers are tested against a mocked `db` module (no live database
required), covering the areas most likely to cause data loss or incorrect
business results:

- **Auth**: login creates/verifies users with real bcrypt hashing, issues a
  valid signed JWT, rejects a wrong password; JWT verification rejects
  expired and tampered/forged tokens; login is rate-limited (429 after 5
  attempts/15 min); logout requires a valid token.
- **Auth middleware**: missing/malformed tokens rejected with `401`, a token whose
  `userId` doesn't match the requested resource rejected with `403`, public routes
  (`/auth/login`, `GET /products*`) reachable with no token at all.
- **Health readings**: request validation, and duplicate-skip counting for the
  `ON CONFLICT (device_id, reading_timestamp) DO NOTHING` sync path.
- **Cart**: validation, quantity merging via `ON CONFLICT (user_id, product_id)`, and
  the `PATCH`/`DELETE` endpoints' ownership check (scoped to `user_id`, not just `:id`).
- **Orders**: rejecting checkout on an empty cart, `409` on insufficient
  stock (and that product rows are locked with `FOR UPDATE OF p` while
  checking), the full checkout transaction (cart snapshot → order +
  order_items → stock decremented → cart cleared) via the mocked
  `db.transaction`, the `item_count` aggregate on `GET /orders`, and order
  cancellation (stock restored, already-cancelled rejected with `409`).
- **Products**: pagination envelope shape, limit clamped to 100, search
  term passed through as a case-insensitive filter.

Mocking `db` means these are controller/routing tests, not a check that the
SQL itself is correct against real Postgres — CI ([`../.github/workflows/ci.yml`](../.github/workflows/ci.yml))
covers that gap by running `npm run db:migrate` and `npm run db:seed`
against a real ephemeral Postgres service container on every push, which
is the one place `schema.sql` and `database/migrations/*.sql` actually get
executed and checked for syntax errors rather than just read.

## Error handling

Summary table in [`../docs/ARCHITECTURE.md#error-handling`](../docs/ARCHITECTURE.md#error-handling).
In short: request validation and ownership checks fail fast with `400`/`403`
before any DB call; duplicate health readings and the empty-cart checkout
guard are handled via DB constraints and an explicit pre-transaction check,
respectively, rather than ad hoc application logic; insufficient stock at
checkout fails with `409` inside the same transaction, no partial charge
possible; unexpected/DB errors always collapse to a generic `500`, with the
real error logged (structured, via `pino`) server-side, never leaked to the
client; a 404 handler and a catch-all error middleware in `app.js` are a
safety net below every controller's own try/catch, so nothing — not even a
bug in a handler with no try/catch — can leak a raw stack trace to a caller.
