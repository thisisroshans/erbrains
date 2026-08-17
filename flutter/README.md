# FitRing

Flutter client for the *Wearable Health & Shopping* app (ERBrains take-home
assignment). Talks to the Express/PostgreSQL backend in [`../api`](../api).

Screens are static-UI-first: they were scaffolded from a design handoff
(`Wearable App Screens.dc.html`, 11 screens) and then wired to real state.
See [`../Senior Mobile Developer Assignment 1.pdf`](<../Senior Mobile Developer Assignment 1.pdf>)
for the original spec this implements.

## Setup

Requires the backend running first — see [`../api/README.md`](../api/README.md)
(`npm install && npm run db:migrate && npm run db:seed && npm start`).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart for Riverpod
flutter run                                                  # picks a connected device/emulator
```

`lib/core/config/app_config.dart` points at the backend automatically:
`10.0.2.2:3000` on the Android emulator (the emulator's alias for the host's
`localhost`), `localhost:3000` everywhere else (iOS simulator, web, desktop).
A physical device needs the host machine's real LAN IP — override with
`flutter run --dart-define=API_BASE_URL=http://<host-ip>:3000`.

Demo login (seeded by the backend): **`demo@erbrains.io` / `password123`**.
Login also auto-creates any other email/password on first use — the backend
upserts (see `api/auth.routes.js`) — so any credentials work.

### Tests

```bash
flutter test
```

`test/health_sync_manager_test.dart` drives the offline sync engine's
drain/retry/backoff logic against fakes — no device, network, or live Hive
box needed. See "Testing" below for what is and isn't covered.

## Architecture

**Clean Architecture** (domain / data / presentation), applied pragmatically
— see "Why not the textbook version everywhere" below for what was
deliberately left out and why.

```
lib/
  design_system/            Nocturne design tokens + primitives (button, card, tag, ...) — the
                             shared visual vocabulary every screen (View) is built from.

  core/
    domain/
      entities/               Plain data classes: AppUser, Product, Cart, Order,
                               Device, HealthReading, HealthSummaryPoint. No
                               Flutter/Dio/Hive imports — pure Dart.
      repositories/           Abstract contracts: AuthRepository, DeviceRepository,
                               ProductRepository, CartRepository, OrderRepository.
                               Presentation code depends on these, never on a
                               concrete impl or on ApiClient directly.

    data/
      datasources/
        remote/                ApiClient + ApiException — one method per backend
                                endpoint, the only place that speaks HTTP.
        local/                 TokenStorage, ProductsLocalCache — Hive-backed,
                                the only place that reads/writes those boxes.
      repositories/             *Impl classes satisfying the domain contracts,
                                each composing one or more datasources
                                (e.g. ProductRepositoryImpl = ApiClient +
                                ProductsLocalCache + the cache-first policy).

    health_sync/               HealthReadingLocalStore, SyncManager, HealthSyncEngine
                                — the offline engine. Deliberately *not* squeezed into
                                the repository shape above; see below.
    wearable/                  WearableService interface + MockWearableService —
                                the assignment's own required architecture, kept
                                as its own abstraction rather than folded into
                                "repositories" (a live device stream isn't a CRUD resource).
    offline/                   ConnectivityMonitor, CachePolicy, Hive box setup, LocalDataWiper
    providers/                 The composition root: datasource_providers.dart wires
                                the data sources, repository_providers.dart wires
                                domain-typed repositories on top of them.

  features/<name>/presentation/
    controllers/              The Controller/ViewModel layer — Riverpod notifiers
                               and providers, one per feature, depending only on
                               core/domain/repositories (never ApiClient/Hive directly).
    screens/                  The View layer — one file per screen.
    widgets/                  Feature-local presentational widgets (charts, tab bar, ...).

  app.dart, main.dart        Entry point, theme, ProviderScope
```

**Why "MVC" and "Riverpod" aren't in tension.** The classic Controller's job
— receive an intent, decide what changes, hand the View new state — is
exactly what a Riverpod `Notifier` does here. A separate hand-rolled
Controller class delegating straight to a Notifier would be a pass-through
layer with no logic of its own, which is the same kind of unnecessary
indirection the assignment's "avoid unnecessary complexity" guidance warns
against. So: **Model = `core/domain/entities`, View = `presentation/screens`
+ `presentation/widgets`, Controller = `presentation/controllers`** (Riverpod
notifiers/providers) — MVC roles, Riverpod idioms.

