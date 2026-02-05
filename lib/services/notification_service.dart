import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

class NotificationService {
  static NotificationService _instance = NotificationService._init();
  static NotificationService get instance => _instance;

  @visibleForTesting
  static set instance(NotificationService newInstance) => _instance = newInstance;

  NotificationService._init();

  @visibleForTesting
  NotificationService();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required int intervalDays,
  }) async {
    // Cancel existing reminder if any
    await _notifications.cancel(id);

    if (intervalDays <= 0) return;

    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(days: intervalDays));

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Measurement reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // This is for daily, but we want interval
      payload: 'measurement_reminder',
    );
    
    debugPrint('Reminder scheduled for $scheduledDate');
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
