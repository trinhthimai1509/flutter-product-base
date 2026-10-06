import 'dart:async';

import '../../../../core/error/app_failure.dart';
import '../../../../shared/models/paged.dart';
import '../../../../shared/utils/id_generator.dart';
import '../../domain/chat_provider.dart';
import '../../domain/entities/chat_event.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_metadata.dart';
import '../../domain/entities/participant.dart';
import '../../domain/extensions/ai_extensions.dart';

/// In-process provider for demos and tests. Simulates three conversation
/// styles with one engine to prove the chat domain is generic:
///
/// * `assistant` — AI: streamed token-by-token reply, stop, regenerate,
///   citations when the message contains a `?`.
/// * `support` — human agent: typing indicator then a full reply; has a long
///   history to demonstrate pagination.
/// * `team` — group chat between humans.
///
/// Include `/fail` in a message to make its first send attempt fail (retry
/// then succeeds).
class MockChatProvider implements GenerativeChatProvider {
  MockChatProvider({
    required this.self,
    this.tokenDelay = const Duration(milliseconds: 35),
    this.replyDelay = const Duration(milliseconds: 500),
    this.supportHistorySize = 45,
    IdGenerator? ids,
    DateTime Function()? clock,
  }) : _ids = ids ?? RandomIdGenerator(),
       _clock = clock ?? DateTime.now {
    _seed();
  }

  static const assistantConversationId = 'assistant';
  static const supportConversationId = 'support';
  static const teamConversationId = 'team';

  static const assistantParticipant = Participant(
    id: 'mock-ai',
    displayName: 'Mock Assistant',
    type: SenderType.ai,
  );
  static const agentParticipant = Participant(
    id: 'agent-linh',
    displayName: 'Linh (Support)',
    type: SenderType.agent,
  );
  static const teammateA = Participant(
    id: 'user-an',
    displayName: 'An',
    type: SenderType.user,
  );
  static const teammateB = Participant(
    id: 'user-binh',
    displayName: 'Bình',
    type: SenderType.user,
  );

  final Participant self;
  final Duration tokenDelay;
  final Duration replyDelay;
  final int supportHistorySize;
  final IdGenerator _ids;
  final DateTime Function() _clock;

  final Map<String, Conversation> _conversations = {};
  final Map<String, List<Message>> _store = {};
  final Set<String> _failedOnce = {};
  final Set<String> _stopRequested = {};
  final _incoming = StreamController<ChatEvent>.broadcast();

  @override
  ChatProviderInfo get info => const ChatProviderInfo(
    id: 'mock',
    displayName: 'Mock provider',
    capabilities: {
      ChatCapability.streaming,
      ChatCapability.stopGeneration,
      ChatCapability.regenerate,
      ChatCapability.typingIndicators,
      ChatCapability.attachments,
      ChatCapability.citations,
    },
  );

  @override
  ModelInfo get model =>
      const ModelInfo(id: 'mock-1', displayName: 'Mock model');

  @override
  Stream<ChatEvent> get incoming => _incoming.stream;

  /// Pushes an unsolicited event, as a realtime server would.
  void simulateIncoming(ChatEvent event) => _incoming.add(event);

  // ---------------------------------------------------------------------------

  @override
  Future<List<Conversation>> fetchConversations() async {
    await Future<void>.delayed(replyDelay ~/ 2);
    return _conversations.values.toList();
  }

  @override
  Future<Paged<Message>> fetchMessages(
    String conversationId, {
    String? before,
    int limit = 30,
  }) async {
    await Future<void>.delayed(replyDelay ~/ 2);
    final all = _store[conversationId] ?? const <Message>[];
    var end = all.length;
    if (before != null) {
      final index = all.indexWhere((m) => m.id == before);
      end = index < 0 ? 0 : index;
    }
    final start = (end - limit).clamp(0, end);
    final items = all.sublist(start, end);
    return Paged(items: items, nextCursor: start > 0 ? items.first.id : null);
  }

