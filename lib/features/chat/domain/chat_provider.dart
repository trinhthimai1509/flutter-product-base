import '../../../shared/models/paged.dart';
import '../../file/domain/attachment.dart';
import 'entities/chat_event.dart';
import 'entities/conversation.dart';
import 'entities/message.dart';
import 'entities/message_metadata.dart';
import 'entities/participant.dart';
import 'extensions/ai_extensions.dart';

/// Optional features a provider may support. UI and repository check these
/// instead of checking concrete provider types.
enum ChatCapability {
  streaming,
  stopGeneration,
  regenerate,
  typingIndicators,
  attachments,
  readReceipts,
  realtime,
  citations,
  toolCalls,
}

class ChatProviderInfo {
  const ChatProviderInfo({
    required this.id,
    required this.displayName,
    this.capabilities = const {},
  });

  final String id;
  final String displayName;
  final Set<ChatCapability> capabilities;

  bool supports(ChatCapability capability) => capabilities.contains(capability);
}

/// A message the current user wants to send.
class OutgoingMessage {
  const OutgoingMessage({
    required this.clientMessageId,
    required this.conversationId,
    required this.sender,
    required this.createdAt,
    this.type = MessageType.text,
    this.content = '',
    this.attachments = const [],
    this.replyTo,
    this.metadata = const MessageMetadata.empty(),
    this.history = const [],
  });

  factory OutgoingMessage.fromMessage(
    Message message, {
    List<Message> history = const [],
  }) => OutgoingMessage(
    clientMessageId: message.id,
    conversationId: message.conversationId,
    sender: message.sender,
    createdAt: message.createdAt,
    type: message.type,
    content: message.content,
    attachments: message.attachments,
    replyTo: message.replyTo,
    metadata: message.metadata,
    history: history,
  );

  /// Optimistic local id; providers echo it in `MessageUpserted.replacesId`.
  final String clientMessageId;
  final String conversationId;
  final Participant sender;
  final DateTime createdAt;
  final MessageType type;
  final String content;
  final List<Attachment> attachments;
  final ReplyReference? replyTo;
  final MessageMetadata metadata;

  /// Recent messages (oldest first) for providers that need context, such
  /// as AI providers building a prompt. Realtime providers ignore it.
  final List<Message> history;

  Message toMessage({String? id, MessageStatus status = MessageStatus.sent}) =>
      Message(
        id: id ?? clientMessageId,
        conversationId: conversationId,
        sender: sender,
        createdAt: createdAt,
        type: type,
        content: content,
        attachments: attachments,
        replyTo: replyTo,
        metadata: metadata,
        status: status,
      );
}

/// Transport/backend behind the chat engine. Swap implementations to go from
/// mock to realtime human chat, remote AI, local AI or RAG without touching
/// domain, repository or UI.
///
/// Implementations report errors as [MessageFailed] events where possible;
/// thrown errors are mapped to `AppFailure` by the repository.
abstract interface class ChatProvider {
  ChatProviderInfo get info;

  Future<List<Conversation>> fetchConversations();

  /// Page of messages older than [before] (a cursor from a previous page),
  /// items in chronological order.
  Future<Paged<Message>> fetchMessages(
    String conversationId, {
    String? before,
    int limit = 30,
  });

  /// Sends [message] and emits resulting events: acceptance, replies,
  /// streaming deltas, typing, failures. Completes when the exchange ends.
  Stream<ChatEvent> send(OutgoingMessage message);

  /// Unsolicited events (messages from other users, typing, presence).
  /// Request/response providers return an empty stream.
  Stream<ChatEvent> get incoming;

  Future<void> dispose();
}

/// Additional contract for providers backed by a generative model.
abstract interface class GenerativeChatProvider implements ChatProvider {
  ModelInfo get model;

  /// Stops the in-flight generation in [conversationId], if any. The
  /// streamed message is completed with what was generated so far.
  Future<void> stopGeneration(String conversationId);

  /// Produces a new answer for the last user message in [history].
  Stream<ChatEvent> regenerate(
    String conversationId, {
    required List<Message> history,
  });
}
