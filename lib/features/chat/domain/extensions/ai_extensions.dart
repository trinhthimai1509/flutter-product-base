import '../entities/message_metadata.dart';

/// Optional AI-specific message data. These live on top of the generic chat
/// domain: nothing in `Message`/`Conversation` depends on them, and they
/// carry no vendor types.

/// Which model produced a message and how generation ended.
class AiGenerationInfo extends MessageExtension {
  const AiGenerationInfo({
    required this.model,
    this.finishReason,
    this.promptTokens,
    this.completionTokens,
  });

  final ModelInfo model;

  /// e.g. `stop`, `length`, `cancelled`, `error`.
  final String? finishReason;
  final int? promptTokens;
  final int? completionTokens;

  bool get wasCancelled => finishReason == FinishReasons.cancelled;

  @override
  String get key => 'ai.generation';

  @override
  Map<String, Object?> toJson() => {
    'model': model.toJson(),
    'finishReason': finishReason,
    'promptTokens': promptTokens,
    'completionTokens': completionTokens,
  };

  @override
  List<Object?> get props => [
    model,
    finishReason,
    promptTokens,
    completionTokens,
  ];
}

abstract final class FinishReasons {
  static const stop = 'stop';
  static const length = 'length';
  static const cancelled = 'cancelled';
  static const error = 'error';
}

/// Vendor-neutral model descriptor.
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.displayName,
    this.isLocal = false,
    this.contextWindow,
  });

  final String id;
  final String displayName;

  /// True when inference runs on-device.
  final bool isLocal;
  final int? contextWindow;

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'isLocal': isLocal,
    'contextWindow': contextWindow,
  };

  @override
  bool operator ==(Object other) =>
      other is ModelInfo && other.id == id && other.isLocal == isLocal;

  @override
  int get hashCode => Object.hash(id, isLocal);
}

/// Sources backing an answer (RAG / web search / knowledge base).
class Citations extends MessageExtension {
  const Citations(this.sources);

  final List<SourceReference> sources;

  @override
  String get key => 'ai.citations';

  @override
  Map<String, Object?> toJson() => {
    'sources': [for (final s in sources) s.toJson()],
  };

  @override
  List<Object?> get props => [sources];
}

class SourceReference {
  const SourceReference({
    required this.id,
    required this.title,
    this.uri,
    this.snippet,
    this.score,
  });

  final String id;
  final String title;
  final String? uri;
  final String? snippet;

  /// Retrieval relevance (0..1), when the backend provides it.
  final double? score;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'uri': uri,
    'snippet': snippet,
    'score': score,
  };

  @override
  bool operator ==(Object other) =>
      other is SourceReference && other.id == id && other.uri == uri;

  @override
  int get hashCode => Object.hash(id, uri);
}

/// Tool/function calls made while producing a message.
class ToolCalls extends MessageExtension {
  const ToolCalls(this.calls);

  final List<ToolCallResult> calls;

  @override
  String get key => 'ai.toolCalls';

  @override
  Map<String, Object?> toJson() => {
    'calls': [for (final c in calls) c.toJson()],
  };

  @override
  List<Object?> get props => [calls];
}

class ToolCallResult {
  const ToolCallResult({
    required this.id,
    required this.name,
    this.argumentsJson,
    this.resultJson,
    this.isError = false,
  });

  final String id;
  final String name;

  /// Raw JSON strings keep this type vendor-neutral.
  final String? argumentsJson;
  final String? resultJson;
  final bool isError;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'arguments': argumentsJson,
    'result': resultJson,
    'isError': isError,
  };

  @override
  bool operator ==(Object other) =>
      other is ToolCallResult && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
