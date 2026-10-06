# REPORT — Flutter Project Base

Date: 2026-10-06 · Author: Claude (AI coding agent), working unattended

---

## 1. Executive summary

**Before:** no Flutter repository existed locally. The official remote
`trinhthimai1509/flutter_project_base` was **empty** (private, no branches).
The only other "BaseProject" on the machine
(`AndroidStudioProjects/BaseProject`) is a native Android/Gradle project, not
Flutter and not under git, so it was left alone. The project was bootstrapped
from scratch with `flutter create` (Flutter 3.47.5 stable, Dart 3.13.4).

**After:** a working, tested, documented Flutter foundation:

- Feature-first Clean Architecture with Riverpod (state + DI).
- Core: environments, networking with token refresh, unified failures,
  storage abstractions, logging with redaction, route guard, theme, EN/VI.
- Features: auth (guest + email, secure session, restore, refresh), settings
  (persisted theme/language), profile, files/attachments, notifications,
  and a **generic chat engine** with Mock / Remote AI / Local AI / Realtime
  providers.
- Demo app: Splash → Sign in → Home → Chat demo / Foundation showcase /
  Profile / Settings.
- **86 tests, all passing. `flutter analyze`: No issues found.**
- **Android debug APK built** (from a short-path copy — see §8). Web release
  build also succeeds.
- Pushed to `origin/main` over HTTPS.

## 2. Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for details.

```
lib/app        composition root (bootstrap, App, router, splash/404)
lib/core       infrastructure, never imports features
lib/shared     reusable widgets/models/utils
lib/features/  auth, settings, profile, file, notification, chat, home(demo)
               each: domain / data / application / presentation (as needed)
```

Key decisions:
- **Riverpod 3 without codegen** for state + DI (one tool, overridable,
  testable, no build_runner).
- **Dependency inversion at core boundaries**: `AccessTokenSource` (core) is
  implemented by auth and wired in bootstrap; routing uses core
  `SessionStatus`.
- **`Result<T>` + sealed `AppFailure`**; `ErrorMapper` is the only place
  aware of library exceptions.
- **Two Dio clients** (public / authenticated) to avoid refresh recursion;
  queued auth interceptor refreshes once on 401.
- **Route access as data** (`AppRoutes.access`) + pure `RouteGuard`.
- **Chat = events + repository**: providers only translate transport ⇄
  `ChatEvent`; the repository owns optimistic send, retry, streaming,
  pagination, typing, uploads; UI reads the cache.
- **Typed message metadata** (`MessageExtension`) instead of a dynamic map.
- **No database bundled**; `ChatCache` / repositories are the seams.

## 3. Dependencies

| Package | Version | Why |
| --- | --- | --- |
| `flutter_riverpod` | ^3.4.3 | State management + DI (single framework) |
| `go_router` | ^18.0.2 | Declarative routing, redirects, deep links (official Flutter package) |
| `dio` | ^5.11.1 | HTTP client with interceptors, cancellation, timeouts |
| `shared_preferences` | ^2.5.5 | Non-sensitive key-value persistence |
| `flutter_secure_storage` | ^11.2.0 | Keychain/Keystore storage for tokens |
| `package_info_plus` | ^10.x | App version/build number for Settings › About |
| `equatable` | ^3.0.0 | Value equality for entities/state without codegen |
| `intl` | ^0.20.x | Required by gen-l10n |
| `flutter_localizations` | sdk | Material/Cupertino localizations |
| `mocktail` (dev) | ^1.0.5 | Mocks without codegen |
| `flutter_lints` (dev) | ^6.0.0 | Lint baseline (+ stricter rules in `analysis_options.yaml`) |

Not added on purpose: freezed/json_serializable (codegen), get_it, Bloc,
Firebase, file_picker/image_picker, local notifications, any LLM SDK, any
database. `flutter pub outdated` reports 9 transitive packages with newer
versions that are incompatible with current constraints (normal; pinned by
the Flutter SDK).

## 4. Completed work

Legend: **DONE** = implemented, wired and tested/working ·
**PARTIAL** = usable foundation, some parts are interfaces or demo-only ·
**NOT IMPLEMENTED** = not done.

