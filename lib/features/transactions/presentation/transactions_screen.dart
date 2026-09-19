import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

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

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(currentCycleTransactionsProvider);
    final categories = switch (ref.watch(activeCategoriesProvider)) {
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
              '当前周期流水',
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
          const SizedBox(height: 12),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _LoadError(
                error: error,
                onRetry: () => ref.invalidate(currentCycleTransactionsProvider),
              ),
              data: (entries) => _TransactionList(
                entries: _filtered(entries),
                categories: categories,
                onEdit: widget.onEdit,
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
}

final class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.entries,
    required this.categories,
    required this.onEdit,
  });

  final List<TransactionEntry> entries;
  final List<Category> categories;
  final EditAllocationCallback onEdit;

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
                onTap: entry.entryKind == EntryKind.allocation
                    ? () => onEdit(entry)
                    : null,
                leading: CircleAvatar(
                  child: Icon(_iconFor(entry.flowType), size: 20),
                ),
                title: Text(category?.name ?? '未知分类'),
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
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.entryKind == EntryKind.refund ? '+' : '-'} '
                      '${Money.fromCents(entry.amountCents).format()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: entry.entryKind == EntryKind.refund
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    if (entry.entryKind == EntryKind.allocation) ...[
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

IconData _iconFor(FlowType flowType) => switch (flowType) {
  FlowType.expense => Icons.shopping_bag_outlined,
  FlowType.saving => Icons.savings_outlined,
  FlowType.investment => Icons.show_chart_rounded,
};

String _flowLabel(FlowType flowType) => switch (flowType) {
  FlowType.expense => '消费',
  FlowType.saving => '存款',
  FlowType.investment => '理财',
};
