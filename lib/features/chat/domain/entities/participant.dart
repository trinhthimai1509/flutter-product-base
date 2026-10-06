import 'package:equatable/equatable.dart';

/// What kind of party sent a message. Drives rendering and routing, never
/// vendor logic.
enum SenderType {
  /// A human end user (including the current user).
  user,

  /// A human support/operator agent.
  agent,

  /// A scripted/rule-based bot.
  bot,

  /// A generative AI model (remote or on-device).
  ai,

  /// The system itself (joins, notices, dividers).
  system,
}

class Participant extends Equatable {
  const Participant({
    required this.id,
    required this.displayName,
    required this.type,
    this.avatarUrl,
  });

  static const system = Participant(
    id: 'system',
    displayName: 'System',
    type: SenderType.system,
  );

  final String id;
  final String displayName;
  final SenderType type;
  final String? avatarUrl;

  bool get isHuman => type == SenderType.user || type == SenderType.agent;
  bool get isAutomated => type == SenderType.bot || type == SenderType.ai;

  @override
  List<Object?> get props => [id, displayName, type, avatarUrl];
}
