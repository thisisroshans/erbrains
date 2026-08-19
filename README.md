# Wearable Health & Shopping

ERBrains take-home assignment: a mobile app that syncs data from a wearable
device and includes a small shopping flow. Two projects, one repo:

- **[`api/`](api)** — Node.js + Express + PostgreSQL REST API
- **[`flutter/`](flutter)** — Flutter client ("FitRing"), Riverpod +
  Clean Architecture, talking to `api/` over REST

Original spec: [`Senior Mobile Developer Assignment 1.pdf`](<docs\Senior Mobile Developer Assignment 1.pdf>).

## System overview

```mermaid
flowchart LR
    W["Wearable device\n(simulated)"] -->|readings stream| App

    subgraph Mobile["flutter/ — Flutter app"]
        App["Riverpod controllers + screens"]
        Local[("Hive\nlocal cache/queue")]
        App <--> Local
    end

    App -->|REST, Bearer token| API

    subgraph Backend["api/ — Node / Express"]
        API["routes -> controllers -> models"]
    end

    API --> DB[("PostgreSQL")]
```

## Quick start

Backend first, then the client — see each project's README for full setup,
environment variables, and test commands:

```bash
# 1. Backend
cd api
npm install && npm run db:migrate && npm run db:seed && npm start

# 2. Flutter client (separate terminal)
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Demo login (seeded by the backend): `demo@erbrains.io` / `password123`.
The backend needs a `JWT_SECRET` set (`api/.env.example` has the full
variable list) — `npm install` doesn't fail without one, but the server
throws on first request if it's missing.

Interactive API docs (Swagger UI) are served at `http://localhost:3000/docs`
once the backend is running — a second way to explore the API beyond the
Postman collection.

- [`api/README.md`](api/README.md) — backend setup, env vars, running tests
- [`flutter/README.md`](flutter/README.md) — client setup, running tests, platform notes (Android verified, iOS not built — see why)

## Android build

A prebuilt release APK is at [`dist/FitRing.apk`](dist/FitRing.apk)
(~51 MB) — install it directly without building from source:

```bash
adb install dist/FitRing.apk
```

It's signed with Flutter's default debug keystore (see
`flutter/android/app/build.gradle.kts` — no real signing config exists for
this project), so Android will treat it as an unsigned/debug app; on a
physical device you may need to allow installs from the source you're
using to sideload it. It points at `10.0.2.2:3000` by default (the
emulator's alias for the host), so on a physical device pass the host's
LAN IP at install/run time per
[`flutter/README.md`](flutter/README.md#setup) if you're building from
source instead — the prebuilt APK itself is baked to the emulator address
and won't reach a backend running elsewhere without a rebuild.

## Documentation

This README covers only the top-level overview. Everything else — system
and per-project architecture, the database schema, the full API reference,
the wearable integration approach, the offline sync design, and the
reasoning behind every non-obvious technical decision — lives in
[`docs/`](docs), which is the source of truth for all of it:

| Doc | Covers |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | System context, backend MVC layering, Flutter Clean Architecture layering, request-flow and checkout sequence diagrams, error handling |
| [`docs/DATABASE.md`](docs/DATABASE.md) | Full ERD, constraints, and idempotency design |
| [`docs/API.md`](docs/API.md) | Endpoint reference, auth model, worked `curl` example |
| [`docs/WEARABLE_INTEGRATION.md`](docs/WEARABLE_INTEGRATION.md) | `WearableService` abstraction, mock → real SDK swap path, connection/retry state machine |
| [`docs/OFFLINE_SYNC.md`](docs/OFFLINE_SYNC.md) | Reading + cart/order offline queues, conflict resolution, retry/backoff, OS-level background sync, cache policy |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Every major technical decision and trade-off, backend and Flutter, plus explicit scope exclusions |

## Testing

```bash
cd api && npm test          # 55 tests — routing/business logic against a mocked db
cd flutter && flutter test  # 33 tests — offline sync engine correctness against fakes
```

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs both
suites on every push, plus `flutter analyze`, `flutter build apk --debug`,
and — the one thing neither test suite does — applies `schema.sql` and
`database/migrations/*.sql` against a real, ephemeral Postgres service
container, so a schema syntax error can't hide behind the backend's
mocked-`db` unit tests.

See each README's Tests section for what's covered and what deliberately isn't.
