import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pb_common/pb_common.dart';
import 'package:timezone/timezone.dart' as tz;

import 'local_notifications.dart';

/// [LocalNotifications] backed by `flutter_local_notifications`.
///
/// Android setup (desugaring, boot/scheduled receivers) and iOS setup are
/// listed in docs/MODULE_CATALOG.md#pb_notifications.
class PluginLocalNotifications implements LocalNotifications {
  PluginLocalNotifications({
    FlutterLocalNotificationsPlugin? plugin,
    this.androidIcon = '@mipmap/ic_launcher',
    this._logger = const NoOpPbLogger(),
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final PbLogger _logger;

  /// Drawable/mipmap used as the small icon on Android. Use a monochrome
  /// drawable in a real app; the launcher icon renders as a white square on
  /// some devices.
  final String androidIcon;

  final _opened = StreamController<String?>.broadcast();
  final Map<String, NotificationChannelSpec> _channels = {};

  @override
  Future<void> initialize({
    required List<NotificationChannelSpec> channels,
  }) async {
    await _plugin.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
        // Permission is requested explicitly via requestPermission().
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        web: const WebInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _opened.add(response.payload),
    );
    _channels
      ..clear()
      ..addEntries(channels.map((c) => MapEntry(c.id, c)));
    final android = _android;
    if (android != null) {
      for (final channel in channels) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.name,
            description: channel.description,
            importance: _importance(channel.importance),
          ),
        );
      }
    }
    _logger.debug('Initialized ${channels.length} channel(s)', tag: 'notify');
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
      : null;

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
      : null;

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _android;
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _ios;
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return false;
    } on Object catch (error) {
      _logger.warning('Permission request failed', tag: 'notify', error: error);
      return false;
    }
  }

  @override
  Future<bool> canPostNotifications() async {
    try {
      final android = _android;
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _ios;
      if (ios != null) {
        final options = await ios.checkPermissions();
        return options?.isEnabled ?? false;
      }
      return false;
    } on Object {
      return false;
    }
  }

  NotificationDetails _details(String channelId) {
    final channel = _channels[channelId];
    final importance = channel?.importance ?? NotificationImportance.normal;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channel?.name ?? channelId,
        channelDescription: channel?.description,
        importance: _importance(importance),
        priority: switch (importance) {
          NotificationImportance.low => Priority.low,
          NotificationImportance.normal => Priority.defaultPriority,
          NotificationImportance.high => Priority.high,
        },
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  @override
  Future<void> show(LocalNotification notification) => _plugin.show(
    id: notificationIntId(notification.id),
    title: notification.title,
    body: notification.body,
    notificationDetails: _details(notification.channelId),
    payload: notification.payload,
  );

  @override
  Future<void> schedule(ReminderRequest reminder) async {
    // An absolute instant in UTC: no time-zone database needed, and the
    // reminder fires at the same moment whatever the device zone becomes.
    final at = tz.TZDateTime.from(reminder.triggerAt.toUtc(), tz.UTC);
    await _plugin.zonedSchedule(
      id: notificationIntId(reminder.id),
      scheduledDate: at,
      notificationDetails: _details(reminder.channelId),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: reminder.title,
      body: reminder.body,
      payload: reminder.payload,
    );
    _logger.debug('Scheduled ${reminder.id} at $at', tag: 'notify');
  }

  @override
  Future<void> cancel(String id) => _plugin.cancel(id: notificationIntId(id));

  @override
  Stream<String?> get onOpened => _opened.stream;

  @override
  Future<String?> launchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        return details!.notificationResponse?.payload;
      }
    } on Object catch (error) {
      _logger.warning(
        'Launch details unavailable',
        tag: 'notify',
        error: error,
      );
    }
    return null;
  }

  static Importance _importance(NotificationImportance value) =>
      switch (value) {
        NotificationImportance.low => Importance.low,
        NotificationImportance.normal => Importance.defaultImportance,
        NotificationImportance.high => Importance.high,
      };

  Future<void> dispose() => _opened.close();
}
