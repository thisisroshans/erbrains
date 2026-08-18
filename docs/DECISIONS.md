# Major technical decisions and trade-offs

Each item below states the option chosen and the concrete reason, so a
reviewer can tell whether the reasoning still holds rather than taking the
choice on faith. None of these are claimed as the only correct answer —
they're judgment calls made for this codebase at this size.

## Backend

- **No ORM.** Raw, parameterised SQL via `pg` instead of an ORM
  (Sequelize/Prisma/TypeORM). The query surface is small enough that an
  ORM would add a translation layer without buying much, and it keeps the
  upsert/`ON CONFLICT` logic — load-bearing for duplicate prevention (see
  [DATABASE.md](DATABASE.md)), not incidental — explicit rather than
  hidden behind an abstraction.
- **Transactions for checkout only.** `POST /orders` is the one endpoint
  where multiple writes (order, order_items, cart clear) must commit or
  roll back as a unit — see the sequence diagram in
  [ARCHITECTURE.md](ARCHITECTURE.md#checkout-transaction). Every other
  endpoint is a single statement and doesn't need one.
- **Mock auth, not JWT.** The assignment explicitly allows mock auth. The
  token is a base64-encoded, unsigned blob of `{ userId, email, issuedAt }`
  — readable by anyone who decodes it, with no signature preventing
  tampering. Acceptable for a take-home talking to itself; not production-
  ready. Swapping in real JWTs touches only `api/middleware/auth.js` and
  `api/controllers/auth.controller.js` — no route or model changes, since
  everything downstream just reads `req.auth.userId`.
- **Ownership checks live in controllers, not just middleware.**
  `requireAuth` only proves identity; `ensureSelf` (and per-controller
  `WHERE user_id = req.auth.userId` scoping, e.g. in `cart.model.js`)
  decides whether that identity may act on the specific resource in the
  request. Keeping this explicit per-controller, rather than one generic
  rule, is what stops a guessed cart-item id from working across users.
- **`app.js` / `server.js` split** exists purely for testability — `app.js`
  is `require`d by tests without opening a network port or needing a live
  database.
- **models/controllers/routes over one flat `app.js`.** Route handlers
  started out written inline in `app.js`; moved into explicit MVC layers
  so each piece is independently readable and testable — `models/*.js`
  never sees an HTTP request, `controllers/*.js` never writes SQL. Pure
  refactor: every SQL string, status code, and response shape stayed
  identical, which is why the existing 33 tests needed zero edits.
- **No migration framework** (Flyway/Knex/Prisma migrate) — `schema.sql`
  applied idempotently via guarded DDL. Sufficient for a single-environment
  take-home; wouldn't scale to a team needing versioned, reversible
  migrations with rollback.
- **`products.image_url` points at placeholder images** (`placehold.co`),
  not real product photography — none exists for this project. Swapping in
  real asset URLs needs no schema change; the column is already a plain
  URL string.

## Flutter

- **Riverpod (generator-based) over Bloc/Cubit or plain Provider.**
  Explicit requirement mid-build. Immutable state + `copyWith`, composition
  via `ref.watch`, no imperative `notifyListeners()`.
- **No `UseCase` classes, no `HealthRepository` wrapper around the sync
  engine** — see [ARCHITECTURE.md](ARCHITECTURE.md#deliberate-departures-from-textbook-clean-architecture).
- **Hive without generated `TypeAdapter`s** — every cached value is a
  plain `Map<String, dynamic>` via each model's own `toHiveMap`/`toJson`.
  One fewer codegen pipeline running alongside `riverpod_generator`; the
  models are small enough that hand-written (de)serialization isn't a
  maintenance burden.
- **One Hive box per genuinely distinct concern** (`health_readings`,
  `products_cache`, `cart_sync`), not one per resource-type the way a
  larger reference architecture might — see
  [OFFLINE_SYNC.md](OFFLINE_SYNC.md#why-this-apps-shape-is-much-smaller-than-the-reference-philosophy).
- **The cart/order queue shares one box for its baseline cache and its
  mutation queue** (`cart_sync`, keyed by a reserved baseline key plus one
  key per mutation), rather than the two-box split the products/readings
  split might suggest. A single `box.watch()` stream then reacts to either
  changing, and the Cart screen genuinely needs to redraw on both — see
  [OFFLINE_SYNC.md](OFFLINE_SYNC.md#cartorder-offline-queue).
- **Cart-item id remapping is persisted, not held in memory.** An item
  added offline gets a `local:<mutation id>` placeholder id; once its
  `add` mutation syncs, every other queued mutation referencing that
  placeholder is rewritten to the real id *in the Hive queue itself*
  (`CartSyncStore.rewriteCartItemId`), not just in a transient in-process
  map. An in-memory map would lose the mapping if the app were killed
  between the `add` syncing and a dependent `setQuantity`/`remove`
  draining — the persisted rewrite survives that.
- **No client-minted ids for health readings.** The backend already
  dedupes on the natural key `(device_id, reading_timestamp)`; a client id
  would solve a duplicate-detection problem that doesn't exist here.
  `HealthReading.localId` exists purely as the Hive key and never appears
  in a request body.
- **History computes summaries client-side** (`HealthReadingLocalStore.summary`)
  rather than calling `GET /health/summary`, so it's fully offline-capable
  and reflects readings that haven't synced yet.
- **Mock auth token is an opaque, unsigned blob**, matching the backend's
  own choice — this is a take-home assignment, not a production auth
  scheme; swapping in real JWTs is backend-only.
- **`IndexedStack` for the four root tabs** (Dashboard/History/Shop/
  Profile) rather than lazy-built routes — keeps scroll position and
  provider state per tab across switches. Trade-off: all four build
  immediately after login rather than on first visit (confirmed live —
  Shop's product images start loading as soon as Dashboard does, not when
  the user taps Shop).
- **Zero `setState` in the app.** All UI state — including things easy to
  leave as widget-local, like the bottom-tab index (`ShellTabIndex`) and
  the product-detail quantity stepper (`ProductQuantity`) — is Riverpod
  state instead, for consistency with the rest of the state model.

## Scope decisions (deliberately out of scope)

These are things a reviewer might expect and won't find, kept here so the
absence reads as a decision rather than an oversight:

- **No real payment gateway, no shipping/payment columns on `orders`.**
  Matches the assignment's explicit "no real payment gateway" scope.
  Checkout's shipping-address fields and the flat $5 shipping line
  (`flutter/lib/features/checkout/presentation/screens/checkout_screen.dart`,
  `flutter/lib/features/cart/presentation/screens/cart_screen.dart`) are
  UI-only decoration matching the design; `POST /orders` takes only
  `{ userId }` and nothing typed into those fields is ever sent. The
  backend's order total is the cart subtotal, full stop.
- **Wearable telemetry that never reaches the API.** Battery level and
  live connection status are device-layer telemetry per the PDF's
  wearable-simulation spec, not health data — the Dashboard reads them
  straight from the `WearableService` stream
  (`flutter/lib/features/dashboard/presentation/screens/dashboard_screen.dart`),
  never the backend, and `WearableSnapshot` (which carries battery) is
  intentionally distinct from `HealthReading` (which is what actually gets
  synced).
- **No offline queue for auth** — logging in needs a live server by
  construction; see [OFFLINE_SYNC.md](OFFLINE_SYNC.md#why-so-little-is-queued).
  (Cart/order writes *do* queue offline now — see
  [OFFLINE_SYNC.md](OFFLINE_SYNC.md#cartorder-offline-queue) — this bullet
  used to cover them too, before that was built.)
- **Checkout never claims success it hasn't confirmed.** When "Place
  order" can't complete synchronously (offline, or the backend rejects it
  and it enters the normal retry cycle), the screen reports it as queued
  rather than either pretending it succeeded or throwing an error the
  user has to interpret — the alternative (silently folding a possible
  order-placement failure into the generic cart-mutation pending count,
  with no dedicated messaging) was considered and rejected specifically
  because a checkout failing silently is a worse failure mode than a cart
  quantity change failing silently. See
  [OFFLINE_SYNC.md](OFFLINE_SYNC.md#cartorder-offline-queue).
- **Background sync (`workmanager`) is verified to compile, not verified
  to run.** `flutter build apk --debug` succeeds with the dependency
  linked in, but no Android emulator/device was available to confirm the
  periodic task actually registers or fires on a real OS, and iOS wasn't
  built or run at all. Shipped anyway, on the reasoning that a real,
  honestly-labeled implementation with a clear "verify on-device before
  relying on this" note is more useful to a reviewer than no
  implementation — but this is the one piece in the whole app with a
  materially lower confidence level than everything else, and that's
  flagged everywhere it's discussed rather than glossed over. See
  [OFFLINE_SYNC.md](OFFLINE_SYNC.md#background-sync).
- **No rate limiting** on the backend, and correspondingly no
  `429`/`Retry-After` handling on the client — see
  [OFFLINE_SYNC.md](OFFLINE_SYNC.md#why-this-apps-shape-is-much-smaller-than-the-reference-philosophy).
- **No widget-level or golden tests** for Flutter screens, and no
  integration test suite running the backend's SQL against a real
  Postgres instance — both verified instead via live manual runs against
  an emulator + backend. See
  [`../api/README.md#tests`](../api/README.md#tests) and
  [`../flutter/README.md#tests`](../flutter/README.md#tests) for exactly
  what automated coverage exists and why those specific areas were
  prioritized (data-loss-risk logic first).
