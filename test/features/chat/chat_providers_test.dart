import 'dart:async';

import 'package:flutter_project_base/features/chat/data/providers/ai_chat_providers.dart';
import 'package:flutter_project_base/features/chat/data/providers/realtime_chat_provider.dart';
import 'package:flutter_project_base/features/chat/domain/ai/text_generation.dart';
import 'package:flutter_project_base/features/chat/domain/chat_provider.dart';
import 'package:flutter_project_base/features/chat/domain/entities/chat_event.dart';
import 'package:flutter_project_base/features/chat/domain/entities/conversation.dart';
import 'package:flutter_project_base/features/chat/domain/entities/message.dart';
import 'package:flutter_project_base/features/chat/domain/entities/participant.dart';
import 'package:flutter_project_base/features/chat/domain/extensions/ai_extensions.dart';
import 'package:flutter_project_base/shared/models/paged.dart';
import 'package:flutter_project_base/shared/utils/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

const me = Participant(id: 'me', displayName: 'Me', type: SenderType.user);
const bot = Participant(id: 'bot', displayName: 'Bot', type: SenderType.ai);

OutgoingMessage outgoing(String text, {List<Message> history = const []}) =>
    OutgoingMessage(
      clientMessageId: 'c1',
      conversationId: 'conv',
      sender: me,
      createdAt: DateTime(2026),
      content: text,
      history: history,
    );

/// Scripted engine standing in for a remote API or local model.
class FakeEngine implements LocalInferenceEngine, RemoteAiClient {
  FakeEngine(this.chunks, {this.delay = Duration.zero});

  final List<AiStreamChunk> chunks;
  final Duration delay;
  GenerationRequest? lastRequest;
  int loads = 0;
  bool cancelled = false;
  bool _loaded = false;

  @override
  ModelInfo get model => const ModelInfo(id: 'fake', displayName: 'Fake');

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load(LocalModelConfig config) async {
    loads++;
    _loaded = true;
  }

  @override
  Future<void> unload() async => _loaded = false;

  @override
  Stream<AiStreamChunk> generate(GenerationRequest request) async* {
    lastRequest = request;
    for (final chunk in chunks) {
      await Future<void>.delayed(delay);
      if (cancelled) return;
      yield chunk;
    }
  }

  @override
  Future<void> cancel() async => cancelled = true;
}

String assemble(List<ChatEvent> events) {
  final buffer = StringBuffer();
  for (final e in events.whereType<MessageDelta>()) {
    buffer.write(e.delta);
  }
  return buffer.toString();
}

