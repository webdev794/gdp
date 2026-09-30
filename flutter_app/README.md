# Tudee Shopping Center — mobile app

Flutter customer app for Android and iPhone. It talks to the store API (the same one the website uses), so accounts, orders, cards, addresses, support chats, gift cards and reviews are shared with the website.

- Website/API address: `lib/config.dart` (`AppConfig.siteUrl`), or `--dart-define=SITE_URL=https://…` at build time.
- API calls: `lib/services/api_service.dart` (reviews: `review_service.dart`, fees: `checkout_fees.dart`, branding: `branding_service.dart`).
- Card entry: Stripe Elements in a web view — `lib/screens/checkout/stripe_card_form.dart` (used for paying and for saving a card).

## Build and run (Windows, tools on D:)

```cmd
set JAVA_HOME=D:\Java\jdk17
set ANDROID_HOME=D:\Android\Sdk
set PUB_CACHE=D:\PubCache
set GRADLE_USER_HOME=D:\Gradle
cd /d D:\gdp\flutter_app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome              # browser preview
flutter build apk --release        # Android: build\app\outputs\flutter-apk\app-release.apk
```

## iPhone

Built on GitHub Actions (`.github/workflows/flutter_ios.yml` at the repo root). Download from the run's **Artifacts**:

- `TudeeShoppingCenter-iOS-simulator` — upload to Appetize (iOS) to test in a browser.
- `TudeeShoppingCenter-iOS` — unsigned `.ipa`; needs an Apple Developer account to sign for real iPhones / TestFlight.

## Before publishing to the stores

Change the app ID from `com.example.supermarket` (Android `android/app/build.gradle.kts`, iOS bundle ID), add a release signing key, and set up the Play Console / App Store Connect listings.
