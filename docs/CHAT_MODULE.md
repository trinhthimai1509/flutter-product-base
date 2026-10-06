# Chat Module

`lib/features/chat` is a **generic chat engine**. The same domain, repository,
state and widgets serve:

| Scenario | Provider |
| --- | --- |
| User ↔ User (direct / group) | `RealtimeChatProvider` + your transport |
| User ↔ Support agent | `RealtimeChatProvider` (agents are `SenderType.agent`) |
| User ↔ Bot | any provider; bot = `SenderType.bot` |
| User ↔ Remote AI | `RemoteAIChatProvider` + your `RemoteAiClient` |
| User ↔ Local AI | `LocalAIChatProvider` + your `LocalInferenceEngine` |
| User ↔ Enterprise RAG | `RemoteAIChatProvider` (citations via `CitationsChunk`) or a custom provider |
| Demo / tests | `MockChatProvider` |

Nothing outside a provider knows which of these is in use.

## Layering

```
presentation/   ConversationListPage, ConversationPage,
                MessageBubble, ChatComposer, TypingIndicator, AttachmentChip
      │
application/    chatProviderProvider, chatCacheProvider, chatRepositoryProvider,
                conversationsProvider, ConversationController (per conversation)
      │
domain/         Conversation, Message, Participant, SenderType, MessageType,
                MessageStatus, ReplyReference, MessageMetadata/MessageExtension,
                ChatEvent, ChatProvider, GenerativeChatProvider, ChatCapability,
                ChatRepository, ChatCache,
                ai/text_generation.dart, extensions/ai_extensions.dart (optional AI layer)
      ▲
data/           ChatRepositoryImpl, InMemoryChatCache,
                providers/{mock, ai (Remote/Local), realtime}
```

## Domain

### Participant & SenderType

```dart
enum SenderType { user, agent, bot, ai, system }
Participant(id, displayName, type, avatarUrl)
```

The current user is a `Participant` built from the auth session
(`chatSelfProvider`). `isMine` is `message.sender.id == self.id`.

### Message

| Field | Notes |
| --- | --- |
| `id` | Client id while sending; may be replaced by the server id |
| `conversationId` | |
| `sender` | `Participant` |
| `type` | `text, image, video, audio, file, system, custom` |
| `content` | Text (may be empty for attachment-only messages) |
| `attachments` | `List<Attachment>` from the file module |
| `status` | `sending, sent, delivered, read, streaming, failed` |
| `createdAt` | |
| `replyTo` | `ReplyReference(messageId, senderName, preview)` — renders without loading the original |
| `metadata` | `MessageMetadata` (typed extensions, see below) |

### Controlled metadata

`MessageMetadata` is a container of **typed** `MessageExtension`s, at most one
per type:

```dart
class BookingRef extends MessageExtension {          // defined in YOUR app
  const BookingRef(this.bookingId);
  final String bookingId;
  @override String get key => 'app.booking';          // stable serialization key
  @override Map<String, Object?> toJson() => {'bookingId': bookingId};
  @override List<Object?> get props => [bookingId];
}

final m = message.copyWith(metadata: message.metadata.put(const BookingRef('b1')));
m.metadata.get<BookingRef>()?.bookingId;              // typed access, null if absent
```

This gives extensibility without a `Map<String, dynamic>` free-for-all: every
piece of extra data has a type, an owner and a serialization key.

Built-in optional extensions (`domain/extensions/ai_extensions.dart`):
`AiGenerationInfo` (model, finish reason, token usage), `Citations`
(`SourceReference` list for RAG), `ToolCalls` (`ToolCallResult` list).
They contain no vendor types.

### Conversation

`id, title, kind (direct | group | support | assistant), participants,
updatedAt, lastMessage, unreadCount`. `kind` is a UI hint only.

## Provider abstraction

```dart
abstract interface class ChatProvider {
  ChatProviderInfo get info;                           // id, name, capabilities
  Future<List<Conversation>> fetchConversations();
  Future<Paged<Message>> fetchMessages(String conversationId, {String? before, int limit});
  Stream<ChatEvent> send(OutgoingMessage message);     // reply events for this send
  Stream<ChatEvent> get incoming;                      // unsolicited realtime events
  Future<void> dispose();
}

abstract interface class GenerativeChatProvider implements ChatProvider {
  ModelInfo get model;
  Future<void> stopGeneration(String conversationId);
  Stream<ChatEvent> regenerate(String conversationId, {required List<Message> history});
}
```

