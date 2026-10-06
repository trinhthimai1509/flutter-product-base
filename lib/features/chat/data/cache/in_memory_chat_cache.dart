import 'dart:async';

import '../../domain/chat_cache.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Volatile [ChatCache]. Data lives for the app session only.
class InMemoryChatCache implements ChatCache {
  final List<Conversation> _conversations = [];
  final Map<String, Map<String, Message>> _messages = {};

  final _conversationChanges = StreamController<void>.broadcast();
  final _messageChanges = StreamController<String>.broadcast();

  @override
  List<Conversation> get conversations {
    final sorted = [..._conversations]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  @override
  Stream<List<Conversation>> watchConversations() => Stream.multi((controller) {
    controller.add(conversations);
    final sub = _conversationChanges.stream.listen(
      (_) => controller.add(conversations),
    );
    controller.onCancel = sub.cancel;
  });

  @override
  Future<void> putConversations(List<Conversation> conversations) async {
    _conversations
      ..clear()
      ..addAll(conversations);
    _conversationChanges.add(null);
  }

  @override
  Future<void> upsertConversation(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
    _conversationChanges.add(null);
  }

  @override
  List<Message> messages(String conversationId) => List<Message>.unmodifiable(
    (_messages[conversationId]?.values.toList() ?? <Message>[])
      ..sort(Message.compareByTime),
  );

  @override
  Message? message(String conversationId, String messageId) =>
      _messages[conversationId]?[messageId];

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.multi((controller) {
        controller.add(messages(conversationId));
        final sub = _messageChanges.stream
            .where((id) => id == conversationId)
            .listen((_) => controller.add(messages(conversationId)));
        controller.onCancel = sub.cancel;
      });

  @override
  Future<void> upsertMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) return;
    final bucket = _messages.putIfAbsent(conversationId, () => {});
    for (final message in messages) {
      bucket[message.id] = message;
    }
    _messageChanges.add(conversationId);
  }

  @override
  Future<void> replaceMessage(
    String conversationId,
    String oldId,
    Message message,
  ) async {
    final bucket = _messages.putIfAbsent(conversationId, () => {});
    bucket
      ..remove(oldId)
      ..[message.id] = message;
    _messageChanges.add(conversationId);
  }

  @override
  Future<void> clear() async {
    _conversations.clear();
    final ids = _messages.keys.toList();
    _messages.clear();
    _conversationChanges.add(null);
    ids.forEach(_messageChanges.add);
  }
}
