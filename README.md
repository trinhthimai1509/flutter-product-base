# Flutter Product Base

[![CI](https://github.com/trinhthimai1509/flutter-product-base/actions/workflows/ci.yml/badge.svg)](https://github.com/trinhthimai1509/flutter-product-base/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A reusable, production-minded **foundation** for Flutter apps: enterprise,
booking, fintech, SaaS, support desks, AI chat (remote or on-device) and
user-to-user chat. It is not a product. It is the layer you start every
product from.

- **Runs with no server.** A built-in fake backend lets you sign in, chat and
  explore every module right after cloning.
- **Clean, enforced architecture.** Feature-first Clean Architecture with
  Riverpod, strict lints, and written rules for humans and AI agents
  ([AGENTS.md](AGENTS.md)).
- **Opt-in capability packages.** Ads with consent, a Pro purchase and
  paywall, Firebase telemetry, local notifications, in-app review,
  onboarding and connectivity live in `packages/`. Keep what your product
  needs, delete the rest.
- **No vendor lock-in.** Every capability is an interface with a real
  implementation and a fake; no SDK type leaks into the app.
- **Tested.** App and package tests, `flutter analyze` clean, CI on every
  push.

## Contents

- [What's included](#whats-included)
- [Capability packages](#capability-packages)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Environments](#environments)
- [Test, analyze, format, build](#test-analyze-format-build)
- [Project structure](#project-structure)
- [Starting a new app from this base](#starting-a-new-app-from-this-base)
- [Adding a language](#adding-a-language)
- [Documentation](#documentation)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## What's included

| Area | What's included |
| --- | --- |
| Architecture | Feature-first Clean Architecture, Riverpod 3 for state + DI (no codegen) |
| Environments | development / staging / production via `--dart-define-from-file` |
| Networking | Dio client, bearer-token injection, single refresh on 401, error normalization, redacted logging |
| Errors | Sealed `AppFailure` hierarchy + `Result<T>`; UI never sees library exceptions |
| Storage | `KeyValueStore` (preferences) and `SecureStore` (tokens) abstractions |
| Auth | Guest + email/password, session restore, token refresh, OAuth extension point |
| Navigation | go_router with auth guard, guest-only routes, deep-link preservation, 404 page |
| Design system | Material 3 theme from a seed color, light/dark/system, tokens, buttons, inputs, states, dialogs, snackbars, responsive helpers |
| Localization | ARB-based, English + Vietnamese |
| Settings | Theme, dynamic color, language, notifications switch, Pro, privacy options, rate/share, privacy policy, sign out |
| Profile | Minimal, extensible `UserProfile` |
| Files | Vendor-neutral `Attachment` model, MIME helpers, uploader/picker interfaces |
| Notifications | In-app bus; local notifications and reminders via `pb_notifications`; push interface |
| **Chat** | Generic chat engine: conversations, messages, participants, attachments, replies, statuses, typing, pagination, retry, streaming; replaceable providers (Mock, Remote AI, Local AI, Realtime) |
| Onboarding | First-launch pager with skip/finish, persisted, router-driven |
| Tests | Unit, widget and app smoke tests for the app and every package |
| CI | GitHub Actions: format, analyze, app + package tests, debug APK |

What is deliberately **not** included: code generation (freezed,
json_serializable), a database, file/image pickers, push messaging,
subscriptions, or any LLM SDK. These are extension points you fill in per
app. The status of every module (DONE / PARTIAL / NOT IMPLEMENTED) is
tracked in [docs/REPORT.md](docs/REPORT.md).

## Capability packages

Each package is plain Dart/Flutter (no Riverpod, no app imports) with a
contract, a plugin-backed implementation and a fake. The app wires them in
[`lib/core/capabilities/capability_providers.dart`](lib/core/capabilities/capability_providers.dart).

| Package | What it does | Vendor SDK |
| --- | --- | --- |
| `pb_common` | Logging contract, `PremiumState` seam | — |
| `pb_telemetry` | Analytics + crash-reporting contracts, no-op/recording | — |
| `pb_telemetry_firebase` | Firebase Analytics + Crashlytics, no-op fallback | Firebase |
| `pb_connectivity` | Online/offline hint, offline banner | connectivity_plus |
| `pb_onboarding` | Pager, skip/finish, persisted completion | — |
| `pb_notifications` | Channels, permission, local notifications, reminders | flutter_local_notifications |
| `pb_review` | In-app review as one call | in_app_review |
| `pb_billing` | One lifetime Pro purchase, restore, `PremiumState` | in_app_purchase |
| `pb_premium` | Paywall: benefits, store price, purchase, restore | — |
| `pb_ads` | AdMob + UMP consent, throttled interstitials, rewarded, banner | google_mobile_ads |

APIs, wiring, native setup and how to remove a package:
[docs/MODULE_CATALOG.md](docs/MODULE_CATALOG.md). Ads and purchases:
[docs/MONETIZATION.md](docs/MONETIZATION.md).

## Requirements

- Flutter **3.47+** (stable), Dart **3.13+** (see `environment` in `pubspec.yaml`)
- Android SDK for Android builds; Xcode on macOS for iOS builds
- Platforms in the repo: Android, iOS, Web

## Quick start

```bash
git clone https://github.com/trinhthimai1509/flutter-product-base.git
cd flutter-product-base
flutter pub get
flutter run --dart-define-from-file=config/development.json
```

The development config uses an **in-process fake backend**
(`USE_FAKE_BACKEND=true`), so the app runs with no server. Sign in with any
email and a password of 6+ characters, or tap **Continue as guest**.

Demo flow: **Splash → Onboarding (first launch) → Sign in → Home → Chat
demo / Foundation showcase / Capabilities / Profile / Settings**.

The **Capabilities** page exercises every package: connectivity, telemetry
events, notification permission and a 10-second reminder, in-app review,
test ads (banner, interstitial, rewarded), the Pro paywall and onboarding
replay. In development, ads use Google test units and billing uses an
in-process fake, so everything works without store accounts.

In the chat demo:

- **Mock Assistant**: streamed AI-style answers, a stop button while
  generating, and *Regenerate*. End a message with `?` to see citations.
- **Customer Support**: human-agent style replies with a typing indicator.
  Scroll up to load older pages (45 seeded messages).
- **Product Team**: group chat.
- Include `/fail` in a message to simulate a failed send, then tap it to retry.
- The paperclip attaches a sample PDF (simulated upload with progress).
- Long-press a message to reply to it.

## Environments

Configuration is compile-time (`--dart-define`), read by
[`AppConfig.fromEnvironment`](lib/core/config/app_config.dart).

| File | Purpose |
| --- | --- |
| `config/development.json` | Local development, fake backend, network logs on |
| `config/staging.json` | Staging API URL |
| `config/production.json` | Production; network logs are forced off in code |

```bash
flutter run --dart-define-from-file=config/staging.json
flutter build apk --release --dart-define-from-file=config/production.json
```

| Key | Meaning |
| --- | --- |
| `APP_ENV`, `APP_NAME`, `API_BASE_URL` | Environment, display name, API root |
| `USE_FAKE_BACKEND` | In-process fake auth/chat backend |
| `ENABLE_NETWORK_LOGS`, `LOG_NETWORK_BODIES` | Redacted HTTP logging (forced off in production) |
| `CONNECT_TIMEOUT_MS`, `RECEIVE_TIMEOUT_MS` | HTTP timeouts |
| `ENABLE_FIREBASE` | Firebase telemetry (needs `flutterfire configure`) |
| `ADS_ENABLED` | Show ads (Google test units until you set yours) |
| `USE_FAKE_BILLING`, `PRO_PRODUCT_ID` | Fake vs. real store, Pro product id |
| `APP_STORE_ID`, `PRIVACY_POLICY_URL` | Rate-app on iOS, Settings › Privacy policy |

> [!IMPORTANT]
> All three config files ship with `USE_FAKE_BACKEND: true` and placeholder
> `example.com` URLs, so every environment runs offline. Once you have a real
> backend, set it to `false` and adapt `HttpAuthRemoteDataSource` to your API
> shape.

**Secrets:** nothing compiled into an app is secret. Do not put API keys for
paid services (LLM vendors, payment providers) in these files; call them
through your backend. For per-developer overrides, create
`config/<env>.local.json` (git-ignored).

Running without any `--dart-define` uses development defaults.

## Test, analyze, format, build

```bash
flutter analyze                                           # app + packages
flutter test                                              # app
for p in packages/*/; do (cd "$p" && flutter test); done  # each package
dart format lib test packages
flutter build apk --debug --dart-define-from-file=config/development.json
```

The same steps run in GitHub Actions on every push and pull request
([.github/workflows/ci.yml](.github/workflows/ci.yml)).

Notes:

- On Windows, `dart format .` can crash when the project path is very long,
  because it walks generated `ios/Flutter/ephemeral` folders. Formatting
  `lib test` avoids it. Cloning to a short path (e.g. `C:\src\fpb`) also
  avoids an Android build failure caused by the 260-character path limit.
- On macOS, if the project sits on an exFAT/FAT drive (e.g. a USB stick),
  Finder creates `._*` metadata files. Git ignores them, but they break
  `flutter test` and `flutter gen-l10n`; run `dot_clean -m .` first.

## Project structure

```
lib/
├── main.dart                 # entry → bootstrap()
├── app/                      # composition root: App widget, bootstrap, router, splash/404
│   ├── bootstrap/
│   └── router/               # routes, guard wiring
├── core/                     # feature-agnostic infrastructure
│   ├── auth/                 # AccessTokenSource, SessionStatus (contracts only)
│   ├── capabilities/         # Riverpod wiring for packages/pb_* (the only place)
│   ├── config/               # AppConfig, AppEnvironment
│   ├── di/                   # core Riverpod providers
│   ├── error/                # AppFailure, Result, ErrorMapper, localized messages
│   ├── localization/         # ARB files + generated AppLocalizations
│   ├── logging/              # AppLogger, Redactor
│   ├── navigation/           # RouteAccess + RouteGuard (pure logic)
│   ├── network/              # ApiClient, DioFactory, interceptors
│   ├── storage/              # KeyValueStore, SecureStore
│   └── theme/                # AppTheme, spacing/radius/breakpoint tokens
├── shared/                   # reusable widgets, models, utils (no business logic)
└── features/
    ├── auth/                 # domain / data / application / presentation
    ├── chat/                 # generic chat engine (see docs/CHAT_MODULE.md)
    ├── file/                 # attachments, MIME, uploader & picker contracts
    ├── home/                 # demo home + foundation showcase (replace in apps)
    ├── notification/         # in-app bus, local/push interfaces
    ├── onboarding/           # intro content + persisted flag (pb_onboarding)
    ├── premium/              # paywall page (pb_premium)
    ├── profile/
    └── settings/

packages/                     # opt-in capabilities (pub workspace)
├── pb_common/  pb_telemetry/  pb_telemetry_firebase/  pb_connectivity/
├── pb_onboarding/  pb_notifications/  pb_review/
└── pb_billing/  pb_premium/  pb_ads/
```

Each feature follows `domain → data → application → presentation`. Folders
are only created when they contain something. Dependencies point inward:
`core/` never imports from `features/`, and `domain/` stays pure Dart. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full rules.

## Starting a new app from this base

Follow [docs/NEW_APP_CHECKLIST.md](docs/NEW_APP_CHECKLIST.md) for the full
list. The essentials:

1. Rename the package (`pubspec.yaml` `name` and `description`, imports) and
   the application id (`android/app/build.gradle.kts`
   `applicationId`/`namespace`, iOS bundle id). The base uses
   `com.example.flutter_project_base`, which app stores reject.
2. Set your brand seed color in `appThemeProvider` (`lib/app/app.dart`).
3. Point `config/*.json` at your API and turn off `USE_FAKE_BACKEND`.
4. Replace `features/home` with your real home; keep or delete the demo
   features.
5. Override `chatProviderProvider` with your real chat provider.
6. Delete the capability packages you won't ship
   ([MODULE_CATALOG.md](docs/MODULE_CATALOG.md#removing-a-package-from-an-app)),
   and replace Google's test AdMob ids in the ones you keep.
7. Configure release signing (keep the keystore **outside** the repo).

## Adding a language

1. Copy `lib/core/localization/arb/app_en.arb` to `app_<code>.arb` and
   translate the values (keep keys and placeholders).
2. Run `flutter gen-l10n` (it also runs automatically on `flutter run` and
   `flutter build`). Generated files in `lib/core/localization/generated/`
   are committed.
3. Add the language name to `SettingsPage._languageName`.
4. For iOS, add the locale to `CFBundleLocalizations` in
   `ios/Runner/Info.plist` (`en` and `vi` are already listed).

## Documentation

- [AGENTS.md](AGENTS.md): rules for humans and AI agents working on this repo
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): layers, dependency rules, DI, networking, routing, errors
- [docs/CHAT_MODULE.md](docs/CHAT_MODULE.md): chat engine and providers (realtime, remote AI, local AI, RAG)
- [docs/MODULE_CATALOG.md](docs/MODULE_CATALOG.md): every capability package: API, wiring, native setup, removal
- [docs/MONETIZATION.md](docs/MONETIZATION.md): ads, Pro purchase and paywall, store setup
- [docs/THEMING.md](docs/THEMING.md): brand color, dynamic color, semantic colors, tokens
- [docs/NEW_APP_CHECKLIST.md](docs/NEW_APP_CHECKLIST.md): from a fresh copy to a store-ready app
- [docs/ADDING_FEATURE.md](docs/ADDING_FEATURE.md): checklists to add features, packages, APIs, screens, routes, tests
- [docs/REPORT.md](docs/REPORT.md): current status, decisions, known issues, review guide

## Roadmap

Planned next steps (details in [docs/REPORT.md](docs/REPORT.md#12-recommended-next-steps)):

- Persistent chat cache (Drift) for offline history
- Per-conversation provider routing (AI + human support in one app), unread
  counts and read receipts
- Concrete WebSocket transport for realtime chat
- Real file picker/uploader and a push notification adapter (FCM)
- Subscriptions in `pb_billing`, server receipt verification
- Bottom-navigation shell template, Markdown rendering for AI messages,
  integration and golden tests

## Contributing

Issues and pull requests are welcome. Before opening a PR:

1. Read [AGENTS.md](AGENTS.md). The golden rule: **the base stays generic**.
   Product-specific code belongs in the app that uses the base; add an
   extension point here instead.
2. Follow the checklists in [docs/ADDING_FEATURE.md](docs/ADDING_FEATURE.md).
3. Make sure the quality gates pass:

   ```bash
   dart format lib test packages
   flutter analyze   # No issues found!
   flutter test      # all green, plus each package's tests
   ```

4. Use small commits with conventional prefixes (`feat:`, `fix:`, `docs:`,
   `test:`, `chore:`, `refactor:`).

## License

Released under the [MIT License](LICENSE). You are free to use this base for
personal and commercial apps.