| Module | Status | Notes |
| --- | --- | --- |
| Core (config/env) | DONE | dev/staging/prod via `--dart-define-from-file`; prod forces logs off |
| Network | DONE | base URL, headers, timeouts, bearer injection, refresh-on-401 (queued, single replay), error normalization, redacted logging, cancellation via `CancelToken`. No blanket retry (by design) |
| Error handling | DONE | sealed `AppFailure` (+ `CancelledFailure`), `Result`, `guard`, localized messages, global error hooks |
| Storage | DONE | `KeyValueStore` (SharedPreferences), `SecureStore` (flutter_secure_storage), in-memory variants. No DB (by design) |
| Auth | DONE | guest, email/password, secure persistence, session restore (offline-tolerant), single-flight refresh, logout (best-effort remote). OAuth = credential type + endpoint convention only (no vendor SDK) |
| Navigation | DONE | go_router, auth guard, guest-only route, deep-link `from=` preservation, open-redirect protection, nested routes, 404 page. Bottom-nav shell not added (not needed by demo) |
| Design system | DONE | M3 theme from seed, light/dark/system, typography tweaks, spacing/radius/breakpoints, `AppButton`, `AppTextField`, loading/empty/error views, confirm dialog, snackbar helper, `ResponsiveCenter`, responsive home grid |
| Localization | DONE | ARB EN (template) + VI complete (95 keys), iOS `CFBundleLocalizations` set, guide in README |
| Settings | DONE | theme mode, language (incl. system), app name/version/environment, sign out with confirm; persisted |
| Profile | PARTIAL | `UserProfile` + repository built from the auth session and a profile page. No remote `GET /me` or edit (no backend contract yet) |
| File / media | PARTIAL | `Attachment` (kind, MIME, size, local/remote source, upload status/progress, media info), MIME helpers, `FileUploader`/`AttachmentPicker` contracts, fake uploader + demo picker, upload pipeline used by chat. No real picker or storage vendor (needs native plugins/backend) |
| Notification | PARTIAL | Domain (`AppNotification`, channels) + interfaces for local/push/in-app. In-app center **implemented** and shown via snackbar (demo button). Local/push are no-op implementations (need plugins/Firebase credentials) |
| Chat | DONE (engine) / PARTIAL (real transports) | See §5 |
| Testing | DONE | 86 tests: unit, widget, app smoke |
| Documentation | DONE | README, AGENTS.md (+ CLAUDE.md pointer), ARCHITECTURE, CHAT_MODULE, ADDING_FEATURE, REPORT |

## 5. Chat module

| Capability | Status | Where |
| --- | --- | --- |
| Domain (Conversation, Message, Participant, Attachment, MessageStatus, MessageType, SenderType user/agent/bot/ai/system, ReplyReference, typed metadata) | DONE | `domain/entities` |
| Provider abstraction (`ChatProvider`, `GenerativeChatProvider`, capabilities, events) | DONE | `domain/chat_provider.dart` |
| Conversation list / detail UI | DONE | `presentation/` |
| Send text, receive message | DONE | repository + Mock provider |
| Streaming (deltas, caret in UI) | DONE | `MessageDelta`; Mock/Remote/Local providers |
| Stop generation / regenerate | DONE | Mock + AI base; UI buttons by capability |
| Retry failed message | DONE | `/fail` demo; tap failed bubble |
| Pagination (cursor) | DONE | support conversation, 45 seeded messages, load on scroll-up |
| Loading / empty / error states | DONE | `ConversationPage`, `ConversationListPage` |
| Attachments | DONE (pipeline) / demo picker | upload with progress via `FileUploader`; real picker in app |
| Reply to message | DONE | long-press → reply banner → quoted bubble |
| Message status (sending/sent/delivered/read/failed/streaming) | DONE | status icons |
| Typing state | DONE | `TypingChanged`, `TypingIndicator` |
| Local cache | PARTIAL | `InMemoryChatCache` (session only); `ChatCache` interface ready for Drift/SQLite |
| Realtime readiness | PARTIAL | `RealtimeChatProvider` implemented over `RealtimeChatTransport` + `ChatEventCodec` + `ChatHistoryApi` (tested with fakes). No concrete WebSocket transport/codec (backend-specific) |
| Remote AI readiness | PARTIAL | `RemoteAIChatProvider` fully implemented over `RemoteAiClient` (tested with fake engine: streaming, citations, tool calls, errors, regenerate). No vendor client shipped (by requirement) |
| Local AI readiness | PARTIAL | `LocalAIChatProvider` over `LocalInferenceEngine` (lazy load, stop, unload; tested). No llama.cpp/llamadart binding or model bundled (by requirement) |
| RAG readiness | PARTIAL | `Citations`/`SourceReference`, `CitationsChunk`, `buildRequest` override hook; UI renders sources |
| Per-conversation provider routing (AI + human in one app) | NOT IMPLEMENTED | documented as next step |
| Unread counts / read receipts updates | PARTIAL | fields + status exist; no logic to mark read |

