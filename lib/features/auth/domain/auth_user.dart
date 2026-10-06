import 'package:equatable/equatable.dart';

/// Identity of the signed-in principal. Deliberately minimal: business
/// profile data belongs to the profile feature or the consuming app.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.isAnonymous = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String?,
    displayName: json['displayName'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    isAnonymous: json['isAnonymous'] as bool? ?? false,
  );

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  /// True for guest sessions.
  final bool isAnonymous;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'isAnonymous': isAnonymous,
  };

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl, isAnonymous];
}
