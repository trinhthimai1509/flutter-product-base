import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pb_ads/pb_ads.dart';
import 'package:pb_billing/pb_billing.dart';
import 'package:pb_notifications/pb_notifications.dart';
import 'package:pb_review/pb_review.dart';
import 'package:pb_telemetry/pb_telemetry.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/capabilities/capability_providers.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/responsive.dart';
import '../../../shared/widgets/section_header.dart';
import '../../onboarding/application/onboarding_providers.dart';

/// Catalog of the opt-in capability packages, each exercised for real (or
/// through its fake where the build has no store/SDK). A verification
/// screen, not product UI: delete it in a real app.
class CapabilitiesPage extends ConsumerStatefulWidget {
  const CapabilitiesPage({super.key});

  @override
  ConsumerState<CapabilitiesPage> createState() => _CapabilitiesPageState();
}

class _CapabilitiesPageState extends ConsumerState<CapabilitiesPage> {
  bool? _canNotify;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final can = await ref
        .read(localNotificationsProvider)
        .canPostNotifications();
    if (mounted) setState(() => _canNotify = can);
  }

  void _snack(String message) => context.showAppSnackBar(message);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final online = ref.watch(isOnlineProvider).value ?? true;
    final telemetry = ref.watch(telemetryProvider);
    final notifications = ref.watch(localNotificationsProvider);
    final review = ref.watch(appReviewManagerProvider);
    final ads = ref.watch(adsControllerProvider);
    final billing = ref.watch(billingManagerProvider);
    final onboarding = ref.watch(onboardingControllerProvider);

    Widget actions(List<Widget> children) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: children,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeCapabilitiesTitle)),
      bottomNavigationBar: AppBannerAd(controller: ads),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            SectionHeader(l10n.capConnectivity),
            ListTile(
              leading: Icon(online ? Icons.wifi : Icons.wifi_off),
              title: Text(online ? l10n.capOnline : l10n.capOffline),
            ),
            SectionHeader(l10n.capTelemetry),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(l10n.capTelemetryBackend(telemetry.backendName)),
            ),
            actions([
              OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(analyticsProvider)
                      .logEvent(
                        const AnalyticsEvent('demo_button', {'source': 'demo'}),
                      );
                  _snack(l10n.capEventLogged);
                },
                child: Text(l10n.capLogEvent),
              ),
            ]),
            SectionHeader(l10n.settingsNotifications),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(
                l10n.capPermissionStatus(
                  _canNotify ?? false
                      ? l10n.capPermissionGranted
                      : l10n.capPermissionNotGranted,
                ),
              ),
            ),
            actions([
              OutlinedButton(
                onPressed: () async {
                  await notifications.requestPermission();
                  await _refreshPermission();
                },
                child: Text(l10n.capRequestPermission),
              ),
              OutlinedButton(
                onPressed: () => notifications.show(
                  LocalNotification(
                    id: 'demo',
                    channelId: AppNotificationChannels.reminders,
                    title: l10n.notificationDemoTitle,
                    body: l10n.notificationDemoBody,
                    payload: AppRoutes.capabilities,
                  ),
                ),
                child: Text(l10n.capShowNow),
              ),
              OutlinedButton(
                onPressed: () async {
                  await notifications.schedule(
                    ReminderRequest(
                      id: 'demo-reminder',
                      triggerAt: DateTime.now().add(
                        const Duration(seconds: 10),
                      ),
                      channelId: AppNotificationChannels.reminders,
                      title: l10n.notificationDemoTitle,
                      body: l10n.notificationDemoBody,
                      payload: AppRoutes.capabilities,
                    ),
                  );
                  _snack(l10n.capReminderScheduled);
                },
                child: Text(l10n.capScheduleReminder),
              ),
            ]),
            SectionHeader(l10n.capReview),
            actions([
              OutlinedButton(
                onPressed: () async {
                  final outcome = await review.requestReview();
                  if (outcome == ReviewOutcome.unavailable) {
                    _snack(l10n.capReviewUnavailable);
                  }
                },
                child: Text(l10n.capRequestReview),
              ),
            ]),
            SectionHeader(l10n.capAds),
            ValueListenableBuilder<bool>(
              valueListenable: ads.adsAvailable,
              builder: (context, available, _) => ListTile(
                leading: const Icon(Icons.ad_units_outlined),
                title: Text(
                  l10n.capAdsStatus(available ? l10n.commonYes : l10n.commonNo),
                ),
              ),
            ),
            actions([
              OutlinedButton(
                onPressed: ads.recordQualifyingAction,
                child: Text(l10n.capRecordAction),
              ),
              OutlinedButton(
                onPressed: () async {
                  final outcome = await ads.showInterstitial();
                  _snack(l10n.capAdResult(outcome.runtimeType.toString()));
                },
                child: Text(l10n.capShowInterstitial),
              ),
              OutlinedButton(
                onPressed: () async {
                  final outcome = await ads.showRewarded();
                  _snack(
                    l10n.capAdResult(switch (outcome) {
                      RewardEarned(:final amount, :final type) =>
                        '+$amount $type',
                      _ => outcome.runtimeType.toString(),
                    }),
                  );
                },
                child: Text(l10n.capShowRewarded),
              ),
            ]),
            SectionHeader(l10n.premiumTitle),
            ValueListenableBuilder<PurchaseState>(
              valueListenable: billing.purchaseState,
              builder: (context, state, _) => ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.capPremiumStatus(state.name)),
              ),
            ),
            actions([
              FilledButton.tonal(
                onPressed: () => context.push(AppRoutes.premium),
                child: Text(l10n.capOpenPaywall),
              ),
              if (billing is FakeBillingManager)
                OutlinedButton(
                  onPressed: billing.reset,
                  child: Text(l10n.capResetPurchase),
                ),
            ]),
            SectionHeader(l10n.capOnboarding),
            actions([
              OutlinedButton(
                onPressed: onboarding.reset,
                child: Text(l10n.settingsReplayOnboarding),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