void main() {
  group('RemoteAIChatProvider', () {
    test('streams deltas and attaches citations/tool calls', () async {
      final engine = FakeEngine([
        const TextChunk('Hello'),
        const TextChunk(' world'),
        const CitationsChunk([SourceReference(id: 's1', title: 'Doc')]),
        const ToolCallChunk(ToolCallResult(id: 't1', name: 'search')),
        const DoneChunk(completionTokens: 2),
      ]);
      final provider = RemoteAIChatProvider(
        client: engine,
        assistant: bot,
        systemPrompt: 'Be nice',
        ids: SequentialIdGenerator(),
      );

      final events = await provider.send(outgoing('Hi')).toList();

      final accepted = events.first as MessageUpserted;
      expect(accepted.replacesId, 'c1');
      expect(accepted.message.status, MessageStatus.sent);
      expect(assemble(events), 'Hello world');

      final finalMsg = (events.last as MessageUpserted).message;
      expect(finalMsg.sender, bot);
      expect(finalMsg.content, 'Hello world');
      expect(finalMsg.metadata.get<Citations>()?.sources.single.id, 's1');
      expect(finalMsg.metadata.get<ToolCalls>()?.calls.single.name, 'search');
      expect(finalMsg.metadata.get<AiGenerationInfo>()?.completionTokens, 2);

      final turns = engine.lastRequest!.turns;
      expect(turns.first.role, AiRole.system);
      expect(turns.last.role, AiRole.user);
      expect(turns.last.content, 'Hi');
      expect(provider.info.supports(ChatCapability.citations), isTrue);
    });

    test('maps history to roles', () async {
      final engine = FakeEngine([const TextChunk('ok')]);
      final provider = RemoteAIChatProvider(client: engine, assistant: bot);
      final history = [
        Message(
          id: '1',
          conversationId: 'conv',
          sender: me,
          createdAt: DateTime(2026),
          content: 'q1',
        ),
        Message(
          id: '2',
          conversationId: 'conv',
          sender: bot,
          createdAt: DateTime(2026),
          content: 'a1',
        ),
        Message(
          id: '3',
          conversationId: 'conv',
          sender: Participant.system,
          createdAt: DateTime(2026),
          content: 'joined',
        ),
      ];
      await provider.send(outgoing('q2', history: history)).toList();
      final roles = engine.lastRequest!.turns.map((t) => t.role).toList();
      expect(roles, [AiRole.user, AiRole.assistant, AiRole.user]);
    });

    test('engine errors produce a failed reply instead of throwing', () async {
      final provider = RemoteAIChatProvider(
        client: _ThrowingEngine(),
        assistant: bot,
      );
      final events = await provider.send(outgoing('Hi')).toList();
      final reply = (events.last as MessageUpserted).message;
      expect(reply.status, MessageStatus.failed);
      expect(
        reply.metadata.get<AiGenerationInfo>()?.finishReason,
        FinishReasons.error,
      );
    });

    test('regenerate re-answers the last user message', () async {
      final engine = FakeEngine([const TextChunk('again')]);
      final provider = RemoteAIChatProvider(client: engine, assistant: bot);
      final history = [
        Message(
          id: '1',
          conversationId: 'conv',
          sender: me,
          createdAt: DateTime(2026),
          content: 'q',
        ),
        Message(
          id: '2',
          conversationId: 'conv',
          sender: bot,
          createdAt: DateTime(2026),
          content: 'old',
        ),
      ];
      final events = await provider
          .regenerate('conv', history: history)
          .toList();
      expect(assemble(events), 'again');
      expect(engine.lastRequest!.turns.last.content, 'q');
    });
  });

  group('LocalAIChatProvider', () {
    test('loads the model lazily once and stops on request', () async {
      final engine = FakeEngine(
        List.generate(50, (i) => TextChunk('t$i ')),
        delay: const Duration(milliseconds: 2),
      );
      final provider = LocalAIChatProvider(
        engine: engine,
        modelConfig: const LocalModelConfig(modelPath: '/models/x.gguf'),
        assistant: bot,
      );
      expect(engine.loads, 0);

      final events = <ChatEvent>[];
      final done = provider.send(outgoing('Hi')).forEach(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 15));
      await provider.stopGeneration('conv');
      await done;

      expect(engine.loads, 1);
      expect(engine.cancelled, isTrue);
      final reply = (events.last as MessageUpserted).message;
      expect(
        reply.metadata.get<AiGenerationInfo>()?.finishReason,
        FinishReasons.cancelled,
      );
      expect(events.whereType<MessageDelta>().length, lessThan(50));

      engine.cancelled = false;
      await provider.send(outgoing('Again')).toList();
      expect(engine.loads, 1, reason: 'model stays loaded');
      expect(provider.model.id, 'fake');
    });
  });

  group('RealtimeChatProvider', () {
    test('sends frames, connects lazily and decodes incoming frames', () async {
      final transport = _FakeTransport();
      final provider = RealtimeChatProvider(
        transport: transport,
        codec: _Codec(),
        history: _History(),
      );

      final incoming = <ChatEvent>[];
      final sub = provider.incoming.listen(incoming.add);

      final events = await provider.send(outgoing('hey')).toList();
      expect(transport.connected, isTrue);
      expect(transport.sent.single, {
        'type': 'message',
        'text': 'hey',
        'clientId': 'c1',
      });
      expect(
        (events.single as MessageUpserted).message.status,
        MessageStatus.sent,
      );

      transport.push({'type': 'typing', 'user': 'u2'});
      transport.push({'type': 'ping'});
      await Future<void>.delayed(Duration.zero);
      expect(incoming.single, isA<TypingChanged>());

      await sub.cancel();
      await provider.dispose();
      expect(transport.connected, isFalse);
    });
  });
}

class _ThrowingEngine implements RemoteAiClient {
  @override
  ModelInfo get model => const ModelInfo(id: 'x', displayName: 'X');

  @override
  Stream<AiStreamChunk> generate(GenerationRequest request) =>
      Stream.error(StateError('boom'));

  @override
  Future<void> cancel() async {}
}

class _FakeTransport implements RealtimeChatTransport {
  final _frames = StreamController<Map<String, dynamic>>.broadcast();
  final sent = <Map<String, dynamic>>[];
  bool connected = false;

  void push(Map<String, dynamic> frame) => _frames.add(frame);

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async => connected = true;

  @override
  Future<void> disconnect() async {
    connected = false;
    await _frames.close();
  }

  @override
  Stream<Map<String, dynamic>> get frames => _frames.stream;

  @override
  Future<void> sendFrame(Map<String, dynamic> frame) async => sent.add(frame);
}

class _Codec implements ChatEventCodec {
  @override
  ChatEvent? decode(Map<String, dynamic> frame) => switch (frame['type']) {
    'typing' => TypingChanged(
      conversationId: 'conv',
      participant: Participant(
        id: frame['user'] as String,
        displayName: 'U2',
        type: SenderType.user,
      ),
      isTyping: true,
    ),
    _ => null,
  };

  @override
  Map<String, dynamic> encodeOutgoing(OutgoingMessage message) => {
    'type': 'message',
    'text': message.content,
    'clientId': message.clientMessageId,
  };
}

class _History implements ChatHistoryApi {
  @override
  Future<List<Conversation>> fetchConversations() async => [];

  @override
  Future<Paged<Message>> fetchMessages(
    String conversationId, {
    String? before,
    int limit = 30,
  }) async => const Paged.empty();
}
