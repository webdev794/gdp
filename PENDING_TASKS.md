# Pending tasks

Work agreed with the client but not done yet. Newest at the top.

## Flutter app (`flutter_app/`) — make it use the real store backend

Today the app reads the catalogue, categories, store settings and login from the live API, but several customer flows are still simulated on the phone, so they never reach the website/admin. Goal: **everything dynamic — anything done in the app shows on the website account, and vice versa.**

- [x] **Orders are shared both ways.** An order placed in the app appears in the website account (and admin); an order placed on the website appears in the app's order history and tracking, with live status updates. No sample/local-only orders anywhere.
- [x] **No simulated data anywhere.** Remove every local fallback that fakes success (`MockDataService` / `MockAuthService` sample orders, threads, riders); on network errors show a clear retry message instead.

- [x] **Checkout places real orders.** `ApiService.createOrder` posts a made-up payload to `/api/checkout`; the backend checks out the *server-side cart* (`/api/cart/*`), so the call fails and the app silently creates a local "confirmed" order with an invented rider. Sync the cart to `/api/cart/items`, call `/api/checkout` with `address_id`/address + payment method, and show the real order (or the real error). Remove the local fallback order.
- [x] **Order history & tracking from the server.** Replace the hard-coded `_cachedOrders` sample orders (fake riders, e.g. "Alex Rivera") with `GET /api/orders`; order tracking should read the real status/rider/delivery code.
- [x] **Saved cards in the app.** Cards saved on the website are listed at checkout and charged the same way as the website (works in the web preview too). Adding a new card needs the phone app (Stripe card form).
- [x] **Card payment on a real phone.** Verified on the local store with Stripe test mode, using the app's exact calls: add card in Account (saved, listed, removed), checkout with a saved card (paid), checkout with a new card + "save for next time" (paid, card saved). Card form rendered at phone width shows Name, Card number, Expiry and CVC. Optional: a final tap-through on Appetize with the next APK.
- [x] **Receipt download.** Order tracking has a "Download bill" button (same PDF as the website; share/save sheet on phones, download on web).
- [x] **Estimated totals.** The basket shows the app's own fee/tax estimate; the store's real total is shown on the placed order. Use the server cart totals instead.
- [x] **Support chat shared with the website.** List threads with `GET /api/support/threads`, open a thread and poll for replies, send with `POST /api/support/threads/{id}/messages`. Remove the hard-coded sample threads and the local fallback thread.
- [x] **Gift cards issued by admin usable in the app.** Backend has `POST /api/gift-cards/check`; add a gift-card field at checkout (same flow as the website) and apply it to the order.
- [x] **Saved addresses & profile from the server.** Confirm `getAddresses/createAddress/...` hit `/api/addresses` with no local-only fallback, so addresses match the website.
- [x] **Sign in / register shared with the website.** Same accounts; fake OTP successes and the mock "John Doe" code login removed; sign-up and code login use the store's 6-digit email codes.
- [x] **Only admin-published products in the app.** The 21 built-in sample products/categories were removed; the app shows only the store catalogue (`/api/products`, `/api/categories`).
- [x] **Stock stays in sync everywhere.** Orders lower stock on the store (Admin shows it); the app reloads the catalogue after each order, shows OUT OF STOCK, and won't add more than the stock left.
- [x] **Add a new card in the app.** Account → Payments: list saved cards, Add new card, Make default, Remove (same cards as the website). Checkout: saved cards, "Add new card" with "Save this card for next time". Card form has separate Name / Card number / Expiry / CVC fields (the one-line Stripe box hid CVC on phones). Phone app only; the web preview explains instead.
- [x] **Hide internal product fields in the app.** Product details now show only Category, Pack / Unit and Availability; removed product ID, SKU, category slug, warehouse stock, price range, created/updated dates and "Active in catalog". Product cards show the category (like the website) instead of the SKU code.
- [x] **Delivery feedback (code checked).** After delivery the customer rates the rider (stars + text) on website and app; comment is admin-only, stars go to the rider. App fixed: "Leave Review" now shows only once the order is delivered (was shown as soon as a rider was assigned), a refused rating shows an error instead of fake success, and the comment box says only the store sees it.
- [x] **Test delivery feedback with a real delivered order.** Done on the local store: rating refused before delivery; after delivery the customer's stars + comment are saved; Admin → Orders shows both; the rider console counts the stars and does not show the comment. Test data removed.
- [x] **End & rate support chats in the app.** Chat screen has END CHAT (new store endpoint `POST /api/support/threads/{id}/close`; replying reopens) and a rating strip: RATE CHAT (1–5 + comment, once staff replied — same as website) or, for chats the rider started, RATE RIDER (stars to rider, comment admin-only).
- [x] **End chat on the website.** The website's End Chat button now uses the same endpoint (it used to post a message, which kept the chat open).
- [x] **Product reviews on website and app.** Reviews are written from an order (website: Order history → "Rate"; app: My Orders → order → "Rate this item"), once per item per order, once the order is confirmed: 1–5 stars + a few words. Product pages show reviews read-only with the average. Admin → **Reviews**: Hide/Show and Delete (abusive or wrong reviews). New table `product_reviews` (migration 2026_09_29_120000).
- [ ] **Deploy to live.** Bundle ready: `.tmp/deploy/gdp-cpanel-update.zip` (backend + website; applies new database tables once on first load, log in `storage/logs/deploy-migrate.log`). Needed for app reviews, demo-product hiding and contact settings on the live site.
- [x] **Delivery area check.** The app code you sent has an unfinished "Universal Mode" change (`LocationService.isDeliverable` always `true`, test-only ETA formula), so every location is treated as deliverable. Restore the real radius check (2 tests in `test/widget_test.dart` fail until then).
- [x] **Leftover admin/rider code.** `lib/screens/admin/*` and `lib/screens/rider/*` are not reachable from the customer app — remove them (and their `ApiService` admin/rider methods) once confirmed not needed.
- [x] **iOS build pipeline.** Moved to `.github/workflows/flutter_ios.yml` (repo root, runs in `flutter_app/`, Flutter 3.47.5, output `TudeeShoppingCenter.ipa`). Runs on push to `main` or manually from GitHub → Actions once the file is on `main`.
- [x] **Delivery code pops up for the buyer.** When the rider taps "send code" the store makes the 6-digit code (and emails it). App: order screen checks every 5 s while out for delivery and shows the code in a big pop-up. Website: a watcher on every page (while signed in) shows the same pop-up and a browser notification (if allowed).
- [ ] **Signed iPhone build** (needs client): Apple Developer account (US$99/year), bundle ID, signing certificate + provisioning profile as GitHub secrets, then TestFlight / App Store upload.
- [ ] **Play Store release** (needs client): real app ID instead of `com.example.supermarket` (e.g. `com.tudee.shop`), a private release signing key (keystore) instead of the debug key, Play Console account (US$25 one-time), store listing and privacy policy.

