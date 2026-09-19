import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

void main() {
  test('calculates salary allocation and remaining amount', () {
    final entries = [
      _entry(id: 'expense', amountCents: 30000),
      _entry(id: 'saving', amountCents: 20000, flowType: FlowType.saving),
      _entry(
        id: 'investment',
        amountCents: 10000,
        flowType: FlowType.investment,
      ),
      _entry(
        id: 'refund',
        amountCents: 5000,
        entryKind: EntryKind.refund,
        reversesTransactionId: 'expense',
      ),
    ];

    final summary = SalarySummary.fromTransactions(
      salaryCents: 100000,
      transactions: entries,
    );

    expect(summary.netExpenseCents, 25000);
    expect(summary.savingCents, 20000);
    expect(summary.investmentCents, 10000);
    expect(summary.allocatedCents, 55000);
    expect(summary.remainingCents, 45000);
  });

  test('ignores soft-deleted entries', () {
    final summary = SalarySummary.fromTransactions(
      salaryCents: 100000,
      transactions: [
        _entry(
          id: 'deleted',
          amountCents: 50000,
          deletedAt: DateTime.utc(2026, 9, 19),
        ),
      ],
    );

    expect(summary.allocatedCents, 0);
    expect(summary.remainingCents, 100000);
  });

  test('allows a negative remaining amount without losing the invariant', () {
    final summary = SalarySummary.fromTransactions(
      salaryCents: 10000,
      transactions: [_entry(id: 'overspend', amountCents: 15000)],
    );

    expect(summary.allocatedCents, 15000);
    expect(summary.remainingCents, -5000);
    expect(
      summary.salaryCents,
      summary.allocatedCents + summary.remainingCents,
    );
  });
}

TransactionEntry _entry({
  required String id,
  required int amountCents,
  FlowType flowType = FlowType.expense,
  EntryKind entryKind = EntryKind.allocation,
  String? reversesTransactionId,
  DateTime? deletedAt,
}) => TransactionEntry(
  id: id,
  salaryCycleId: 'cycle-1',
  entryKind: entryKind,
  flowType: flowType,
  amountCents: amountCents,
  categoryId: 'category-1',
  reversesTransactionId: reversesTransactionId,
  occurredAt: DateTime.utc(2026, 9, 19, 12),
  occurredOn: const LocalDate(2026, 9, 19),
  deletedAt: deletedAt,
);
