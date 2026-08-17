# API / UI-state gaps

Found while mapping the 11 design screens (`Wearable App Screens.dc.html`) onto
the backend (`../api`). Referenced from `// see docs/API_GAPS.md` comments in
the Flutter source where still relevant.

## Resolved

These were closed on the backend and wired into the Flutter client:

1. **Cart decrement/remove** — `PATCH /cart/:id` (set exact quantity) and
   `DELETE /cart/:id` now exist. `CartController.setQuantity`/`.removeItem`
   call them; the Cart screen's `-` stepper actually removes the line item
   at quantity 1 instead of showing a "not supported" snackbar.
2. **Product images** — `products.image_url` (seeded with placeholder
   images — no real product photography exists). `ProductImagePlaceholder`
   renders the real image when present, falling back to the icon tile on
   null/load failure. `GET /cart` was also updated to select it so cart
   line items show images too.
3. **Order item counts** — `GET /orders` now returns `item_count` per
   order (a `COUNT` subquery over `order_items`). `Order.itemCount` is a
   required, non-nullable field again.
4. **User display names** — `users.name` column; `POST /auth/login`
   accepts an optional `name` on creation and returns it. `AppUser.name`
   is persisted in `TokenStorage` and restored on relaunch;
   `AppUser.displayName` prefers it over the email-derived fallback.
5. **Auth middleware** — every route except `/auth/login` and the two
   `GET /products` routes now requires a valid bearer token via
   `api/middleware/auth.js`, and each handler verifies the token's
   `userId` matches whatever `userId` the request acts on (`ensureSelf`).
   The Flutter `ApiClient` was already attaching the token to every
   request, so this required no client-side change beyond handling the
   `401`/`403` it can now actually return.
6. **SpO₂ summary had no min** — `GET /health/summary` now returns
   `min_spo2` alongside `avg_spo2`. `HealthSummaryPoint.minSpo2` is a
   required field; the History screen shows "Avg X% · Min Y%" from real
   data instead of just the average.
7. **No offline storage or sync queue** — was the one item under
   "Explicitly paused" below; now built. See
   [docs/OFFLINE_SYNC.md](OFFLINE_SYNC.md) for the full design. Short
   version: every wearable reading is written to a local Hive store the
   instant it's captured (this is what History reads from — fully
   offline-capable), and a `SyncManager` drains pending readings to
   `POST /health/readings` in batches with per-reading retry/backoff,
   triggered by connectivity changes, app launch/resume, and a periodic
   timer. Surfaced via a sync banner on every screen.

## Still open — scope decisions, not backend defects

- **Battery / connection status are device-layer, not API.** The PDF's
  architecture puts these in the wearable simulation, not the health-data
  API — `WearableSnapshot.batteryPercent` and `WearableConnectionState`
  never touch the backend by design.
- **Shipping cost / address / payment are UI-only.** `orders` still has no
  `shipping_address` or payment columns, and the PDF explicitly doesn't
  require a real payment gateway. Checkout collects name/address into text
  fields that are never sent — `POST /orders` only takes `{ userId }`. The
  Cart/Checkout screens show a flat $5 shipping line for visual parity
  with the design, but it's never added to what the backend actually
  charges (`total_amount` = subtotal only).
- **Order status is always `completed`.** No shipped/delivered lifecycle
  exists (nor is one required by the PDF). Order History only ever
  renders what the API returns, which today is always "Completed".
- **The mock's "client-generated id" dedupe note doesn't match the real
  backend.** Screen 05's copy says "each reading carries a client-generated
  id — the backend rejects duplicates on retry," but the actual
  implementation (now built — see docs/OFFLINE_SYNC.md) dedupes on the
  `(device_id, reading_timestamp)` unique constraint, not a separate id
  column. Functionally equivalent for idempotent retries, just a
  documentation nuance — `HealthReading.localId` exists purely as the
  local Hive key/queue identifier and never leaves the device.