Done: real checkout (cash on delivery + Stripe card), gift cards at checkout, order history/tracking from the store with live refresh, fake payment options (Apple Pay/Google Pay/PayPal) removed, admin/rider screens removed (backed up in `.tmp/flutter-backup/removed/`), website address in one place (`lib/config.dart`). Earlier: branding (logo from Store settings, app icon, favicon, "Tudee Shopping Center" name, address/contact in the side menu) and promo codes removed (no backend support).

## Website / backend

- [x] **Hide demo products.** Hidden locally with Admin's demo "hide" action (54 hidden; only Organic Lemon active; reversible via "show"). On the live site: after uploading the deploy bundle, Admin → Products → hide demo products.

- [ ] **Real contact email/phone.** Pages use `{email}` / `{phone}` from Admin → Store settings; currently `test@example.com` and no phone.
- [x] **Footer app-store and social links.** The 7 fake "grocerly" links are cleared (local settings + defaults for new installs); empty links are hidden on the website. On the live site clear them in Admin → Footer. Add the real links when the client sends them.
- [x] **Address spelling:** corrected "Kataka" to **Kakata** (capital of Margibi County) in the app and backend defaults.
- [ ] **Street name:** "Kakatown Highway" doesn't appear in maps/search; the main road is the **Monrovia–Kakata Highway**. Confirm the exact street with the client, then set it in Admin → Store settings (and redeploy the backend so the live site uses the new contact settings).
