# Pending tasks

Only what is still open. Finished work is listed in `work_done.md` (features) and `task_done_today.md` (latest day).

## Waiting on you

- [ ] **Deploy to live.** Upload `.tmp/deploy/gdp-cpanel-update.zip` (backend + website + Android app) to `public_html/` and extract. New database tables are added automatically on the first page load (log: `storage/logs/deploy-migrate.log`). Needed on the live site for: product reviews, End chat, delivery-code pop-up, gift-card split, demo-product hiding, contact settings and the Android download link.
- [ ] **After deploying, in Admin (live site):** Products → **Delete products without images** (removes icon-only products; ones on past orders are hidden) and hide demo products; Stores → **Remove saved addresses outside delivery area** (removes Mohali etc. and addresses with no map pin; store radius is 5 km); Pages → Footer → clear the placeholder "grocerly" links. (Already done on the local store.)
- [ ] **Try the apps once:** Android from `https://testcaresortwork.co.in/gdp/downloads/tudee-shopping-center.apk` (after deploy) or Appetize; iPhone simulator build on Appetize (GitHub → Actions → Flutter iOS build → Artifacts → `TudeeShoppingCenter-iOS-simulator`).

## Waiting on the client

- [ ] **Real contact email and phone.** Admin → Store settings (pages fill `{email}` / `{phone}` automatically). Currently `test@example.com` and no phone.
- [ ] **Exact street name.** "Kakatown Highway" doesn't appear in maps; the main road is the **Monrovia–Kakata Highway**. Confirm, then set it in Admin → Store settings.
- [ ] **Real footer links.** App Store / Play Store and social-media URLs (Admin → Pages → Footer).
- [ ] **iPhone app on real phones (TestFlight).** Needs an Apple Developer account (US$99/year) and an App Store Connect API key; then signing is added to `.github/workflows/flutter_ios.yml` so every build goes to TestFlight.
- [ ] **Play Store release.** Real app ID instead of `com.example.supermarket` (e.g. `com.tudee.shop`), a private release signing key (keystore) instead of the debug key, Play Console account (US$25 one-time), store listing and privacy policy.

## Housekeeping

- [ ] **Revoke the old GitHub token** (`ghp_KaVO…`, account `caresortsolutions515-afk`) that was in the Flutter app's original project settings.
