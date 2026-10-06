import '../../../../core/error/app_failure.dart';
import 'conversation.dart';
import 'message.dart';
import 'participant.dart';

/// Everything a [ChatProvider] can tell the repository. Both replies to a
/// send and unsolicited realtime traffic use the same event vocabulary.
sealed class ChatEvent {
  const ChatEvent();
}

/// Insert or replace a message. When [replacesId] is set, the message with
/// that id (usually the optimistic local copy) is replaced, which lets
/// servers assign their own ids.
class MessageUpserted extends ChatEvent {
  const MessageUpserted(this.message, {this.replacesId});

  final Message message;
  final String? replacesId;
}

/// Streaming chunk appended to an existing message's content.
class MessageDelta extends ChatEvent {
  const MessageDelta({
    required this.conversationId,
    required this.messageId,
    required this.delta,
  });

  final String conversationId;
  final String messageId;
  final String delta;
}

class MessageFailed extends ChatEvent {
  const MessageFailed({
    required this.conversationId,
    required this.messageId,
    required this.failure,
  });

  final String conversationId;
  final String messageId;
  final AppFailure failure;
}

class TypingChanged extends ChatEvent {
  const TypingChanged({
    required this.conversationId,
    required this.participant,
    required this.isTyping,
  });

  final String conversationId;
  final Participant participant;
  final bool isTyping;
}

class ConversationUpserted extends ChatEvent {
  const ConversationUpserted(this.conversation);

  final Conversation conversation;
}
