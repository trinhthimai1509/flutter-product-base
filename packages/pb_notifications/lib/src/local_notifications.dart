import 'dart:async';

/// How intrusive a channel's notifications are (Android channel importance;
/// ignored on iOS).
enum NotificationImportance { low, normal, high }

/// An Android notification channel. Create every channel once at start-up via
/// [LocalNotifications.initialize]; names are user-visible, so localize them.
class NotificationChannelSpec {
  const NotificationChannelSpec({
    required this.id,
    required this.name,
    this.description,
    this.importance = NotificationImportance.normal,
  });

  final String id;
  final String name;
  final String? description;
  final NotificationImportance importance;
}

/// A notification shown right away.
class LocalNotification {
  const LocalNotification({
    required this.id,
    required this.channelId,
    required this.title,
    this.body,
    this.payload,
  });

  /// Same id replaces an existing notification.
  final String id;
  final String channelId;
  final String title;
  final String? body;

  /// Returned by [LocalNotifications.onOpened] on tap, e.g. a deep link.
  final String? payload;
}

/// A deferrable reminder: delivered at or shortly after [triggerAt] (the OS
/// may batch it to save battery). Exact alarms are deliberately not offered;
/// an alarm clock needs its own permission and policy.
class ReminderRequest {
  const ReminderRequest({
    required this.id,
    required this.triggerAt,
    required this.channelId,
    required this.title,
    this.body,
    this.payload,
  });

  /// Same id replaces an existing reminder.
  final String id;
  final DateTime triggerAt;
  final String channelId;
  final String title;
  final String? body;
  final String? payload;
}

/// Device-local notifications: channels, permission, show, schedule, cancel.
/// Push messaging is out of scope (it needs a backend and credentials).
abstract interface class LocalNotifications {
  /// Call once at start-up. Creates the Android channels.
  Future<void> initialize({required List<NotificationChannelSpec> channels});

  /// Asks the OS for permission (Android 13+, iOS). Ask from a UI moment the
  /// user understands, not at launch.
  Future<bool> requestPermission();

  /// Permission granted and notifications enabled for the app.
  Future<bool> canPostNotifications();

  Future<void> show(LocalNotification notification);
  Future<void> schedule(ReminderRequest reminder);
  Future<void> cancel(String id);

  /// Payloads of notifications the user tapped while the app was running.
  Stream<String?> get onOpened;

  /// Payload of the notification that launched the app, if any.
  Future<String?> launchPayload();
}

/// Maps string ids to the 31-bit ints the platforms require (FNV-1a), so
/// the same string always addresses the same notification.
int notificationIntId(String id) {
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// In-memory [LocalNotifications] for tests, previews and unsupported
/// platforms.
class FakeLocalNotifications implements LocalNotifications {
  FakeLocalNotifications({this.permissionGranted = false});

  bool permissionGranted;
  final List<NotificationChannelSpec> channels = [];
  final Map<String, LocalNotification> shown = {};
  final Map<String, ReminderRequest> scheduled = {};
  final _opened = StreamController<String?>.broadcast();

  @override
  Future<void> initialize({
    required List<NotificationChannelSpec> channels,
  }) async => this.channels
    ..clear()
    ..addAll(channels);

  @override
  Future<bool> requestPermission() async => permissionGranted = true;

  @override
  Future<bool> canPostNotifications() async => permissionGranted;

  @override
  Future<void> show(LocalNotification notification) async =>
      shown[notification.id] = notification;

  @override
  Future<void> schedule(ReminderRequest reminder) async =>
      scheduled[reminder.id] = reminder;

  @override
  Future<void> cancel(String id) async {
    shown.remove(id);
    scheduled.remove(id);
  }

  /// Simulates a tap on a notification.
  void simulateOpen(String? payload) => _opened.add(payload);

  @override
  Stream<String?> get onOpened => _opened.stream;

  @override
  Future<String?> launchPayload() async => null;

  Future<void> dispose() => _opened.close();
}
