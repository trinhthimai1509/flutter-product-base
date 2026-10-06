import '../../../core/error/result.dart';
import '../../file/domain/attachment.dart';
import 'chat_provider.dart';
import 'entities/conversation.dart';
import 'entities/message.dart';
import 'entities/participant.dart';

/// Single entry point for the chat UI. Combines a [ChatProvider] (transport)
/// with a `ChatCache` (local state) and owns optimistic sending, retry,
/// pagination and streaming assembly.
abstract interface class ChatRepository {
  ChatProviderInfo get providerInfo;

  /// The current user as a chat participant.
  Participant get self;

  Stream<List<Conversation>> watchConversations();
  Future<Result<void>> refreshConversations();

  /// Messages of a conversation, chronological. Emits the cached value
  /// immediately, then on every change.
  Stream<List<Message>> watchMessages(String conversationId);

  /// Participants currently typing in a conversation.
  Stream<Set<Participant>> watchTyping(String conversationId);

  /// Loads the newest page if nothing was loaded yet.
  Future<Result<void>> loadInitial(String conversationId);

  /// Loads the next older page. Returns whether more pages remain.
  Future<Result<bool>> loadOlder(String conversationId);

  bool hasMore(String conversationId);

  /// Sends a message optimistically. Never throws: failures are reflected as
  /// [MessageStatus.failed] on the message.
  Future<void> sendMessage(
    String conversationId, {
    String text = '',
    List<Attachment> attachments = const [],
    ReplyReference? replyTo,
  });

  /// Re-sends a failed message (same id).
  Future<void> retry(String conversationId, String messageId);

  /// No-op unless the provider supports [ChatCapability.stopGeneration].
  Future<void> stopGeneration(String conversationId);

  /// No-op unless the provider supports [ChatCapability.regenerate].
  Future<void> regenerate(String conversationId);

  Future<void> dispose();
}
