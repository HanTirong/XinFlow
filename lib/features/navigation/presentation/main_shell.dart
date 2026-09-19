import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/home/presentation/home_screen.dart';
import 'package:xinflow/features/reports/presentation/report_screen.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_settlement_sheet.dart';
import 'package:xinflow/features/settings/presentation/settings_screen.dart';
import 'package:xinflow/features/transactions/presentation/add_allocation_sheet.dart';
import 'package:xinflow/features/transactions/presentation/add_refund_sheet.dart';
import 'package:xinflow/features/transactions/presentation/transactions_screen.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

final class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final homeSnapshot = ref.watch(homeSnapshotProvider);
    final pages = [
      homeSnapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _HomeLoadError(
          message: error.toString(),
          onRetry: () => ref.invalidate(homeSnapshotProvider),
        ),
        data: (snapshot) => HomeScreen(
          snapshot: snapshot,
          onAddAllocation: _openAddAllocation,
          onSalaryReceived: () => _openCycleSettlement(snapshot),
        ),
      ),
      TransactionsScreen(onEdit: _openEditAllocation),
      const ReportScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openAddAllocation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('记一笔'),
            )
          : null,
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

  Future<void> _openAddAllocation([String? categoryId]) =>
      _openAllocationEditor(initialCategoryId: categoryId);

  Future<void> _openEditAllocation(TransactionEntry entry) =>
      _openAllocationEditor(entry: entry);

  Future<void> _openAllocationEditor({
    String? initialCategoryId,
    TransactionEntry? entry,
  }) async {
    final result = await showModalBottomSheet<AllocationEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => AddAllocationSheet(
        initialCategoryId: initialCategoryId,
        entry: entry,
      ),
    );
    if (result != null && mounted) {
      final message = switch (result) {
        AllocationEditorResult.created => '已记入本期工资流向。',
        AllocationEditorResult.updated => '流水修改已保存。',
        AllocationEditorResult.deleted => '流水已删除，余额已重新计算。',
        AllocationEditorResult.refundRequested => null,
      };
      if (result == AllocationEditorResult.refundRequested && entry != null) {
        await _openRefund(entry);
        return;
      }
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openRefund(TransactionEntry original) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => AddRefundSheet(original: original),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('退款已记录，余额已更新。')));
    }
  }

  Future<void> _openCycleSettlement(HomeSnapshot snapshot) async {
    final bootstrap = await ref.read(startupProvider.future);
    if (!mounted || bootstrap.settings == null) return;
    final switched = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => CycleSettlementSheet(
        snapshot: snapshot,
        salaryDay: bootstrap.settings!.salaryDay,
      ),
    );
    if (switched == true && mounted) {
      ref
        ..invalidate(homeSnapshotProvider)
        ..invalidate(currentCycleTransactionsProvider)
        ..invalidate(salaryCyclesProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('新工资周期已开始。')));
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
