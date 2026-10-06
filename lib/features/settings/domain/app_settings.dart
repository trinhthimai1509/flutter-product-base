import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// User preferences that affect the whole app.
class AppSettings extends Equatable {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;

  /// Null means "follow the device language".
  final Locale? locale;

  AppSettings copyWith({ThemeMode? themeMode, Locale? Function()? locale}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale == null ? this.locale : locale(),
      );

  @override
  List<Object?> get props => [themeMode, locale];
}
