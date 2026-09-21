import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/reminders/application/daily_reminder_notifications.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

final class DailyReminderCard extends ConsumerStatefulWidget {
  const DailyReminderCard({super.key});

  @override
  ConsumerState<DailyReminderCard> createState() => _DailyReminderCardState();
}

final class _DailyReminderCardState extends ConsumerState<DailyReminderCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).value;
    final supported = DailyReminderNotifications.instance.isSupported;
    final time = settings == null
        ? '--:--'
        : '${settings.dailyReminderHour.toString().padLeft(2, '0')}:${settings.dailyReminderMinute.toString().padLeft(2, '0')}';

    return Card(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('每日记账提醒'),
            subtitle: Text(
              !supported
                  ? '当前仅支持安卓版'
                  : settings?.dailyReminderEnabled == true
                  ? '每天约 $time 提醒补记当日消费'
                  : '关闭 · 默认时间 $time',
            ),
            value: settings?.dailyReminderEnabled ?? false,
            onChanged: _working || settings == null || !supported
                ? null
                : (enabled) => _setEnabled(settings, enabled),
          ),
          if (supported)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('提醒时间'),
              subtitle: const Text('系统可能因省电策略稍晚送达'),
              trailing: Text(time),
              enabled: !_working && settings != null,
              onTap: settings == null || _working
                  ? null
                  : () => _pickTime(settings),
            ),
        ],
      ),
    );
  }

  Future<void> _setEnabled(AppSettings settings, bool enabled) async {
    setState(() => _working = true);
    try {
      if (enabled &&
          !await DailyReminderNotifications.instance.requestPermission()) {
        _message('请先允许薪流发送通知；未开启提醒。');
        return;
      }
      await _saveAndSync(
        previous: settings,
        enabled: enabled,
        hour: settings.dailyReminderHour,
        minute: settings.dailyReminderMinute,
      );
      _message(enabled ? '每日记账提醒已开启。' : '每日记账提醒已关闭。');
    } on Object catch (error) {
      _message('设置提醒失败：$error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pickTime(AppSettings settings) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.dailyReminderHour,
        minute: settings.dailyReminderMinute,
      ),
      helpText: '选择每日记账提醒时间',
    );
    if (selected == null || !mounted) return;
    setState(() => _working = true);
    try {
      await _saveAndSync(
        previous: settings,
        enabled: settings.dailyReminderEnabled,
        hour: selected.hour,
        minute: selected.minute,
      );
      _message('提醒时间已更新。');
    } on Object catch (error) {
      _message('修改提醒时间失败：$error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _saveAndSync({
    required AppSettings previous,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateDailyReminder(
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
    try {
      await DailyReminderNotifications.instance.sync(await repository.load());
    } on Object {
      // Do not leave the switch on when no reminder could be scheduled.
      await repository.updateDailyReminder(
        enabled: previous.dailyReminderEnabled,
        hour: previous.dailyReminderHour,
        minute: previous.dailyReminderMinute,
      );
      await DailyReminderNotifications.instance.sync(await repository.load());
      rethrow;
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
