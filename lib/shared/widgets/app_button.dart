import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, text }

/// Standard button with built-in loading state.
///
/// While [isLoading] is true the button is disabled and shows a spinner, which
/// prevents double submission.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: callback, child: child),
    };

    return Semantics(
      button: true,
      label: isLoading ? label : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
