import '../../../core/error/result.dart';
import 'auth_credential.dart';
import 'auth_session.dart';

abstract interface class AuthRepository {
  /// Loads a persisted session, refreshing it if expired.
  /// Returns `Ok(null)` when there is no usable session.
  Future<Result<AuthSession?>> restoreSession();

  Future<Result<AuthSession>> signIn(AuthCredential credential);

  /// Exchanges the stored refresh token for new tokens.
  Future<Result<AuthSession>> refreshSession();

  /// In-memory current session (no I/O).
  AuthSession? get currentSession;

  /// Clears local session; best-effort server logout.
  Future<void> signOut();
}