## 6. Tests

Command: `flutter test` → **86 passed, 0 failed** (14 suites).

| Suite | Tests |
| --- | --- |
| test/app_smoke_test.dart (boot→sign-in→guest home; chat send + AI reply; settings theme/language/sign-out; 404) | 4 |
| test/core/auth_interceptor_test.dart | 4 |
| test/core/error_mapper_test.dart | 7 |
| test/core/redactor_test.dart | 2 |
| test/core/route_guard_test.dart | 6 |
| test/features/auth/auth_controller_test.dart | 4 |
| test/features/auth/auth_repository_test.dart | 9 |
| test/features/chat/chat_domain_test.dart | 7 |
| test/features/chat/chat_providers_test.dart (Remote AI, Local AI, Realtime) | 6 |
| test/features/chat/chat_repository_test.dart | 12 |
| test/features/file/mime_types_test.dart | 4 |
| test/features/settings/settings_controller_test.dart | 4 |
| test/widgets/chat_widgets_test.dart | 10 |
| test/widgets/shared_widgets_test.dart | 7 |

Bugs found and fixed by tests during the task: `signOut` crashed when the
remote data source threw synchronously; home tiles overflowed with a fixed
grid height under larger text (now natural height).

## 7. Analyze

`flutter analyze` → **No issues found!** (with stricter rules:
`strict-inference`, `avoid_dynamic_calls`, `unawaited_futures`,
`prefer_relative_imports`, `directives_ordering`, `cancel_subscriptions`,
`close_sinks`, …). Generated l10n files are excluded from analysis.

`dart format lib test` → clean. `dart format .` **crashes** in this
environment (see Known issues) — not a code problem.

## 8. Build

