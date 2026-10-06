import 'package:flutter_project_base/core/auth/session_status.dart';
import 'package:flutter_project_base/core/storage/secure_store.dart';
import 'package:flutter_project_base/features/auth/application/auth_providers.dart';
import 'package:flutter_project_base/features/auth/data/auth_session_storage.dart';
import 'package:flutter_project_base/features/auth/domain/auth_session.dart';
import 'package:flutter_project_base/features/auth/domain/auth_state.dart';
import 'package:flutter_project_base/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('starts unknown, then unauthenticated without stored session', () async {
    final container = createTestContainer();
    expect(container.read(authControllerProvider), isA<AuthUnknown>());
    await _settle();
    await _settle();
    expect(container.read(authControllerProvider), isA<Unauthenticated>());
    expect(
      container.read(authControllerProvider).status,
      SessionStatus.signedOut,
    );
  });

  test('restores a stored session', () async {
    final secure = InMemorySecureStore();
    await AuthSessionStorage(secure).write(
      const AuthSession(
        user: AuthUser(id: 'u1', displayName: 'Mai'),
        accessToken: 'a',
      ),
    );
    final container = createTestContainer(secureStore: secure);
    container.read(authControllerProvider);
    await _settle();
    await _settle();
    expect(container.read(authControllerProvider).user?.displayName, 'Mai');
  });

  test('sign in, guest and sign out update state', () async {
    final container = createTestContainer();
    final controller = container.read(authControllerProvider.notifier);
    await _settle();

    final result = await controller.signInWithEmail(' me@x.io ', 'secret1');
    expect(result.isOk, isTrue);
    expect(container.read(authControllerProvider).user?.email, 'me@x.io');

    await controller.signOut();
    expect(container.read(authControllerProvider), isA<Unauthenticated>());

    await controller.continueAsGuest();
    final state = container.read(authControllerProvider);
    expect(state.status, SessionStatus.signedIn);
    expect(state.session?.isGuest, isTrue);
  });

  test('failed sign in keeps user signed out', () async {
    final container = createTestContainer();
    final controller = container.read(authControllerProvider.notifier);
    await _settle();
    await _settle();
    final result = await controller.signInWithEmail('me@x.io', '1');
    expect(result.isOk, isFalse);
    expect(container.read(authControllerProvider), isA<Unauthenticated>());
  });
}
