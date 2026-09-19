import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class TransactionRuleViolation implements Exception {
  const TransactionRuleViolation(this.message);

  final String message;

  @override
  String toString() => message;
}

final class RefundPolicy {
  const RefundPolicy._();

  static int refundableCents({
    required TransactionEntry original,
    required Iterable<TransactionEntry> existingRefunds,
  }) {
    _ensureRefundableOriginal(original);

    final refundedCents = existingRefunds
        .where(
          (entry) =>
              !entry.isDeleted &&
              entry.entryKind == EntryKind.refund &&
              entry.reversesTransactionId == original.id,
        )
        .fold<int>(0, (total, entry) => total + entry.amountCents);

    return original.amountCents - refundedCents;
  }

  static void ensureCanRefund({
    required TransactionEntry original,
    required Iterable<TransactionEntry> existingRefunds,
    required int refundCents,
  }) {
    if (refundCents <= 0) {
      throw const TransactionRuleViolation('退款金额必须大于 0。');
    }

    final remaining = refundableCents(
      original: original,
      existingRefunds: existingRefunds,
    );
    if (refundCents > remaining) {
      throw TransactionRuleViolation('退款金额不能超过尚可退款的 $remaining 分。');
    }
  }

  static void _ensureRefundableOriginal(TransactionEntry original) {
    if (original.isDeleted ||
        original.entryKind != EntryKind.allocation ||
        original.flowType != FlowType.expense) {
      throw const TransactionRuleViolation('只能对有效的消费分配记录退款。');
    }
  }
}