**Events** (`ChatEvent`, sealed) are the only language between providers and
the repository:

| Event | Meaning |
| --- | --- |
| `MessageUpserted(message, replacesId?)` | insert/replace (acceptance with server id, replies, final streamed message) |
| `MessageDelta(conversationId, messageId, delta)` | streaming chunk appended to content |
| `MessageFailed(conversationId, messageId, failure)` | delivery failed |
| `TypingChanged(conversationId, participant, isTyping)` | typing indicator |
| `ConversationUpserted(conversation)` | conversation created/updated |

**Capabilities** (`ChatCapability`): `streaming, stopGeneration, regenerate,
typingIndicators, attachments, readReceipts, realtime, citations, toolCalls`.
The UI shows the stop button / regenerate / attach only when supported.

## Repository (`ChatRepositoryImpl`)

Owns all chat behavior so providers stay thin:

- **Optimistic send:** creates the message locally (`sending`) → uploads local
  attachments through `FileUploader` (status/progress on the attachment) →
  calls `provider.send()` with recent `history` (default 20 messages) →
  applies events. Thrown errors or `MessageFailed` → `failed`.
- **Retry:** `retry(conversationId, messageId)` re-sends a failed message of
  the current user with the same id.
- **Streaming:** `MessageDelta`s are appended to the message in the cache;
  the UI re-renders on every change; final `MessageUpserted` sets `sent` and
  metadata.
- **Pagination:** cursor-based. `loadInitial` fetches the newest page;
  `loadOlder` fetches pages before the cursor until `nextCursor` is null.
  The list is reversed in the UI and loads more near the top.
- **Typing:** per conversation set of typing participants
  (`watchTyping`).
- **Realtime:** subscribes to `provider.incoming` for the repository's
  lifetime and applies events the same way.
- **Stop / regenerate:** delegated to `GenerativeChatProvider` when the
  capability exists, otherwise no-ops.
- **Cache:** everything goes through `ChatCache` (source of truth for UI).

## Cache

`ChatCache` stores conversations and messages and exposes streams. The base
ships `InMemoryChatCache` (lost on restart). For offline history implement
`ChatCache` with Drift/SQLite/Isar and override `chatCacheProvider`. The
cache is recreated when the signed-in user changes, so data never leaks
between accounts.

## State & UI

- `conversationsProvider` — refreshes from the provider, then streams the
  cache.
- `conversationControllerProvider(conversationId)` — `ConversationState`:
  messages, initial/more loading, `hasMore`, `loadFailure`, typing,
  `replyTo`, pending attachments, `isGenerating`. Actions: `send`, `retry`,
  `loadMore`, `stopGeneration`, `regenerate`, `setReplyTo`,
  `addAttachments`, `removeAttachment`.
- Widgets are callback-based and Riverpod-free (`MessageBubble`,
  `ChatComposer`, `TypingIndicator`, `AttachmentChip`) so apps can restyle or
  reuse them with any state solution.

## Realtime chat (user↔user, support)

`RealtimeChatProvider` needs three app-supplied adapters:

```dart
abstract interface class RealtimeChatTransport {   // WebSocket, Socket.IO, MQTT, Firebase…
  Future<void> connect(); Future<void> disconnect(); bool get isConnected;
  Stream<Map<String, dynamic>> get frames;
  Future<void> sendFrame(Map<String, dynamic> frame);
}
abstract interface class ChatEventCodec {          // your wire format ⇄ ChatEvent
  ChatEvent? decode(Map<String, dynamic> frame);
  Map<String, dynamic> encodeOutgoing(OutgoingMessage message);
}
abstract interface class ChatHistoryApi {          // REST listing/history
  Future<List<Conversation>> fetchConversations();
  Future<Paged<Message>> fetchMessages(String conversationId, {String? before, int limit});
}
```

Sending is optimistic (marked `sent` once the frame is written). The server
can echo the message as `MessageUpserted(replacesId: clientMessageId)` to
assign its id, and later send `delivered`/`read` updates the same way.
Typing → `TypingChanged`. Reconnect/backoff and presence belong in your
transport. No concrete WebSocket transport or JSON codec ships in the base
(it depends on your backend protocol).

