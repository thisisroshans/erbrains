# FitRing

Flutter client for the *Wearable Health & Shopping* app (ERBrains take-home
assignment). Talks to the Express/PostgreSQL backend in [`../api`](../api).

Screens are static-UI-first: they were scaffolded from a design handoff
(`Wearable App Screens.dc.html`, 11 screens) and then wired to real state.
See [`../Senior Mobile Developer Assignment 1.pdf`](<../Senior Mobile Developer Assignment 1.pdf>)
for the original spec this implements.

Architecture, the wearable integration approach, offline sync design, and
the reasoning behind every technical decision live in
[`../docs/`](../docs) — this README only covers running the project
locally. See in particular:
[`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md#flutter) (Clean
Architecture layering, request-flow diagram),
[`../docs/WEARABLE_INTEGRATION.md`](../docs/WEARABLE_INTEGRATION.md)
(`WearableService`, mock → real SDK path, connection/retry state machine),
[`../docs/OFFLINE_SYNC.md`](../docs/OFFLINE_SYNC.md) (offline queue design),
[`../docs/API.md`](../docs/API.md) (endpoint reference this client consumes),
[`../docs/DECISIONS.md`](../docs/DECISIONS.md#flutter) (trade-offs).

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
upserts (see `api/auth.routes.js`) — so any credentials work. If you seeded
the database before the backend's auth was upgraded to real bcrypt/JWT, the
old demo password hash won't verify — see
[`../api/README.md#setup`](../api/README.md#setup) for the one-line fix.

## Platform notes (Android / iOS)

**Android** is the platform this app was actually built and run against —
debug APK builds, `flutter analyze`/`flutter test`, and CI
(`../.github/workflows/ci.yml`) all cover it directly.

**iOS was not built.** No Mac / Apple developer environment was available
in the environment this was developed in. Rather than leave that as a
silent gap, here's what was actually checked: `AppConfig`'s platform
branching (`lib/core/config/app_config.dart`) already covers iOS
correctly (falls through to `localhost:3000`, matching how the iOS
simulator reaches the host machine); every dependency in `pubspec.yaml`
(`dio`, `flutter_riverpod`, `hive`, `connectivity_plus`,
`shared_preferences`, `workmanager`, `google_fonts`, `phosphor_flutter`,
`uuid`, `intl`) is genuinely cross-platform, nothing Android-only snuck
in; and `ios/Runner/Info.plist` already carries the background-sync
`UIBackgroundModes`/`BGTaskSchedulerPermittedIdentifiers` keys the
`workmanager` integration needs. The `ios/` project itself is the
standard `flutter create` scaffold. In short: nothing found blocks an iOS
build architecturally, but "nothing found" is not the same claim as "it
builds and runs" — that still needs an actual Mac to confirm.

## Tests

```bash
flutter test
```

Three suites (33 tests total), all against fakes — no live device or
network required for any of them:

- **`test/health_sync_manager_test.dart`** (14 tests) — the reading
  queue's correctness-critical logic: device-registration gating before
  any reading syncs, per-reading attempt counting, the pending→failed
  transition at `maxAttempts`, backoff actually blocking a too-soon
  automatic retry, `retryFailed` restoring a full attempt budget,
  per-reading duplicate reconciliation, the staleness-eviction sweep, and
  the `isRetryable` classification (a non-retryable `ApiException` fails
  immediately, skipping the attempt budget; a retryable one still backs
  off normally).
- **`test/cart_sync_manager_test.dart`** (12 tests) — the cart/order
  queue's equivalent: local→real cart-item-id rewriting for a dependent
  mutation, `placeOrder` gating behind every prior cart edit (including
  staying queued when an earlier mutation fails, not just when it
  succeeds), `refreshBaseline` running once after a full drain, the same
  retry/backoff/failed-transition coverage as the reading queue, and the
  same `isRetryable` classification — a queued `placeOrder` that hits a
  `409` (insufficient stock) fails immediately rather than retrying a
  rejection that can't become true later.
- **`test/effective_cart_test.dart`** (7 tests) — the pure function that
  projects the mutation queue onto the last-known server cart for
  display, including the upsert-matching "add to an existing line
  increments quantity" case.

This is the piece where a bug would silently lose health data or corrupt
a cart/order, so it's the piece that's unit-tested — matching the
assignment's own guidance to focus tests where "incorrect behavior could
cause data loss."

Backend logic (auth, cart upserts, stock validation, order transactions,
duplicate prevention) is tested in `../api/tests/` (55 tests) — see
[`../api/README.md#tests`](../api/README.md#tests).

**Not covered by automated tests today:** widget-level tests for the
screens themselves, the Riverpod providers that wrap plain CRUD over
`ApiClient`/`HealthReadingLocalStore` (History's summary computation), and
— the one real gap worth calling out explicitly — the OS-level background
sync task (`core/background/background_sync.dart`) has no automated
coverage and was not run against a live Android/iOS device; see
[`../docs/OFFLINE_SYNC.md#background-sync`](../docs/OFFLINE_SYNC.md#background-sync)
for exactly what was and wasn't verified. Everything else in this list
was instead verified with a live run against a real emulator + backend
(login → dashboard → history → shop → cart → checkout → order history →
profile, plus the full offline→queue→reconnect→drain→retry-failed cycle
with the emulator's network toggled off and on) — that pass predates the
cart/order queue and background sync work, though, so it doesn't cover
either. Worth adding unit coverage for `HealthReadingLocalStore.summary`
specifically if this continues past the take-home stage — it's the one
piece of non-trivial derived logic (day/week bucketing, min/max/avg) that
currently only has manual verification behind it.

## Error handling

Summary table in [`../docs/ARCHITECTURE.md#error-handling`](../docs/ARCHITECTURE.md#error-handling).
In short: `ApiClient` wraps every Dio error into a typed `ApiException`
carrying the backend's own message, so no raw Dio/network exception ever
reaches a screen. A 401 on an *authenticated* request (the JWT expired, or
the server's secret rotated) is distinguished from a login-form 401 (wrong
password) and triggers a global session-expiry event, dropping the app
back to Login and wiping local data — see
[`../docs/API.md`](../docs/API.md#client-consumption-flutter). Reads fall
back to local Hive data where one exists (History always, Products
cache-first with a grace window, Cart to its last-known baseline). Health
readings and cart/order writes both queue for later sync rather than
failing outright — see [`../docs/OFFLINE_SYNC.md`](../docs/OFFLINE_SYNC.md)
— with a queued `placeOrder` specifically surfaced to the user as
"queued," never as a silent success, and a non-retryable rejection (e.g.
insufficient stock) surfaced immediately rather than retried.

## Known gap: no light/system theme

The app renders dark-only (`themeMode: ThemeMode.dark` in `app.dart`),
regardless of the device's system setting. This was investigated, not
overlooked: `NocturneColors` (`lib/design_system/nocturne_colors.dart`)
are `static const Color` values referenced directly across every screen,
not routed through `Theme.of(context)` — so wiring `ThemeMode.system`
alone would change nothing visually. A real light theme means re-threading
dozens of widgets through context-aware tokens, which is a large refactor
with real regression risk that can't be verified without a live
emulator/device to actually look at the result. See
[`../docs/DECISIONS.md`](../docs/DECISIONS.md#flutter) for the full
reasoning behind deferring this rather than shipping it unverified.
