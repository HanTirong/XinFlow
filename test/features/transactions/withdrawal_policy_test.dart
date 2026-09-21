import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/domain/withdrawal_policy.dart';

void main() {
  test('supports multiple partial withdrawals and caps their total', () {
    final original = _entry(
      id: 'saving',
      kind: EntryKind.allocation,
      amount: 10000,
    );
    final withdrawals = [
      _entry(
        id: 'withdrawal-1',
        kind: EntryKind.withdrawal,
        amount: 3000,
        originalId: original.id,
      ),
      _entry(
        id: 'withdrawal-2',
        kind: EntryKind.withdrawal,
        amount: 2000,
        originalId: original.id,
      ),
    ];

    expect(
      WithdrawalPolicy.withdrawableCents(
        original: original,
        existingWithdrawals: withdrawals,
      ),
      5000,
    );
    expect(
      () => WithdrawalPolicy.ensureCanWithdraw(
        original: original,
        existingWithdrawals: withdrawals,
        withdrawalCents: 5001,
      ),
      throwsA(isA<Exception>()),
    );
  });
}

TransactionEntry _entry({
  required String id,
  required EntryKind kind,
  required int amount,
  String? originalId,
}) => TransactionEntry(
  id: id,
  salaryCycleId: 'cycle',
  entryKind: kind,
  flowType: FlowType.saving,
  amountCents: amount,
  categoryId: 'saving',
  reversesTransactionId: originalId,
  occurredAt: DateTime.utc(2026, 9, 20),
  occurredOn: const LocalDate(2026, 9, 20),
);
