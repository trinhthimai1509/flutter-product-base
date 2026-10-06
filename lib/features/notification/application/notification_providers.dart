import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../data/default_notification_services.dart';
import '../domain/notification_services.dart';

final inAppNotificationCenterProvider = Provider<InAppNotificationCenter>((
  ref,
) {
  final center = StreamInAppNotificationCenter();
  ref.onDispose(center.dispose);
  return center;
});

/// Override with a real implementation (e.g. flutter_local_notifications).
final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => NoopLocalNotificationService(ref.watch(appLoggerProvider)),
);

/// Override with a real implementation (e.g. Firebase Messaging).
final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => NoopPushNotificationService(),
);
