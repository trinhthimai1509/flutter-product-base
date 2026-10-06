import 'app_failure.dart';
import 'error_mapper.dart';

/// Explicit success/failure return type for repositories and use cases.
///
/// Usage:
/// ```dart
/// switch (await repo.load()) {
///   case Ok(:final value): ...
///   case Err(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppFailure failure) = Err<T>;

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  AppFailure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}

/// Runs [body] and converts any thrown error into an [Err] via [mapError].
Future<Result<T>> guard<T>(
  Future<T> Function() body, {
  AppFailure Function(Object error, StackTrace stackTrace) mapError =
      ErrorMapper.map,
}) async {
  try {
    return Ok(await body());
  } catch (error, stackTrace) {
    return Err(mapError(error, stackTrace));
  }
}
