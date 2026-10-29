# Monetization: ads, Pro purchase, paywall

How `pb_ads`, `pb_billing` and `pb_premium` fit together, and what to set up
in the stores. Package APIs are in [MODULE_CATALOG.md](MODULE_CATALOG.md).

```
pb_billing ──► BillingPremiumState ──► premiumStateProvider ──► pb_ads (hides ads)
     │                                                      └──► your features (unlock)
     └──► pb_premium (paywall UI)
```

Premium means exactly one thing here: **the user owns the lifetime Pro
product.** Subscriptions and tiers are not supported.

## Choosing a combination

| Product | Packages | Notes |
| --- | --- | --- |
| Free, no ads | none of the three | Delete them; override `premiumStateProvider` with `PremiumState.alwaysFree` or remove it |
| Ads only | `pb_ads` | Override `premiumStateProvider` with `PremiumState.alwaysFree` |
| Paid unlock, no ads | `pb_billing` + `pb_premium` | Features read `premiumStateProvider` |
| Ads + "remove ads" purchase | all three | The default wiring in this repo |

## Environments

| Key | development / staging | production |
| --- | --- | --- |
| `ADS_ENABLED` | `true` (Google **test** units) | `false` until you add real units |
| `USE_FAKE_BILLING` | `true` (in-process fake, purchases always succeed) | `false` (real store) |
| `PRO_PRODUCT_ID` | `pro` | your product id |

Never ship Google test units in production, and never click your own real
ads: AdMob suspends accounts for it. Use `AdsConfig.testDeviceIds` to see
test ads on your devices with real units.

## Ads setup (AdMob)

1. Create the app and three ad units (banner, interstitial, rewarded) in
   AdMob for each platform.
2. Replace the **app ids**:
   - Android: `manifestPlaceholders["admobApplicationId"]` in
     `android/app/build.gradle.kts` (use a different value per build type
     if you like; every build type needs one).
   - iOS: `GADApplicationIdentifier` in `ios/Runner/Info.plist`, and the
     full `SKAdNetworkItems` list from Google's docs.
3. Return your units from `adsConfigProvider` for production, keeping
   `AdsConfig.testAds()` for every other environment.
4. Configure the GDPR message (and US state messages if needed) in AdMob ›
   Privacy & messaging. UMP shows it from `initialize()`. Settings shows
   *Privacy options* when UMP says the user must be able to change consent.
5. Publish `app-ads.txt` on your developer website.

**Where to show ads** is a product decision. Call
`recordQualifyingAction()` when the user finishes a unit of value (level,
article, task), and `showInterstitial()` at natural breaks. The
`InterstitialPolicy` (default: 3 minutes and 3 actions) protects users and
your store rating.

## Pro purchase setup

**Google Play**

1. Upload a build signed with your release key to an internal testing track
   (billing does not work with debug-signed builds that Play has not seen).
2. Monetize › Products › In-app products › create `PRO_PRODUCT_ID` as a
   one-time product, and activate it.
3. Add license testers (Setup › License testing) to buy without being
   charged.

**App Store**

1. App Store Connect › your app › In-App Purchases › create a
   **Non-Consumable** with the same product id.
2. Complete the agreements, tax and banking forms (products stay
   unavailable until you do).
3. Test with a Sandbox account or a StoreKit configuration file in Xcode.

Then set `USE_FAKE_BILLING` to `false` and `PRO_PRODUCT_ID` in the config of
the environment you are testing.

**Restore.** Android re-checks ownership at every launch. iOS relies on the
ownership cache plus the user tapping *Restore purchase* (store guidelines
require that button; it is on the paywall).

**Server verification** is not included. If Pro unlocks something valuable
(content, credits), verify purchases on your backend and treat the
ownership cache as a hint only.

## Paywall copy

`features/premium/presentation/premium_page.dart` passes `PremiumContent`
from the ARB files (`premiumHeadline`, `premiumBenefit…`). Promise only
what Pro actually unlocks in your app, and keep "one-time purchase" in the
footnote: stores reject paywalls that misdescribe the billing model.
