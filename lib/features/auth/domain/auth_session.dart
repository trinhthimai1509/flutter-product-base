import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// Tokens + user for an authenticated (or guest) session.
class AuthSession extends Equatable {
  const AuthSession({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String?,
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
  );

  final AuthUser user;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool get isGuest => user.isAnonymous;
  bool get canRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  /// Treats tokens as expired slightly early to avoid racing the server.
  bool isExpired(
    DateTime now, {
    Duration leeway = const Duration(seconds: 30),
  }) => expiresAt != null && !now.isBefore(expiresAt!.subtract(leeway));

  AuthSession copyWith({
    AuthUser? user,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) => AuthSession(
    user: user ?? this.user,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [user, accessToken, refreshToken, expiresAt];

  /// Never print tokens.
  @override
  String toString() => 'AuthSession(user: ${user.id}, guest: $isGuest)';
}