| Command | Platform | Result |
| --- | --- | --- |
| `flutter build apk --debug --dart-define-from-file=config/development.json` (in the session folder) | Android | **FAILED — environment**: `impellerc` could not write `…\build\app\intermediates\flutter\debug\flutter_assets\packages/material_ui/shaders/ink_sparkle.frag.spirv`. The working folder path is ~200 chars, so the output path exceeds Windows MAX_PATH (260) |
| Same command in an identical copy at `%TEMP%\fpb` (short path) | Android | **SUCCESS** — `build\app\outputs\flutter-apk\app-debug.apk` (173,381,339 bytes) |
| `flutter build web --dart-define-from-file=config/development.json` (short path) | Web | **SUCCESS** — `build\web`. One warning: CupertinoIcons font referenced by a dependency but `cupertino_icons` not included (we don't use Cupertino icons) |
| `flutter run -d web-server` | Web (debug) | App ran in browser: splash → sign-in (validation works) → guest → home; reload on `/#/home/chat/assistant` restored the session and opened the deep link |
| iOS | — | Not built: requires macOS/Xcode (machine is Windows) |
| Windows desktop | — | Not targeted (no Visual Studio; platform not generated) |

APK artifacts are build outputs and are not committed.

## 9. Git

- Remote: `origin` → `https://github.com/trinhthimai1509/flutter_project_base.git`
  (the SSH URL `git@github.com:…` was configured first, but this machine has
  no SSH key; switched to HTTPS per owner instruction. Authentication used
  `gh`'s credential helper passed per command — no global git config was
  changed).
- Branch: `main` (tracks `origin/main`). Remote was empty → first push created
  `main`. No force push, no history rewrite.
- Commits (oldest → newest):

| Hash | Message |
| --- | --- |
| `b81c55a` | chore: bootstrap Flutter project scaffold and tooling |
| `2b72a0d` | feat: add reusable core foundation |
| `c5ed501` | feat: add auth, settings, profile, file and notification foundations |
| `a16732e` | feat: add generic chat module with replaceable providers |
| `a19b514` | feat: add app shell, router and foundation demo |
| `a5dc6f1` | test: add foundation, chat, widget and app smoke tests |
| `b62f38c` | docs: document architecture, chat module and contribution rules |
| `57f5a4e` | chore: normalize line endings with .gitattributes |
| `9684378` | docs: add project report |
| (this commit) | docs: record final git verification in report |

- Push #1 (`b81c55a..b62f38c`): `* [new branch] main -> main`, upstream set.
- Push #2: `b62f38c..9684378  main -> main` (fetched first; local was `ahead 2`, no divergence).
- Push #3: this report update (fast-forward).
- Commit authorship uses the machine's global git identity.
- Final verification output is recorded in §9.1 (filled after the last push).

### 9.1 Final sync verification

After push #2 (`git fetch origin` first):

```
$ git status -sb
## main...origin/main

$ git log --oneline --decorate -n 10
9684378 (HEAD -> main, origin/main) docs: add project report
57f5a4e chore: normalize line endings with .gitattributes
b62f38c docs: document architecture, chat module and contribution rules
a5dc6f1 test: add foundation, chat, widget and app smoke tests
a19b514 feat: add app shell, router and foundation demo
a16732e feat: add generic chat module with replaceable providers
c5ed501 feat: add auth, settings, profile, file and notification foundations
2b72a0d feat: add reusable core foundation
b81c55a chore: bootstrap Flutter project scaffold and tooling

$ git rev-list --left-right --count main...origin/main
0	0
```

`main` and `origin/main` both pointed to
`96843783e4f3e3e62072686c014d0a0a16233ebf`. The commit that records this
section is pushed the same way (push #3); check `git log -1` for its hash.

## 10. Known issues

1. **Windows long-path limit in this folder.** The session folder path is
   very long; `flutter build apk` fails with an impellerc write error and
   `dart format .` crashes walking `ios/Flutter/ephemeral`. Workarounds:
   clone the repo to a short path (e.g. `C:\src\flutter_project_base`), or
   enable Windows long paths (`LongPathsEnabled`), or use
   `dart format lib test`. Not a project defect.
2. Android toolchain warnings on this machine (`flutter doctor`):
   `cmdline-tools` missing and Android licenses status unknown. The debug
   build still succeeds; release/Play tooling may need them.
3. App id/package `com.example.flutter_project_base` must be renamed per app
   (stores reject `com.example`). Release signing is not configured
   (debug key; keystore must stay outside the repo).
4. `USE_FAKE_BACKEND` is `true` in all three config files so every
   environment runs without a server; set it to `false` once a backend exists.
   `HttpAuthRemoteDataSource` assumes a common REST shape — adapt to the real API.
5. Chat cache is in-memory (history lost on restart); unread counts are not
   updated; no per-conversation provider routing.
6. Local/push notifications are no-ops; file picker is a demo returning a
   sample PDF; uploader is fake.
7. Web build warning about CupertinoIcons font from a dependency (harmless;
   add `cupertino_icons` if Cupertino icons are ever used).
8. Browser-pane automation couldn't reliably type into Flutter web text fields,
   so chat sending was verified via the full-app widget smoke test rather
   than in the browser.
9. Debug APK is ~165 MB (all ABIs, debug); release builds are much smaller.

## 11. Decisions made without the owner

| Decision | Reason | Alternatives considered | Impact | Can change later? |
| --- | --- | --- | --- | --- |
| Bootstrap a new Flutter project in the session folder | No Flutter repo existed; remote empty | Reuse `AndroidStudioProjects/BaseProject` (native Android, unrelated) | Fresh, clean history | Yes |
| Riverpod 3 (no codegen) for state + DI | One framework, testable, overridable, no build step | Bloc + get_it, Provider, GetX | All features use providers/Notifiers | Yes, but costly |
| go_router | Official, redirects/deep links | auto_route (codegen), Navigator 2 by hand | Routes in one file | Yes |
| Dio | Interceptors, cancellation, mature | `http` + custom wrapper | Network layer | Yes (behind `ApiClient`) |
| `--dart-define-from-file` for environments (no native flavors) | Simple, cross-platform, no Gradle/Xcode scheme work | Native flavors, `.env` + flutter_dotenv | Same app id for all envs | Yes — add flavors when separate installs are needed |
| Fake backend enabled by default | Base must run without a server | Require a backend | Demo works offline | Yes (config flag) |
| No database | No current use case | Drift/Isar now | Chat history in memory | Yes (`ChatCache`) |
| Typed `MessageExtension` metadata | Extensible without a dynamic map | `Map<String, dynamic>`, freezed unions | Apps define small classes | Yes |
| Chat events + repository design | Keeps providers thin, logic tested once | Provider-specific repositories | All transports share behavior | Yes |
| AI provider base for both Remote and Local AI | Same prompt/stream/stop logic | Separate implementations | Less duplication | Yes |
| No vendor SDKs (LLM, Firebase, pickers) | Requirements + avoid lock-in/credentials | Bundle them | Interfaces + fakes only | Yes |
| Commit generated l10n files | Analyzer/IDE work right after clone | Generate on build only | Regenerate after ARB edits | Yes |
| Stricter lints (`strict-inference`, `avoid_dynamic_calls`, …) | Catch bugs early for agents | Default `flutter_lints` | Slightly more typing | Yes |
| `.gitattributes` with LF | Consistent formatting across OSes (`core.autocrlf=true` here) | Rely on per-user config | Files stored with LF | Yes |
| Switched `origin` to HTTPS and used `gh` credentials per command | No SSH key; owner instructed HTTPS | Configure SSH, `gh auth setup-git` (global change) | No global config change | Yes |
| Added `CLAUDE.md` pointing to `AGENTS.md` | Claude Code reads CLAUDE.md | Duplicate content | Single source of truth | Yes |
| Included web platform | Second platform to verify builds; quick previews | Android/iOS only | `web/` folder | Yes (delete folder) |

## 12. Recommended next steps

**P0**
- Rename package/app id and set the brand seed color for the first real app.
- Configure release signing outside the repo; enable Windows long paths or
  work from a short path.
- Decide the real backend contract; implement `HttpAuthRemoteDataSource`
  mapping and set `USE_FAKE_BACKEND=false` for staging/production.
- Install Android `cmdline-tools` and accept licenses on build machines; add
  CI (analyze + test + build apk) on GitHub Actions.

**P1**
- Persistent `ChatCache` (Drift) for offline chat history.
- Composite chat provider routing by conversation kind (AI + human support in
  one app); unread counts and read receipts.
- Concrete WebSocket `RealtimeChatTransport` + JSON `ChatEventCodec` once the
  protocol is defined.
- Real `AttachmentPicker` (file_picker/image_picker) and `FileUploader`
  (presigned S3/MinIO) in the consuming app.
- Firebase Messaging / local notifications implementations (needs credentials).
- Native flavors if separate dev/staging installs are needed.

**P2**
- Crash reporting adapter (Sentry/Crashlytics) behind `AppLogger`.
- Bottom-navigation shell (`StatefulShellRoute`) template.
- Markdown rendering for AI messages; image/video previews in bubbles.
- Integration tests on device (`integration_test`), golden tests for theme.

## 13. Review guide (15–30 minutes)

1. **Clone to a short path** (avoids the Windows path issue):
   `git clone https://github.com/trinhthimai1509/flutter_project_base.git C:\src\fpb`
2. `flutter pub get` → `flutter analyze` (expect *No issues found!*) →
   `flutter test` (expect 86 passed).
3. **Run:** `flutter run --dart-define-from-file=config/development.json`
   (Android emulator or `-d chrome`).
4. Sign-in screen: tap *Sign in* empty → validation; then *Continue as guest*.
5. **Chat demo → Mock Assistant:** send "What is this?" → streamed reply with
   *Sources*; send a long message and press **Stop**; tap **Regenerate**.
6. Send a message containing `/fail` → red bubble → tap to retry.
7. **Customer Support:** scroll up to load older pages; send a message →
   typing indicator → agent reply; paperclip → sample PDF uploads with
   progress; long-press a message → reply.
8. **Settings:** switch Dark/Light/System; switch to Tiếng Việt and back;
   restart app → preferences persist; *Sign out* → back to sign-in.
9. **Foundation showcase:** buttons, inputs, states, dialog, snackbar,
   *Send in-app notification*.
10. Close and reopen the app → session restored (guest stays signed in).
11. `git log --oneline` — 9–10 logical commits.

Files most worth reviewing:
- `lib/features/chat/domain/chat_provider.dart` and `domain/entities/*` — the generic contract.
- `lib/features/chat/data/chat_repository_impl.dart` — send/retry/stream/paginate logic.
- `lib/features/chat/data/providers/ai_chat_providers.dart` — Remote/Local AI extension points.
- `lib/core/network/interceptors/auth_interceptor.dart` + `lib/features/auth/data/auth_repository_impl.dart` — token lifecycle.
- `lib/core/navigation/route_access.dart` + `lib/app/router/app_router.dart` — guard.
- `lib/core/error/*` — failure model.
- `AGENTS.md` — rules future agents must follow.
