import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/budgets/domain/budget.dart';
import 'package:xinflow/features/budgets/domain/budget_calculator.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class BudgetManagementCard extends ConsumerWidget {
  const BudgetManagementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(homeSnapshotProvider).value;
    final budgets = snapshot == null
        ? const AsyncValue<List<Budget>>.data([])
        : ref.watch(cycleBudgetsProvider(snapshot.cycle.id));
    return Card(
      child: ListTile(
        leading: const Icon(Icons.speed_rounded),
        title: const Text('预算与提醒'),
        subtitle: Text(
          budgets.when(
            data: (items) =>
                items.isEmpty ? '尚未设置本周期预算' : '${items.length} 项本周期预算',
            loading: () => '正在读取预算…',
            error: (_, _) => '预算读取失败',
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: snapshot == null
            ? null
            : () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _BudgetSheet(cycleId: snapshot.cycle.id),
              ),
      ),
    );
  }
}

final class _BudgetSheet extends ConsumerWidget {
  const _BudgetSheet({required this.cycleId});

  final String cycleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(cycleBudgetsProvider(cycleId));
    final transactions =
        ref.watch(cycleTransactionsProvider(cycleId)).value ??
        const <TransactionEntry>[];
    final categories =
        ref.watch(allCategoriesProvider).value ?? const <Category>[];
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '本周期预算',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _edit(context, ref, categories),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新增'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: budgets.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('可设置周期消费上限或某个消费分类的预算。'));
                  }
                  final progress = BudgetCalculator.calculate(
                    budgets: items,
                    transactions: transactions,
                  );
                  return ListView.separated(
                    itemCount: progress.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = progress[index];
                      final category = item.budget.categoryId == null
                          ? null
                          : categories
                                .where(
                                  (value) => value.id == item.budget.categoryId,
                                )
                                .firstOrNull;
                      return Card(
                        child: ListTile(
                          title: Text(category?.name ?? '周期消费上限'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: item.ratio.clamp(0, 1),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '已用 ${Money.fromCents(item.spentCents).format()} / ${Money.fromCents(item.budget.limitCents).format()}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: '删除预算',
                            onPressed: () => ref
                                .read(budgetRepositoryProvider)
                                .delete(item.budget.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                          onTap: () => _edit(
                            context,
                            ref,
                            categories,
                            budget: item.budget,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories, {
    Budget? budget,
  }) async {
    var amountText = budget == null
        ? ''
        : (budget.limitCents / 100).toStringAsFixed(2);
    var categoryId = budget?.categoryId;
    final expenseCategories = categories.where(
      (item) =>
          item.isTopLevel && item.isActive && item.flowType == FlowType.expense,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(budget == null ? '新增预算' : '修改预算'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: categoryId,
                decoration: const InputDecoration(labelText: '预算范围'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('周期消费上限')),
                  for (final category in expenseCategories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: budget == null
                    ? (value) => setState(() => categoryId = value)
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: amountText,
                onChanged: (value) => amountText = value,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: '预算金额',
                  prefixText: '¥ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      final cents = Money.parse(amountText).cents;
      await ref
          .read(budgetRepositoryProvider)
          .save(
            Budget(
              id: budget?.id ?? ref.read(idGeneratorProvider).next(),
              salaryCycleId: cycleId,
              categoryId: categoryId,
              limitCents: cents,
            ),
          );
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('预算保存失败：$error')));
      }
    }
  }
}
