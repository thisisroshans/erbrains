# Offline-first strategy

**Status: shipped for the app's one offline-critical resource.** FitRing
has a single genuinely offline-sensitive workflow — the PDF's target
scenario: *"the device generates 100 readings while the phone has no
internet; when internet returns, sync those readings."* That workflow is
fully built: readings are captured to local storage the instant the mock
wearable emits them, queue and drain in order, survive app restarts, and
surface their state in a sync banner. Everything else in the app (cart,
orders, auth) stays network-only, deliberately — see "Why so little is
queued" below.

**Shipped:**
- **Local storage** — a single Hive box (`health_readings`) holding every
  reading the device has ever produced, synced or not. This IS the
  offline store the PDF's "Local Health Data" section asks for, not a
  cache of a server response — see `HealthReadingLocalStore`.
- **`CachePolicy` consultation** — cache-first, applied to the one other
  resource worth it: the product catalog (`GET /products`), which behaves
  like the reference philosophy's "near-static reference data" case. See
  `ProductsLocalCache` / `shop_providers.dart`.
- **`ConnectivityMonitor`** — thin wrapper over `connectivity_plus`
  exposing a current snapshot and an offline→online transition stream.
- **`SyncManager`** — drains pending readings to `POST /health/readings`
  in write-order batches, gated on an idempotent device registration
  (`POST /devices`) since `health_readings.device_id` is a foreign key.
  Triggered by: app launch (`HealthSyncEngine.start()`), every wearable
  reading (a drain attempt follows every write — see below), connectivity
  offline→online, a 10s periodic timer, and app-foreground-resume — all
  wired in `RootShell`.
- **Per-reading retry with backoff** — a failed batch increments every
  reading's attempt counter; readings under `maxAttempts` (default 5) stay
  `pending` for the next drain, readings that exhaust it move to `failed`
  and stop being auto-retried. Backoff (2s/4s/8s/16s/30s, keyed to the
  worst attempt count in the failed batch) blocks the next automatic
  attempt — see `SyncManager._scheduleRetry`.
- **Sync UI** — `SyncBanner` above every screen in `RootShell`: silent
  when the queue is empty, a quiet strip while pending, a tappable
  failed-state opening `SyncFailedSheet` with Retry (full attempt budget
  restored) / Discard (permanent — a real gap in that period's history,
  not a display filter). Screen 05 (`SyncStatusScreen`) shows the same
  state as a dedicated page.
