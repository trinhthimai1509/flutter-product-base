# Adding Features

Checklists and templates for extending the base. Example used throughout: a
generic `announcements` feature (list of announcements from an API).

First ask: **is this generic?** If it only makes sense for one product, build
it in that product's repository on top of the base, not here.

---

## How to add a new feature

```
lib/features/announcements/
├── domain/
│   ├── announcement.dart              # entity (pure Dart, Equatable)
│   └── announcement_repository.dart   # abstract interface
├── data/
│   ├── announcement_remote_data_source.dart
│   └── announcement_repository_impl.dart
├── application/
│   └── announcement_providers.dart    # providers + controller(s)
└── presentation/
    └── announcements_page.dart
```

Checklist:
- [ ] Create only the layers you need (a purely local feature may have no `data/remote`).
- [ ] Domain has no Flutter/Dio/Riverpod imports.
- [ ] Strings added to `app_en.arb` **and** `app_vi.arb`.
- [ ] Route + access rule added (see below).
- [ ] Unit tests for repository/controller, widget test for new reusable widgets.
- [ ] `flutter analyze` clean, `flutter test` green.
- [ ] Docs: update `docs/REPORT.md` status; architecture docs if you add a new pattern.

## How to add an API

1. Define the data source contract and an HTTP implementation using
   `ApiClient` (throws `AppFailure` only):

```dart
abstract interface class AnnouncementRemoteDataSource {
  Future<List<Announcement>> fetch({CancelToken? cancelToken});
}

class HttpAnnouncementRemoteDataSource implements AnnouncementRemoteDataSource {
  HttpAnnouncementRemoteDataSource(this._client);
  final ApiClient _client;

  @override
  Future<List<Announcement>> fetch({CancelToken? cancelToken}) async {
    final json = await _client.get<List<dynamic>>('/announcements', cancelToken: cancelToken);
    return [for (final item in json) Announcement.fromJson(item as Map<String, dynamic>)];
  }
}
```

2. Use `apiClientProvider` (authenticated) or `publicApiClientProvider`
   (no token, no refresh).
3. If the backend error format differs, adapt `ErrorMapper.fromStatus`
   (`_messageOf`, `_fieldErrorsOf`) once — not per feature.
4. Optionally add a `Fake…DataSource` and select it when
   `appConfigProvider.useFakeBackend` is true.

## How to add a repository

```dart
abstract interface class AnnouncementRepository {
  Future<Result<List<Announcement>>> getAll();
}

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._remote);
  final AnnouncementRemoteDataSource _remote;

  @override
  Future<Result<List<Announcement>>> getAll() => guard(_remote.fetch);
}
```

- Interface in `domain/`, implementation in `data/`.
- Return `Result<T>`; use `guard()` so any thrown error becomes `Err(AppFailure)`.
- Caching/merging logic belongs here, not in the UI.

## How to add a dependency (DI)

```dart
// application/announcement_providers.dart
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(
    HttpAnnouncementRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);

final announcementsProvider = FutureProvider.autoDispose<List<Announcement>>((ref) async {
  final result = await ref.watch(announcementRepositoryProvider).getAll();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});
```

- Prefer `Notifier`/`AsyncNotifier` when the screen has actions; `FutureProvider`
  / `StreamProvider` for read-only data.
- Need a value created at startup (async init)? Declare a provider that throws
  and override it in `app/bootstrap/bootstrap.dart`.
- Need core to call into your feature? Define an interface in `core/`,
  implement it in the feature, override the core provider in bootstrap.

**Adding a pub package:** prefer well-maintained, popular, vendor-neutral
packages; wrap them behind an interface if they touch many files; document
the reason in `docs/REPORT.md` (Dependencies). Never add a second
state-management library.

## How to add a screen

```dart
class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(announcementsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.announcementsTitle)),
      body: data.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          failure: e is AppFailure ? e : null,
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyView()
            : ResponsiveCenter(child: ListView(/* ... */)),
      ),
    );
  }
}
```

- Use `LoadingView` / `EmptyView` / `ErrorView`, `AppButton`, `AppTextField`,
  `showAppSnackBar`, `showConfirmDialog`.
- Use `AppSpacing`/`AppRadius`; wrap content in `ResponsiveCenter`.
- Keep widgets dumb where possible: pass data + callbacks so they are
  testable without providers.

## How to add a route

1. `lib/app/router/app_routes.dart`:
   ```dart
   static const announcements = '/home/announcements';
   ```
   If the route needs non-default access, add it to `AppRoutes.access`
   (`public`, `signedOutOnly`, `signedIn` — default is `signedIn`).
2. `lib/app/router/app_router.dart`: add a `GoRoute` (nested under `/home`
   for authenticated pages):
   ```dart
   GoRoute(path: 'announcements', builder: (_, _) => const AnnouncementsPage()),
   ```
3. Navigate with `context.push(AppRoutes.announcements)` (or `go`).
4. Path parameters: `':id'` + `state.pathParameters['id']`; build paths with
   a helper like `AppRoutes.conversation(id)`.
5. Add a guard test in `test/core/route_guard_test.dart` if you add access rules.

## How to add tests

| What | Where | Tooling |
| --- | --- | --- |
| Pure logic, mappers | `test/core/…`, `test/features/<f>/…` | `test()` |
| Repositories | `test/features/<f>/…` | fakes or `mocktail` mocks of data sources |
| Controllers/providers | same | `createTestContainer(overrides: [...])` |
| Widgets | `test/widgets/…` | `testApp(widget)` gives theme + l10n |
| App flows | `test/app_smoke_test.dart` | `ProviderScope(overrides: baseTestOverrides())` + `App()` |

```dart
test('getAll maps failures', () async {
  final remote = _MockRemote();
  when(() => remote.fetch(cancelToken: any(named: 'cancelToken')))
      .thenThrow(const NetworkFailure());
  final result = await AnnouncementRepositoryImpl(remote).getAll();
  expect(result.failureOrNull, isA<NetworkFailure>());
});
```

Tips:
- `baseTestOverrides()` gives in-memory storage, silent logger, zero-latency
  fake auth. Add `retry: noRetry` to containers/scopes.
- After `enterText`, call `tester.pump()` before tapping buttons whose enabled
  state depends on the text.
- Mock providers with zero delays (e.g. `MockChatProvider(tokenDelay: Duration.zero, replyDelay: Duration.zero)`).

## Removing a feature

Delete `lib/features/<name>/`, its routes, links (e.g. in `HomePage`), ARB
keys, tests and any bootstrap overrides. Run analyze — the compiler will show
any remaining references.
