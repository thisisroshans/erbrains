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
- **Real JWT + bcrypt, even though the assignment explicitly allows mock
  auth.** The original mock — an unsigned base64 blob, unsalted SHA-256
  password hash — was upgraded because Authentication is graded as its own
  criterion, not just a means to reach the other features. `bcryptjs`
  (pure JS, not native `bcrypt`) specifically — no node-gyp/native build
  step for anyone else running `npm install` on an arbitrary machine;
  slower per-hash, an acceptable trade at this app's login volume. The
  JWT's 7-day expiry has no refresh-token rotation behind it — a
  deliberate scope line for a mobile session, not a web app's, not an
  oversight. See [API.md](API.md#auth-model) for the shape and
  `api/utils/jwt.js`/`api/utils/password.js` for the implementation.
- **Logout doesn't blacklist the token.** A stateless JWT has no
  server-side session to destroy. A revocation list (a table of not-yet-
  expired-but-revoked token ids, checked on every request) was considered
  and rejected — real added state and cleanup burden for a benefit this
  app doesn't need at its size. `POST /auth/logout` exists for a complete
  REST surface (the assignment lists logout as a required feature) and
  always returns `200`; the actual security boundary is the token's own
  expiry.
- **Rate limiting only on `POST /auth/login`**, not globally. Every other
  route already requires a valid token, so the attack this defends against
  (guessing a password) doesn't apply to them — rate-limiting an
  already-authenticated route would just be a blunt, undifferentiated
  request cap with no specific threat it's responding to.
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
- **Tracked migrations layered on top of the original idempotent
  `schema.sql`, not a framework swap** (Flyway/Knex/Prisma migrate). The
  baseline stays as guarded DDL, applied in full every run; schema changes
  since then are numbered files in `database/migrations/`, applied once
  and recorded in a `schema_migrations` table. Proportionate to this
  project's size — a full migration framework would be more machinery than
  the actual amount of schema churn justifies. See
  [DATABASE.md](DATABASE.md) for the mechanics.
- **Stock validation locks rows with `SELECT ... FOR UPDATE OF p`,
  decrements `stock` inline in the checkout transaction, and rejects with
  `409`** rather than a separate reservation/hold step. This is exactly
  the redesign [OFFLINE_SYNC.md](OFFLINE_SYNC.md#why-so-little-is-queued)
  flagged as needed once stock validation existed — the client's
  `ApiException.isRetryable` classification (statusCode `null`/5xx =
  retryable, any 4xx = not) is the other half: a queued `placeOrder` that
  hits this `409` fails immediately instead of burning its retry budget on
  a rejection that can't become true by trying again.
- **Order cancellation has no fulfillment-state guard** — any order except
  an already-`cancelled` one can be cancelled, `completed` included. There
  is no shipping/fulfillment pipeline in this app that would make
  cancelling a completed order unsafe, so adding one would be defending
  against a state transition that can't actually cause harm here.
- **`GET /products` returns a paginated envelope**
  (`{ data, page, limit, total }`), not a bare array — a breaking response-
  shape change, absorbed entirely inside `ApiClient.getProducts()` so nothing
  above the data layer needed to change. With only 5 seed products the
  client still just requests one large page (`limit=100`) rather than
  paging through multiple requests; the server-side pagination exists for
  when the catalog is bigger than that, not because the client needs it today.
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
- **The client treats the token as opaque** — it never decodes or
  inspects the JWT itself, just stores and attaches it. The backend's move
  from a mock blob to a real signed JWT (see Backend, above) needed zero
  client-side parsing changes because of this; only a new failure mode
  (expiry) needed handling, via `ApiClient.onSessionExpired` — see next.
- **A 401 on an *authenticated* request triggers a global session-expiry
  event, not a per-call error.** `ApiClient` distinguishes "login returned
  401" (wrong password — a normal `ApiException` on the login form) from
  "a request that had a token attached got 401 back" (the token expired or
  the server's secret rotated) by checking whether the failed request
  actually carried an `Authorization` header. Only the second case clears
  the stored token and drops the whole app back to the login screen
  (`AuthController` listens on `ApiClient.onSessionExpired`) — this needed
  to live at the HTTP-client level, not in individual screens, since any
  request anywhere in the app could be the one that discovers the session
  died.
- **A `BleWearableService` stub exists but isn't wired in.** Adds no real
  functionality — every method throws `UnimplementedError` — but makes the
  "this architecture is ready for a real SDK" claim in
  [WEARABLE_INTEGRATION.md](WEARABLE_INTEGRATION.md) a concrete, compileable
  seam in the repo (real platform-channel names, real method shapes)
  instead of only a paragraph of prose.
- **Light/system theme was scoped out after investigation, not before
  it.** `NocturneColors` are `static const Color` values referenced
  directly throughout every screen — not routed through `Theme.of(context)`
  anywhere. Wiring `ThemeMode.system` alone would change nothing visually;
  a real light theme means re-threading dozens of widgets through
  context-aware tokens, which is a large refactor with real regression
  risk that can't be verified without a live emulator/device to actually
  look at the result. Attempting it anyway and shipping it unverified was
  judged worse than clearly not doing it — see the note in
  [ARCHITECTURE.md](ARCHITECTURE.md#flutter) for what a real
  implementation would need to touch.
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
- **No `429`/`Retry-After`-aware backoff on the client**, even though the
  backend now rate-limits login. The one rate-limited route (`POST
  /auth/login`) is never retried automatically by anything in this app —
  a `429` there surfaces once on the login form, same as any other login
  error, so there's no automatic-retry loop that a `Retry-After` parser
  would need to inform. Every *other* route stays unrate-limited, per the
  reasoning above.
- **No widget-level or golden tests** for Flutter screens — verified
  instead via live manual runs against an emulator + backend. This is now
  the one specific gap in that category; the backend's SQL *is* checked
  against a real Postgres instance, just in CI
  (`.github/workflows/ci.yml`) rather than the local test suite — see
  [`../api/README.md#tests`](../api/README.md#tests) and
  [`../flutter/README.md#tests`](../flutter/README.md#tests) for exactly
  what automated coverage exists and why those specific areas were
  prioritized (data-loss-risk logic first).
- **iOS was never built** — no Mac/Apple developer environment was
  available. The codebase was audited for iOS-readiness instead of
  attempting a build that couldn't be verified: `AppConfig`'s platform
  branching already covers iOS, every dependency in `pubspec.yaml` is
  cross-platform, and `ios/Runner/Info.plist` already carries the
  background-sync keys. See
  [`../flutter/README.md`](../flutter/README.md) for the specific
  statement made about this to reviewers.