## Remote AI

```dart
class MyBackendAiClient implements RemoteAiClient {
  @override ModelInfo get model => const ModelInfo(id: 'gpt-x', displayName: 'Assistant');
  @override Stream<AiStreamChunk> generate(GenerationRequest request) async* {
    // POST request.turns to YOUR backend (which holds the vendor API key),
    // parse SSE/WebSocket chunks and yield:
    //   TextChunk('…'), CitationsChunk([...]), ToolCallChunk(...), DoneChunk(...)
  }
  @override Future<void> cancel() async { /* cancel the HTTP request */ }
}

// Wire it:
chatProviderProvider.overrideWith((ref) => RemoteAIChatProvider(
  client: MyBackendAiClient(ref.watch(apiClientProvider)),
  assistant: const Participant(id: 'assistant', displayName: 'Assistant', type: SenderType.ai),
  systemPrompt: 'You are a helpful assistant.',
  conversations: [/* initial assistant conversations */],
));
```

`AiChatProviderBase` builds the prompt from history (user → `user`, ai/bot/
agent → `assistant`, system messages skipped), streams deltas, supports stop
(`TextGenerationEngine.cancel()`) and regenerate, and stores
`AiGenerationInfo`/`Citations`/`ToolCalls` in metadata. Override
`buildRequest` to customize prompting or trim to the context window.

**Never put vendor API keys in the app.** Proxy through your backend.

## Local AI (on-device)

```dart
class LlamaEngine implements LocalInferenceEngine {   // e.g. llama.cpp / llamadart bindings
  @override bool get isLoaded => …;
  @override Future<void> load(LocalModelConfig config) => …; // config.modelPath (downloaded at runtime)
  @override Future<void> unload() => …;
  @override ModelInfo get model => const ModelInfo(id: 'llama-3-8b-q4', displayName: 'Llama 3', isLocal: true);
  @override Stream<AiStreamChunk> generate(GenerationRequest r) => …; // yield TextChunk per token
  @override Future<void> cancel() => …;
}

chatProviderProvider.overrideWith((ref) => LocalAIChatProvider(
  engine: LlamaEngine(),
  modelConfig: const LocalModelConfig(modelPath: '/path/to/model.gguf', contextSize: 4096),
  assistant: const Participant(id: 'local-ai', displayName: 'On-device AI', type: SenderType.ai),
));
```

The model is loaded lazily on first generation and kept loaded; `dispose`
unloads it. The base bundles **no** model and **no** native inference
dependency — add them in the app that needs offline AI. Pair with a
persistent `ChatCache` for offline history.

## RAG

Two options:
1. **Server-side RAG (recommended):** your backend retrieves documents and
   streams the answer. Emit `CitationsChunk(sources)` from your
   `RemoteAiClient`; the bubble shows a *Sources* row automatically.
2. **Client-side retrieval:** subclass `RemoteAIChatProvider` /
   `LocalAIChatProvider` and override `buildRequest` to inject retrieved
   context as a system turn, and emit citations from the engine.

`SourceReference(id, title, uri, snippet, score)` is vendor-neutral.

## Creating a new provider

1. Implement `ChatProvider` (or `GenerativeChatProvider`) in
   `features/chat/data/providers/` **of your app** (or here only if generic).
2. Declare honest `ChatProviderInfo.capabilities`.
3. In `send`, emit `MessageUpserted(accepted, replacesId: outgoing.clientMessageId)`
   then reply events; report failures as `MessageFailed` (or throw — the
   repository maps it to `failed`).
4. Push unsolicited traffic through `incoming`.
5. Return cursor pages from `fetchMessages` (`Paged(items, nextCursor)`),
   items chronological.
6. Override `chatProviderProvider` in bootstrap or a `ProviderScope`.
7. Test it like `test/features/chat/chat_providers_test.dart` with a fake
   transport/engine, and run it through `ChatRepositoryImpl` as in
   `chat_repository_test.dart`.

To use different providers per conversation (e.g. AI assistant + human
support in one app), write a small composite provider that routes by
`conversationId` / `Conversation.kind` — see REPORT "next steps".
