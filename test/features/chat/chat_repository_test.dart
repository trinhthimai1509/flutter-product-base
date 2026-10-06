import 'package:flutter_project_base/features/chat/data/cache/in_memory_chat_cache.dart';
import 'package:flutter_project_base/features/chat/data/chat_repository_impl.dart';
import 'package:flutter_project_base/features/chat/data/providers/mock_chat_provider.dart';
import 'package:flutter_project_base/features/chat/domain/entities/chat_event.dart';
import 'package:flutter_project_base/features/chat/domain/entities/message.dart';
import 'package:flutter_project_base/features/chat/domain/entities/participant.dart';
import 'package:flutter_project_base/features/chat/domain/extensions/ai_extensions.dart';
import 'package:flutter_project_base/features/file/data/demo_file_services.dart';
import 'package:flutter_project_base/features/file/domain/attachment.dart';
import 'package:flutter_project_base/shared/utils/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

const self = Participant(id: 'me', displayName: 'Me', type: SenderType.user);

void main() {
  late MockChatProvider provider;
  late InMemoryChatCache cache;
  late ChatRepositoryImpl repository;

  setUp(() {
    provider = MockChatProvider(
      self: self,
      tokenDelay: Duration.zero,
      replyDelay: Duration.zero,
    );
    cache = InMemoryChatCache();
    repository = ChatRepositoryImpl(
      provider: provider,
      cache: cache,
      self: self,
      ids: SequentialIdGenerator('local'),
      uploader: FakeFileUploader(stepDelay: Duration.zero, steps: 2),
      pageSize: 20,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await provider.dispose();
  });

  List<Message> messages(String id) => cache.messages(id);

  test('loads conversations into the cache', () async {
    final result = await repository.refreshConversations();
    expect(result.isOk, isTrue);
    final list = await repository.watchConversations().first;
    expect(
      list.map((c) => c.id),
      containsAll(['assistant', 'support', 'team']),
    );
  });

  test(
    'send to assistant: optimistic message, server id, streamed AI reply',
    () async {
      await repository.loadInitial('assistant');
      final statuses = <MessageStatus>[];
      final sub = repository.watchMessages('assistant').listen((list) {
        final mine = list.where((m) => m.sender.id == 'me');
        if (mine.isNotEmpty) statuses.add(mine.last.status);
      });

      await repository.sendMessage('assistant', text: '  Hello?  ');
      await sub.cancel();

      final list = messages('assistant');
      final mine = list.where((m) => m.sender.id == 'me').single;
      expect(mine.content, 'Hello?');
      expect(mine.id, startsWith('srv-'), reason: 'replaced by server copy');
      expect(mine.status, MessageStatus.sent);
      expect(statuses.first, MessageStatus.sending);

      final reply = list.last;
      expect(reply.sender.type, SenderType.ai);
      expect(reply.status, MessageStatus.sent);
      expect(reply.content, contains('Hello?'));
      expect(
        reply.metadata.get<AiGenerationInfo>()?.finishReason,
        FinishReasons.stop,
      );
      expect(reply.metadata.get<Citations>()?.sources, isNotEmpty);
    },
  );

  test('streaming emits intermediate streaming states', () async {
    final seen = <MessageStatus>{};
    final sub = repository.watchMessages('assistant').listen((list) {
      for (final m in list.where((m) => m.sender.type == SenderType.ai)) {
        seen.add(m.status);
      }
    });
    await repository.sendMessage('assistant', text: 'stream please');
    await sub.cancel();
    expect(seen, contains(MessageStatus.streaming));
  });

  test('failed send is marked failed and retry delivers it', () async {
    await repository.sendMessage('team', text: 'hello /fail');
    final failed = messages('team').where((m) => m.isFailed).single;
    expect(failed.id, 'local-1');

    await repository.retry('team', failed.id);
    final mine = messages('team').where((m) => m.sender.id == 'me').single;
    expect(mine.status, MessageStatus.sent);
    expect(messages('team').any((m) => m.isFailed), isFalse);
  });

  test('retry ignores messages that are not failed or not mine', () async {
    await repository.loadInitial('team');
    final other = messages('team').first;
    await repository.retry('team', other.id);
    expect(messages('team').first, other);
  });

  test('pagination loads older pages until exhausted', () async {
    expect(repository.hasMore('support'), isTrue);
    await repository.loadInitial('support');
    expect(messages('support'), hasLength(20));
    expect(repository.hasMore('support'), isTrue);

    var more = (await repository.loadOlder('support')).valueOrNull;
    expect(more, isTrue);
    expect(messages('support'), hasLength(40));

    more = (await repository.loadOlder('support')).valueOrNull;
    expect(more, isFalse);
    expect(messages('support'), hasLength(46)); // 45 + system message
    expect(messages('support').first.type, MessageType.system);
    expect(repository.hasMore('support'), isFalse);
  });

  test('human reply exposes typing indicator', () async {
    final typingStates = <bool>[];
    final sub = repository
        .watchTyping('support')
        .listen((s) => typingStates.add(s.isNotEmpty));
    await repository.sendMessage('support', text: 'Need help');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(typingStates, containsAllInOrder([false, true, false]));
    expect(messages('support').last.sender.type, SenderType.agent);
  });

  test('stopGeneration cancels the stream and marks the reply', () async {
    final slow = MockChatProvider(
      self: self,
      tokenDelay: const Duration(milliseconds: 5),
      replyDelay: Duration.zero,
    );
    final repo = ChatRepositoryImpl(provider: slow, cache: cache, self: self);
    final sending = repo.sendMessage('assistant', text: 'long answer');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await repo.stopGeneration('assistant');
    await sending;

    final reply = messages('assistant').last;
    expect(reply.status, MessageStatus.sent);
    expect(
      reply.metadata.get<AiGenerationInfo>()?.finishReason,
      FinishReasons.cancelled,
    );
    await repo.dispose();
    await slow.dispose();
  });

  test('regenerate produces another AI answer', () async {
    await repository.sendMessage('assistant', text: 'first');
    final before = messages('assistant').length;
    await repository.regenerate('assistant');
    final after = messages('assistant');
    expect(after.length, before + 1);
    expect(after.last.content, contains('another take'));
  });

  test('attachments are uploaded before sending', () async {
    final picked = await DemoAttachmentPicker(SequentialIdGenerator('att'))
        .pick();
    await repository.sendMessage('support', attachments: picked);
    final mine = messages('support').where((m) => m.sender.id == 'me').last;
    expect(mine.type, MessageType.file);
    final attachment = mine.attachments.single;
    expect(attachment.uploadStatus, UploadStatus.uploaded);
    expect(attachment.source, isA<RemoteAttachmentSource>());
  });

  test('empty messages are ignored', () async {
    await repository.sendMessage('team', text: '   ');
    expect(messages('team'), isEmpty);
  });

  test('incoming realtime events are applied', () async {
    provider.simulateIncoming(
      MessageUpserted(
        Message(
          id: 'push-1',
          conversationId: 'team',
          sender: MockChatProvider.teammateA,
          createdAt: DateTime.now(),
          content: 'pushed',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(messages('team').single.content, 'pushed');
  });
}
