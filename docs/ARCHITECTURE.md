# Architecture

## Goals

1. Reusable across very different products.
2. Easy to add or remove a feature (delete a folder + its routes/providers).
3. Testable without devices, servers or plugins.
4. Simple enough for a new developer or an AI agent to extend correctly.
5. No speculative abstractions: an interface exists because there is a real
   second implementation (fake, in-memory, vendor) or a test seam.

## Layers

```
lib/
  app/        composition root: App widget, bootstrap, router
  core/       infrastructure shared by all features (no feature knowledge)
  shared/     reusable widgets/models/utils (no business logic)
  features/   vertical slices, each with domain/data/application/presentation
```

Inside a feature:

| Layer | Contains | May depend on |
| --- | --- | --- |
| `domain/` | Entities, value objects, repository **interfaces**, pure logic | `core/error`, `shared/models`, other domains |
| `data/` | Repository implementations, remote/local data sources, fakes | `domain`, `core` |
| `application/` | Riverpod providers + `Notifier` controllers (use-case orchestration, UI state) | `domain`, `data` (to wire), `core` |
| `presentation/` | Pages and widgets | `application`, `domain`, `core`, `shared` |

### Dependency direction

```
            ┌──────────────┐
            │     app/     │  (wires everything; the only place that knows all features)
            └──────┬───────┘
                   ▼
   presentation → application → domain ◄── data
         │              │          ▲         │
         └──────────────┴──► core ◄┴─────────┘
                              ▲
                            shared
```

- `core` never imports `features`. Example: the network layer needs the access
  token owned by `features/auth`. Core defines
  [`AccessTokenSource`](../lib/core/auth/access_token_source.dart); auth
  implements it ([`AuthTokenSource`](../lib/features/auth/application/auth_token_source.dart));
  bootstrap wires it with `accessTokenSourceProvider.overrideWith(...)`.
- Routing uses `SessionStatus` (core), not `AuthState` (feature).
- Use cases: there is no separate `usecases/` folder. Controllers call
  repositories directly; when orchestration grows (multiple repositories,
  complex rules), extract a plain Dart use-case class into `domain/` or
  `application/`. This avoids one-line pass-through classes.

## State management & DI: Riverpod 3

**Decision:** `flutter_riverpod` (no code generation) for both state
management and dependency injection.

Why:
- One tool for DI and state (fewer concepts than Bloc + get_it).
- Compile-safe, testable: any dependency can be overridden in
  `ProviderScope`/`ProviderContainer` without global singletons.
- Providers are lazy, so unused features cost nothing at startup.
- No build_runner step keeps the base easy to clone and understand.

Conventions:
- Infrastructure → `Provider<T>` (e.g. `apiClientProvider`).
- Feature state → `NotifierProvider` / `AsyncNotifierProvider` /
  `StreamProvider`; per-entity state uses `.family` (e.g.
  `conversationControllerProvider(conversationId)`).
- Values only known at startup (config, `SharedPreferences`) are provided by
  overrides in [`bootstrap`](../lib/app/bootstrap/bootstrap.dart); their
  default implementation throws to catch missing wiring.
- Tests use `createTestContainer()` / `baseTestOverrides()` from
  `test/helpers/test_helpers.dart`.
- Riverpod 3 retries failing providers automatically; tests pass
  `retry: noRetry`.

## Configuration

[`AppConfig`](../lib/core/config/app_config.dart) is built from
`--dart-define` values (`config/<env>.json`). `AppEnvironment` = development
| staging | production. Production forcibly disables network logging.
`useFakeBackend` switches data sources to in-process fakes so the base runs
without a server.

## Networking

- [`DioFactory`](../lib/core/network/dio_factory.dart) creates two clients:
  - `publicDioProvider` — no auth handling; used for auth endpoints (login,
    refresh) and public APIs. This avoids refresh recursion.
  - `authenticatedDioProvider` — `AuthInterceptor` + logging.
- [`AuthInterceptor`](../lib/core/network/interceptors/auth_interceptor.dart)
  (a `QueuedInterceptor`): injects `Authorization: Bearer`, on 401 calls
  `AccessTokenSource.refresh()` once and replays the request with a separate
  client; if refresh fails it calls `onSessionExpired()` (→ auth signs out →
  router redirects). Opt out per request with
  `Options(extra: {AuthInterceptor.skipAuth: true})`.
- [`LoggingInterceptor`](../lib/core/network/interceptors/logging_interceptor.dart)
  logs method/path/status/duration; bodies and headers only when
  `LOG_NETWORK_BODIES` is on, always through
  [`Redactor`](../lib/core/logging/redactor.dart) (passwords, tokens,
  cookies, API keys, OTP, card data…).
- [`ApiClient`](../lib/core/network/api_client.dart) wraps Dio and throws
  `AppFailure` only. Cancellation: pass a Dio `CancelToken`; cancellations map
  to `CancelledFailure`.
- Retry: **no blanket retry** (non-idempotent requests would duplicate side
  effects). Token refresh retry is built in; add targeted retry for
  idempotent calls when needed.

## Error handling