**State management: Riverpod, generator-based (`@riverpod`), not
Bloc/Cubit or plain `ChangeNotifier`.** Providers are annotated
functions/classes over immutable state (`copyWith`), composed by reading
each other (`ref.watch`) rather than constructor injection. Every
provider file has a generated `*.g.dart` sibling — run
`dart run build_runner build` after touching provider signatures.

### Why not the textbook version everywhere

Two deliberate departures from a by-the-book Clean Architecture, both
because the extra layer would have no logic in it:

- **No `UseCase` class per operation.** A `LoginUseCase` that does nothing
  but call `authRepository.login(...)` is a pass-through — the controller
  calling the repository directly *is* the use case here, same reasoning
  as the backend's "no services layer" decision (see `../api/README.md`).
- **The offline engine (`core/health_sync/`) isn't wrapped in a
  `HealthRepository`.** `SyncManager` and `HealthReadingLocalStore` already
  provide a clean, purpose-built interface — batched drain, retry/backoff,
  live counts via streams. Forcing that into a generic
  `Future<List<Entity>> get(id)`-shaped repository would lose exactly the
  vocabulary (`drain()`, `pendingCount`, `retryFailed()`) that makes
  `docs/OFFLINE_SYNC.md`'s design legible. `SyncManager` *is* this
  subsystem's repository-equivalent, just named for what it actually does.
  It does, however, depend on `DeviceRepository` for device registration
  (`core/health_sync/health_sync_providers.dart`) — the one place these two
  subsystems genuinely meet.

## API documentation

