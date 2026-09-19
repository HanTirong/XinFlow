import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

void main() {
  group('RefundPolicy', () {
    test('subtracts existing refunds from the refundable amount', () {
      final original = _expense(id: 'expense', amountCents: 10000);
      final refunds = [
        _refund(id: 'refund-1', originalId: original.id, amountCents: 3000),
        _refund(id: 'refund-2', originalId: original.id, amountCents: 2000),
      ];

      expect(
        RefundPolicy.refundableCents(
          original: original,
          existingRefunds: refunds,
        ),
        5000,
      );
    });

    test('rejects a refund above the original remaining amount', () {
      final original = _expense(id: 'expense', amountCents: 10000);
      final refunds = [
        _refund(id: 'refund-1', originalId: original.id, amountCents: 8000),
      ];

      expect(
        () => RefundPolicy.ensureCanRefund(
          original: original,
          existingRefunds: refunds,
          refundCents: 2001,
        ),
        throwsA(isA<TransactionRuleViolation>()),
      );
    });

    test('ignores a deleted refund', () {
      final original = _expense(id: 'expense', amountCents: 10000);
      final deletedRefund = _refund(
        id: 'refund-1',
        originalId: original.id,
        amountCents: 8000,
        deletedAt: DateTime.utc(2026, 9, 19),
      );

      expect(
        RefundPolicy.refundableCents(
          original: original,
          existingRefunds: [deletedRefund],
        ),
        10000,
      );
    });
  });
}

TransactionEntry _expense({required String id, required int amountCents}) =>
    TransactionEntry(
      id: id,
      salaryCycleId: 'cycle-1',
      entryKind: EntryKind.allocation,
      flowType: FlowType.expense,
      amountCents: amountCents,
      categoryId: 'food',
      occurredAt: DateTime.utc(2026, 9, 19, 12),
      occurredOn: const LocalDate(2026, 9, 19),
    );

TransactionEntry _refund({
  required String id,
  required String originalId,
  required int amountCents,
  DateTime? deletedAt,
}) => TransactionEntry(
  id: id,
  salaryCycleId: 'cycle-1',
  entryKind: EntryKind.refund,
  flowType: FlowType.expense,
  amountCents: amountCents,
  categoryId: 'food',
  reversesTransactionId: originalId,
  occurredAt: DateTime.utc(2026, 9, 19, 13),
  occurredOn: const LocalDate(2026, 9, 19),
  deletedAt: deletedAt,
);
