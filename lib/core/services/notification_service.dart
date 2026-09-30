import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const String _scheduledKey = 'scheduled_manager_notifications';

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  static Future<List<String>> _readScheduledIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_scheduledKey) ?? <String>[];
  }

  static Future<void> _saveScheduledIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scheduledKey, ids);
  }

  static Future<void> scheduleManagerReminder({
    required String orderId,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async {
    await initialize();

    if (scheduledFor.isBefore(DateTime.now())) {
      return;
    }

    final scheduledIds = await _readScheduledIds();
    if (scheduledIds.contains(orderId)) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'manager_order_reminders',
      'Manager order reminders',
      channelDescription: 'Reminders before delivery time',
      importance: Importance.max,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      orderId.hashCode & 0x7fffffff,
      title,
      body,
      tz.TZDateTime.from(scheduledFor, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    scheduledIds.add(orderId);
    await _saveScheduledIds(scheduledIds);
  }

  static Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
    await _saveScheduledIds([]);
  }
}