Full endpoint reference: [`../api/README.md`](../api/README.md#api-documentation).
`lib/core/data/datasources/remote/api_client.dart` is a 1:1 wrapper — one method per backend
route. Every request except `login` and the two product GETs carries
`Authorization: Bearer <token>` (attached by a Dio interceptor reading
`TokenStorage`); the backend verifies it and scopes the request to that
token's `userId` (`api/middleware/auth.js`).

## Database design

Owned by the backend — see [`../api/README.md`](../api/README.md#database)
and [`../api/database/schema.sql`](../api/database/schema.sql) for the ERD
and constraints. The Flutter app's local Hive storage is a separate,
client-only concern (health readings + a product cache), documented below.

## Wearable integration approach

Three-layer separation, exactly as the assignment's architecture diagram asks:

```
Flutter screens (Dashboard, History, Connection, ...)
        |
WearableService (abstract interface — lib/core/wearable/wearable_service.dart)
        |
MockWearableService (lib/core/wearable/mock_wearable_service.dart)
```

Screens depend only on the interface: `connectionState`/`readings`/
`reconnectStatus` streams and `connect()`/`disconnect()`/`reconnect()`.
Nothing in `lib/features/` imports `MockWearableService` directly.

**Replacing the mock with a real SDK.** The recommended path is **Flutter
Platform Channels over a real vendor plugin**, not raw platform channels
hand-rolled per-project:

- Write `BleWearableService implements WearableService` in Dart. It talks
  to a platform channel (`MethodChannel` for commands, `EventChannel` for
  the reading/connection-state streams) instead of a `Timer`.
- Android side: Kotlin, using the vendor's BLE SDK (or `flutter_blue_plus`
  if the "smart ring" exposes a standard BLE GATT profile rather than a
  proprietary SDK) inside the platform channel's method/event handlers.
- iOS side: Swift + CoreBluetooth (or the vendor's iOS SDK), same channel
  contract.
- Swap `MockWearableService()` for `BleWearableService()` at the single
  provider that constructs it (`wearableServiceProvider` in
  `lib/core/providers/wearable_providers.dart`) — **zero screen changes**,
  because every screen already depends on `WearableService`, not the mock.

**Why platform channels + a thin per-platform native layer, not a
pre-built Flutter BLE package alone:** a real "smart ring" vendor SDK is
almost never a generic BLE GATT profile — it's a proprietary Android AAR /
iOS framework with its own pairing, firmware, and data-encoding handshake.
A generic Flutter BLE plugin gets you raw characteristic read/write; the
vendor SDK's own connection and parsing logic still has to run natively
and get bridged over, which is exactly what a platform channel is for.
If the ring *did* expose standard BLE GATT (heart rate service `0x180D`,
battery service `0x180F`), a Flutter-side BLE plugin would remove the need
for native code almost entirely — worth checking before assuming the
native-bridge path.

### Connection handling & retry strategy

`MockWearableService` models the full connection lifecycle the assignment
lists — connected, disconnected, connecting, reconnecting,
connection-failed (`lib/core/wearable/wearable_connection_state.dart`) —
and implements **exponential backoff on unexpected drops**: retry delays
2s, 4s, 8s, 16s (4 automatic attempts), then stop and require the user to
tap "Reconnect now" (screen 03, `lib/features/connection/presentation/screens/connection_screen.dart`).
A manual reconnect always works, even after auto-retry has given up. This
is a real device concern (BLE stacks don't retry forever either) that a
real SDK-backed `WearableService` would keep, just swapping "simulated
drop" for "OS reported the peripheral disconnected."

## Local health data & History

Every reading — whether it's synced to the backend yet or not — is
persisted locally the instant the wearable emits it
(`HealthReadingLocalStore`, a Hive box). The History screen
(`lib/features/history/`) reads and computes its charts **from that local
store**, not the network, so it works fully offline and reflects
just-captured data immediately.

**Large-dataset behavior:** `HealthReadingLocalStore.recent()` always caps
at 20 rows (matching the design's "Showing the latest 20..." note) — it
never loads the full box into a widget. Daily/weekly summaries only ever
scan the last 7 days of readings (`HealthReadingLocalStore.summary`,
mirroring the backend's own `GET /health/summary` window), so the amount
of data touched per render is bounded regardless of how long the app has
been running. There is currently no hard cap on the *box's* total size —
see docs/OFFLINE_SYNC.md's "Explicitly not built" list for the periodic
eviction sweep that would bound it, noted as a deliberate, lower-priority
gap rather than an oversight.

## Offline synchronization approach

Full design rationale in [`docs/OFFLINE_SYNC.md`](docs/OFFLINE_SYNC.md) —
this is the short version.

**Target scenario (100 readings generated offline, synced on reconnect)
works and is verified live**, not just unit-tested: readings write to Hive
immediately regardless of connectivity; `SyncManager` batches whatever's
pending to `POST /health/readings`; `ConnectivityMonitor` (via
`connectivity_plus`) triggers a drain on the offline→online transition, on
top of app-launch, a 10s periodic timer, and foreground-resume (all wired
in `RootShell`). Duplicate prevention rides entirely on the backend's
`(device_id, reading_timestamp)` unique constraint — a replayed batch is a
harmless no-op, so there's no client-side dedup logic to get wrong.

Per-reading retry: a failed batch increments every reading's attempt
counter; under `maxAttempts` (5) it stays `pending` for the next drain,
past it the reading moves to `failed` and stops auto-retrying — surfaced
in a banner on every screen (`SyncBanner`) with a Retry/Discard sheet.
Backoff between automatic attempts is 2s→4s→8s→16s→30s.

**Only health readings are queued** — cart/order writes stay network-only.
The PDF's offline requirement is specifically about wearable data
generated while disconnected; cart/order actions are user-initiated,
in-the-moment, and queuing them raises a stock/price reconciliation
problem the assignment doesn't ask for. Full reasoning in
docs/OFFLINE_SYNC.md's "Why so little is queued."

## Error handling

| Situation | Handling |
| --- | --- |
| Bluetooth/device disconnect | `WearableConnectionState.disconnected` → auto-reconnect with backoff → `connectionFailed` after 4 attempts → manual "Reconnect now" always available. See Connection screen. |
| API failure (4xx/5xx) | `ApiClient` wraps every Dio error into `ApiException` with the backend's own `{ error: "..." }` message; screens surface it via `SnackBar` or an inline error card (`_ErrorNote` pattern in History/Shop). |
| No internet | Reads fall back to local data where one exists (History: always, from Hive; Products: cache-first up to a 7-day grace — see `CachePolicy.productsCatalog`). Writes (health readings) queue instead of failing; cart/order actions surface the network error since they have no offline path. |
| Backend unavailable | Same as API failure — `DioException` without a response still resolves to a generic `ApiException`, never an uncaught exception reaching the UI. |
| Duplicate health readings | Not client-side logic — the backend's unique constraint makes a replay a no-op; `SyncManager` doesn't need to detect duplicates itself. |
| Authentication failure | Wrong password → `401` surfaced on the login form. An expired/invalid token on any other request → the backend's `401`/`403` (see `api/middleware/auth.js`) surfaces as a normal `ApiException`; there's no silent-logout-on-401 interceptor today — a session that goes stale mid-use shows an error on the next action rather than force-navigating to Login. |
| Failed synchronisation | Per-reading retry/backoff as described above, surfaced in `SyncBanner`, with manual Retry/Discard once exhausted. |

## Major technical decisions and trade-offs

- **Riverpod (generator-based) over Bloc/Cubit or plain Provider.**
  Explicit instruction mid-build. Immutable state + `copyWith`,
  composition via `ref.watch`, no imperative `notifyListeners()`.
- **Hive without generated `TypeAdapter`s** — every cached value is a
  plain `Map<String, dynamic>` via each model's own `toHiveMap`/`toJson`.
  One fewer codegen pipeline running alongside `riverpod_generator`; the
  models are small enough that hand-written (de)serialization isn't a
  maintenance burden.
- **One Hive box per genuinely distinct concern** (`health_readings`,
  `products_cache`), not one per resource-type the way a larger reference
  architecture might. See docs/OFFLINE_SYNC.md for the full reasoning —
  short version: this app only has one resource that needs a real offline
  queue.
- **No client-minted ids for health readings.** The backend already
  dedupes on a natural key; adding a client id would be solving a problem
  that doesn't exist here (see docs/API_GAPS.md's "client-generated id"
  note).
- **History computes summaries client-side** rather than calling
  `GET /health/summary`, so it's fully offline-capable and reflects
  readings that haven't synced yet — see "Local health data" above.
- **Mock auth token is an opaque, unsigned blob**, matching the backend's
  own choice (`api/auth.routes.js`) — this is a take-home assignment, not
  a production auth scheme; swapping in real JWTs is backend-only.
- **`IndexedStack` for the four root tabs** (Dashboard/History/Shop/
  Profile) rather than lazy-built routes — keeps scroll position and
  provider state per tab across switches. Trade-off: all four build
  immediately after login rather than on first visit (confirmed during
  live testing — Shop's product images start loading as soon as
  Dashboard does, not when the user actually taps Shop).
- **No shipping/payment backend support** (no `shipping_address` or
  payment columns) — matches the PDF's explicit "no real payment gateway"
  scope. Checkout's address fields and the flat $5 shipping line are UI
  decoration; `POST /orders` only ever takes `{ userId }`. Documented in
  full in docs/API_GAPS.md.

## Testing

```bash
flutter test
```

`test/health_sync_manager_test.dart` (7 tests) covers the offline engine's
correctness-critical logic against fakes — no live device or network:
device-registration gating before any reading syncs, per-reading attempt
counting, the pending→failed transition at `maxAttempts`, backoff actually
blocking a too-soon automatic retry, and `retryFailed` restoring a full
attempt budget. This is the piece where a bug would silently lose health
data, so it's the piece that's unit-tested — matching the assignment's own
guidance to focus tests where "incorrect behavior could cause data loss."

Backend logic (auth, cart upserts, order transactions, duplicate
prevention) is tested in `../api/tests/` (33 tests) — see
[`../api/README.md#tests`](../api/README.md#tests).

**Not covered by automated tests today:** widget-level tests for the
screens themselves, and the Riverpod providers that wrap plain CRUD over
`ApiClient`/`HealthReadingLocalStore` (cart quantity math, History's
summary computation) — these were instead verified with a live run against
a real emulator + backend (login → dashboard → history → shop → cart →
checkout → order history → profile, plus the full offline→queue→
reconnect→drain→retry-failed cycle with the emulator's network toggled
off and on). Worth adding unit coverage for `HealthReadingLocalStore.summary`
specifically if this continues past the take-home stage — it's the one
piece of non-trivial derived logic (day/week bucketing, min/max/avg) that
currently only has that manual verification behind it.
