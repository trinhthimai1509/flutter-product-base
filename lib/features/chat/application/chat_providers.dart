import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../file/application/file_providers.dart';
import '../data/cache/in_memory_chat_cache.dart';
import '../data/chat_repository_impl.dart';
import '../data/providers/mock_chat_provider.dart';
import '../domain/chat_cache.dart';
import '../domain/chat_provider.dart';
import '../domain/chat_repository.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/participant.dart';

/// The current user as a chat participant. Only rebuilds when identity
/// changes (not on token refresh).
final chatSelfProvider = Provider<Participant>((ref) {
  final id = ref.watch(authControllerProvider.select((s) => s.user?.id));
  final name = ref.watch(
    authControllerProvider.select((s) => s.user?.displayName ?? s.user?.email),
  );
  return Participant(
    id: id ?? 'anonymous',
    displayName: name ?? 'You',
    type: SenderType.user,
  );
});

/// The transport behind the chat. The base wires [MockChatProvider];
/// apps override this with Remote/Local AI or realtime providers:
///
/// ```dart
/// chatProviderProvider.overrideWith((ref) => RemoteAIChatProvider(...))
/// ```
final chatProviderProvider = Provider<ChatProvider>((ref) {
  final provider = MockChatProvider(self: ref.watch(chatSelfProvider));
  ref.onDispose(provider.dispose);
  return provider;
});

/// Swap for a persistent implementation (Drift/SQLite) for offline history.
final chatCacheProvider = Provider<ChatCache>((ref) {
  // New user => fresh cache, so data never leaks between accounts.
  ref.watch(chatSelfProvider.select((p) => p.id));
  return InMemoryChatCache();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repository = ChatRepositoryImpl(
    provider: ref.watch(chatProviderProvider),
    cache: ref.watch(chatCacheProvider),
    self: ref.watch(chatSelfProvider),
    uploader: ref.watch(fileUploaderProvider),
    logger: ref.watch(appLoggerProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// Conversation list; triggers a refresh from the provider on first listen.
final conversationsProvider = StreamProvider.autoDispose<List<Conversation>>((
  ref,
) async* {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.refreshConversations();
  if (result.failureOrNull case final failure?) throw failure;
  yield* repository.watchConversations();
});
