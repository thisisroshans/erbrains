# FitRing

Flutter client for the *Wearable Health & Shopping* app (ERBrains take-home
assignment). Talks to the Express/PostgreSQL backend in [`../api`](../api).

Screens are static-UI-first: they were scaffolded from a design handoff
(`Wearable App Screens.dc.html`, 11 screens) and then wired to real state.
See [`../Senior Mobile Developer Assignment 1.pdf`](<../Senior Mobile Developer Assignment 1.pdf>)
for the original spec this implements.

This README is written so someone newer to Flutter (or newer to this specific
codebase) can follow it end to end. Sections that involve a less obvious idea
start with an **"In plain English"** box that explains it with an everyday
comparison before getting into the technical detail. If you already know the
concept, skip straight past the box — nothing after it repeats what's in it.
The backend's [`../api/README.md`](../api/README.md) uses the same format and
is worth reading alongside this one, since a few analogies (the wristband,
the filing cabinet) are shared between the two.

---

## Setup

> **In plain English:** these commands are, in order: *"download the tools
> this app needs"* → *"generate some boilerplate code a robot can write
> faster than we can"* → *"launch the app on a device."* The backend has to
> already be running first — the app is a phone screen with no brain of its
> own until it can actually talk to the API.

Requires the backend running first — see [`../api/README.md`](../api/README.md)
(`npm install && npm run db:migrate && npm run db:seed && npm start`).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart for Riverpod
flutter run                                                  # picks a connected device/emulator
```

What each step does:

1. **`flutter pub get`** downloads every package listed in `pubspec.yaml`
   (Riverpod, Dio, Hive, etc.) — the Flutter equivalent of `npm install`.
2. **`dart run build_runner build`** is a code-generation step. Riverpod lets
   us write a short, annotated function like `@riverpod Future<Product>
   product(...)` instead of hand-writing a full provider class every time.
   Think of it like a **recipe shorthand**: you write the short version, and
   a robot (`build_runner`) reads it and writes out the long, boring, fully
   spelled-out version into a matching `*.g.dart` file next to it, so you
   never have to type that boilerplate by hand. You only need to re-run this
   command when you *change* one of those shorthand recipes — editing a
   screen or a widget doesn't require it.
3. **`flutter run`** compiles the app and launches it on whatever device or
   emulator is currently connected (`flutter devices` lists the options).

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

---

## Architecture

> **In plain English:** imagine a restaurant chain that wants to be able to
> swap out its kitchen equipment (say, moving from gas stoves to induction)
> without ever having to reprint the menu or retrain the waitstaff. To pull
> that off, you'd keep three things strictly separate:
>
> - A **recipe book** that just describes *what* a dish is and the steps to
>   make it — "a burger needs a bun, a patty, and 4 minutes on the grill" —
>   without caring whether the grill is gas or induction. That's
>   `core/domain/`: plain data classes (`Product`, `Order`, `HealthReading`,
>   ...) and *interfaces* describing what a repository can do, with zero
>   mention of Dio, Hive, or HTTP anywhere in the folder.
> - The **actual kitchen** — the real stove, the real fridge, today's actual
>   brand of ketchup — which is where the recipe book's instructions get
>   carried out for real. That's `core/data/`: the code that actually calls
>   the backend over HTTP (`datasources/remote/`) and actually reads/writes
>   local storage (`datasources/local/`), wired together into concrete
>   implementations of the recipe book's interfaces.
> - The **dining room and waitstaff** — what the customer actually sees and
>   talks to. A customer orders a burger; they never walk into the kitchen
>   themselves. That's `features/<name>/presentation/`: screens (what you
>   see) and controllers (the "waiter" who takes the order, asks the kitchen
>   for it via the recipe-book interface, and brings back the result as
>   state the screen can display).
>
> The payoff: if this project swapped Postgres+Express for, say, Firebase
> tomorrow, only the "kitchen" (`core/data/`) would need to change. The
> recipe book (`core/domain/`) and the dining room (the screens) wouldn't
> need to know or care — they were never written against Dio or Hive
> directly, only against the plain interfaces. This layering is called
> **Clean Architecture**, and it's a very common way to structure apps that
> need to stay flexible about *how* data is fetched or stored.

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

**Why "MVC" and "Riverpod" aren't in tension.** In the same restaurant
picture, the classic MVC "Controller" is the waiter: takes an order (an
intent — "user tapped Add to Cart"), decides what to tell the kitchen, and
brings the result back out to the table as something the customer can see.
That's exactly what a Riverpod `Notifier` does here — it receives an intent,
calls into the domain layer, and exposes new state for the screen to render.
A separate hand-rolled Controller class that just forwarded to a Notifier
underneath would be a waiter who relays your order to *another* waiter before
it reaches the kitchen — a pass-through layer with no job of its own, which
is the same kind of unnecessary indirection the assignment's "avoid
unnecessary complexity" guidance warns against. So: **Model =
`core/domain/entities`, View = `presentation/screens` + `presentation/
widgets`, Controller = `presentation/controllers`** (Riverpod notifiers/
providers) — MVC roles, Riverpod idioms.

**State management: Riverpod, generator-based (`@riverpod`), not
Bloc/Cubit or plain `ChangeNotifier`.** Providers are annotated
functions/classes over immutable state (`copyWith`), composed by reading
each other (`ref.watch`) rather than constructor injection. Every
provider file has a generated `*.g.dart` sibling — run
`dart run build_runner build` after touching provider signatures (see
Setup above for what that command is actually doing).

### Why not the textbook version everywhere

Two deliberate departures from a by-the-book Clean Architecture, both
because the extra layer would have no logic in it — an empty pass-through
box on the diagram that exists only because the textbook says to draw it:

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

---

## API documentation

> **In plain English:** same wristband idea as the backend README — once
> you're logged in, every request the app makes to the server needs to show
> that wristband (`Authorization: Bearer <token>`). Rather than every screen
> having to remember to dig the wristband out of your pocket and show it
> manually, the app has one central "usher" (a Dio interceptor) that
> automatically attaches it to every outgoing request. It's like a theme
> park where your wristband is scanned for you automatically at every ride's
> turnstile — you never have to think about showing it yourself.

Full endpoint reference: [`../api/README.md`](../api/README.md#api-documentation).
`lib/core/data/datasources/remote/api_client.dart` is a 1:1 wrapper — one method per backend
route. Every request except `login` and the two product GETs carries
`Authorization: Bearer <token>` (attached by a Dio interceptor reading
`TokenStorage`); the backend verifies it and scopes the request to that
token's `userId` (`api/middleware/auth.js`).

Concretely, calling `ref.read(cartProvider(userId).notifier).addToCart(...)`
from a screen flows like this: **controller** (`presentation/controllers`)
→ **domain repository interface** (`core/domain/repositories`) →
**concrete repository impl** (`core/data/repositories`) → **`ApiClient`**
(attaches the token, makes the HTTP call) → backend. Any HTTP failure comes
back up that same chain wrapped as an `ApiException`, never a raw Dio
exception — see Error handling below.

---

## Database design

> **In plain English:** there are actually *two* separate places data lives
> in this app, and it's worth being clear about which is which. The "real"
> filing cabinet — the one with users, orders, and the full history of every
> health reading ever recorded — lives on the backend server, in Postgres
> (see [`../api/README.md`](../api/README.md#database) for that ERD). What
> lives *on the phone* is much smaller: think of it as a little pocket
> notebook the phone carries around. The notebook holds a rolling window of
> recent health readings (so the app has something to show even with no
> signal) and a cached copy of the product catalog (so browsing the shop
> doesn't grind to a halt the moment you lose connectivity). It's not a
> second "real" database — it's scratch space, and the backend's Postgres
> database is always the source of truth.

Owned by the backend — see [`../api/README.md`](../api/README.md#database)
and [`../api/database/schema.sql`](../api/database/schema.sql) for the ERD
and constraints. The Flutter app's local Hive storage is a separate,
client-only concern (health readings + a product cache), documented below.

**What's actually in the phone's notebook (Hive boxes):**

| Box | Holds | Why it exists locally |
|---|---|---|
| `health_readings` | Every reading captured on-device, synced or not, plus its sync status/attempt count | So the History screen and the offline sync queue both work with zero network — see "Local health data" and "Offline synchronization" below |
| `products_cache` | The last successfully fetched product catalog | So the Shop screen can still show *something* (a stale-but-usable catalog) when offline — see `CachePolicy` below |

Hive stores plain `Map<String, dynamic>` values rather than generated
`TypeAdapter` classes here — see "Major technical decisions" for why.

---

## Wearable integration approach

> **In plain English:** think of `WearableService` as the **button layout
> of a universal remote control** — "power," "volume up," "channel down."
> The buttons stay in exactly the same place and do the same thing no
> matter what brand of TV you actually point the remote at. Every screen in
> this app was built to press those buttons (`connect()`, `disconnect()`,
> listen to the `readings` stream) without ever caring what's actually
> behind them.
>
> `MockWearableService` is a **pretend TV** — it doesn't talk to any real
> hardware, it just makes up believable channel numbers (heart rate, SpO₂,
> steps) on a timer, so we can test and demo the whole remote without owning
> a real smart ring yet. Swapping in a real device later is like pointing
> the same universal remote at an actual Samsung TV instead of the pretend
> one: you don't redesign the remote's buttons, you just teach it — once,
> in one place — how to actually speak that TV's language underneath. That
> translation layer, from Dart's "universal remote" down to the phone's real
> Bluetooth radio, is what a **platform channel** is for.

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

> **In plain English:** real Bluetooth devices drop connection sometimes —
> that's just how BLE radios behave, not a bug. The right response isn't to
> retry forever (that would drain the battery hammering a device that's
> genuinely out of range) or to give up after one try (a real momentary
> blip shouldn't force the user to manually reconnect). So the app waits a
> little longer between each retry attempt — 2 seconds, then 4, then 8,
> then 16 — the way you'd naturally wait a bit longer each time you re-try
> calling someone whose call keeps dropping, instead of redialing
> instantly and hoping. After four tries with no luck, it stops trying
> automatically and puts the ball back in the user's court with a
> "Reconnect now" button — always available, no matter how many automatic
> attempts already failed.

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

---

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

---

## Offline synchronization approach

> **In plain English:** imagine you're on a camping trip with no mail
> service. Every day you write a letter (a health reading) and drop it in
> your own mailbox at the campsite — that's writing to the local Hive
> store, and it happens *immediately*, whether or not the mail truck is
> anywhere nearby. The mailbox doesn't care if the truck is running; it
> just holds your letters safely until it is.
>
> Once the mail truck (an internet connection) shows up again, the campsite
> worker (`SyncManager`) doesn't make one trip per letter — they gather up
> *everything* waiting in the mailbox and drive it to the post office (the
> backend) in one batch trip. That's **batching**, and it's a lot more
> efficient than a request per reading.
>
> If a trip fails (the truck breaks down, the network drops mid-upload),
> the worker doesn't throw the letters away — they try again a little later,
> waiting slightly longer each time: "try again in 2 seconds, then if that
> fails wait 4, then 8, then 16, then 30." That's the same **exponential
> backoff** idea as the wearable's reconnect strategy above, and for the
> same reason — don't hammer a connection that just failed. If a letter
> keeps failing after several honest attempts, the worker sets it aside in
> a "needs your attention" pile instead of retrying forever — that's the
> `failed` state, and it's what the `SyncBanner` shows you with a Retry/
> Discard choice.
>
> And here's the detail that makes the whole system forgiving of mistakes:
> if the *same* letter accidentally gets mailed twice — say, a retry fires
> because the app never heard back, even though the letter actually arrived
> fine the first time — the post office doesn't file it twice. It
> recognises "I already have a letter from this exact sender, dated exactly
> this time" (the backend's `(device_id, reading_timestamp)` unique
> constraint) and just discards the duplicate. Because that safety net
> lives at the post office, the campsite worker never has to keep its own
> "have I already sent this one?" checklist — it can just re-send anything
> it's unsure about, worry-free.

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
problem the assignment doesn't ask for (imagine adding an item to your cart
offline, and by the time it "sends" hours later, the price changed or the
last one sold out — that's a genuinely different, harder problem than
"resend this sensor reading"). Full reasoning in docs/OFFLINE_SYNC.md's
"Why so little is queued."

---

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

---

## Major technical decisions and trade-offs

> **In plain English:** as with the backend README, each item below is
> "here were the realistic options, here's the one we went with, and here's
> the concrete reason" — not a claim that it's the only right answer.

- **Riverpod (generator-based) over Bloc/Cubit or plain Provider.**
  Explicit instruction mid-build. Immutable state + `copyWith`,
  composition via `ref.watch`, no imperative `notifyListeners()`. In plain
  terms: instead of a screen reaching in and mutating some shared object in
  place (which is easy to lose track of as an app grows), every state
  change produces a brand-new, immutable snapshot of state — much easier to
  reason about, since a piece of state can never change "behind your back"
  mid-read.
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
  dedupes on a natural key (device + timestamp); adding a client-generated
  id would be solving a duplicate-detection problem that doesn't exist
  here (see docs/API_GAPS.md's "client-generated id" note) — same "the
  post office already checks for duplicates" reasoning as the offline sync
  section above.
- **History computes summaries client-side** rather than calling
  `GET /health/summary`, so it's fully offline-capable and reflects
  readings that haven't synced yet — see "Local health data" above.
- **Mock auth token is an opaque, unsigned blob**, matching the backend's
  own choice (`api/auth.routes.js`) — this is a take-home assignment, not
  a production auth scheme; swapping in real JWTs is backend-only.
- **`IndexedStack` for the four root tabs** (Dashboard/History/Shop/
  Profile) rather than lazy-built routes — keeps scroll position and
  provider state per tab across switches. In plain terms: it's the
  difference between four rooms that all stay furnished and lit even when
  you're not standing in them, versus rooms that get built from scratch
  every time you walk back in. Trade-off: all four build immediately after
  login rather than on first visit (confirmed during live testing — Shop's
  product images start loading as soon as Dashboard does, not when the
  user actually taps Shop).
- **No shipping/payment backend support** (no `shipping_address` or
  payment columns) — matches the PDF's explicit "no real payment gateway"
  scope. Checkout's address fields and the flat $5 shipping line are UI
  decoration; `POST /orders` only ever takes `{ userId }`. Documented in
  full in docs/API_GAPS.md.

---

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
