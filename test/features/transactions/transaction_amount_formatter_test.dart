import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/presentation/transaction_amount_formatter.dart';

void main() {
  test('formats allocation and refund amounts consistently', () {
    final allocation = TransactionEntry(
      id: 'allocation',
      salaryCycleId: 'cycle',
      entryKind: EntryKind.allocation,
      flowType: FlowType.expense,
      amountCents: 27220,
      categoryId: 'shopping',
      occurredAt: DateTime(2026, 9, 19),
      occurredOn: const LocalDate(2026, 9, 19),
    );
    final refund = TransactionEntry(
      id: 'refund',
      salaryCycleId: 'cycle',
      entryKind: EntryKind.refund,
      flowType: FlowType.expense,
      amountCents: 1000,
      categoryId: 'shopping',
      reversesTransactionId: allocation.id,
      occurredAt: DateTime(2026, 9, 20),
      occurredOn: const LocalDate(2026, 9, 20),
    );

    expect(formatTransactionAmount(allocation), '- ¥272.20');
    expect(formatTransactionAmount(refund), '+ ¥10');
  });
}
