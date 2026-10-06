import 'package:flutter/material.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/failure_messages.dart';
import '../../core/localization/l10n.dart';
import '../../core/theme/app_tokens.dart';

/// Centered progress indicator with optional label.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Placeholder for empty lists/screens.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String? title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _MessageLayout(
      icon: icon,
      title: title ?? context.l10n.commonEmpty,
      message: message,
      action: action,
    );
  }
}

/// Error placeholder with retry. Pass a [failure] to get a localized message.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.failure, this.message, this.onRetry});

  final AppFailure? failure;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MessageLayout(
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      title: l10n.commonErrorTitle,
      message: message ?? failure?.localizedMessage(l10n),
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
    );
  }
}

class _MessageLayout extends StatelessWidget {
  const _MessageLayout({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
