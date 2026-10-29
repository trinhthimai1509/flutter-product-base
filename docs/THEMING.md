# Theming

The theme is built from parameters, not by editing component styles.
Code: [`lib/core/theme/`](../lib/core/theme/).

## Brand color

```dart
// lib/app/app.dart
final appThemeProvider = Provider<AppTheme>(
  (ref) => const AppTheme(seedColor: Color(0xFF0B7A75), fontFamily: 'Inter'),
);
```

`AppTheme` derives a full Material 3 light and dark `ColorScheme` from the
seed (`ColorScheme.fromSeed`) and applies shared component styles: 48 dp
buttons, rounded cards, inputs, snackbars and dialogs. To use a font family,
add the font files to `pubspec.yaml` first.

## Dynamic color (Android 12+)

When the device offers wallpaper colors, `dynamicSeedColorProvider` reads
the wallpaper's primary color and the app builds both schemes from it with
the same tonal-spot algorithm Android uses. Users can turn it off in
Settings › Appearance › Dynamic color (`settings.dynamicColor`, on by
default). The switch is hidden on devices without dynamic colors, and the
brand seed is used there.

If your brand must always win, override
`dynamicSeedColorProvider` with `(ref) async => null`, or delete it and the
settings row.

## Semantic colors

Material 3 only defines `error`. `AppSemanticColors` (a `ThemeExtension`)
adds `success`/`onSuccess` and `warning`/`onWarning` for both brightnesses:

```dart
final colors = AppSemanticColors.of(context);
Icon(Icons.check_circle, color: colors.success);
```

The offline banner uses `warning`. Change the values in
`lib/core/theme/app_theme.dart`. Keep a contrast ratio of at least 4.5:1
between each color and its `on…` color.

## Tokens

Use `AppSpacing`, `AppRadius`, `WindowSize`/`context.windowSize` and
`AppLayout.maxContentWidth` (`app_tokens.dart`) instead of magic numbers.

## Shared widgets

`lib/shared/widgets/`: `AppButton`, `AppTextField`, `LoadingView` /
`EmptyView` / `ErrorView`, `showConfirmDialog` / `showAppSnackBar`,
`ResponsiveCenter`, `SectionHeader`, `PremiumBadge`, `OfflineBanner`.
They take already-localized strings and never hold a string resource.
Product-specific components belong to the product, not here.
