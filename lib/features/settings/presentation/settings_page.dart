import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/responsive.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_state.dart';
import '../application/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final config = ref.watch(appConfigProvider);
    final info = ref.watch(appInfoProvider);
    final isSignedIn = ref.watch(authControllerProvider) is Authenticated;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _SectionHeader(l10n.settingsAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto),
                    label: Text(l10n.settingsThemeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode),
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode),
                    label: Text(l10n.settingsThemeDark),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => controller.setThemeMode(s.first),
              ),
            ),
            _SectionHeader(l10n.settingsLanguage),
            RadioGroup<String>(
              groupValue: settings.locale?.languageCode ?? '',
              onChanged: (code) => controller.setLocale(
                code == null || code.isEmpty ? null : AppLocales.fromCode(code),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: '',
                    title: Text(l10n.settingsLanguageSystem),
                  ),
                  for (final locale in AppLocales.supported)
                    RadioListTile<String>(
                      value: locale.languageCode,
                      title: Text(_languageName(locale)),
                    ),
                ],
              ),
            ),
            _SectionHeader(l10n.settingsAbout),
            ListTile(
              leading: const Icon(Icons.apps),
              title: Text(l10n.settingsAppName),
              trailing: Text(config.appName),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsVersion),
              trailing: Text('${info.version} (${info.buildNumber})'),
            ),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(l10n.settingsEnvironment),
              trailing: Text(config.environment.name),
            ),
            if (isSignedIn) ...[
              _SectionHeader(l10n.settingsAccount),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(l10n.authSignOut),
                onTap: () async {
                  final confirmed = await context.showConfirmDialog(
                    title: l10n.authSignOutConfirmTitle,
                    message: l10n.authSignOutConfirmMessage,
                    confirmLabel: l10n.authSignOut,
                    destructive: true,
                  );
                  if (confirmed) {
                    await ref.read(authControllerProvider.notifier).signOut();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Language names are shown in their own language (endonyms), so they are
  /// intentionally not translated.
  static String _languageName(Locale locale) => switch (locale.languageCode) {
    'en' => 'English',
    'vi' => 'Tiếng Việt',
    _ => locale.toLanguageTag(),
  };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
