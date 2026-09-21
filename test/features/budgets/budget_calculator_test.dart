import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/budgets/domain/budget.dart';
import 'package:xinflow/features/budgets/domain/budget_calculator.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

void main() {
  test('uses net expenses for overall and category budget progress', () {
    const budgets = [
      Budget(id: 'overall', salaryCycleId: 'cycle', limitCents: 10000),
      Budget(
        id: 'food-budget',
        salaryCycleId: 'cycle',
        categoryId: 'food',
        limitCents: 5000,
      ),
    ];
    final expense = _entry('expense', EntryKind.allocation, 6000, 'food');
    final refund = _entry(
      'refund',
      EntryKind.refund,
      1000,
      'food',
      originalId: expense.id,
    );
    final saving = _entry(
      'saving',
      EntryKind.allocation,
      9000,
      'saving',
      flowType: FlowType.saving,
    );

    final result = BudgetCalculator.calculate(
      budgets: budgets,
      transactions: [expense, refund, saving],
    );
    expect(result[0].spentCents, 5000);
    expect(result[1].spentCents, 5000);
    expect(result[1].isExceeded, isTrue);
  });
}

TransactionEntry _entry(
  String id,
  EntryKind kind,
  int amount,
  String categoryId, {
  String? originalId,
  FlowType flowType = FlowType.expense,
}) => TransactionEntry(
  id: id,
  salaryCycleId: 'cycle',
  entryKind: kind,
  flowType: flowType,
  amountCents: amount,
  categoryId: categoryId,
  reversesTransactionId: originalId,
  occurredAt: DateTime.utc(2026, 9, 20),
  occurredOn: const LocalDate(2026, 9, 20),
);
