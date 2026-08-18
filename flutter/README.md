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
upserts (see `api/auth.routes.js`) — so any credentials work.

## Tests

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

## Error handling

Summary table in [`../docs/ARCHITECTURE.md#error-handling`](../docs/ARCHITECTURE.md#error-handling).
In short: `ApiClient` wraps every Dio error into a typed `ApiException`
carrying the backend's own message, so no raw Dio/network exception ever
reaches a screen; reads fall back to local Hive data where one exists
(History always, Products cache-first with a grace window) and health
readings queue for later sync, but cart/order writes have no offline path
and surface the network error directly.
