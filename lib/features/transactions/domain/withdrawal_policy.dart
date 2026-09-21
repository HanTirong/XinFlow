import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

abstract final class WithdrawalPolicy {
  static int withdrawableCents({
    required TransactionEntry original,
    required Iterable<TransactionEntry> existingWithdrawals,
  }) {
    _ensureWithdrawableOriginal(original);
    final withdrawn = existingWithdrawals
        .where(
          (entry) =>
              !entry.isDeleted &&
              entry.entryKind == EntryKind.withdrawal &&
              entry.reversesTransactionId == original.id,
        )
        .fold<int>(0, (total, entry) => total + entry.amountCents);
    return original.amountCents - withdrawn;
  }

  static void ensureCanWithdraw({
    required TransactionEntry original,
    required Iterable<TransactionEntry> existingWithdrawals,
    required int withdrawalCents,
  }) {
    if (withdrawalCents <= 0) {
      throw const TransactionRuleViolation('提取金额必须大于 0。');
    }
    final remaining = withdrawableCents(
      original: original,
      existingWithdrawals: existingWithdrawals,
    );
    if (withdrawalCents > remaining) {
      throw TransactionRuleViolation('提取金额不能超过尚可提取的 $remaining 分。');
    }
  }

  static void _ensureWithdrawableOriginal(TransactionEntry original) {
    if (original.isDeleted ||
        original.entryKind != EntryKind.allocation ||
        original.flowType == FlowType.expense) {
      throw const TransactionRuleViolation('只能从有效的存款或理财分配记录中提取。');
    }
  }
}
