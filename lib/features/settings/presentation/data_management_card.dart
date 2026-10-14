import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';

final class DataManagementCard extends ConsumerWidget {
  const DataManagementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      leading: const Icon(Icons.storage_rounded),
      title: const Text('本地数据管理'),
      subtitle: const Text('数据统计、备份提醒、删除历史周期与清空数据'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DataManagementScreen()),
      ),
    ),
  );
}

final class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(localDataOverviewProvider);
    final cycles =
        ref.watch(salaryCyclesProvider).value ?? const <SalaryCycle>[];
    final activeCycle = _activeCycle(cycles);
    final hasPreviousCycle = cycles.any(
      (item) => item.status == SalaryCycleStatus.closed,
    );
    final settings = ref.watch(appSettingsProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('本地数据管理')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: overview.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('读取失败：$error'),
                data: (value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据概览',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text('工资周期 ${value.cycles} 个 · 流水 ${value.transactions} 条'),
                    Text('分类 ${value.categories} 个 · 预算 ${value.budgets} 项'),
                    Text('数据库约占 ${_formatBytes(value.approximateBytes)}'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('备份提醒'),
              subtitle: Text(
                settings == null
                    ? '正在读取…'
                    : '距离上次备份 ${settings.lastBackupAt == null ? '尚无记录' : _daysAgo(settings.lastBackupAt!)}；每 ${settings.backupReminderDays} 天提醒',
              ),
              trailing: settings == null
                  ? null
                  : DropdownButton<int>(
                      value: settings.backupReminderDays,
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3 天')),
                        DropdownMenuItem(value: 7, child: Text('7 天')),
                        DropdownMenuItem(value: 14, child: Text('14 天')),
                        DropdownMenuItem(value: 30, child: Text('30 天')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsRepositoryProvider)
                              .updatePrivacy(backupReminderDays: value);
                        }
                      },
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text('当前工资周期', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (activeCycle != null)
            Card(
              child: ListTile(
                title: Text(_cycleRange(activeCycle)),
                subtitle: Text(
                  hasPreviousCycle ? '如果误点了工资到账，可以撤销最近一次周期切换' : '首个工资周期不能撤销',
                ),
                trailing: IconButton(
                  tooltip: '撤销最近一次周期切换',
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: hasPreviousCycle
                      ? () => _undoLatestCycle(context, ref)
                      : null,
                ),
              ),
            )
          else
            const Text('正在读取当前周期…'),
          const SizedBox(height: 20),
          Text('历史周期', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final cycle in cycles.where(
            (item) => item.status == SalaryCycleStatus.closed,
          ))
            Card(
              child: ListTile(
                title: Text(
                  '${cycle.startedAt.year}-${cycle.startedAt.month.toString().padLeft(2, '0')}-${cycle.startedAt.day.toString().padLeft(2, '0')} ～ ${cycle.expectedPayDate.previousDay}',
                ),
                subtitle: const Text('删除后，该周期的流水与预算将一并永久删除'),
                trailing: IconButton(
                  tooltip: '删除历史周期',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _deleteCycle(context, ref, cycle),
                ),
              ),
            ),
          if (!cycles.any((item) => item.status == SalaryCycleStatus.closed))
            const Text('暂无可删除的历史周期。'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _clearAll(context, ref),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('清空全部账务与设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCycle(
    BuildContext context,
    WidgetRef ref,
    SalaryCycle cycle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除这个历史周期？'),
        content: const Text('此操作无法撤销。建议先导出备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(localDataServiceProvider).deleteClosedCycle(cycle.id);
    ref
      ..invalidate(salaryCyclesProvider)
      ..invalidate(localDataOverviewProvider)
      ..invalidate(crossCycleReportProvider);
  }

  Future<void> _undoLatestCycle(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(localDataServiceProvider);
      final preview = await service.previewLatestCycleUndo();
      if (!context.mounted) return;
      if (preview == null) {
        _message(context, '没有可以撤销的工资周期切换。');
        return;
      }
      if (!preview.canUndo) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('暂时无法撤销'),
            content: Text(
              '当前周期包含 ${preview.transactionCount} 笔流水和 '
              '${preview.budgetCount} 项预算。请先清理这些内容，再撤销周期切换。',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('撤销最近一次周期切换？'),
          content: Text(
            '将删除当前周期 ${_cycleRange(preview.activeCycle)}，并恢复上一周期 '
            '${_cycleRange(preview.previousCycle)}。\n\n'
            '已有历史流水不会丢失。建议操作前先导出备份。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认撤销'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      await service.undoLatestCycleTransition();
      ref
        ..invalidate(homeSnapshotProvider)
        ..invalidate(salaryCyclesProvider)
        ..invalidate(localDataOverviewProvider)
        ..invalidate(cycleTransactionsProvider)
        ..invalidate(cycleBudgetsProvider)
        ..invalidate(cycleReportProvider)
        ..invalidate(crossCycleReportProvider);
      if (context.mounted) _message(context, '已撤销最近一次工资周期切换。');
    } on Object catch (error) {
      if (context.mounted) _message(context, '撤销失败：$error');
    }
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部本地数据？'),
        content: const Text('工资周期、流水、预算、自定义分类和设置将被清空，应用会回到首次设置。此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(localDataServiceProvider).clearAll();
    ref.invalidate(startupProvider);
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

SalaryCycle? _activeCycle(Iterable<SalaryCycle> cycles) {
  for (final cycle in cycles) {
    if (cycle.status == SalaryCycleStatus.active) return cycle;
  }
  return null;
}

String _cycleRange(SalaryCycle cycle) {
  final start = cycle.startedAt;
  return '${start.year}-${start.month.toString().padLeft(2, '0')}-'
      '${start.day.toString().padLeft(2, '0')} ～ ${cycle.expectedPayDate.previousDay}';
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

String _daysAgo(DateTime at) {
  final days = DateTime.now().difference(at).inDays;
  return days <= 0 ? '今天' : '$days 天前';
}
