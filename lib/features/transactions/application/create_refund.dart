import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class CreateRefund {
  const CreateRefund({
    required this.salaryCycles,
    required this.transactions,
    required this.clock,
    required this.idGenerator,
  });

  final SalaryCycleRepository salaryCycles;
  final TransactionRepository transactions;
  final Clock clock;
  final IdGenerator idGenerator;

  Future<int> refundableCents(String transactionId) async {
    final original = await _loadOriginal(transactionId);
    final refunds = await transactions.listRefundsFor(transactionId);
    return RefundPolicy.refundableCents(
      original: original,
      existingRefunds: refunds,
    );
  }

  Future<TransactionEntry> execute({
    required String transactionId,
    required int amountCents,
    String? note,
  }) async {
    final original = await _loadOriginal(transactionId);
    final refunds = await transactions.listRefundsFor(transactionId);
    RefundPolicy.ensureCanRefund(
      original: original,
      existingRefunds: refunds,
      refundCents: amountCents,
    );
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.length > 200) {
      throw ArgumentError.value(note, 'note', '备注不能超过 200 个字符。');
    }

    final now = clock.now();
    final refund = TransactionEntry(
      id: idGenerator.next(),
      salaryCycleId: original.salaryCycleId,
      entryKind: EntryKind.refund,
      flowType: FlowType.expense,
      amountCents: amountCents,
      categoryId: original.categoryId,
      subcategoryId: original.subcategoryId,
      reversesTransactionId: original.id,
      occurredAt: now,
      occurredOn: LocalDate.fromDateTime(now),
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    await transactions.add(refund);
    return refund;
  }

  Future<TransactionEntry> _loadOriginal(String transactionId) async {
    final original = await transactions.getById(transactionId);
    if (original == null) {
      throw const TransactionRuleViolation('原消费记录不存在。');
    }
    final activeCycle = await salaryCycles.getActiveCycle();
    if (activeCycle == null || activeCycle.id != original.salaryCycleId) {
      throw const TransactionRuleViolation('历史工资周期中的流水默认只读。');
    }
    RefundPolicy.refundableCents(original: original, existingRefunds: const []);
    return original;
  }
}
