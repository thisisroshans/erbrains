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

## Setup

```bash
npm install
cp .env.example .env   # or edit the existing .env — see variables below
npm run db:migrate     # creates tables (idempotent, safe to re-run)
npm run db:seed        # inserts sample data (see below)
npm start               # http://localhost:3000
```

- `npm run db:migrate` runs [`database/schema.sql`](database/schema.sql). It's
  safe to re-run against an existing database — see the guarded
  `ADD COLUMN IF NOT EXISTS` / `ADD CONSTRAINT` statements at the end of the
  file, which cover databases created before `users.name` /
  `products.image_url` existed.
- `npm run db:seed` runs [`database/seed.js`](database/seed.js) and is
  idempotent — re-running it does not duplicate the user, device, readings,
  or order.

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

A ready-to-import Postman collection is in [`Wearable-Health-API.postman_collection.json`](Wearable-Health-API.postman_collection.json)
(regenerate with `generate-postman.ps1`). Run **POST /auth/login** first — its test script
populates the collection's `{{token}}` and `{{userId}}` variables that every other request uses.

## Tests

```bash
npm test
```

Route handlers are tested against a mocked `db` module (no live database
required), covering the areas most likely to cause data loss or incorrect
business results:

- **Auth middleware**: missing/malformed tokens rejected with `401`, a token whose
  `userId` doesn't match the requested resource rejected with `403`, public routes
  (`/auth/login`, `GET /products*`) reachable with no token at all.
- **Health readings**: request validation, and duplicate-skip counting for the
  `ON CONFLICT (device_id, reading_timestamp) DO NOTHING` sync path.
- **Cart**: validation, quantity merging via `ON CONFLICT (user_id, product_id)`, and
  the `PATCH`/`DELETE` endpoints' ownership check (scoped to `user_id`, not just `:id`).
- **Orders**: rejecting checkout on an empty cart, the full checkout transaction
  (cart snapshot → order + order_items → cart cleared) via the mocked `db.transaction`,
  and the `item_count` aggregate on `GET /orders`.

Mocking `db` means these are controller/routing tests, not a check that the
SQL itself is correct against real Postgres — there's no integration suite
running migrations against a throwaway database. Worth adding if this goes
past take-home scope.

## Error handling

Summary table in [`../docs/ARCHITECTURE.md#error-handling`](../docs/ARCHITECTURE.md#error-handling).
In short: request validation and ownership checks fail fast with `400`/`403`
before any DB call; duplicate health readings and the empty-cart checkout
guard are handled via DB constraints and an explicit pre-transaction check,
respectively, rather than ad hoc application logic; unexpected/DB errors
always collapse to a generic `500` with the real error logged server-side,
never leaked to the client.
