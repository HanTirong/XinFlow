import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/app.dart';
import 'package:xinflow/features/reminders/application/daily_reminder_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DailyReminderNotifications.instance.initialize();
  } on Object catch (error) {
    // A notification-plugin failure must never prevent access to local data.
    debugPrint('Daily reminder initialization failed: $error');
  }
  runApp(const ProviderScope(child: XinFlowApp()));
}
