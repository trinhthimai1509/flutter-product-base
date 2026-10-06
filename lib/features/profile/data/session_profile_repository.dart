import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

/// Builds the profile from the current auth session. Replace with a remote
/// implementation (e.g. `GET /me`) when the backend exposes profile data.
class SessionProfileRepository implements ProfileRepository {
  SessionProfileRepository(this._currentSession);

  final AuthSession? Function() _currentSession;

  @override
  Future<Result<UserProfile>> getCurrentProfile() async {
    final user = _currentSession()?.user;
    if (user == null) return const Err(UnauthorizedFailure('No session'));
    return Ok(
      UserProfile(
        id: user.id,
        displayName: user.displayName,
        email: user.email,
        avatarUrl: user.avatarUrl,
        isGuest: user.isAnonymous,
      ),
    );
  }
}
