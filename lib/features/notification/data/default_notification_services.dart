import 'dart:async';

import '../../../core/logging/app_logger.dart';
import '../domain/app_notification.dart';
import '../domain/notification_services.dart';

/// Broadcast-stream implementation of the in-app bus.
class StreamInAppNotificationCenter implements InAppNotificationCenter {
  final _controller = StreamController<AppNotification>.broadcast();

  @override
  Stream<AppNotification> get notifications => _controller.stream;

  @override
  void publish(AppNotification notification) => _controller.add(notification);

  Future<void> dispose() => _controller.close();
}

/// Placeholder until a local notification plugin is added. Logs instead of
/// showing anything, so callers can be written against the interface today.
class NoopLocalNotificationService implements LocalNotificationService {
  NoopLocalNotificationService(this._logger);

  final AppLogger _logger;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> show(AppNotification notification) async => _logger.info(
    'Local notification (noop): ${notification.id}',
    tag: 'notify',
  );

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<AppNotification> get onOpened => const Stream.empty();
}

/// Placeholder until push (e.g. Firebase Messaging) is configured.
class NoopPushNotificationService implements PushNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<AppNotification> get onMessage => const Stream.empty();

  @override
  Stream<AppNotification> get onOpened => const Stream.empty();
}
