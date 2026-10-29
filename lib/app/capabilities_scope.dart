import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_notifications/pb_notifications.dart';

import '../core/capabilities/capability_providers.dart';
import '../core/localization/l10n.dart';
import '../shared/widgets/status_badges.dart';
import 'router/app_router.dart';

/// Starts the capability packages once the first frame is up, and hosts
/// app-wide capability UI (the offline banner).
///
/// Lives in `MaterialApp.builder`, below Localizations, so channel names can
/// be localized.
class CapabilitiesScope extends ConsumerStatefulWidget {
  const CapabilitiesScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CapabilitiesScope> createState() => _CapabilitiesScopeState();
}

class _CapabilitiesScopeState extends ConsumerState<CapabilitiesScope> {
  StreamSubscription<String?>? _openedSub;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final notifications = ref.read(localNotificationsProvider);
    // Billing starts with the provider; reading it here makes sure the
    // store is queried (and ownership restored) at launch.
    ref.read(billingManagerProvider);
    await notifications.initialize(
      channels: [
        NotificationChannelSpec(
          id: AppNotificationChannels.reminders,
          name: l10n.notificationChannelReminders,
          description: l10n.notificationChannelRemindersDescription,
        ),
      ],
    );
    _openedSub = notifications.onOpened.listen(_openPayload);
    _openPayload(await notifications.launchPayload());
    // Consent may show a form, so ads start after the first frame.
    await ref.read(adsControllerProvider).initialize();
  }

  /// Notification payloads are in-app locations; anything else is ignored.
  void _openPayload(String? payload) {
    if (payload == null ||
        !payload.startsWith('/') ||
        payload.startsWith('//')) {
      return;
    }
    // `go` builds the parent stack, e.g. home → capabilities.
    ref.read(routerProvider).go(payload);
  }

  @override
  void dispose() {
    _openedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    return Column(
      children: [
        if (!online) OfflineBanner(message: context.l10n.offlineBanner),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !online,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
