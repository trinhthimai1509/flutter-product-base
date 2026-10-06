import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../auth/application/auth_providers.dart';
import '../data/session_profile_repository.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SessionProfileRepository(() => repository.currentSession);
});

/// Reloads whenever the auth state changes.
final currentProfileProvider = FutureProvider<UserProfile>((ref) async {
  ref.watch(authControllerProvider);
  final result = await ref.watch(profileRepositoryProvider).getCurrentProfile();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});
