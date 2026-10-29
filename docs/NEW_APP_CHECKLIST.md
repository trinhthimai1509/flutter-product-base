# New app checklist

From a fresh copy of this base to a store-ready product. Tick in order.

## 1. Identity

- [ ] Rename the Dart package (`name` in `pubspec.yaml`, then fix
      `package:flutter_project_base/` imports in `test/`).
- [ ] Set the Android `applicationId` and `namespace`
      (`android/app/build.gradle.kts`) and move `MainActivity.kt` to the new
      package. `com.example.*` is rejected by Play.
- [ ] Set the iOS bundle id (Xcode › Runner › Signing & Capabilities).
- [ ] App name: `APP_NAME` in `config/*.json`, `android:label` in
      `AndroidManifest.xml`, `CFBundleDisplayName` in `Info.plist`.
- [ ] Launcher icons and splash (e.g. `flutter_launcher_icons`).

## 2. Brand

- [ ] Seed color and font in `appThemeProvider` ([THEMING.md](THEMING.md)).
- [ ] Decide on dynamic color (keep, or override the provider).

## 3. Capabilities

- [ ] Go through [MODULE_CATALOG.md](MODULE_CATALOG.md) and **remove every
      package you will not ship**, including its native setup.
- [ ] Replace the onboarding pages, or set `onboardingEnabledProvider` to
      false.
- [ ] Delete the demo pages: `features/home` (showcase, capabilities) and
      the chat demo if unused.

## 4. Backend and config

- [ ] `API_BASE_URL` per environment; `USE_FAKE_BACKEND: false` once the API
      exists, and adapt `HttpAuthRemoteDataSource` to its shape.
- [ ] Override `chatProviderProvider` with your real chat provider (if chat
      is kept).
- [ ] `PRIVACY_POLICY_URL`, `APP_STORE_ID`.

## 5. Monetization (if kept)

- [ ] Real AdMob app ids and units, consent message, `app-ads.txt`
      ([MONETIZATION.md](MONETIZATION.md)).
- [ ] Pro product created and active in Play Console and App Store
      Connect; `PRO_PRODUCT_ID`; `USE_FAKE_BILLING: false` for production.
- [ ] Paywall copy matches what Pro unlocks.

## 6. Telemetry (if kept)

- [ ] `flutterfire configure`, pass the options in `_initTelemetry`,
      `ENABLE_FIREBASE: true`.
- [ ] Name your analytics events; check nothing personal is logged.

## 7. Notifications (if kept)

- [ ] Monochrome notification icon for Android.
- [ ] Localized channel names for every channel you create.

## 8. Release

- [ ] Release signing with a keystore **outside** the repo
      (`key.properties` is git-ignored).
- [ ] Data safety form (Play) and privacy nutrition labels (App Store).
      Each kept package adds entries: ads (device ids, advertising),
      Firebase (crash and usage data), billing (purchase history).
- [ ] `flutter analyze`, `flutter test`, package tests, release builds:
      the CI workflow runs them on every push.
