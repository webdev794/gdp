# Pending tasks

Work agreed with the client but not done yet. Newest at the top.

## Flutter app (`flutter_app/`) — make it use the real store backend

Today the app reads the catalogue, categories, store settings and login from the live API, but several customer flows are still simulated on the phone, so they never reach the website/admin. Goal: **everything dynamic — anything done in the app shows on the website account, and vice versa.**

- [x] **Orders are shared both ways.** An order placed in the app appears in the website account (and admin); an order placed on the website appears in the app's order history and tracking, with live status updates. No sample/local-only orders anywhere.
- [x] **No simulated data anywhere.** Remove every local fallback that fakes success (`MockDataService` / `MockAuthService` sample orders, threads, riders); on network errors show a clear retry message instead.

- [x] **Checkout places real orders.** `ApiService.createOrder` posts a made-up payload to `/api/checkout`; the backend checks out the *server-side cart* (`/api/cart/*`), so the call fails and the app silently creates a local "confirmed" order with an invented rider. Sync the cart to `/api/cart/items`, call `/api/checkout` with `address_id`/address + payment method, and show the real order (or the real error). Remove the local fallback order.
- [x] **Order history & tracking from the server.** Replace the hard-coded `_cachedOrders` sample orders (fake riders, e.g. "Alex Rivera") with `GET /api/orders`; order tracking should read the real status/rider/delivery code.
- [x] **Saved cards in the app.** Cards saved on the website are listed at checkout and charged the same way as the website (works in the web preview too). Adding a new card needs the phone app (Stripe card form).
- [ ] **Card payment on a real phone.** Card orders open the Stripe card form in a web view (`lib/screens/checkout/card_payment_screen.dart`); verify on an Android device with the test card. On the web preview only cash on delivery is offered.
- [x] **Receipt download.** Order tracking has a "Download bill" button (same PDF as the website; share/save sheet on phones, download on web).
- [x] **Estimated totals.** The basket shows the app's own fee/tax estimate; the store's real total is shown on the placed order. Use the server cart totals instead.
- [x] **Support chat shared with the website.** List threads with `GET /api/support/threads`, open a thread and poll for replies, send with `POST /api/support/threads/{id}/messages`. Remove the hard-coded sample threads and the local fallback thread.
- [x] **Gift cards issued by admin usable in the app.** Backend has `POST /api/gift-cards/check`; add a gift-card field at checkout (same flow as the website) and apply it to the order.
- [x] **Saved addresses & profile from the server.** Confirm `getAddresses/createAddress/...` hit `/api/addresses` with no local-only fallback, so addresses match the website.
- [x] **Sign in / register shared with the website.** Same accounts; fake OTP successes and the mock "John Doe" code login removed; sign-up and code login use the store's 6-digit email codes.
- [x] **Only admin-published products in the app.** The 21 built-in sample products/categories were removed; the app shows only the store catalogue (`/api/products`, `/api/categories`).
- [x] **Stock stays in sync everywhere.** Orders lower stock on the store (Admin shows it); the app reloads the catalogue after each order, shows OUT OF STOCK, and won't add more than the stock left.
- [ ] **Add a new card in the app.** Checkout should always offer "Add new card" next to saved cards, with a "save this card for next time" tick (same as the website). Also add/remove/default cards under Account → Payment methods (`/api/billing/setup-intent`, `/api/billing/payment-methods`). Currently a new card works only in the phone app (Stripe card form in a web view) and is hidden in the web preview; it is never saved to the account.
- [x] **Hide internal product fields in the app.** Product details now show only Category, Pack / Unit and Availability; removed product ID, SKU, category slug, warehouse stock, price range, created/updated dates and "Active in catalog". Product cards show the category (like the website) instead of the SKU code.
- [ ] **Verify delivery feedback end to end.** After delivery the customer rates the rider (stars + text) on website and app (`POST /api/orders/{id}/rider-review`); comment visible to admin only, stars in the rider console. Already built — test it with a real delivered order in the app and check Admin → Orders and the rider app.
- [x] **End & rate support chats in the app.** Chat screen has END CHAT (new store endpoint `POST /api/support/threads/{id}/close`; replying reopens) and a rating strip: RATE CHAT (1–5 + comment, once staff replied — same as website) or, for chats the rider started, RATE RIDER (stars to rider, comment admin-only).
- [x] **End chat on the website.** The website's End Chat button now uses the same endpoint (it used to post a message, which kept the chat open).
- [x] **Product reviews on website and app.** Reviews are written from an order (website: Order history → "Rate"; app: My Orders → order → "Rate this item"), once per item per order, once the order is confirmed: 1–5 stars + a few words. Product pages show reviews read-only with the average. Admin → **Reviews**: Hide/Show and Delete (abusive or wrong reviews). New table `product_reviews` (migration 2026_09_29_120000).
- [ ] **Deploy to live.** Bundle ready: `.tmp/deploy/gdp-cpanel-update.zip` (backend + website; applies new database tables once on first load, log in `storage/logs/deploy-migrate.log`). Needed for app reviews, demo-product hiding and contact settings on the live site.
- [x] **Delivery area check.** The app code you sent has an unfinished "Universal Mode" change (`LocationService.isDeliverable` always `true`, test-only ETA formula), so every location is treated as deliverable. Restore the real radius check (2 tests in `test/widget_test.dart` fail until then).
- [x] **Leftover admin/rider code.** `lib/screens/admin/*` and `lib/screens/rider/*` are not reachable from the customer app — remove them (and their `ApiService` admin/rider methods) once confirmed not needed.
- [ ] **iOS build pipeline.** The iOS GitHub workflow is at `flutter_app/.github/workflows/build_ios.yml`, but GitHub only runs workflows from the repo root `.github/workflows/`. Move/adapt it (working directory `flutter_app`) to build the iPhone app on a macOS runner.

Done: real checkout (cash on delivery + Stripe card), gift cards at checkout, order history/tracking from the store with live refresh, fake payment options (Apple Pay/Google Pay/PayPal) removed, admin/rider screens removed (backed up in `.tmp/flutter-backup/removed/`), website address in one place (`lib/config.dart`). Earlier: branding (logo from Store settings, app icon, favicon, "Tudee Shopping Center" name, address/contact in the side menu) and promo codes removed (no backend support).

## Website / backend

- [ ] **Hide demo products.** 54 of 55 products are the seeded demo products (e.g. Baby Lotion), all still active, so website and app both show them. Admin → Products → hide/delete demo products. The demo flag (commit 54fab53) must be deployed to the live site first.

- [ ] **Real contact email/phone.** Pages use `{email}` / `{phone}` from Admin → Store settings; currently `test@example.com` and no phone.
- [ ] **Footer app-store and social links** still point to placeholder `grocerly` URLs (Admin → Footer).
- [x] **Address spelling:** corrected "Kataka" to **Kakata** (capital of Margibi County) in the app and backend defaults.
- [ ] **Street name:** "Kakatown Highway" doesn't appear in maps/search; the main road is the **Monrovia–Kakata Highway**. Confirm the exact street with the client, then set it in Admin → Store settings (and redeploy the backend so the live site uses the new contact settings).
