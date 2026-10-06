# Flutter Project Base

A reusable, production-minded **foundation** for Flutter apps — enterprise,
booking, fintech, SaaS, support desks, AI chat (remote or on-device) and
user-to-user chat. It is not a product: it is the layer you start every
product from.

What you get out of the box:

| Area | What's included |
| --- | --- |
| Architecture | Feature-first Clean Architecture, Riverpod for state + DI |
| Environments | development / staging / production via `--dart-define-from-file` |
| Networking | Dio client, bearer-token injection, refresh-on-401, error normalization, redacted logging |
| Errors | Sealed `AppFailure` hierarchy + `Result<T>`; UI never sees library exceptions |
| Storage | `KeyValueStore` (preferences) and `SecureStore` (tokens) abstractions |
| Auth | Guest + email/password, session restore, token refresh, OAuth extension point |
| Navigation | go_router with auth guard, guest-only routes, deep-link preservation, 404 page |
| Design system | Material 3 theme from a seed color, light/dark/system, tokens, buttons, inputs, states, dialogs, snackbars, responsive helpers |
| Localization | ARB-based, English + Vietnamese |
| Settings | Theme, language (persisted), app info, sign out |
| Profile | Minimal, extensible `UserProfile` |
| Files | Vendor-neutral `Attachment` model, MIME helpers, uploader/picker interfaces |
| Notifications | Local / push / in-app abstractions (in-app implemented) |
| **Chat** | Generic chat engine: conversations, messages, participants, attachments, replies, statuses, typing, pagination, retry, streaming; replaceable providers (Mock, Remote AI, Local AI, Realtime) |
| Tests | 86 unit, widget and app smoke tests |

> Status of every module (DONE / PARTIAL / NOT IMPLEMENTED) is tracked in
> [docs/REPORT.md](docs/REPORT.md).

---

## Requirements

- Flutter **3.47+** (stable), Dart **3.13+** — see `environment` in `pubspec.yaml`
- Android SDK (for Android builds), Xcode on macOS (for iOS builds)

## Quick start

```bash
flutter pub get
flutter run --dart-define-from-file=config/development.json
```

The development config uses an **in-process fake backend**
(`USE_FAKE_BACKEND=true`), so the app runs with no server. Sign in with any
email + a 6+ character password, or tap **Continue as guest**.

Demo flow: **Splash → Sign in → Home → Chat demo / Foundation showcase /
Profile / Settings**.

In the chat demo:

- **Mock Assistant** – streamed AI-style answers; stop button while
  generating; *Regenerate*; end a message with `?` to see citations.
- **Customer Support** – human-agent style replies with a typing indicator;
  scroll up to load older pages (45 seeded messages).
- **Product Team** – group chat.
- Include `/fail` in a message to simulate a failed send, then tap it to retry.
- Paperclip attaches a sample PDF (simulated upload with progress).
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
flutter run   --dart-define-from-file=config/staging.json
flutter build apk --release --dart-define-from-file=config/production.json
```

Keys: `APP_ENV`, `APP_NAME`, `API_BASE_URL`, `USE_FAKE_BACKEND`,
`ENABLE_NETWORK_LOGS`, `LOG_NETWORK_BODIES`, `CONNECT_TIMEOUT_MS`,
`RECEIVE_TIMEOUT_MS`.

**Secrets:** nothing compiled into an app is secret. Do not put API keys for
paid services (LLM vendors, payment providers) in these files — call them
through your backend. For per-developer overrides create
`config/<env>.local.json` (git-ignored).

When you have a real backend, set `USE_FAKE_BACKEND` to `false` and adjust
`HttpAuthRemoteDataSource` to your API shape.

Running without any `--dart-define` uses development defaults.

## Test, analyze, format, build

```bash
flutter analyze
flutter test
dart format lib test
flutter build apk --debug --dart-define-from-file=config/development.json
```

> `dart format .` can crash on Windows when the project path is very long,
> because it walks generated `ios/Flutter/ephemeral` folders. Formatting
> `lib test` avoids it.

## Project structure

```
lib/
├── main.dart                 # entry → bootstrap()
├── app/                      # composition root: App widget, bootstrap, router, splash/404
│   ├── bootstrap/
│   └── router/               # routes, guard wiring
├── core/                     # feature-agnostic infrastructure
│   ├── auth/                 # AccessTokenSource, SessionStatus (contracts only)
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
    ├── notification/         # local / push / in-app abstractions
    ├── profile/
    └── settings/
```

Each feature follows `domain → data → application → presentation`; folders are
only created when they contain something.

## Documentation

- [AGENTS.md](AGENTS.md) — rules for humans and AI agents working on this repo
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layers, dependency rules, DI, networking, routing, errors
- [docs/CHAT_MODULE.md](docs/CHAT_MODULE.md) — chat engine and providers (realtime, remote AI, local AI, RAG)
- [docs/ADDING_FEATURE.md](docs/ADDING_FEATURE.md) — checklists to add features, APIs, screens, routes, tests
- [docs/REPORT.md](docs/REPORT.md) — current status, decisions, known issues, review guide

## Adding a language

1. Copy `lib/core/localization/arb/app_en.arb` to `app_<code>.arb` and
   translate the values (keep keys and placeholders).
2. Run `flutter gen-l10n` (also runs automatically on `flutter run`/`build`).
   Generated files in `lib/core/localization/generated/` are committed.
3. Add the language name to `SettingsPage._languageName`.
4. For iOS, add the locale to `CFBundleLocalizations` in `ios/Runner/Info.plist` (en and vi are already listed).

## Starting a new app from this base

1. Rename the package (`pubspec.yaml` `name`, imports) and the application id
   (`android/app/build.gradle.kts` `applicationId`/`namespace`, iOS bundle id).
   The base uses `com.example.flutter_project_base`, which stores reject.
2. Set your brand seed color in `appThemeProvider` (`lib/app/app.dart`).
3. Point `config/*.json` at your API and turn off `USE_FAKE_BACKEND`.
4. Replace `features/home` with your real home; keep or delete demo features.
5. Override `chatProviderProvider` with your real chat provider.
6. Configure release signing (keystore **outside** the repo).
