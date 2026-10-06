import 'dart:async';

import '../../../../shared/models/paged.dart';
import '../../domain/chat_provider.dart';
import '../../domain/entities/chat_event.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Bidirectional connection (WebSocket, Socket.IO, MQTT, Firebase, ...).
/// Frames are JSON-like maps so the transport stays protocol-agnostic.
abstract interface class RealtimeChatTransport {
  Future<void> connect();
  Future<void> disconnect();
  bool get isConnected;
  Stream<Map<String, dynamic>> get frames;
  Future<void> sendFrame(Map<String, dynamic> frame);
}

/// Translates between your backend's wire format and chat events.
abstract interface class ChatEventCodec {
  /// Returns null for frames that are not chat events (pings, acks...).
  ChatEvent? decode(Map<String, dynamic> frame);
  Map<String, dynamic> encodeOutgoing(OutgoingMessage message);
}

/// History/listing endpoints (usually REST alongside the socket).
abstract interface class ChatHistoryApi {
  Future<List<Conversation>> fetchConversations();
  Future<Paged<Message>> fetchMessages(
    String conversationId, {
    String? before,
    int limit,
  });
}

/// Human-to-human / support chat over a realtime transport.
///
/// Sending is optimistic: once the frame is written, the message is marked
/// `sent`; the server may later echo it (via the codec) with
/// `MessageUpserted(replacesId: clientMessageId)` to assign its own id or
/// update status to delivered/read.
class RealtimeChatProvider implements ChatProvider {
  RealtimeChatProvider({
    required this.transport,
    required this.codec,
    required this.history,
    this.capabilities = const {
      ChatCapability.realtime,
      ChatCapability.typingIndicators,
      ChatCapability.attachments,
      ChatCapability.readReceipts,
    },
  });

  final RealtimeChatTransport transport;
  final ChatEventCodec codec;
  final ChatHistoryApi history;
  final Set<ChatCapability> capabilities;

  @override
  ChatProviderInfo get info => ChatProviderInfo(
    id: 'realtime',
    displayName: 'Realtime chat',
    capabilities: capabilities,
  );

  @override
  Stream<ChatEvent> get incoming => transport.frames
      .map(codec.decode)
      .where((e) => e != null)
      .cast<ChatEvent>();

  @override
  Future<List<Conversation>> fetchConversations() =>
      history.fetchConversations();

  @override
  Future<Paged<Message>> fetchMessages(
    String conversationId, {
    String? before,
    int limit = 30,
  }) => history.fetchMessages(conversationId, before: before, limit: limit);

  @override
  Stream<ChatEvent> send(OutgoingMessage message) async* {
    if (!transport.isConnected) await transport.connect();
    await transport.sendFrame(codec.encodeOutgoing(message));
    yield MessageUpserted(
      message.toMessage(status: MessageStatus.sent),
      replacesId: message.clientMessageId,
    );
  }

  @override
  Future<void> dispose() => transport.disconnect();
}
