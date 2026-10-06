import 'package:flutter_project_base/core/error/app_failure.dart';
import 'package:flutter_project_base/core/error/result.dart';
import 'package:flutter_project_base/core/logging/app_logger.dart';
import 'package:flutter_project_base/core/storage/secure_store.dart';
import 'package:flutter_project_base/features/auth/data/auth_remote_data_source.dart';
import 'package:flutter_project_base/features/auth/data/auth_repository_impl.dart';
import 'package:flutter_project_base/features/auth/data/auth_session_storage.dart';
import 'package:flutter_project_base/features/auth/data/fake_auth_remote_data_source.dart';
import 'package:flutter_project_base/features/auth/domain/auth_credential.dart';
import 'package:flutter_project_base/features/auth/domain/auth_session.dart';
import 'package:flutter_project_base/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  late InMemorySecureStore secureStore;
  late AuthSessionStorage storage;
  var now = DateTime(2026, 1, 1, 12);

  AuthRepositoryImpl repo(AuthRemoteDataSource remote) => AuthRepositoryImpl(
    remote: remote,
    storage: storage,
    logger: const SilentLogger(),
    clock: () => now,
  );

  AuthSession session({DateTime? expiresAt, String? refresh = 'r1'}) =>
      AuthSession(
        user: const AuthUser(id: 'u1', email: 'a@b.c'),
        accessToken: 'a1',
        refreshToken: refresh,
        expiresAt: expiresAt,
      );

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    secureStore = InMemorySecureStore();
    storage = AuthSessionStorage(secureStore);
  });

  test('sign in persists the session in secure storage', () async {
    final repository = repo(
      FakeAuthRemoteDataSource(latency: Duration.zero, clock: () => now),
    );
    final result = await repository.signIn(
      const EmailPasswordCredential(email: 'me@x.io', password: 'secret1'),
    );
    expect(result.isOk, isTrue);
    expect(repository.currentSession?.user.email, 'me@x.io');
    expect((await storage.read())?.accessToken, isNotEmpty);
  });

  test('wrong credentials return UnauthorizedFailure', () async {
    final repository = repo(FakeAuthRemoteDataSource(latency: Duration.zero));
    final result = await repository.signIn(
      const EmailPasswordCredential(email: 'me@x.io', password: '123'),
    );
    expect(result.failureOrNull, isA<UnauthorizedFailure>());
    expect(repository.currentSession, isNull);
  });

  test('guest sign in creates anonymous session', () async {
    final repository = repo(FakeAuthRemoteDataSource(latency: Duration.zero));
    final result = await repository.signIn(const GuestCredential());
    expect(result.valueOrNull?.isGuest, isTrue);
  });

  test('restores a valid stored session without network', () async {
    final remote = _MockRemote();
    await storage.write(session(expiresAt: now.add(const Duration(hours: 1))));
    final result = await repo(remote).restoreSession();
    expect(result.valueOrNull?.accessToken, 'a1');
    verifyZeroInteractions(remote);
  });

  test('refreshes an expired session on restore', () async {
    final remote = _MockRemote();
    when(() => remote.refresh('r1')).thenAnswer(
      (_) async =>
          session(expiresAt: now.add(const Duration(hours: 1)))
              .copyWith(accessToken: 'a2', refreshToken: 'r2'),
    );
    await storage.write(
      session(expiresAt: now.subtract(const Duration(minutes: 1))),
    );
    final result = await repo(remote).restoreSession();
    expect(result.valueOrNull?.accessToken, 'a2');
    expect((await storage.read())?.refreshToken, 'r2');
  });

  test('rejected refresh clears the session', () async {
    final remote = _MockRemote();
    when(() => remote.refresh(any())).thenThrow(const UnauthorizedFailure());
    await storage.write(
      session(expiresAt: now.subtract(const Duration(minutes: 1))),
    );
    final repository = repo(remote);
    final result = await repository.restoreSession();
    expect(result.valueOrNull, isNull);
    expect(await storage.read(), isNull);
    expect(repository.currentSession, isNull);
  });

  test('offline refresh keeps the stored session', () async {
    final remote = _MockRemote();
    when(() => remote.refresh(any())).thenThrow(const NetworkFailure());
    await storage.write(
      session(expiresAt: now.subtract(const Duration(minutes: 1))),
    );
    final result = await repo(remote).restoreSession();
    expect(result.valueOrNull?.accessToken, 'a1');
  });

  test('concurrent refreshes share one network call', () async {
    final remote = _MockRemote();
    var calls = 0;
    when(() => remote.refresh(any())).thenAnswer((_) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return session().copyWith(accessToken: 'a$calls');
    });
    await storage.write(session());
    final repository = repo(remote);
    await repository.restoreSession();
    final results = await Future.wait([
      repository.refreshSession(),
      repository.refreshSession(),
      repository.refreshSession(),
    ]);
    expect(calls, 1);
    expect(results.every((r) => r is Ok), isTrue);
  });

  test('sign out clears local session even if remote fails', () async {
    final remote = _MockRemote();
    registerFallbackValue(session());
    when(() => remote.signOut(any())).thenThrow(const NetworkFailure());
    await storage.write(session());
    final repository = repo(remote);
    await repository.restoreSession();
    await repository.signOut();
    expect(repository.currentSession, isNull);
    expect(await storage.read(), isNull);
  });
}
