import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// User preferences that affect the whole app.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.useDynamicColor = true,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;

  /// Use the wallpaper-derived palette where the OS offers one (Android 12+).
  final bool useDynamicColor;

  /// The app's own switch, independent of the OS permission. What it gates
  /// (reminders, marketing) is the product's decision.
  final bool notificationsEnabled;

  /// Null means "follow the device language".
  final Locale? locale;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? Function()? locale,
    bool? useDynamicColor,
    bool? notificationsEnabled,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: locale == null ? this.locale : locale(),
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
  );

  @override
  List<Object?> get props => [
    themeMode,
    locale,
    useDynamicColor,
    notificationsEnabled,
  ];
}
