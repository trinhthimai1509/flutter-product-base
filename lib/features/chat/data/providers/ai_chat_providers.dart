import 'dart:async';

import '../../../../shared/models/paged.dart';
import '../../../../shared/utils/id_generator.dart';
import '../../domain/ai/text_generation.dart';
import '../../domain/chat_provider.dart';
import '../../domain/entities/chat_event.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_metadata.dart';
import '../../domain/entities/participant.dart';
import '../../domain/extensions/ai_extensions.dart';

/// Shared logic for providers backed by a [TextGenerationEngine]:
/// prompt building from history, streaming assembly, stop and regenerate.
///
/// Conversation history is owned by the `ChatCache`, not by the engine, so
/// [fetchMessages] returns nothing; persist the cache for durable history.
abstract class AiChatProviderBase implements GenerativeChatProvider {
  AiChatProviderBase({
    required this.engine,
    required this.assistant,
    this.systemPrompt,
    this.options = const GenerationOptions(),
    List<Conversation> conversations = const [],
    IdGenerator? ids,
    DateTime Function()? clock,
  }) : _conversations = [...conversations],
       _ids = ids ?? RandomIdGenerator(),
       _clock = clock ?? DateTime.now;

  final TextGenerationEngine engine;

  /// The participant shown as the author of generated messages.
  final Participant assistant;
  final String? systemPrompt;
  final GenerationOptions options;

  final List<Conversation> _conversations;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final Set<String> _stopRequested = {};

  @override
  ModelInfo get model => engine.model;

  /// Hook for engines that need preparation (e.g. loading a local model).
  Future<void> prepare() async {}

  @override
  Future<List<Conversation>> fetchConversations() async => [..._conversations];

  @override
  Future<Paged<Message>> fetchMessages(
    String conversationId, {
    String? before,
    int limit = 30,
  }) async => const Paged.empty();

  @override
  Stream<ChatEvent> get incoming => const Stream.empty();

  @override
  Stream<ChatEvent> send(OutgoingMessage message) async* {
    yield MessageUpserted(
      message.toMessage(status: MessageStatus.sent),
      replacesId: message.clientMessageId,
    );
    yield* _generate(message.conversationId, [
      ...message.history,
      message.toMessage(),
    ]);
  }

  @override
  Stream<ChatEvent> regenerate(
    String conversationId, {
    required List<Message> history,
  }) {
    // Drop trailing generated answers so the model answers the last user
    // message again.
    final trimmed = [...history];
    while (trimmed.isNotEmpty && trimmed.last.sender.id == assistant.id) {
      trimmed.removeLast();
    }
    if (trimmed.isEmpty) return const Stream.empty();
    return _generate(conversationId, trimmed);
  }

  @override
  Future<void> stopGeneration(String conversationId) async {
    _stopRequested.add(conversationId);
    await engine.cancel();
  }

  Stream<ChatEvent> _generate(
    String conversationId,
    List<Message> history,
  ) async* {
    _stopRequested.remove(conversationId);
    await prepare();

    var reply = Message(
      id: _ids.next(),
      conversationId: conversationId,
      sender: assistant,
      createdAt: _clock(),
      status: MessageStatus.streaming,
    );
    yield MessageUpserted(reply);

    final buffer = StringBuffer();
    final sources = <SourceReference>[];
    final tools = <ToolCallResult>[];
    DoneChunk? done;
    var failed = false;

    try {
      await for (final chunk in engine.generate(
        buildRequest(conversationId, history),
      )) {
        if (_stopRequested.contains(conversationId)) break;
        switch (chunk) {
          case TextChunk(:final text):
            buffer.write(text);
            yield MessageDelta(
              conversationId: conversationId,
              messageId: reply.id,
              delta: text,
            );
          case CitationsChunk(sources: final s):
            sources.addAll(s);
          case ToolCallChunk(:final call):
            tools.add(call);
          case DoneChunk():
            done = chunk;
        }
      }
    } catch (_) {
      failed = true;
    }

    final stopped = _stopRequested.remove(conversationId);
    var metadata = MessageMetadata.of([
      AiGenerationInfo(
        model: model,
        finishReason: failed
            ? FinishReasons.error
            : stopped
            ? FinishReasons.cancelled
            : done?.finishReason ?? FinishReasons.stop,
        promptTokens: done?.promptTokens,
        completionTokens: done?.completionTokens,
      ),
    ]);
    if (sources.isNotEmpty) metadata = metadata.put(Citations(sources));
    if (tools.isNotEmpty) metadata = metadata.put(ToolCalls(tools));

    reply = reply.copyWith(
      content: buffer.toString(),
      status: failed ? MessageStatus.failed : MessageStatus.sent,
      metadata: metadata,
    );
    yield MessageUpserted(reply);
  }

  /// Maps chat history to model turns. Override to customize prompting
  /// (e.g. inject RAG context or trim to the context window).
  GenerationRequest buildRequest(String conversationId, List<Message> history) {
    return GenerationRequest(
      conversationId: conversationId,
      options: options,
      turns: [
        if (systemPrompt != null) ChatTurn(AiRole.system, systemPrompt!),
        for (final m in history)
          if (m.sender.type != SenderType.system && m.content.isNotEmpty)
            ChatTurn(
              m.sender.isAutomated || m.sender.type == SenderType.agent
                  ? AiRole.assistant
                  : AiRole.user,
              m.content,
            ),
      ],
    );
  }

  @override
  Future<void> dispose() async {}
}

/// Chat with a remote model through a [RemoteAiClient] (your backend proxy or
/// a vendor adapter). Supports RAG citations and tool results if the client
/// emits them.
class RemoteAIChatProvider extends AiChatProviderBase {
  RemoteAIChatProvider({
    required RemoteAiClient client,
    required super.assistant,
    super.systemPrompt,
    super.options,
    super.conversations,
    super.ids,
    super.clock,
  }) : super(engine: client);

  @override
  ChatProviderInfo get info => const ChatProviderInfo(
    id: 'remote-ai',
    displayName: 'Remote AI',
    capabilities: {
      ChatCapability.streaming,
      ChatCapability.stopGeneration,
      ChatCapability.regenerate,
      ChatCapability.citations,
      ChatCapability.toolCalls,
    },
  );
}

/// Chat with an on-device model through a [LocalInferenceEngine]. The model
/// is loaded lazily on first use from [modelConfig].
class LocalAIChatProvider extends AiChatProviderBase {
  LocalAIChatProvider({
    required LocalInferenceEngine engine,
    required this.modelConfig,
    required super.assistant,
    super.systemPrompt,
    super.options,
    super.conversations,
    super.ids,
    super.clock,
  }) : _local = engine,
       super(engine: engine);

  final LocalInferenceEngine _local;
  final LocalModelConfig modelConfig;
  Future<void>? _loading;

  @override
  ChatProviderInfo get info => const ChatProviderInfo(
    id: 'local-ai',
    displayName: 'Local AI',
    capabilities: {
      ChatCapability.streaming,
      ChatCapability.stopGeneration,
      ChatCapability.regenerate,
    },
  );

  @override
  Future<void> prepare() async {
    if (_local.isLoaded) return;
    try {
      await (_loading ??= _local.load(modelConfig));
    } finally {
      _loading = null;
    }
  }

  @override
  Future<void> dispose() => _local.unload();
}
