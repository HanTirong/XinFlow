import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/reports/domain/cycle_report.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

void main() {
  test('aggregates refunds into category and daily net expense', () {
    final cycle = SalaryCycle(
      id: 'cycle-1',
      salaryCents: 1000000,
      startedAt: DateTime.utc(2026, 9, 1),
      expectedPayDate: const LocalDate(2026, 10, 1),
      status: SalaryCycleStatus.active,
    );
    final previous = SalarySummary.fromTransactions(
      salaryCents: 800000,
      transactions: const [],
    );
    final previousCycle = SalaryCycle(
      id: 'cycle-previous',
      salaryCents: 800000,
      startedAt: DateTime.utc(2026, 8, 1),
      expectedPayDate: const LocalDate(2026, 9, 1),
      status: SalaryCycleStatus.closed,
      closedAt: DateTime.utc(2026, 9, 1),
      finalRemainingCents: 800000,
    );
    final report = CycleReport.fromData(
      cycle: cycle,
      previousCycle: previousCycle,
      previousSummary: previous,
      transactions: [
        _entry(id: 'food-1', amountCents: 10000, categoryId: 'food'),
        _entry(
          id: 'refund-1',
          amountCents: 2500,
          categoryId: 'food',
          kind: EntryKind.refund,
        ),
        _entry(id: 'shop-1', amountCents: 4000, categoryId: 'shopping'),
        _entry(
          id: 'saving-1',
          amountCents: 50000,
          categoryId: 'saving',
          flowType: FlowType.saving,
        ),
      ],
    );

    expect(report.summary.netExpenseCents, 11500);
    expect(report.summary.savingCents, 50000);
    expect(report.expenseByCategory, {'food': 7500, 'shopping': 4000});
    expect(report.dailyNetExpense[const LocalDate(2026, 9, 20)], 11500);
    expect(report.previousCycle, same(previousCycle));
    expect(report.previousSummary, same(previous));
  });
}

TransactionEntry _entry({
  required String id,
  required int amountCents,
  required String categoryId,
  EntryKind kind = EntryKind.allocation,
  FlowType flowType = FlowType.expense,
}) => TransactionEntry(
  id: id,
  salaryCycleId: 'cycle-1',
  entryKind: kind,
  flowType: flowType,
  amountCents: amountCents,
  categoryId: categoryId,
  reversesTransactionId: kind == EntryKind.refund ? 'food-1' : null,
  occurredAt: DateTime.utc(2026, 9, 20),
  occurredOn: const LocalDate(2026, 9, 20),
);
