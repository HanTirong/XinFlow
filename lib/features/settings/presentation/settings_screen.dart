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
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';
import 'package:xinflow/features/salary_cycles/presentation/salary_entry_sheet.dart';

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);

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
            child: const ListTile(
              leading: Icon(Icons.calendar_today_outlined),
              title: Text('工资周期'),
              subtitle: Text('每月 10 日至次月 9 日；打开应用后自动结算。'),
            ),
          ),
          const SizedBox(height: 12),
          const BudgetManagementCard(),
          const SizedBox(height: 12),
          const DailyReminderCard(),
          const SizedBox(height: 12),
          const _PendingSalaryCard(),
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
              subtitle: Text('数据库版本 8 · 备份格式版本 2'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PendingSalaryCard extends ConsumerWidget {
  const _PendingSalaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref.watch(pendingSalaryCyclesProvider).value ?? const <SalaryCycle>[];
    if (pending.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('待填写工资', style: Theme.of(context).textTheme.titleMedium),
              for (final cycle in pending)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatSalaryCycleRange(cycle)),
                  subtitle: Text(
                    cycle.status == SalaryCycleStatus.active ? '当前周期' : '历史周期',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    final saved = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => SalaryEntrySheet(cycle: cycle),
                    );
                    if (saved != true) return;
                    ref
                      ..invalidate(pendingSalaryCyclesProvider)
                      ..invalidate(homeSnapshotProvider)
                      ..invalidate(salaryCyclesProvider)
                      ..invalidate(cycleReportProvider)
                      ..invalidate(crossCycleReportProvider);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
