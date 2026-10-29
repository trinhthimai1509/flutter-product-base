import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Material 3 theme built from a single seed color.
///
/// Apps re-brand by passing their own [seedColor] (and optionally a font
/// family) instead of editing component styles one by one.
class AppTheme {
  const AppTheme({this.seedColor = const Color(0xFF3557D6), this.fontFamily});

  final Color seedColor;
  final String? fontFamily;

  ThemeData get light => build(Brightness.light);
  ThemeData get dark => build(Brightness.dark);

  /// [colorScheme] replaces the seed-derived scheme, e.g. with the device's
  /// dynamic (Material You) colors on Android 12+.
  ThemeData build(Brightness brightness, {ColorScheme? colorScheme}) {
    final scheme =
        colorScheme ??
        ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      brightness: brightness,
    );
    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
      extensions: [
        brightness == Brightness.light
            ? AppSemanticColors.light
            : AppSemanticColors.dark,
      ],
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
    );
  }

  TextTheme _textTheme(TextTheme base) => base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
}

/// Status colors Material 3 does not define (it only has `error`).
/// Read with `AppSemanticColors.of(context)`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF1B7F3B),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5A00),
    onWarning: Color(0xFFFFFFFF),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF7DDC95),
    onSuccess: Color(0xFF00391A),
    warning: Color(0xFFFFB94D),
    onWarning: Color(0xFF462B00),
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;

  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) => AppSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}
