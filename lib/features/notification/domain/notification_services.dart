import 'app_notification.dart';

/// Device-local notifications (e.g. `flutter_local_notifications`).
abstract interface class LocalNotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> show(AppNotification notification);
  Future<void> cancel(String id);

  /// Emits when the user taps a local notification.
  Stream<AppNotification> get onOpened;
}

/// Remote push (e.g. Firebase Messaging, OneSignal, APNs directly).
/// Implementations map vendor messages to [AppNotification].
abstract interface class PushNotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();

  /// Device token to register with your backend.
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;

  /// Messages received while the app is in the foreground.
  Stream<AppNotification> get onMessage;

  /// User opened the app from a push.
  Stream<AppNotification> get onOpened;
}

/// In-app notification bus. UI listens and renders banners/snackbars.
abstract interface class InAppNotificationCenter {
  Stream<AppNotification> get notifications;
  void publish(AppNotification notification);
}
