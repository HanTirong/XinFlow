import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:xinflow/features/settings/domain/app_settings.dart';

/// Schedules a private, local reminder. No transaction data leaves the device.
final class DailyReminderNotifications {
  DailyReminderNotifications._();

  static final instance = DailyReminderNotifications._();
  static const _notificationId = 2100;
  static const _payload = 'daily-expense-reminder';
  static const _timeZoneChannel = MethodChannel('xinflow/local_timezone');

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<int> openRequests = ValueNotifier<int>(0);
  Future<void> _lastOperation = Future<void>.value();
  bool _initialized = false;
  bool _pendingOpen = false;

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_xinflow'),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == _payload) _signalOpen();
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == _payload) {
      _signalOpen();
    }
    _initialized = true;
  }

  void _signalOpen() {
    _pendingOpen = true;
    openRequests.value++;
  }

  bool takePendingOpen() {
    if (!_pendingOpen) return false;
    _pendingOpen = false;
    return true;
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!isSupported) return false;
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  Future<void> sync(AppSettings? settings) {
    if (!isSupported) return Future<void>.value();
    if (!_initialized && settings?.dailyReminderEnabled != true) {
      return Future<void>.value();
    }
    final next = _lastOperation.then((_) => _apply(settings));
    // A failed attempt must not prevent a later setting change from retrying.
    _lastOperation = next.catchError((Object _) {});
    return next;
  }

  Future<void> _apply(AppSettings? settings) async {
    await initialize();
    if (settings?.dailyReminderEnabled != true) {
      await _plugin.cancel(id: _notificationId);
      return;
    }
    if (!await areNotificationsEnabled()) {
      await _plugin.cancel(id: _notificationId);
      throw StateError('系统通知权限未开启。');
    }

    time_zone_data.initializeTimeZones();
    final zone = await _timeZoneChannel.invokeMethod<String>('getTimeZone');
    if (zone == null) throw StateError('无法读取手机时区。');
    tz.setLocalLocation(tz.getLocation(zone));
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      settings!.dailyReminderHour,
      settings.dailyReminderMinute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        settings.dailyReminderHour,
        settings.dailyReminderMinute,
      );
    }
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: '记一下今天的消费',
      body: '花一分钟补记，看看本期工资还剩多少。',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_expense_reminder',
          '每日记账提醒',
          channelDescription: '每天提醒补记当日消费',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _payload,
    );
  }
}
