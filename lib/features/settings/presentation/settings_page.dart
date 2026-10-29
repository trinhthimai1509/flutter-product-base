import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pb_billing/pb_billing.dart';
import 'package:pb_review/pb_review.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/capabilities/capability_providers.dart';
import '../../../core/di/core_providers.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/responsive.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badges.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_state.dart';
import '../../onboarding/application/onboarding_providers.dart';
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
    final dynamicColorSupported = ref.watch(dynamicColorSupportedProvider);
    final billing = ref.watch(billingManagerProvider);
    final ads = ref.watch(adsControllerProvider);
    final external = ref.watch(externalActionsProvider);

    Future<void> open(String url) async {
      if (!await external.openUrl(url) && context.mounted) {
        context.showAppSnackBar(l10n.settingsLinkFailed);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            ValueListenableBuilder<PurchaseState>(
              valueListenable: billing.purchaseState,
              builder: (context, state, _) {
                final owned = state == PurchaseState.purchased;
                return ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(
                    owned ? l10n.settingsPremiumActive : l10n.settingsPremium,
                  ),
                  subtitle: owned ? null : Text(l10n.settingsPremiumSubtitle),
                  trailing: owned
                      ? const PremiumBadge()
                      : const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.premium),
                );
              },
            ),
            SectionHeader(l10n.settingsAppearance),
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
            if (dynamicColorSupported)
              SwitchListTile(
                secondary: const Icon(Icons.palette_outlined),
                title: Text(l10n.settingsDynamicColor),
                subtitle: Text(l10n.settingsDynamicColorSubtitle),
                value: settings.useDynamicColor,
                onChanged: controller.setUseDynamicColor,
              ),
            SectionHeader(l10n.settingsLanguage),
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
            SectionHeader(l10n.settingsNotifications),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(l10n.settingsNotifications),
              subtitle: Text(l10n.settingsNotificationsSubtitle),
              value: settings.notificationsEnabled,
              onChanged: (enabled) async {
                await controller.setNotificationsEnabled(enabled);
                if (!enabled) return;
                // Turning the app switch on is the moment to ask the OS.
                final notifications = ref.read(localNotificationsProvider);
                final granted =
                    await notifications.canPostNotifications() ||
                    await notifications.requestPermission();
                if (!granted && context.mounted) {
                  context.showAppSnackBar(
                    l10n.settingsNotificationsDenied,
                    type: AppSnackType.error,
                  );
                }
              },
            ),
            SectionHeader(l10n.settingsAbout),
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
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(l10n.settingsRateApp),
              onTap: () async {
                final review = ref.read(appReviewManagerProvider);
                if (await review.requestReview() == ReviewOutcome.unavailable) {
                  await review.openStoreListing();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.settingsShareApp),
              onTap: () =>
                  external.shareText(l10n.settingsShareMessage(config.appName)),
            ),
            if (config.privacyPolicyUrl case final url?)
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: Text(l10n.settingsPrivacyPolicy),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => open(url),
              ),
            ValueListenableBuilder<bool>(
              valueListenable: ads.privacyOptionsRequired,
              builder: (context, required, _) => required
                  ? ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.settingsPrivacyOptions),
                      onTap: ads.showPrivacyOptions,
                    )
                  : const SizedBox.shrink(),
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: Text(l10n.settingsReplayOnboarding),
              onTap: () => ref.read(onboardingControllerProvider).reset(),
            ),
            if (isSignedIn) ...[
              SectionHeader(l10n.settingsAccount),
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