```
AppFailure (sealed)
├── NetworkFailure(reason: noConnection | timeout)
├── UnauthorizedFailure      401
├── ForbiddenFailure         403
├── NotFoundFailure          404
├── ValidationFailure        400/422 (+ fieldErrors)
├── ServerFailure            5xx / unexpected status (+ statusCode)
├── StorageFailure           secure storage / platform errors
├── CancelledFailure         cancelled request / stopped generation
└── UnknownFailure
```

- [`ErrorMapper`](../lib/core/error/error_mapper.dart) is the only place that
  knows library exception types (Dio, PlatformException, TimeoutException…).
- Repositories return [`Result<T>`](../lib/core/error/result.dart)
  (`Ok`/`Err`); `guard(() async { ... })` converts thrown errors.
- Presentation uses
  [`failure.localizedMessage(l10n)`](../lib/core/error/failure_messages.dart)
  — no raw server messages in the UI by default.
- Uncaught errors: `FlutterError.onError` and
  `PlatformDispatcher.instance.onError` log via `AppLogger` (hook for
  Crashlytics/Sentry: override `appLoggerProvider`).

## Storage

| Abstraction | Default | Use for |
| --- | --- | --- |
| [`KeyValueStore`](../lib/core/storage/key_value_store.dart) | `SharedPreferencesStore` (sync reads) | preferences, flags |
| [`SecureStore`](../lib/core/storage/secure_store.dart) | `FlutterSecureStore` (Keychain / Android Keystore) | tokens, secrets |
| `ChatCache` (chat feature) | `InMemoryChatCache` | chat state |

Both core stores have in-memory implementations for tests.

**Database:** none is bundled — no use case needs it yet. To add one
(Drift/SQLite/Isar), implement the relevant feature interfaces in `data/`
(e.g. a `DriftChatCache implements ChatCache`) and override the provider.
Domain and UI are unaffected.

## Auth

- Domain: `AuthUser`, `AuthSession` (tokens + expiry), `AuthState`
  (`AuthUnknown` | `Unauthenticated` | `Authenticated(session)`; guest =
  `session.isGuest`), `AuthCredential` (`GuestCredential`,
  `EmailPasswordCredential`, `OAuthCredential` extension point),
  `AuthRepository`.
- Data: `HttpAuthRemoteDataSource` (REST convention, adapt to backend),
  `FakeAuthRemoteDataSource` (demo/tests), `AuthSessionStorage` (session JSON
  in `SecureStore` only), `AuthRepositoryImpl` (restore, refresh with
  single-flight, offline-tolerant restore, best-effort remote logout).
- Application: `AuthController` restores the session on start; the router
  listens to it.

## Navigation

- go_router, configured in
  [`app_router.dart`](../lib/app/router/app_router.dart); paths in
  [`AppRoutes`](../lib/app/router/app_routes.dart).
- Access rules are data: `AppRoutes.access` maps path prefixes to
  `RouteAccess.public | signedOutOnly | signedIn`.
- [`RouteGuard`](../lib/core/navigation/route_access.dart) is pure logic
  (unit-tested): splash while unknown, redirect to sign-in with `?from=`
  for deep links, back to the original location after sign-in, rejects
  external redirect targets.
- Router is created once; `refreshListenable` re-runs redirects when session
  status changes (navigation state is preserved).
- Nested routes under `/home`; `ShellRoute`/`StatefulShellRoute` can be
  introduced for bottom navigation without changing features.
- Unknown paths → `NotFoundPage`.

## Design system

- [`AppTheme`](../lib/core/theme/app_theme.dart): Material 3 from a seed
  color (light + dark), component themes for buttons, inputs, cards,
  dialogs, snackbars. Re-brand by overriding `appThemeProvider`.
- Tokens: `AppSpacing`, `AppRadius`, `WindowSize` breakpoints, `AppLayout`.
- Widgets in `shared/widgets`: `AppButton` (primary/secondary/text, loading),
  `AppTextField` (password toggle), `LoadingView`, `EmptyView`, `ErrorView`,
  `showAppSnackBar`, `showConfirmDialog`, `ResponsiveCenter`.
- Theme mode (system/light/dark) and locale are persisted by settings.

## Localization

`flutter_localizations` + ARB (`lib/core/localization/arb`), generated
`AppLocalizations` (committed under `generated/`). Access with
`context.l10n`. English is the template; Vietnamese is complete.

## Module boundaries (what each feature exposes)

| Feature | Public surface |
| --- | --- |
| auth | `authControllerProvider`, `AuthState`, `AuthRepository`, `SignInPage` |
| settings | `settingsControllerProvider`, `SettingsPage` |
| profile | `currentProfileProvider`, `UserProfile`, `ProfileRepository` |
| file | `Attachment`, `MimeTypes`, `FileUploader`, `AttachmentPicker`, providers |
| notification | `AppNotification`, service interfaces, `inAppNotificationCenterProvider` |
| chat | `ChatProvider`, `ChatRepository`, `chatProviderProvider`, `conversationControllerProvider`, chat widgets |
| home | demo only — replace in real apps |

Removing a feature: delete its folder, its routes in `app_router.dart`, its
links in `HomePage`, and any overrides in bootstrap.
