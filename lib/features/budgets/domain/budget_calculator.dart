import 'package:xinflow/features/budgets/domain/budget.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

abstract final class BudgetCalculator {
  static List<BudgetProgress> calculate({
    required Iterable<Budget> budgets,
    required Iterable<TransactionEntry> transactions,
  }) {
    final active = transactions.where((entry) => !entry.isDeleted);
    return [
      for (final budget in budgets)
        BudgetProgress(
          budget: budget,
          spentCents: active
              .where(
                (entry) =>
                    entry.flowType == FlowType.expense &&
                    (budget.categoryId == null ||
                        entry.categoryId == budget.categoryId),
              )
              .fold<int>(
                0,
                (total, entry) =>
                    total +
                    (entry.entryKind == EntryKind.refund
                        ? -entry.amountCents
                        : entry.amountCents),
              ),
        ),
    ];
  }
}