  @override
  Stream<ChatEvent> send(OutgoingMessage message) async* {
    await Future<void>.delayed(replyDelay ~/ 2);
    final cid = message.conversationId;

    if (message.content.contains('/fail') &&
        _failedOnce.add(message.clientMessageId)) {
      yield MessageFailed(
        conversationId: cid,
        messageId: message.clientMessageId,
        failure: const NetworkFailure(message: 'Simulated failure'),
      );
      return;
    }

    final accepted = message.toMessage(
      id: 'srv-${_ids.next()}',
      status: MessageStatus.sent,
    );
    _remember(accepted);
    yield MessageUpserted(accepted, replacesId: message.clientMessageId);

    final kind = _conversations[cid]?.kind ?? ConversationKind.assistant;
    switch (kind) {
      case ConversationKind.assistant:
        yield* _generate(cid, message.content);
      case ConversationKind.support:
        yield* _humanReply(cid, agentParticipant, _supportReply(message));
      case ConversationKind.group:
      case ConversationKind.direct:
        final mate = message.content.length.isEven ? teammateA : teammateB;
        yield* _humanReply(cid, mate, '👍 Got it: "${_short(message)}"');
    }
  }

  @override
  Stream<ChatEvent> regenerate(
    String conversationId, {
    required List<Message> history,
  }) {
    final lastUser = history.lastWhere(
      (m) => m.sender.id == self.id,
      orElse: () => history.isEmpty
          ? Message(
              id: 'none',
              conversationId: conversationId,
              sender: self,
              createdAt: _clock(),
            )
          : history.last,
    );
    return _generate(conversationId, lastUser.content, regenerated: true);
  }

  @override
  Future<void> stopGeneration(String conversationId) async =>
      _stopRequested.add(conversationId);

  @override
  Future<void> dispose() => _incoming.close();

  // ---------------------------------------------------------------------------

  Stream<ChatEvent> _generate(
    String conversationId,
    String prompt, {
    bool regenerated = false,
  }) async* {
    _stopRequested.remove(conversationId);
    var reply = Message(
      id: 'ai-${_ids.next()}',
      conversationId: conversationId,
      sender: assistantParticipant,
      createdAt: _clock(),
      status: MessageStatus.streaming,
    );
    yield MessageUpserted(reply);

    final buffer = StringBuffer();
    var stopped = false;
    for (final token in _tokenize(_answerFor(prompt, regenerated))) {
      if (_stopRequested.contains(conversationId)) {
        stopped = true;
        break;
      }
      await Future<void>.delayed(tokenDelay);
      buffer.write(token);
      yield MessageDelta(
        conversationId: conversationId,
        messageId: reply.id,
        delta: token,
      );
    }
    _stopRequested.remove(conversationId);

    var metadata = MessageMetadata.of([
      AiGenerationInfo(
        model: model,
        finishReason: stopped ? FinishReasons.cancelled : FinishReasons.stop,
        completionTokens: buffer.toString().split(' ').length,
      ),
    ]);
    if (prompt.contains('?')) {
      metadata = metadata.put(
        const Citations([
          SourceReference(
            id: 'doc-1',
            title: 'Chat module guide',
            uri: 'docs/CHAT_MODULE.md',
            snippet: 'Providers are replaceable behind ChatProvider.',
          ),
          SourceReference(
            id: 'doc-2',
            title: 'Architecture overview',
            uri: 'docs/ARCHITECTURE.md',
          ),
        ]),
      );
    }
    reply = reply.copyWith(
      content: buffer.toString(),
      status: MessageStatus.sent,
      metadata: metadata,
    );
    _remember(reply);
    yield MessageUpserted(reply);
  }

  Stream<ChatEvent> _humanReply(
    String conversationId,
    Participant from,
    String text,
  ) async* {
    yield TypingChanged(
      conversationId: conversationId,
      participant: from,
      isTyping: true,
    );
    await Future<void>.delayed(replyDelay * 2);
    yield TypingChanged(
      conversationId: conversationId,
      participant: from,
      isTyping: false,
    );
    final reply = Message(
      id: 'srv-${_ids.next()}',
      conversationId: conversationId,
      sender: from,
      createdAt: _clock(),
      content: text,
    );
    _remember(reply);
    yield MessageUpserted(reply);
  }

