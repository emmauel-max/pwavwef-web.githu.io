// lib/services/notification_service.dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const _channelId = 'az_learner_channel';
  static const _channelName = 'AZ Learner';
  static const _channelDesc = 'Class reminders, assignment alerts & more';

  Future<void> initialize() async {
    // Request FCM permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android local notification setup
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapBackground,
    );

    // Create high-importance notification channel (Android 8+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

    // Handle foreground FCM messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification-opened-app (from background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    // Check if app was launched from a notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleRemoteMessage(initial);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4F9CF9),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// Schedule a class reminder notification
  Future<void> scheduleClassReminder({
    required int id,
    required String courseName,
    required String venue,
    required DateTime classTime,
    required int minutesBefore,
  }) async {
    final scheduledTime = classTime.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.zonedSchedule(
      id,
      '📚 Class Reminder: $courseName',
      '$minutesBefore min until your class at $venue',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/timetable',
    );
  }

  /// Schedule an assignment deadline reminder
  Future<void> scheduleAssignmentReminder({
    required int id,
    required String title,
    required String course,
    required DateTime dueDate,
    required int daysBefore,
  }) async {
    final scheduledTime = dueDate.subtract(Duration(days: daysBefore))
        .copyWith(hour: 9, minute: 0, second: 0);
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.zonedSchedule(
      id,
      '📋 Assignment Due Soon: $title',
      '$course assignment is due in $daysBefore day${daysBefore > 1 ? 's' : ''}!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/tasks',
    );
  }

  /// Send Pomodoro session complete notification (works even if app is backgrounded)
  Future<void> notifyPomodoroComplete({required bool isWorkSession}) async {
    await showNotification(
      title: isWorkSession ? '🍅 Focus Session Complete!' : '☕ Break Over!',
      body: isWorkSession
          ? 'Great work! Time to take a short break. 💪'
          : 'Back to focus mode — you\'ve got this! 🎯',
      id: 9999,
      payload: '/study-room',
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<void> cancel(int id) async => _plugin.cancel(id);

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showNotification(
        title: notification.title ?? 'AZ Learner',
        body: notification.body ?? '',
        payload: message.data['route'],
      );
    }
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    _handleRemoteMessage(message);
  }

  void _handleRemoteMessage(RemoteMessage message) {
    debugPrint('[FCM] Opened from notification: ${message.data}');
    // TODO: Use router to navigate to the right screen
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[Notifications] Tapped: ${response.payload}');
    // TODO: Navigate using GoRouter based on payload
  }
}

// Top-level function required by flutter_local_notifications background handler
@pragma('vm:entry-point')
void _onNotificationTapBackground(NotificationResponse response) {
  debugPrint('[Notifications] Background tap: ${response.payload}');
}

extension on DateTime {
  DateTime copyWith({int? hour, int? minute, int? second}) => DateTime(
    year,
    month,
    day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
  );
}
