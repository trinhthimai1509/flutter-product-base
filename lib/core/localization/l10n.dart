import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Supported locales. Add a locale here AND an `app_<code>.arb` file
/// (see README "Adding a language").
abstract final class AppLocales {
  static const english = Locale('en');
  static const vietnamese = Locale('vi');

  static const supported = AppLocalizations.supportedLocales;

  static Locale? fromCode(String? code) {
    if (code == null) return null;
    for (final locale in supported) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }
}

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