  String _answerFor(String prompt, bool regenerated) {
    final quote = prompt.length > 60 ? '${prompt.substring(0, 60)}…' : prompt;
    final intro = regenerated
        ? 'Here is another take.'
        : 'This reply is streamed by MockChatProvider.';
    return '$intro You wrote: "$quote". Replace this provider with '
        'RemoteAIChatProvider or LocalAIChatProvider to talk to a real '
        'model — the repository, state and UI stay exactly the same.';
  }

  String _supportReply(OutgoingMessage message) {
    if (message.attachments.isNotEmpty) {
      final names = message.attachments.map((a) => a.name).join(', ');
      return 'Thanks, I received $names. I will take a look.';
    }
    return 'Thanks for reaching out! An agent reply to "${_short(message)}".';
  }

  String _short(OutgoingMessage m) {
    final text = m.content.isEmpty
        ? m.attachments.map((a) => a.name).join(', ')
        : m.content;
    return text.length > 40 ? '${text.substring(0, 40)}…' : text;
  }

  Iterable<String> _tokenize(String text) sync* {
    final words = text.split(' ');
    for (var i = 0; i < words.length; i++) {
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }

  void _remember(Message message) {
    final list = _store.putIfAbsent(message.conversationId, () => []);
    list
      ..removeWhere((m) => m.id == message.id)
      ..add(message)
      ..sort(Message.compareByTime);
  }

  void _seed() {
    final now = _clock();
    _conversations[assistantConversationId] = Conversation(
      id: assistantConversationId,
      title: 'Mock Assistant',
      kind: ConversationKind.assistant,
      participants: [self, assistantParticipant],
      updatedAt: now,
    );
    _remember(
      Message(
        id: 'seed-ai-welcome',
        conversationId: assistantConversationId,
        sender: assistantParticipant,
        createdAt: now.subtract(const Duration(minutes: 1)),
        content:
            'Hi! I am a mock AI assistant. Ask me anything — end with "?" '
            'to see citations.',
      ),
    );

    _conversations[supportConversationId] = Conversation(
      id: supportConversationId,
      title: 'Customer Support',
      kind: ConversationKind.support,
      participants: [self, agentParticipant],
      updatedAt: now.subtract(const Duration(minutes: 5)),
    );
    final start = now.subtract(Duration(minutes: 10 * supportHistorySize));
    _remember(
      Message(
        id: 'seed-support-0000',
        conversationId: supportConversationId,
        sender: Participant.system,
        type: MessageType.system,
        createdAt: start.subtract(const Duration(minutes: 1)),
        content: 'Conversation started',
      ),
    );
    for (var i = 1; i <= supportHistorySize; i++) {
      final fromAgent = i.isEven;
      _remember(
        Message(
          id: 'seed-support-${i.toString().padLeft(4, '0')}',
          conversationId: supportConversationId,
          sender: fromAgent ? agentParticipant : self,
          createdAt: start.add(Duration(minutes: 10 * i)),
          content: fromAgent
              ? 'Agent message #$i (older history for pagination)'
              : 'My message #$i',
          status: fromAgent ? MessageStatus.sent : MessageStatus.read,
        ),
      );
    }

    _conversations[teamConversationId] = Conversation(
      id: teamConversationId,
      title: 'Product Team',
      kind: ConversationKind.group,
      participants: [self, teammateA, teammateB],
      updatedAt: now.subtract(const Duration(hours: 1)),
    );
    _remember(
      Message(
        id: 'seed-team-1',
        conversationId: teamConversationId,
        sender: teammateA,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 2)),
        content: 'Morning! Did everyone see the new chat module?',
      ),
    );
    _remember(
      Message(
        id: 'seed-team-2',
        conversationId: teamConversationId,
        sender: teammateB,
        createdAt: now.subtract(const Duration(hours: 1)),
        content: 'Yes — same engine for AI, support and team chat 🎉',
      ),
    );

    // Expose last messages for the conversation list.
    for (final entry in _store.entries) {
      final conversation = _conversations[entry.key];
      if (conversation == null || entry.value.isEmpty) continue;
      _conversations[entry.key] = conversation.copyWith(
        lastMessage: entry.value.last,
      );
    }
  }
}
