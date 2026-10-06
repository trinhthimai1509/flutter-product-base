import '../extensions/ai_extensions.dart';

/// Vendor-neutral contracts for generative backends. Remote APIs (OpenAI,
/// Anthropic, Gemini, a company RAG service...) and on-device engines
/// (llama.cpp bindings, llamadart, MLC...) are adapted to these types in the
/// consuming app. The base bundles no SDK and no model.

enum AiRole { system, user, assistant, tool }

class ChatTurn {
  const ChatTurn(this.role, this.content);

  final AiRole role;
  final String content;
}

class GenerationOptions {
  const GenerationOptions({
    this.maxTokens,
    this.temperature,
    this.stopSequences = const [],
  });

  final int? maxTokens;
  final double? temperature;
  final List<String> stopSequences;
}

class GenerationRequest {
  const GenerationRequest({
    required this.turns,
    this.options = const GenerationOptions(),
    this.conversationId,
  });

  final List<ChatTurn> turns;
  final GenerationOptions options;

  /// Lets server-side engines keep their own thread state if they want.
  final String? conversationId;
}

/// One piece of a streamed generation.
sealed class AiStreamChunk {
  const AiStreamChunk();
}

class TextChunk extends AiStreamChunk {
  const TextChunk(this.text);
  final String text;
}

/// Retrieved sources (RAG). May arrive before or after the text.
class CitationsChunk extends AiStreamChunk {
  const CitationsChunk(this.sources);
  final List<SourceReference> sources;
}

class ToolCallChunk extends AiStreamChunk {
  const ToolCallChunk(this.call);
  final ToolCallResult call;
}

class DoneChunk extends AiStreamChunk {
  const DoneChunk({
    this.finishReason = FinishReasons.stop,
    this.promptTokens,
    this.completionTokens,
  });

  final String finishReason;
  final int? promptTokens;
  final int? completionTokens;
}

/// Anything that turns a conversation into a stream of chunks.
abstract interface class TextGenerationEngine {
  ModelInfo get model;

  Stream<AiStreamChunk> generate(GenerationRequest request);

  /// Aborts the current generation (best effort).
  Future<void> cancel();
}

/// Remote model API client (HTTP/SSE/WebSocket). Implement in the app with
/// the vendor of choice; keep API keys on a backend proxy, never in the app.
abstract interface class RemoteAiClient implements TextGenerationEngine {}

class LocalModelConfig {
  const LocalModelConfig({
    required this.modelPath,
    this.contextSize = 4096,
    this.threads,
    this.gpuLayers,
  });

  /// Path to the model file on device (downloaded by the app, not bundled).
  final String modelPath;
  final int contextSize;
  final int? threads;
  final int? gpuLayers;
}

/// On-device inference engine (llama.cpp, llamadart, ...).
abstract interface class LocalInferenceEngine implements TextGenerationEngine {
  bool get isLoaded;
  Future<void> load(LocalModelConfig config);
  Future<void> unload();
}
