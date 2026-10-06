import '../localization/l10n.dart';
import 'app_failure.dart';

/// Presentation helper: localized, user-safe text for a failure.
extension AppFailureMessage on AppFailure {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    NetworkFailure(reason: NetworkFailureReason.timeout) => l10n.errorTimeout,
    NetworkFailure() => l10n.errorNetwork,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    ForbiddenFailure() => l10n.errorForbidden,
    NotFoundFailure() => l10n.errorNotFound,
    ValidationFailure() => l10n.errorValidation,
    ServerFailure() => l10n.errorServer,
    StorageFailure() => l10n.errorStorage,
    CancelledFailure() || UnknownFailure() => l10n.errorUnknown,
  };
}
