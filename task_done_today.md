# Tasks done today — 29 Sep 2026

## Website & store (backend)

- **Rebrand:** Grocerly → **TUDEE SHOPPING CENTER**; demo-store wording replaced with real-store text in pages and footer.
- **Store settings:** contact email, phone and address editable in Admin → Store settings and filled into pages automatically. Address set to Liberia; spelling corrected to **Kakata**.
- **Demo products:** products can be flagged as demo, with bulk hide / show / delete in Admin. Hidden products disappear from both website and app.
- **Product reviews:** customers rate each item from their order (1–5 stars + a few words), once per item per order, once the order is confirmed. Product pages show reviews and the average rating. New Admin → **Reviews** tab to hide/show or delete abusive or wrong reviews.
- **Support chat:** new "end chat" for customers — marks the chat resolved (replying reopens it). The website's End Chat button now uses it.
- **Deploy bundle:** `.tmp/deploy/gdp-cpanel-update.zip` now also applies new database tables automatically on the first page load after upload (no Terminal needed; existing data kept).

## Flutter mobile app (`flutter_app/`)

- **Set up:** Flutter, Java and Android SDK installed on D:, app added to the project, VS Code configured (F5 runs it in Chrome), live preview at http://127.0.0.1:8090.
- **Branding:** TUDEE logo, app icon, favicon, store name and address from Store settings.
- **One website address** for the whole app (`lib/config.dart`), easy to switch to the client's domain.
- **Shared with the website (same account, same data):**
  - Sign in / register (incl. email codes), account refreshed at start.
  - Real checkout: cash on delivery, **saved cards from the website**, new card (phone app), gift cards.
  - Orders: history, live tracking, bill (PDF) download — website and app orders show in both.
  - Support chat: same conversations both ways, End chat, rate chat / rate rider.
  - Saved addresses; choose/change address at checkout.
  - Product reviews (rate from My Orders).
- **Only real store data:** removed sample products, categories, addresses, banners, orders, chats, riders, promo codes and fake payment options (Apple Pay / Google Pay / PayPal). Admin/rider screens removed from the customer app.
- **Matches the store rules:** delivery radius, fees and tax from Admin settings, stock limits and "OUT OF STOCK", catalogue reloads after each order.
- **Looks like the website:** whole product images (not cropped), same icons for products without images, category instead of internal codes; internal fields (SKU, slug, stock count, dates) hidden from customers.

## Fixes along the way

- Removed a GitHub access token from the app's old project settings (kept out of the repo). **Revoke it on GitHub.**
- Fixed sign-in bugs: fake "code verified" success, a mock "John Doe" login, wrong 4-digit code wording.
- Freed disk space on D: (VS Code/Flutter crashes were caused by D: being full).

## Still open

See `PENDING_TASKS.md` — main items: upload the deploy bundle to the live site, add a new card in the app, verify delivery feedback with a real order, Android APK build, iOS build pipeline, real contact email/phone and footer links.
