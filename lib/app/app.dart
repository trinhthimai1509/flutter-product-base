import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/core_providers.dart';
import '../core/localization/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/notification/presentation/in_app_notification_listener.dart';
import '../features/settings/application/settings_controller.dart';
import 'router/app_router.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Theme used by the app; override to re-brand.
final appThemeProvider = Provider<AppTheme>((ref) => const AppTheme());

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = ref.watch(appThemeProvider);
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      routerConfig: ref.watch(routerProvider),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => InAppNotificationListener(
        messengerKey: rootScaffoldMessengerKey,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
