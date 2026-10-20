import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/budgets/domain/budget_calculator.dart';
import 'package:xinflow/features/categories/presentation/category_management_card.dart';
import 'package:xinflow/features/home/presentation/flow_breakdown_screen.dart';
import 'package:xinflow/features/home/presentation/home_screen.dart';
import 'package:xinflow/features/reports/presentation/report_screen.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/salary_entry_sheet.dart';
import 'package:xinflow/features/settings/presentation/settings_screen.dart';
import 'package:xinflow/features/transactions/presentation/add_allocation_sheet.dart';
import 'package:xinflow/features/transactions/presentation/add_refund_sheet.dart';
import 'package:xinflow/features/transactions/presentation/transactions_screen.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/reminders/application/daily_reminder_notifications.dart';

final class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

final class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  bool _amountsRevealed = false;
  final Set<String> _promptedSalaryCycles = {};

  @override
  void initState() {
    super.initState();
    DailyReminderNotifications.instance.openRequests.addListener(
      _openFromReminder,
    );
    DailyReminderNotifications.instance.salaryOpenRequests.addListener(
      _openFromSalaryReminder,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openFromReminder();
      _openFromSalaryReminder();
    });
  }

  @override
  void dispose() {
    DailyReminderNotifications.instance.openRequests.removeListener(
      _openFromReminder,
    );
    DailyReminderNotifications.instance.salaryOpenRequests.removeListener(
      _openFromSalaryReminder,
    );
    super.dispose();
  }

  void _openFromReminder() {
    if (!mounted || !DailyReminderNotifications.instance.takePendingOpen()) {
      return;
    }
    setState(() => _selectedIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openAddAllocation();
    });
  }

  void _openFromSalaryReminder() {
    if (!mounted ||
        !DailyReminderNotifications.instance.takePendingSalaryOpen()) {
      return;
    }
    setState(() => _selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final homeSnapshot = ref.watch(homeSnapshotProvider);
    final categories = switch (ref.watch(allCategoriesProvider)) {
      AsyncData(:final value) => value,
      _ => const <Category>[],
    };
    final settings = ref.watch(appSettingsProvider).value;
    final pages = [
      homeSnapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _HomeLoadError(
          message: error.toString(),
          onRetry: () => ref.invalidate(homeSnapshotProvider),
        ),
        data: (snapshot) {
          if (snapshot.cycle.salaryPending &&
              _promptedSalaryCycles.add(snapshot.cycle.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openSalaryEntry(snapshot.cycle);
            });
          }
          final budgets =
              ref.watch(cycleBudgetsProvider(snapshot.cycle.id)).value ??
              const [];
          final transactions =
              ref.watch(cycleTransactionsProvider(snapshot.cycle.id)).value ??
              const <TransactionEntry>[];
          return HomeScreen(
            snapshot: snapshot,
            onAddAllocation: _openAddAllocation,
            onSalaryReceived: () => _openSalaryEntry(snapshot.cycle),
            onBrowseCycles: () => _selectPage(1),
            onEditCategories: () => showCategoryManagementSheet(context),
            onViewAllTransactions: () => _selectPage(1),
            onEditTransaction: _openEditAllocation,
            onOpenFlowDetail: (flowType) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FlowBreakdownScreen(
                  cycle: snapshot.cycle,
                  flowType: flowType,
                  hideAmounts:
                      (settings?.hideAmounts ?? false) && !_amountsRevealed,
                ),
              ),
            ),
            categories: categories,
            budgetProgress: BudgetCalculator.calculate(
              budgets: budgets,
              transactions: transactions,
            ),
            backupReminderDue:
                settings != null &&
                (settings.lastBackupAt == null ||
                    DateTime.now().difference(settings.lastBackupAt!).inDays >=
                        settings.backupReminderDays),
            hideAmounts: settings?.hideAmounts ?? false,
            amountsRevealed: _amountsRevealed,
            onToggleAmounts: () =>
                setState(() => _amountsRevealed = !_amountsRevealed),
          );
        },
      ),
      TransactionsScreen(
        onAdd: _openAddAllocation,
        onEdit: _openEditAllocation,
        onAddHistorical: _openAddHistoricalAllocation,
        onEditHistorical: _openEditHistoricalAllocation,
      ),
      const ReportScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: '流水',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: '月报',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }

  void _selectPage(int index) => setState(() => _selectedIndex = index);

  Future<void> _openAddAllocation([String? categoryId]) =>
      _openAllocationEditor(initialCategoryId: categoryId);

  Future<void> _openEditAllocation(TransactionEntry entry) =>
      _openAllocationEditor(entry: entry);

  Future<void> _openAddHistoricalAllocation(SalaryCycle cycle) =>
      _openAllocationEditor(historicalCycle: cycle);

  Future<void> _openEditHistoricalAllocation(
    SalaryCycle cycle,
    TransactionEntry entry,
  ) => _openAllocationEditor(entry: entry, historicalCycle: cycle);

  Future<void> _openAllocationEditor({
    String? initialCategoryId,
    TransactionEntry? entry,
    SalaryCycle? historicalCycle,
  }) async {
    if (historicalCycle == null) {
      try {
        final switched = await ref.read(autoSettleDueCyclesProvider).execute();
        if (switched > 0) {
          ref
            ..invalidate(homeSnapshotProvider)
            ..invalidate(salaryCyclesProvider)
            ..invalidate(pendingSalaryCyclesProvider);
          return;
        }
        final active = await ref
            .read(salaryCycleRepositoryProvider)
            .getActiveCycle();
        if (active != null &&
            LocalDate.fromDateTime(active.startedAt).compareTo(
                  LocalDate.fromDateTime(ref.read(clockProvider).now()),
                ) >
                0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('当前周期日期晚于今天，请先撤销误切换。')),
            );
          }
          return;
        }
      } on Object catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('无法检查工资周期：$error')));
        }
        return;
      }
    }
    if (!mounted) return;
    final result = await showModalBottomSheet<AllocationEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => AddAllocationSheet(
        initialCategoryId: initialCategoryId,
        entry: entry,
        historicalCycle: historicalCycle,
      ),
    );
    if (result != null && mounted) {
      final isHistorical =
          historicalCycle != null ||
          result == AllocationEditorResult.createdHistorical ||
          result == AllocationEditorResult.updatedHistorical;
      final message = switch (result) {
        AllocationEditorResult.created => '已记入本期工资流向。',
        AllocationEditorResult.createdHistorical =>
          historicalCycle == null
              ? '已记入所选日期对应的历史周期，请在流水页切换周期查看。'
              : '历史流水已补记，周期余额已重新计算。',
        AllocationEditorResult.updated => '流水修改已保存。',
        AllocationEditorResult.updatedHistorical =>
          historicalCycle == null ? '已转入所选日期对应的历史周期，周期余额已重新计算。' : '历史流水修正已保存。',
        AllocationEditorResult.deleted =>
          isHistorical ? '历史流水已删除，周期余额已重新计算。' : '流水已删除，余额已重新计算。',
        AllocationEditorResult.refundRequested => null,
      };
      if (result == AllocationEditorResult.refundRequested && entry != null) {
        await _openRefund(entry, historicalCycle: historicalCycle);
        return;
      }
      if (message == null) return;
      ref
        ..invalidate(homeSnapshotProvider)
        ..invalidate(salaryCyclesProvider)
        ..invalidate(cycleTransactionsProvider)
        ..invalidate(cycleReportProvider)
        ..invalidate(crossCycleReportProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openRefund(
    TransactionEntry original, {
    SalaryCycle? historicalCycle,
  }) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) =>
          AddRefundSheet(original: original, historicalCycle: historicalCycle),
    );
    if (created == true && mounted) {
      ref
        ..invalidate(homeSnapshotProvider)
        ..invalidate(salaryCyclesProvider)
        ..invalidate(cycleTransactionsProvider)
        ..invalidate(cycleReportProvider)
        ..invalidate(crossCycleReportProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              original.flowType == FlowType.expense
                  ? historicalCycle == null
                        ? '退款已记录，余额已更新。'
                        : '历史退款已补记，周期余额已重新计算。'
                  : historicalCycle == null
                  ? '提取已记录，余额已更新。'
                  : '历史提取已补记，周期余额已重新计算。',
            ),
          ),
        );
    }
  }

  Future<void> _openSalaryEntry(SalaryCycle cycle) async {
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => SalaryEntrySheet(cycle: cycle),
    );
    if (saved == true && mounted) {
      ref
        ..invalidate(homeSnapshotProvider)
        ..invalidate(currentCycleTransactionsProvider)
        ..invalidate(salaryCyclesProvider)
        ..invalidate(pendingSalaryCyclesProvider)
        ..invalidate(cycleReportProvider)
        ..invalidate(crossCycleReportProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('工资金额已保存。')));
    }
  }
}

final class _HomeLoadError extends StatelessWidget {
  const _HomeLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 44),
          const SizedBox(height: 12),
          const Text('首页数据加载失败'),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    ),
  );
}
