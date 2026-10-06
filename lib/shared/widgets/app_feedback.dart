import 'package:flutter/material.dart';

import '../../core/localization/l10n.dart';

enum AppSnackType { info, success, error }

/// Feedback helpers (snackbar + dialogs) so screens don't style these ad hoc.
extension AppFeedbackX on BuildContext {
  void showAppSnackBar(
    String message, {
    AppSnackType type = AppSnackType.info,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;
    showAppSnackBarOn(
      messenger,
      Theme.of(this).colorScheme,
      message,
      type: type,
    );
  }

  /// Returns true when the user confirmed.
  Future<bool> showConfirmDialog({
    required String title,
    String? message,
    String? confirmLabel,
    bool destructive = false,
  }) async {
    final l10n = this.l10n;
    final result = await showDialog<bool>(
      context: this,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: message == null ? null : Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel ?? l10n.commonConfirm),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

/// Context-free variant, e.g. for the root messenger key.
void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  ColorScheme scheme,
  String message, {
  AppSnackType type = AppSnackType.info,
}) {
  final (background, foreground) = switch (type) {
    AppSnackType.info => (scheme.inverseSurface, scheme.onInverseSurface),
    AppSnackType.success => (scheme.primary, scheme.onPrimary),
    AppSnackType.error => (scheme.error, scheme.onError),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Text(message, style: TextStyle(color: foreground)),
      ),
    );
}
