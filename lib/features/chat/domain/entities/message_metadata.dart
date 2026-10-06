import 'package:equatable/equatable.dart';

/// A typed piece of optional message data (AI generation info, citations,
/// booking reference, ...). Each extension is a small immutable class.
///
/// This keeps `Message` generic without turning metadata into an untyped
/// `Map<String, dynamic>`: consumers ask for a concrete type and either get
/// it or null.
abstract class MessageExtension extends Equatable {
  const MessageExtension();

  /// Stable identifier for serialization (cache/backend), e.g. `ai.citations`.
  String get key;

  Map<String, Object?> toJson();
}

/// Type-safe container of [MessageExtension]s, at most one per type.
class MessageMetadata extends Equatable {
  const MessageMetadata._(this._extensions);

  const MessageMetadata.empty() : _extensions = const {};

  factory MessageMetadata.of(Iterable<MessageExtension> extensions) =>
      MessageMetadata._({for (final e in extensions) e.runtimeType: e});

  final Map<Type, MessageExtension> _extensions;

  /// Returns the extension of type [T], or null.
  T? get<T extends MessageExtension>() => _extensions[T] as T?;

  bool has<T extends MessageExtension>() => _extensions.containsKey(T);

  bool get isEmpty => _extensions.isEmpty;

  Iterable<MessageExtension> get all => _extensions.values;

  /// Returns a copy with [extension] added or replaced.
  MessageMetadata put(MessageExtension extension) =>
      MessageMetadata._({..._extensions, extension.runtimeType: extension});

  MessageMetadata remove<T extends MessageExtension>() =>
      MessageMetadata._({..._extensions}..remove(T));

  Map<String, Object?> toJson() => {for (final e in all) e.key: e.toJson()};

  @override
  List<Object?> get props => [_extensions];
}
