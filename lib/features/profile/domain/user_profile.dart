import 'package:equatable/equatable.dart';

/// Generic user profile. Contains only fields every app needs; apps extend
/// it by composition (e.g. `DriverProfile { UserProfile base; ... }`) rather
/// than adding business fields here.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.isGuest = false,
  });

  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final bool isGuest;

  /// Up to two initials for avatar placeholders.
  String get initials {
    final source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (email ?? '');
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'[\s._@-]+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  List<Object?> get props => [id, displayName, email, avatarUrl, isGuest];
}
