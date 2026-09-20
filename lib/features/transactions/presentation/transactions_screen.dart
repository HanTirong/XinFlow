import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/presentation/transaction_amount_formatter.dart';

typedef EditAllocationCallback = void Function(TransactionEntry entry);

enum _FlowFilter { all, expense, saving, investment }

final class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({required this.onEdit, super.key});

  final EditAllocationCallback onEdit;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

final class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _FlowFilter _filter = _FlowFilter.all;
  String? _selectedCycleId;

  @override
  Widget build(BuildContext context) {
    final cycles = switch (ref.watch(salaryCyclesProvider)) {
      AsyncData(:final value) => value,
      _ => const <SalaryCycle>[],
    };
    final selectedCycle = cycles.isEmpty
        ? null
        : cycles.firstWhere(
            (cycle) => cycle.id == _selectedCycleId,
            orElse: () => cycles.first,
          );
    final transactions = selectedCycle == null
        ? const AsyncValue<List<TransactionEntry>>.data([])
        : ref.watch(cycleTransactionsProvider(selectedCycle.id));
    final categories = switch (ref.watch(allCategoriesProvider)) {
      AsyncData(:final value) => value,
      _ => const <Category>[],
    };

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              selectedCycle?.status == SalaryCycleStatus.closed
                  ? '历史周期流水'
                  : '当前周期流水',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<_FlowFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _FlowFilter.all, label: Text('全部')),
                ButtonSegment(value: _FlowFilter.expense, label: Text('消费')),
                ButtonSegment(value: _FlowFilter.saving, label: Text('存款')),
                ButtonSegment(value: _FlowFilter.investment, label: Text('理财')),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) =>
                  setState(() => _filter = selection.single),
            ),
          ),
          if (cycles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SalaryCycleSelector(
                cycle: selectedCycle!,
                onTap: () => _chooseCycle(cycles, selectedCycle),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _LoadError(
                error: error,
                onRetry: selectedCycle == null
                    ? () => ref.invalidate(salaryCyclesProvider)
                    : () => ref.invalidate(
                        cycleTransactionsProvider(selectedCycle.id),
                      ),
              ),
              data: (entries) => _TransactionList(
                entries: _filtered(entries),
                categories: categories,
                onEdit: selectedCycle?.status == SalaryCycleStatus.active
                    ? widget.onEdit
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionEntry> _filtered(List<TransactionEntry> entries) {
    final result = entries
        .where((entry) {
          final type = switch (_filter) {
            _FlowFilter.all => null,
            _FlowFilter.expense => FlowType.expense,
            _FlowFilter.saving => FlowType.saving,
            _FlowFilter.investment => FlowType.investment,
          };
          return type == null || entry.flowType == type;
        })
        .toList(growable: false);
    result.sort((a, b) {
      final dateOrder = b.occurredOn.compareTo(a.occurredOn);
      return dateOrder != 0 ? dateOrder : b.occurredAt.compareTo(a.occurredAt);
    });
    return result;
  }

  Future<void> _chooseCycle(
    List<SalaryCycle> cycles,
    SalaryCycle selected,
  ) async {
    final cycleId = await showSalaryCyclePicker(
      context: context,
      cycles: cycles,
      selectedCycleId: selected.id,
    );
    if (cycleId != null && mounted) {
      setState(() => _selectedCycleId = cycleId);
    }
  }
}

final class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.entries,
    required this.categories,
    required this.onEdit,
  });

  final List<TransactionEntry> entries;
  final List<Category> categories;
  final EditAllocationCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState();
    }
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final showDate =
            index == 0 || entries[index - 1].occurredOn != entry.occurredOn;
        final category = categoryById[entry.categoryId];
        final subcategory = entry.subcategoryId == null
            ? null
            : categoryById[entry.subcategoryId];
        final visual = CategoryVisuals.resolve(
          categoryId: entry.categoryId,
          categories: categories,
          fallbackName: category?.name,
          fallbackType: entry.flowType,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) ...[
              if (index != 0) const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                child: Text(
                  '${entry.occurredOn.month}月${entry.occurredOn.day}日',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: entry.entryKind == EntryKind.allocation && onEdit != null
                    ? () => onEdit!(entry)
                    : null,
                leading: CategoryIconBadge(config: visual),
                title: Text(
                  visual.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  [
                        if (subcategory != null) subcategory.name,
                        if (entry.note != null) entry.note!,
                      ].isEmpty
                      ? _flowLabel(entry.flowType)
                      : [
                          if (subcategory != null) subcategory.name,
                          if (entry.note != null) entry.note!,
                        ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTransactionAmount(entry),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: entry.entryKind == EntryKind.refund
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    if (entry.entryKind == EntryKind.allocation &&
                        onEdit != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text('还没有流水', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('点击右下角“记一笔”开始记录。'),
        ],
      ),
    ),
  );
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('流水加载失败'),
        const SizedBox(height: 8),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}

String _flowLabel(FlowType flowType) => switch (flowType) {
  FlowType.expense => '消费',
  FlowType.saving => '存款',
  FlowType.investment => '理财',
};