- **History is fully offline** — `history_providers.dart` reads recent
  readings and computes daily/weekly summaries straight from the local
  store (`HealthReadingLocalStore.summary`, a client-side port of the
  backend's `GET /health/summary` SQL), not the network. It updates live
  as new readings are captured or synced, via the store's Hive `watch()`
  stream — no polling.
- **Sign-out full local wipe** — `LocalDataWiper` clears every Hive box
  (readings queue included), wired into `AuthNotifier.logout()`.
- **Proof** — `test/health_sync_manager_test.dart` drives `SyncManager`
  against fakes (no Hive-in-Flutter, no network): device-registration
  gating, per-reading attempt counting, the failed-state transition, and
  backoff actually blocking a too-soon retry, all pass.

**Explicitly not built** (see "Why so little is queued" for the reasoning
on each):
- Queuing for cart/order writes.
- Any conflict-resolution machinery for readings — the natural-key dedupe
  already makes it a non-issue, see "Idempotency."
- True OS-level background sync (work continuing while the app is
  killed) — this app has no background-task infrastructure at all, and
  adding one is a platform-configuration project of its own.
- A periodic staleness-eviction sweep — the local store's growth is
  bounded by nothing right now; low priority, noted for later.

## Why this app's shape is much smaller than the reference philosophy

The philosophy this was built from (pasted in full in the session that
produced this doc) describes a multi-domain fitness app — workouts,
meals, progress, billing, a coach — with per-resource cache policies,
optimistic updates across half a dozen Blocs, and a generic
`PendingMutation` queue. FitRing has three domains (health readings,
device pairing, shopping) and one state-management stack decision
(Riverpod, not Bloc/Cubit — every `*Cubit`/`*Bloc` reference in the
source philosophy became a `Notifier`/provider here). Translating the
*philosophy* faithfully meant scaling the *implementation* down hard, not
copying file names. Concretely:

- **One `Box`, not one-per-resource-type.** The reference app's
  catalog/profile/session/billing spread justified separate boxes. This
  app has one resource that needs a real offline queue (readings) and one
  that benefits from a plain cache (products) — `health_readings` and
  `products_cache` are the only two boxes that exist.
- **A generic `PendingMutation` queue was replaced with a resource-
  specific store.** The reference doc's queue holds arbitrary
  method/path/body tuples because it queues many different endpoints.
  This app queues exactly one shape of write — a health reading — so
  `HealthReadingLocalStore` models that directly (with a `syncStatus`
  field) instead of wrapping it in a generic envelope that would only
  ever hold one variant.
- **No `PendingMutation.id` / client-minted UUIDs for readings.** The
  reference philosophy's idempotency section explicitly separates two
  patterns: client-minted ids (meals, sessions) vs. natural-key dedupe
  (weight entries, set logs). Health readings are the second kind — the
  backend already dedupes on `(device_id, reading_timestamp)` via
  `ON CONFLICT ... DO NOTHING` (see `api/database/schema.sql`) — so there
  was no client-id design left to make. `HealthReading.localId` exists
  purely as the Hive key and never appears in a request body.
- **No conflict (409) handling.** Following directly from the point
  above: an endpoint that silently no-ops on a duplicate key can't return
  a conflict. The reference doc's 409-and-404-as-"already applied" branch
  has nothing to attach to here, so it wasn't built.
- **No 429/`Retry-After` handling.** The backend has no rate limiting
  implemented (see `api/middleware/auth.js` and `api/app.js` — nothing
  parses or emits 429). Building a `Retry-After` parser for a response
  the API can't produce would be untested-by-construction dead code;
  `SyncManager`'s generic backoff covers "some request failed" uniformly
  instead.

## Why so little is queued

**Health readings queue. Cart and orders don't.** This mirrors the
reference philosophy's own distinction between "queue this" and "network-
only, for concrete reasons" — applied to what this app actually has:

- **Readings are generated continuously and automatically** by the
  wearable simulation, arrive whether or not anyone's looking at the
  screen, and the PDF explicitly specifies the offline scenario for them
  (100 readings queued, synced on reconnect). This is the one workflow
  where "started while offline, must not be lost" is a real product
  requirement, not a nice-to-have.
- **Cart/order writes are user-initiated, in-the-moment actions** with no
  equivalent requirement. Queuing "add to cart" offline means either
  showing a cart that might not reflect server truth (stock could change)
  or building reconciliation logic for a scenario the assignment doesn't
  ask for. The reference doc's own reasoning for *not* queuing plan
  mutations — "queuing one would mean reconciling a locally-mutated
  version against a server-rewritten one on drain, a merge problem with
  no correct answer" — applies just as well to a cart whose prices/stock
  can move server-side while offline.
- **Auth needs a live server by construction** — there's no offline login.

If a future requirement needs offline cart edits, the pattern to extend is
already here: give `cart_items` a natural key the backend already has
(`user_id, product_id` — it does, per `api/database/schema.sql`), so the
existing upsert-based idempotency model would just work, no client-minted
ids needed there either.

## Cache policy

| Resource | Strategy | TTL | Why |
| --- | --- | --- | --- |
| Health readings | Local-first, always | n/a — never expires, never refetched | This is the primary store, not a cache. See `HealthReadingLocalStore`. |
| Product catalog | Cache-first | 24h, 7-day grace | Near-static reference data — same shape of thing as the reference philosophy's exercise/food catalogs, same policy for the same reason. `CachePolicy.productsCatalog`. |
| Product detail | Network-first, falls back to the cached catalog entry | n/a | Stock/price can legitimately be fresher than the list; but a product reached by tapping an offline-cached tile should still open. |
| Cart / Orders / Auth | Network-only | n/a | See "Why so little is queued." |

`CacheStrategy.staleWhileRevalidate` exists in `cache_policy.dart` as a
documented option but nothing in this app currently uses it — there's no
resource here with the "show it now, silently refresh in the background"
shape the reference philosophy's profile/billing/plan resources had. Left
in as the honest general-purpose primitive rather than deleted, since
`CacheStrategy.cacheFirst`'s implementation (in `shop_providers.dart`)
would extend to it trivially if a future resource needs it — but it is
**not wired to anything today**, which is exactly the kind of claim this
doc exists to keep honest.

## Sync conflict handling

**None needed, and that's a direct consequence of the endpoint shape, not
an oversight.** `POST /health/readings` dedupes via
`ON CONFLICT (device_id, reading_timestamp) DO NOTHING` — a replayed
batch is a harmless no-op, never a conflict. There is no field-level merge
logic anywhere in this engine, matching the reference philosophy's own
explicit non-goal ("field-level CRDT-style merging... not justified by
this API's shape").

## Retry policy

Exponential backoff (2s → 4s → 8s → 16s → 30s, capped) keyed to the worst
per-reading attempt count in a failed batch — see
`SyncManager._backoffSeconds`/`_scheduleRetry`. A reading that exhausts
`maxAttempts` (default 5) moves to `SyncStatus.failed` and stops being
included in automatic drain batches; it surfaces in `SyncBanner`'s failed
sheet with Retry (resets every failed reading to `pending` with a fresh
attempt budget, then drains immediately) or Discard (permanent deletion —
see `HealthReadingLocalStore.discardFailed`). No 429/`Retry-After`
handling — see "Why this app's shape is much smaller" above.

## Background sync

`SyncManager.drain()` triggers on: (1) app launch via
`HealthSyncEngine.start()`, (2) every captured reading (a drain follows
every local write — since readings arrive every few seconds from the mock
wearable, this alone keeps a connected device essentially real-time
without needing a fast periodic timer), (3) `ConnectivityMonitor`
transitioning offline→online, (4) a 10-second periodic timer as a
belt-and-suspenders trigger for "online the whole time, no transition
event fired," (5) app-foreground-resume, and (6) a user-initiated retry
from the sync banner. All of (2)-(6) are wired in `RootShell`
(`_RootShellState`) since foreground-resume and the periodic timer are
inherently widget-lifecycle concerns, not something a plain Riverpod
provider can hook.

True OS-level background sync (work continuing while the app is
backgrounded or killed) is out of scope — no `WorkManager`/
`background_fetch`/`workmanager` dependency exists, and adding one is a
platform-configuration project, not a networking-layer concern. Same
reasoning as the source philosophy document, unchanged.

## Queue persistence and idempotency

One box (`health_readings`), one entry per reading, drained oldest-first
(write order) so a reading logged at 10:00 always attempts sync before one
logged at 10:05 — not that order is load-bearing for correctness here (the
backend's dedupe key doesn't care about arrival order), but it keeps
"what synced and what didn't" intuitive to reason about and to show in the
UI.

**Idempotency rides entirely on the backend's natural key**
`(device_id, reading_timestamp)`, not on `HealthReading.localId`.
`localId` is a client-generated uuid v4, but it's Hive-key-and-queue-
bookkeeping only — it never appears in `toSyncJson()` and never reaches
the API. A batch replayed after a lost response collides with the rows it
already inserted and no-ops on every one of them; the count returned
(`synced`/`duplicatesSkipped`) is informational, not something the client
branches on. `timestamp` is captured client-side at the moment the mock
wearable emits the reading (`WearableSnapshot.timestamp`), so a reading
that sits pending for an hour before syncing keeps its real capture time.

## What this replaces, concretely

| Before this pass | After |
| --- | --- |
| History screen called `GET /health/readings` / `GET /health/summary` directly, spinner on every visit, nothing worked offline | Reads `HealthReadingLocalStore` directly, live via `watch()`, works with zero connectivity |
| Wearable readings existed only as an in-memory stream for the Dashboard tiles — never persisted, never sent to the backend at all | Every reading is written to Hive immediately and drains to the backend automatically |
| No device registration call existed anywhere in the app (a real gap — `health_readings.device_id` is a FK, so syncing would have 400'd) | `SyncManager` registers the device (idempotent upsert) before its first drain each session |
| Product list always hit the network, spinner on every Shop visit | Cache-first against a 24h TTL; browses fully offline once warm |
