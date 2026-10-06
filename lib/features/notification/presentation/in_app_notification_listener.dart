import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../application/notification_providers.dart';
import '../domain/app_notification.dart';

/// Shows in-app notifications as snackbars on [messengerKey].
class InAppNotificationListener extends ConsumerStatefulWidget {
  const InAppNotificationListener({
    super.key,
    required this.messengerKey,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  ConsumerState<InAppNotificationListener> createState() =>
      _InAppNotificationListenerState();
}

class _InAppNotificationListenerState
    extends ConsumerState<InAppNotificationListener> {
  StreamSubscription<AppNotification>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref
        .read(inAppNotificationCenterProvider)
        .notifications
        .listen(_show);
  }

  void _show(AppNotification notification) {
    final messenger = widget.messengerKey.currentState;
    if (messenger == null) return;
    final text = notification.body == null
        ? notification.title
        : '${notification.title}\n${notification.body}';
    showAppSnackBarOn(messenger, Theme.of(context).colorScheme, text);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
