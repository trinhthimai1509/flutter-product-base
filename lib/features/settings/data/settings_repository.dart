import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/app_settings.dart';

/// Persists [AppSettings] in the key-value store.
class SettingsRepository {
  SettingsRepository(this._store);

  static const themeModeKey = 'settings.themeMode';
  static const localeKey = 'settings.locale';

  final KeyValueStore _store;

  /// Synchronous so the first frame already uses the saved theme/language.
  AppSettings load() {
    final themeName = _store.getString(themeModeKey);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      locale: AppLocales.fromCode(_store.getString(localeKey)),
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _store.setString(themeModeKey, mode.name);

  Future<void> saveLocale(Locale? locale) => locale == null
      ? _store.remove(localeKey)
      : _store.setString(localeKey, locale.languageCode);
}
