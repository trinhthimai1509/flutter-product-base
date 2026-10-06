import 'package:equatable/equatable.dart';

/// Unified failure model. Every layer above `data/` sees only [AppFailure],
/// never exceptions from Dio, platform channels or databases.
///
/// [message] is a developer-facing description (safe to log, never contains
/// secrets). User-facing text is produced in the presentation layer, see
/// `failure_messages.dart`.
sealed class AppFailure extends Equatable implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;

  /// Original error, kept for logging/debugging only.
  final Object? cause;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType: $message';
}

enum NetworkFailureReason { noConnection, timeout }

class NetworkFailure extends AppFailure {
  const NetworkFailure({
    this.reason = NetworkFailureReason.noConnection,
    String message = 'Network unavailable',
    super.cause,
  }) : super(message);

  final NetworkFailureReason reason;

  @override
  List<Object?> get props => [...super.props, reason];
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Unauthorized', Object? cause])
    : super(cause: cause);
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'Forbidden', Object? cause])
    : super(cause: cause);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found', Object? cause])
    : super(cause: cause);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({
    String message = 'Validation failed',
    this.fieldErrors = const {},
    super.cause,
  }) : super(message);

  /// Field name -> list of error messages, as returned by the backend.
  final Map<String, List<String>> fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

class ServerFailure extends AppFailure {
  const ServerFailure({
    String message = 'Server error',
    this.statusCode,
    super.cause,
  }) : super(message);

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

class StorageFailure extends AppFailure {
  const StorageFailure([super.message = 'Storage error', Object? cause])
    : super(cause: cause);
}

/// The operation was cancelled by the caller (e.g. a cancelled request or a
/// stopped AI generation). Usually not shown to the user.
class CancelledFailure extends AppFailure {
  const CancelledFailure([super.message = 'Cancelled', Object? cause])
    : super(cause: cause);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Unknown error', Object? cause])
    : super(cause: cause);
}
