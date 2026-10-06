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

  ThemeData get light => _build(Brightness.light);
  ThemeData get dark => _build(Brightness.dark);

  ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      brightness: brightness,
    );
    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
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
