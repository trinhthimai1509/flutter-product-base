import 'package:equatable/equatable.dart';

import '../../../file/domain/attachment.dart';
import 'message_metadata.dart';
import 'participant.dart';

enum MessageType { text, image, video, audio, file, system, custom }

enum MessageStatus {
  /// Created locally, being delivered.
  sending,

  /// Accepted by the provider/server.
  sent,

  /// Reached the recipient's device (realtime chats).
  delivered,

  /// Seen by the recipient.
  read,

  /// Content is still arriving (streamed AI responses).
  streaming,

  /// Delivery failed; can be retried.
  failed,
}

/// Lightweight pointer to the message being replied to, with enough data to
/// render the quote without loading the original.
class ReplyReference extends Equatable {
  const ReplyReference({
    required this.messageId,
    required this.senderName,
    required this.preview,
  });

  factory ReplyReference.of(Message message, {int maxLength = 120}) {
    final text = message.content.isNotEmpty
        ? message.content
        : message.attachments.map((a) => a.name).join(', ');
    return ReplyReference(
      messageId: message.id,
      senderName: message.sender.displayName,
      preview: text.length > maxLength
          ? '${text.substring(0, maxLength)}…'
          : text,
    );
  }

  final String messageId;
  final String senderName;
  final String preview;

  @override
  List<Object?> get props => [messageId, senderName, preview];
}

/// Generic chat message, independent of transport and of AI vendors.
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.createdAt,
    this.type = MessageType.text,
    this.content = '',
    this.attachments = const [],
    this.status = MessageStatus.sent,
    this.replyTo,
    this.metadata = const MessageMetadata.empty(),
  });

  final String id;
  final String conversationId;
  final Participant sender;
  final MessageType type;

  /// Text content (may be empty for attachment-only messages).
  final String content;
  final List<Attachment> attachments;
  final MessageStatus status;
  final DateTime createdAt;
  final ReplyReference? replyTo;
  final MessageMetadata metadata;

  bool get isFailed => status == MessageStatus.failed;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get isPending => status == MessageStatus.sending;

  Message copyWith({
    String? id,
    MessageType? type,
    String? content,
    List<Attachment>? attachments,
    MessageStatus? status,
    DateTime? createdAt,
    ReplyReference? replyTo,
    MessageMetadata? metadata,
  }) => Message(
    id: id ?? this.id,
    conversationId: conversationId,
    sender: sender,
    type: type ?? this.type,
    content: content ?? this.content,
    attachments: attachments ?? this.attachments,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    replyTo: replyTo ?? this.replyTo,
    metadata: metadata ?? this.metadata,
  );

  /// Chronological order with id as tie-breaker (stable sorting).
  static int compareByTime(Message a, Message b) {
    final byTime = a.createdAt.compareTo(b.createdAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    sender,
    type,
    content,
    attachments,
    status,
    createdAt,
    replyTo,
    metadata,
  ];
}
