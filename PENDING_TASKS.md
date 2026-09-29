# Pending tasks

Work agreed with the client but not done yet. Newest at the top.

## Flutter app (`flutter_app/`) — make it use the real store backend

Today the app reads the catalogue, categories, store settings and login from the live API, but several customer flows are still simulated on the phone, so they never reach the website/admin. Goal: **everything dynamic — anything done in the app shows on the website account, and vice versa.**

- [x] **Orders are shared both ways.** An order placed in the app appears in the website account (and admin); an order placed on the website appears in the app's order history and tracking, with live status updates. No sample/local-only orders anywhere.
- [ ] **No simulated data anywhere.** Remove every local fallback that fakes success (`MockDataService` / `MockAuthService` sample orders, threads, riders); on network errors show a clear retry message instead.

- [x] **Checkout places real orders.** `ApiService.createOrder` posts a made-up payload to `/api/checkout`; the backend checks out the *server-side cart* (`/api/cart/*`), so the call fails and the app silently creates a local "confirmed" order with an invented rider. Sync the cart to `/api/cart/items`, call `/api/checkout` with `address_id`/address + payment method, and show the real order (or the real error). Remove the local fallback order.
- [x] **Order history & tracking from the server.** Replace the hard-coded `_cachedOrders` sample orders (fake riders, e.g. "Alex Rivera") with `GET /api/orders`; order tracking should read the real status/rider/delivery code.
- [ ] **Card payment on a real phone.** Card orders open the Stripe card form in a web view (`lib/screens/checkout/card_payment_screen.dart`); verify on an Android device with the test card. On the web preview only cash on delivery is offered.
- [ ] **Receipt download.** The fake "receipt generated" button was removed from order tracking; add a real download of `GET /api/orders/{id}/receipt` (PDF).
- [ ] **Estimated totals.** The basket shows the app's own fee/tax estimate; the store's real total is shown on the placed order. Use the server cart totals instead.
- [ ] **Support chat shared with the website.** List threads with `GET /api/support/threads`, open a thread and poll for replies, send with `POST /api/support/threads/{id}/messages`. Remove the hard-coded sample threads and the local fallback thread.
- [x] **Gift cards issued by admin usable in the app.** Backend has `POST /api/gift-cards/check`; add a gift-card field at checkout (same flow as the website) and apply it to the order.
- [ ] **Saved addresses & profile from the server.** Confirm `getAddresses/createAddress/...` hit `/api/addresses` with no local-only fallback, so addresses match the website.
- [ ] **Product reviews visible on website and app.** Reviews are currently stored only on the phone (`ReviewService`, SharedPreferences). Needs: backend table + endpoints (post a review for a delivered product, list approved reviews per product), admin moderation, website product page display, app switched to the API.
- [ ] **Delivery area check.** The app code you sent has an unfinished "Universal Mode" change (`LocationService.isDeliverable` always `true`, test-only ETA formula), so every location is treated as deliverable. Restore the real radius check (2 tests in `test/widget_test.dart` fail until then).
- [x] **Leftover admin/rider code.** `lib/screens/admin/*` and `lib/screens/rider/*` are not reachable from the customer app — remove them (and their `ApiService` admin/rider methods) once confirmed not needed.
- [ ] **iOS build pipeline.** The iOS GitHub workflow is at `flutter_app/.github/workflows/build_ios.yml`, but GitHub only runs workflows from the repo root `.github/workflows/`. Move/adapt it (working directory `flutter_app`) to build the iPhone app on a macOS runner.

Done: real checkout (cash on delivery + Stripe card), gift cards at checkout, order history/tracking from the store with live refresh, fake payment options (Apple Pay/Google Pay/PayPal) removed, admin/rider screens removed (backed up in `.tmp/flutter-backup/removed/`), website address in one place (`lib/config.dart`). Earlier: branding (logo from Store settings, app icon, favicon, "Tudee Shopping Center" name, address/contact in the side menu) and promo codes removed (no backend support).

## Website / backend

- [ ] **Real contact email/phone.** Pages use `{email}` / `{phone}` from Admin → Store settings; currently `test@example.com` and no phone.
- [ ] **Footer app-store and social links** still point to placeholder `grocerly` URLs (Admin → Footer).
- [ ] **Address spelling:** "Kataka" vs the usual "Kakata" (Margibi County) — confirm with client.
