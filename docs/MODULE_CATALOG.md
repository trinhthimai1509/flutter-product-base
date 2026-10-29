# Module catalog

The app in `lib/` is the foundation every product keeps (architecture, core
services, auth, settings, chat). Everything that pulls in a vendor SDK or is
only useful to some products lives in an **opt-in package** under
`packages/`. A product keeps the packages it needs and deletes the rest.

| Package | One line | Third-party weight |
| --- | --- | --- |
| [`pb_common`](#pb_common) | Logging contract, premium-status seam | none |
| [`pb_telemetry`](#pb_telemetry) | Analytics + crash-reporting contracts | none |
| [`pb_telemetry_firebase`](#pb_telemetry_firebase) | The only package that sees Firebase | firebase_core, firebase_analytics, firebase_crashlytics |
| [`pb_connectivity`](#pb_connectivity) | Online/offline hint | connectivity_plus |
| [`pb_onboarding`](#pb_onboarding) | Pager, skip/finish, persisted completion | none |
| [`pb_notifications`](#pb_notifications) | Channels, permission, local notifications, reminders | flutter_local_notifications, timezone |
| [`pb_review`](#pb_review) | In-app review as one call | in_app_review |
| [`pb_billing`](#pb_billing) | One lifetime Pro purchase; publishes `PremiumState` | in_app_purchase |
| [`pb_premium`](#pb_premium) | Paywall mechanism | (pb_billing) |
| [`pb_ads`](#pb_ads) | AdMob + UMP consent, throttled interstitials, rewarded, banner | google_mobile_ads |

## Rules every package follows

- **No Riverpod, no app imports.** Packages are plain Dart/Flutter. The app
  wires them in one file:
  [`lib/core/capabilities/capability_providers.dart`](../lib/core/capabilities/capability_providers.dart).
- **Contract + real implementation + fake.** Every capability has an
  interface, the plugin-backed class, and a `Fake…` used by tests, the demo
  and platforms without the SDK. No vendor type leaves its package.
- **Never throws for "not available".** Missing store, no consent, no
  Firebase config, unsupported platform: you get an outcome value or a no-op.
- **No strings owned by packages.** Widgets take labels (English defaults);
  the app passes localized text from its ARB files.
- **Logging** goes through `PbLogger` (`pb_common`). The app adapts its
  `AppLogger` once (`AppPbLogger`).
- Packages depend only on `pb_common` and (for `pb_premium`) `pb_billing`.
  No package depends on another capability package.

## Removing a package from an app

1. Delete its providers from `lib/core/capabilities/capability_providers.dart`
   and fix the compile errors that point at its UI (Settings rows,
   capabilities demo, `CapabilitiesScope`).
2. Remove it from `dependencies:` and `workspace:` in `pubspec.yaml`, then
   delete `packages/<name>`.
3. Remove its native setup (listed per package below).
4. `flutter pub get && flutter analyze && flutter test`.

Example: an app that sells nothing removes `pb_ads`, `pb_billing` and
`pb_premium`, and overrides `premiumStateProvider` with
`PremiumState.alwaysFree` (or deletes it).

---

## pb_common

**Purpose.** The only package the others depend on.

```dart
enum PbLogLevel { debug, info, warning, error }
abstract interface class PbLogger { void log(level, message, {tag, error, stackTrace}); }
class NoOpPbLogger implements PbLogger

enum PremiumStatus { unknown, premium, free }
abstract interface class PremiumState {
  PremiumStatus get current;
  Stream<PremiumStatus> get changes;
  static const PremiumState alwaysFree;
}
class FakePremiumState implements PremiumState   // tests, demo toggles
```

`PremiumState` is the seam between "something sells premium"
(`pb_billing`) and "something reacts to premium" (`pb_ads`, your features).

## pb_telemetry

**Purpose.** Analytics and crash-reporting **contracts** with no-op and
recording implementations. Makes Firebase optional.

```dart
class AnalyticsEvent { String name; Map<String, Object> params; }
abstract interface class Analytics { logScreenView(name); logEvent(event); setUserId(id?); }
abstract interface class CrashReporter { recordError(error, stack, {reason, fatal}); log(msg); setCustomKey(k, v); }
class Telemetry { Analytics analytics; CrashReporter crashReporter; String backendName; static const noOp; }
// NoOpAnalytics, NoOpCrashReporter, RecordingAnalytics, RecordingCrashReporter
```

**Wired in the app:** `telemetryProvider` (no-op by default),
`analyticsProvider`, `crashReporterProvider`. The router logs screen views
with route **patterns** (`/home/chat/:conversationId`), never ids.
`bootstrap()` forwards `FlutterError.onError` and
`PlatformDispatcher.onError` to the crash reporter.

**Do not** log emails, names, tokens or message content. Name your own
events; there is no taxonomy here.

## pb_telemetry_firebase

**Purpose.** Binds `Analytics`/`CrashReporter` to Firebase Analytics and
Crashlytics. The only package that imports Firebase.

```dart
final telemetry = await FirebaseTelemetry.initialize(
  options: DefaultFirebaseOptions.currentPlatform, // from flutterfire configure
  logger: AppPbLogger(logger),
);
```

Never throws: without Firebase configuration it logs and returns
`Telemetry.noOp`, so a fresh clone builds and runs.

**Enable it:**

1. `dart pub global activate flutterfire_cli && flutterfire configure`.
   This creates `lib/firebase_options.dart`, the platform config files and
   the Crashlytics Gradle plugin.
2. Pass `options: DefaultFirebaseOptions.currentPlatform` in
   `_initTelemetry` (`lib/app/bootstrap/bootstrap.dart`).
3. Set `"ENABLE_FIREBASE": true` in `config/<env>.json`.

Keep `google-services.json` / `GoogleService-Info.plist` out of git (already
ignored). Collection is off in debug builds by default
(`collectionEnabled: !kDebugMode`).

## pb_connectivity

**Purpose.** "You're offline" hint for the UI.

```dart
abstract interface class NetworkMonitor { Future<bool> isOnline(); Stream<bool> get onStatusChange; }
class ConnectivityPlusNetworkMonitor implements NetworkMonitor
class FakeNetworkMonitor implements NetworkMonitor   // set .online in tests
```

**Wired in the app:** `networkMonitorProvider`, `isOnlineProvider`, and the
`OfflineBanner` shown by `CapabilitiesScope`.

**Do not** use it to decide whether to send a request: a captive portal or a
dead backend still looks "online". Requests handle `NetworkFailure`
themselves (see ARCHITECTURE.md › Error handling).

## pb_onboarding

**Purpose.** A first-launch introduction *mechanism*. Ships no content.

```dart
abstract interface class OnboardingCompletionStore { bool get isCompleted; Future<void> setCompleted(bool); }
class OnboardingController extends ChangeNotifier {
  int pageIndex; bool isCompleted;
  next(pageCount); goToPage(i); skip(); finish(); reset();
}
class OnboardingPage { title; description; Widget? illustration; }
class OnboardingLabels { skip; next; finish; pageIndicator(current, total); }
class OnboardingView extends StatefulWidget { pages; controller; labels; }
```

**Wired in the app:** `features/onboarding/` stores the flag in
`KeyValueStore` (`onboarding.completed`). The router sends every location to
`/onboarding` until it is completed, then continues to sign-in or home.
Skipping counts as completing. Navigation reacts to `isCompleted`, which is
written to storage first, not to the button press.

**Turn it off:** override `onboardingEnabledProvider` with `false`, or delete
the feature and the package. **Replay:** Settings › Replay introduction.

## pb_notifications

**Purpose.** Device-local notifications: Android channels, the runtime
permission, show now, deferrable reminders, and taps.

```dart
class NotificationChannelSpec { id; name; description; importance; }
class LocalNotification { id; channelId; title; body; payload; }
class ReminderRequest { id; triggerAt; channelId; title; body; payload; }
abstract interface class LocalNotifications {
  initialize({channels}); requestPermission(); canPostNotifications();
  show(n); schedule(reminder); cancel(id);
  Stream<String?> get onOpened; Future<String?> launchPayload();
}
class PluginLocalNotifications implements LocalNotifications
class FakeLocalNotifications implements LocalNotifications
```

String ids are mapped to stable 31-bit ints (`notificationIntId`). The same
id replaces an existing notification/reminder.

**Wired in the app:** `localNotificationsProvider`. `CapabilitiesScope`
creates the localized "Reminders" channel after the first frame and routes
tapped payloads that are in-app paths (`/home/...`) through go_router;
anything else is ignored. Settings › Notifications asks for the permission
when the user turns the switch on, not at launch.

**Not included, deliberately:** push messaging (needs a backend and
credentials; the app's `PushNotificationService` interface is the seam) and
exact alarms (`SCHEDULE_EXACT_ALARM` needs its own policy review).
Reminders use `inexactAllowWhileIdle`, so the OS may deliver them a few
minutes late.

**Native setup (already done in this repo):**

- Android: core library desugaring in `android/app/build.gradle.kts`;
  `RECEIVE_BOOT_COMPLETED` and the two `ScheduledNotification*Receiver`s in
  `AndroidManifest.xml`. Use a monochrome small icon in a real app
  (`PluginLocalNotifications(androidIcon: '@drawable/ic_notification')`).
- iOS: `UNUserNotificationCenter.current().delegate` in `AppDelegate.swift`.

## pb_review

**Purpose.** Play / App Store in-app review as one call.

```dart
enum ReviewOutcome { completed, unavailable }
abstract interface class AppReviewManager { Future<ReviewOutcome> requestReview(); Future<bool> openStoreListing(); }
class InAppReviewManager implements AppReviewManager   // appStoreId for iOS store listing
class FakeAppReviewManager implements AppReviewManager
```

`completed` means the flow ran, **not** that a dialog appeared or a review
was written: the stores never say. Do not thank, reward or re-prompt on it.
There is no counter or automatic prompt; when to ask is the product's call.

**Wired in the app:** Settings › Rate this app (falls back to the store
page). Set `APP_STORE_ID` for iOS.

## pb_billing

**Purpose.** One lifetime non-consumable "Pro / remove ads" product via
`in_app_purchase` (Play Billing / StoreKit).

```dart
enum PurchaseState { unknown, notPurchased, pending, purchased }
class ProProduct { id; title; description; formattedPrice; }   // price localized by the store
sealed class PurchaseOutcome   // PurchaseSucceeded, PurchasePending, PurchaseAlreadyOwned, PurchaseCancelled, PurchaseFailed(BillingError)
enum RestoreOutcome { restored, nothingToRestore, failed }
class BillingConfig { proProductId; restoreTimeout; purchaseTimeout; restoreOnStart; }
abstract interface class BillingManager {
  ValueListenable<PurchaseState> purchaseState; ValueListenable<ProProduct?> proProduct;
  initialize(); purchasePro(); restorePurchases(); dispose();
}
class StoreBillingManager implements BillingManager   // over a StoreGateway (InAppPurchaseGateway)
class FakeBillingManager implements BillingManager
class BillingPremiumState implements PremiumState     // premium == owns Pro
abstract interface class OwnershipCache               // last known ownership (UX cache)
```

Behavior worth knowing:

- Every purchase is acknowledged (`completePurchase`). Play refunds
  unacknowledged purchases after 3 days.
- **Android** checks ownership silently at start-up (`restoreOnStart`).
  **iOS** does not, because a restore can prompt for the Apple ID password.
  The `OwnershipCache` (key-value store in the app) remembers Pro across
  launches; "Restore purchase" is the user-initiated check.
- "Nothing to restore" is inferred from store silence within
  `restoreTimeout`. A cached purchase is never downgraded by it, so a slow
  network cannot take Pro away from a paying user.
- **Not included:** subscriptions, tiers, consumables, server receipt
  verification. The cache is a UX convenience, not an entitlement check.

**Wired in the app:** `billingManagerProvider` uses `FakeBillingManager`
when `USE_FAKE_BILLING` is true or on web/desktop, otherwise
`StoreBillingManager` with `PRO_PRODUCT_ID`. `premiumStateProvider` feeds
`pb_ads`. See [MONETIZATION.md](MONETIZATION.md) for store setup.

## pb_premium

**Purpose.** A paywall *mechanism*: benefits list, store price, purchase,
restore, owned state, result messages. Ships no marketing copy.

```dart
class PremiumContent { title; subtitle; benefits; footnote; }
class PremiumLabels { buy(price); unavailable; restore; owned; pending; message(PremiumMessage); }
enum PremiumMessage { purchaseCompleted, purchasePending, alreadyOwned, restored, nothingToRestore, couldNotCheck, failed }
class PremiumController extends ChangeNotifier { PremiumUiState state; purchase(); restore(); dismissMessage(); }
class PremiumView extends StatefulWidget { content; controller; labels; header; }
```

A cancelled purchase shows nothing: the user backed out on purpose. The
price always comes from the store, already localized. Never format or
hardcode one.

**Wired in the app:** `features/premium/` (`/home/premium`), reached from
Settings and the capabilities demo.

## pb_ads

**Purpose.** Google Mobile Ads + User Messaging Platform behind a
product-facing API.

```dart
class AdUnitIds { android; ios; current; }
class AdsConfig { banner; interstitial; rewarded; adsEnabled; interstitialPolicy; testDeviceIds; AdsConfig.testAds(); }
class InterstitialPolicy { minInterval = 3 min; minQualifyingActions = 3; }
abstract interface class AdsController {
  ValueListenable<bool> adsAvailable; ValueListenable<bool> privacyOptionsRequired; String? bannerAdUnitId;
  initialize(); showPrivacyOptions(); showInterstitial(); showRewarded(); recordQualifyingAction(); dispose();
}
class GoogleAdsController implements AdsController   // takes a PremiumState
class FakeAdsController implements AdsController
class AppBannerAd extends StatelessWidget             // renders nothing when unavailable
// outcomes: InterstitialShown/NotAvailable/Throttled/Failed, RewardEarned/Dismissed/NotAvailable/Failed, ConsentOutcome
```

- Ads are available only when: enabled, mobile platform, consent allows
  ads, SDK started, and the user is **not** premium. Buying Pro removes them
  immediately (`PremiumState.changes`).
- Consent (UMP) is gathered in `initialize()`, which `CapabilitiesScope`
  calls after the first frame. Settings shows **Privacy options** when UMP
  says it is required (GDPR).
- Interstitials are throttled by `InterstitialFrequencyGovernor` (time since
  the last one and since start, plus qualifying actions). `Throttled` and
  `NotAvailable` mean "continue without an ad".
- Only `RewardEarned` means the user earned the reward.

**Wired in the app:** `adsConfigProvider` (Google **test** units, switched
by `ADS_ENABLED`) and `adsControllerProvider`.

**Native setup (already done with Google's test app ids):**

- Android: `manifestPlaceholders["admobApplicationId"]` in
  `android/app/build.gradle.kts`, and the `APPLICATION_ID` meta-data in
  `AndroidManifest.xml`. **Without an app id the SDK crashes at launch.**
- iOS: `GADApplicationIdentifier` and `SKAdNetworkItems` in `Info.plist`.

Replace both app ids and the ad units before a production release. See
[MONETIZATION.md](MONETIZATION.md).
