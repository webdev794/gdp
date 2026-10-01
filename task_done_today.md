# Tasks done today — 30 Sep 2026

## Mobile apps (Flutter — `flutter_app/`)

- **Cards:** Account → Payments to list, add, set default and remove saved cards (same cards as the website). Checkout offers saved cards, "Add new card" and "Save this card for next time". The card form now has separate **Name / Card number / Expiry / CVC** fields — the old one-line box hid CVC on phones. Tested end to end with Stripe test mode (save card, pay with saved card, pay with new card, remove).
- **Delivery code pop-up:** when the rider asks for the handover code it pops up in the app (order screen checks every 5 s while out for delivery).
- **Rider rating:** "Leave Review" only after delivery; a refused rating now shows an error. Tested end to end (admin sees the comment, rider sees only stars).
- **Gift cards:** checkout shows how much of the card is used for this order and how much stays for the next one; the placed order shows "Gift card applied" and "Left on your gift card".
- **Android app built:** `tudee-app-release.apk`, downloadable from the live site after deploy (`/gdp/downloads/tudee-shopping-center.apk`).
- **iPhone app built** on GitHub's Mac machines (Actions → "Flutter iOS build"): a simulator build for Appetize and an unsigned `.ipa` for later signing.

## Website & store

- **Delivery code pop-up for the buyer** on every page while signed in, plus a browser notification (if allowed). Code is still emailed too.
- **Rider console:** "Resend a new code" (new code each time) and a hint that the code also pops up in the customer's app and website.
- **Gift cards:** checkout and order confirmation show the amount used and the balance left; the store now returns the remaining balance with the new order.
- **Footer:** demo app-store/social links kept for the client demo; footer lists all categories, centred note, no jump while loading.
- **Products:** demo products shown for the client demo; admin tools added to delete products without images and remove addresses outside the delivery area.
- **Deploy bundle:** now includes the Android app for direct download; new database tables are applied automatically on first load after upload.

## Setup / housekeeping

- Project switched to PHP at `D:\xampp\php84` (php.ini now loads its own extensions); old `D:\xampp8-2-12` deleted. MySQL start-up crash fixed (damaged `mysql.proxies_priv` restored from XAMPP's backup).
- iOS build workflow moved to the repo root (`.github/workflows/flutter_ios.yml`) so GitHub runs it.
- All project `.md` files updated; branch `TSC_v14` pushed to GitHub.

Open items: see `PENDING_TASKS.md`.
