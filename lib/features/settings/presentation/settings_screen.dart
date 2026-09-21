import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/backup/presentation/backup_card.dart';
import 'package:xinflow/features/categories/presentation/category_management_card.dart';
import 'package:xinflow/features/budgets/presentation/budget_management_card.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/settings/presentation/data_management_card.dart';
import 'package:xinflow/features/security/presentation/privacy_security_screen.dart';
import 'package:xinflow/features/reminders/presentation/daily_reminder_card.dart';

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);
    final startup = ref.watch(startupProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Text('我的', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dark_mode_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '外观',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '可跟随手机系统，也可以固定使用浅色或深色模式。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  preference.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => Text(
                      '主题设置读取失败：$error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    data: (selected) => SegmentedButton<AppThemePreference>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AppThemePreference.system,
                          icon: Icon(Icons.settings_brightness_outlined),
                          label: Text('跟随系统'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('浅色'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('深色'),
                        ),
                      ],
                      selected: {selected},
                      onSelectionChanged: (selection) async {
                        final next = selection.single;
                        try {
                          await ref
                              .read(settingsRepositoryProvider)
                              .updateThemePreference(next);
                        } on Object catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text('保存主题失败：$error')),
                            );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('固定发薪日'),
              subtitle: Text(
                startup.when(
                  data: (value) => '每月 ${value.settings?.salaryDay ?? '-'} 日',
                  loading: () => '正在读取…',
                  error: (error, stackTrace) => '读取失败',
                ),
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: startup.value?.settings == null
                  ? null
                  : () => _editSalaryDay(
                      context,
                      ref,
                      startup.value!.settings!.salaryDay,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const BudgetManagementCard(),
          const SizedBox(height: 12),
          const DailyReminderCard(),
          const SizedBox(height: 12),
          const DataManagementCard(),
          const SizedBox(height: 12),
          const PrivacySecurityCard(),
          const SizedBox(height: 12),
          const CategoryManagementCard(),
          const SizedBox(height: 12),
          const BackupCard(),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('薪流 0.1.0'),
              subtitle: Text('数据库版本 4 · 备份格式版本 2'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSalaryDay(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    var salaryDayText = current.toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改固定发薪日'),
        content: TextFormField(
          initialValue: salaryDayText,
          onChanged: (value) => salaryDayText = value,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '每月日期',
            helperText: '请输入 1 至 31；月份较短时取当月最后一天。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final value = int.tryParse(salaryDayText);
    if (confirmed != true) return;
    if (value == null || value < 1 || value > 31) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('发薪日必须是 1 至 31。')));
      }
      return;
    }
    await ref.read(settingsRepositoryProvider).updateSalaryDay(value);
    ref
      ..invalidate(startupProvider)
      ..invalidate(homeSnapshotProvider)
      ..invalidate(salaryCyclesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('固定发薪日已更新。')));
    }
  }
}
