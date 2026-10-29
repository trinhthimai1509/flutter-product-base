import 'package:flutter_test/flutter_test.dart';
import 'package:pb_notifications/pb_notifications.dart';

void main() {
  test('notificationIntId is stable, positive and 31-bit', () {
    final a = notificationIntId('daily-reminder');
    expect(notificationIntId('daily-reminder'), a);
    expect(notificationIntId('weekly-reminder'), isNot(a));
    for (final id in ['', 'x', 'a-very-long-identifier-' * 10]) {
      final value = notificationIntId(id);
      expect(value, greaterThanOrEqualTo(0));
      expect(value, lessThanOrEqualTo(0x7FFFFFFF));
    }
  });

  test(
    'FakeLocalNotifications: schedule replaces by id, cancel removes',
    () async {
      final notifications = FakeLocalNotifications();
      addTearDown(notifications.dispose);
      await notifications.initialize(
        channels: const [NotificationChannelSpec(id: 'r', name: 'Reminders')],
      );

      final at = DateTime(2030);
      await notifications.schedule(
        ReminderRequest(id: 'daily', triggerAt: at, channelId: 'r', title: 'A'),
      );
      await notifications.schedule(
        ReminderRequest(id: 'daily', triggerAt: at, channelId: 'r', title: 'B'),
      );
      expect(notifications.scheduled.length, 1);
      expect(notifications.scheduled['daily']!.title, 'B');

      await notifications.cancel('daily');
      expect(notifications.scheduled, isEmpty);
      expect(notifications.channels.single.id, 'r');
    },
  );

  test('FakeLocalNotifications: permission and taps', () async {
    final notifications = FakeLocalNotifications();
    addTearDown(notifications.dispose);
    expect(await notifications.canPostNotifications(), isFalse);
    expect(await notifications.requestPermission(), isTrue);
    expect(await notifications.canPostNotifications(), isTrue);

    final opened = notifications.onOpened.first;
    notifications.simulateOpen('/home/chat');
    expect(await opened, '/home/chat');
  });
}
