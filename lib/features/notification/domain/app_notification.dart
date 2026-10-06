import 'package:equatable/equatable.dart';

/// How a notification reached the user.
enum NotificationChannel {
  /// Scheduled/shown by the device itself (no server).
  local,

  /// Delivered by a push service (FCM/APNs/...).
  push,

  /// Shown inside the running app (banner/snackbar/inbox).
  inApp,
}

/// Vendor-neutral notification. Push payloads are mapped into this type by
/// the push implementation, so the rest of the app never sees FCM types.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.channel,
    required this.title,
    this.body,
    this.data = const {},
    this.deepLink,
    this.createdAt,
  });

  final String id;
  final NotificationChannel channel;
  final String title;
  final String? body;

  /// String-only payload, compatible with every push provider.
  final Map<String, String> data;

  /// Route to open on tap, e.g. `/home/chat/support`.
  final String? deepLink;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, channel, title, body, data, deepLink];
}
