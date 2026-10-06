import 'entities/conversation.dart';
import 'entities/message.dart';

/// Local store of conversations/messages, the source of truth for the UI.
///
/// The base ships an in-memory implementation. For offline persistence,
/// implement this with Drift/SQLite/Isar; nothing else changes.
abstract interface class ChatCache {
  List<Conversation> get conversations;
  Stream<List<Conversation>> watchConversations();
  Future<void> putConversations(List<Conversation> conversations);
  Future<void> upsertConversation(Conversation conversation);

  /// Chronological messages of a conversation.
  List<Message> messages(String conversationId);
  Message? message(String conversationId, String messageId);
  Stream<List<Message>> watchMessages(String conversationId);

  Future<void> upsertMessages(String conversationId, List<Message> messages);

  /// Replaces [oldId] with [message] (e.g. optimistic -> server copy).
  Future<void> replaceMessage(
    String conversationId,
    String oldId,
    Message message,
  );

  Future<void> clear();
}
