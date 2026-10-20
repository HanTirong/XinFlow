import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class FlowBreakdown {
  const FlowBreakdown({required this.totalCents, required this.groups});

  factory FlowBreakdown.calculate({
    required FlowType flowType,
    required Iterable<TransactionEntry> transactions,
    required Iterable<Category> categories,
  }) {
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final active = transactions.where((entry) => !entry.isDeleted).toList();
    final allocationById = {
      for (final entry in active.where(
        (entry) => entry.entryKind == EntryKind.allocation,
      ))
        entry.id: entry,
    };
    final totals = <String, Map<String?, int>>{};
    var totalCents = 0;

    for (final entry in active.where((entry) => entry.flowType == flowType)) {
      final amount = entry.entryKind == EntryKind.allocation
          ? entry.amountCents
          : -entry.amountCents;
      totalCents += amount;
      final original = allocationById[entry.reversesTransactionId];
      final source = original?.flowType == flowType ? original! : entry;
      final children = totals.putIfAbsent(source.categoryId, () => {});
      children.update(
        source.subcategoryId,
        (current) => current + amount,
        ifAbsent: () => amount,
      );
    }

    final groups = <FlowBreakdownGroup>[
      for (final record in totals.entries)
        FlowBreakdownGroup(
          categoryId: record.key,
          name: categoryById[record.key]?.name ?? '已删除分类',
          totalCents: record.value.values.fold(0, (sum, value) => sum + value),
          children: [
            for (final child in record.value.entries)
              FlowBreakdownItem(
                categoryId: child.key,
                name: child.key == null
                    ? '未细分'
                    : categoryById[child.key]?.name ?? '已删除子类',
                cents: child.value,
              ),
          ]..sort((a, b) => b.cents.compareTo(a.cents)),
        ),
    ]..sort((a, b) => b.totalCents.compareTo(a.totalCents));
    return FlowBreakdown(totalCents: totalCents, groups: groups);
  }

  final int totalCents;
  final List<FlowBreakdownGroup> groups;
}

final class FlowBreakdownGroup {
  const FlowBreakdownGroup({
    required this.categoryId,
    required this.name,
    required this.totalCents,
    required this.children,
  });

  final String categoryId;
  final String name;
  final int totalCents;
  final List<FlowBreakdownItem> children;
}

final class FlowBreakdownItem {
  const FlowBreakdownItem({
    required this.categoryId,
    required this.name,
    required this.cents,
  });

  final String? categoryId;
  final String name;
  final int cents;
}
