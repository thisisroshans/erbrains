# API / UI-state gaps

Found while mapping the 11 design screens (`Wearable App Screens.dc.html`) onto
the existing backend (`../api`). Referenced from `// see docs/API_GAPS.md`
comments throughout the Flutter source. None of these block the current
scaffold — the app either works around them client-side or clearly labels the
UI as not-yet-backed — but they're worth resolving before this goes further.

## Confirmed gaps (need a backend or schema change)

1. **Cart has no decrement/remove endpoint.** `POST /cart` only upserts via
   `ON CONFLICT ... quantity = quantity + $delta`. The Cart screen's `-`
   stepper has nothing to call — currently disabled with an explanatory
   snackbar (`lib/features/cart/cart_screen.dart`). Needs something like
   `PATCH /cart/:id { quantity }` or `DELETE /cart/:id`.

2. **Products have no image column.** `products` table is
   `id, name, description, price, stock, created_at`. Every product/cart/order
   line in the design shows a photo; the app renders a placeholder tile
   (`ProductImagePlaceholder`) everywhere instead. Needs an `image_url`
   column (or a fixed asset-naming convention the client can derive from
   `product.id`/`name`).

3. **`GET /orders` has no item count.** The Order History screen wants
   "2 items · $87.00"; the backend would need to `COUNT` `order_items` per
   order (a join/subquery) or accept an extra round-trip per order to
   `order_items`. `Order.itemCount` is nullable client-side and the row
   just omits the count when it's null.

4. **`users` has no display name.** Login only collects email/password;
   `AppUser.displayName`/`.initials` are derived from the email's local part
   (`jordan` → "Jordan", "J"). Fine for a scaffold, but the Profile screen's
   avatar/name will look derived-not-real. Needs a `name` column + a field
   on `POST /auth/login` (or a follow-up `PATCH /users/me`).

5. **No auth middleware.** Every route trusts whatever `userId` is passed in
   the body/query string — the bearer token the client sends is never
   verified server-side. Not a blocker for a take-home-scale app talking to
   its own backend, but worth flagging: right now any client can read/write
   any other user's cart, orders, or health data just by knowing their uuid.

## Scope decisions (no backend change needed — just documenting the call made)

6. **Battery / connection status are device-layer, not API.** The PDF's
   architecture puts these in the wearable simulation, not the health-data
   API — `WearableSnapshot.batteryPercent` and `WearableConnectionState`
   never touch the backend. This isn't a gap so much as confirming the
   dashboard's live tiles are local-only by design.

7. **Shipping cost / address / payment are UI-only.** `orders` has no
   `shipping_address` or payment columns, and the PDF explicitly doesn't
   require a real payment gateway. The Checkout screen collects
   name/address into text fields that are never sent — `POST /orders` only
   takes `{ userId }`. The Cart/Checkout screens show a flat $5 shipping
   line for visual parity with the design, but it's never added to what
   the backend actually charges (`total_amount` = subtotal only). If real
   shipping pricing matters later, `orders` needs a `shipping_amount`
   column and the total calc needs to include it.

8. **Order status is always `completed`.** There's no shipped/delivered
   lifecycle in the backend (nor a requirement for one in the PDF). The
   design mocks Shipped/Processing tags; Order History only ever renders
   what the API returns, which today is always "Completed".

9. **`health_summary`'s SpO₂ has no min, only avg.** The History screen's
   SpO₂ card wants "Avg 97% · Min 95%"; `GET /health/summary` returns
   `avg_spo2` but not `min_spo2`. `HealthSummaryPoint` only exposes `avgSpo2`
   today — the History screen shows just the average rather than fabricate
   a min. A one-line `MIN(spo2) AS min_spo2` addition to the summary query
   would close this.

10. **The mock's "client-generated id" dedupe note doesn't match the real
    backend.** Screen 05's copy says "each reading carries a client-generated
    id — the backend rejects duplicates on retry," but the actual
    implementation dedupes on the `(device_id, reading_timestamp)` unique
    constraint, not a separate id column. Functionally equivalent for
    idempotent retries, just a documentation nuance — `HealthReading.localId`
    exists purely as a local queue/UI identifier and never leaves the device.

## Explicitly paused

- **Local storage + offline sync queue** (SQLite-backed reading store,
  connectivity-triggered flush to `POST /health/readings`) — paused per
  instruction mid-build. `lib/features/sync/sync_status_screen.dart` renders
  the screen 05 shell with an honest empty state instead of fabricated queue
  data. `sqflite`/`connectivity_plus` were removed from `pubspec.yaml` again
  since nothing uses them yet — re-add when this resumes.
