import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/domain/withdrawal_policy.dart';

final class CreateWithdrawal {
  const CreateWithdrawal({
    required this.salaryCycles,
    required this.transactions,
    required this.clock,
    required this.idGenerator,
  });

  final SalaryCycleRepository salaryCycles;
  final TransactionRepository transactions;
  final Clock clock;
  final IdGenerator idGenerator;

  Future<int> withdrawableCents(String transactionId) async {
    final original = await _loadOriginal(transactionId);
    final reversals = await transactions.listRefundsFor(transactionId);
    return WithdrawalPolicy.withdrawableCents(
      original: original,
      existingWithdrawals: reversals,
    );
  }

  Future<TransactionEntry> execute({
    required String transactionId,
    required int amountCents,
    String? note,
  }) async {
    final original = await _loadOriginal(transactionId);
    final reversals = await transactions.listRefundsFor(transactionId);
    WithdrawalPolicy.ensureCanWithdraw(
      original: original,
      existingWithdrawals: reversals,
      withdrawalCents: amountCents,
    );
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.length > 200) {
      throw ArgumentError.value(note, 'note', '备注不能超过 200 个字符。');
    }
    final now = clock.now();
    final withdrawal = TransactionEntry(
      id: idGenerator.next(),
      salaryCycleId: original.salaryCycleId,
      entryKind: EntryKind.withdrawal,
      flowType: original.flowType,
      amountCents: amountCents,
      categoryId: original.categoryId,
      subcategoryId: original.subcategoryId,
      reversesTransactionId: original.id,
      occurredAt: now,
      occurredOn: LocalDate.fromDateTime(now),
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    await transactions.add(withdrawal);
    return withdrawal;
  }

  Future<TransactionEntry> _loadOriginal(String transactionId) async {
    final original = await transactions.getById(transactionId);
    if (original == null) {
      throw const TransactionRuleViolation('原存款或理财记录不存在。');
    }
    final activeCycle = await salaryCycles.getActiveCycle();
    if (activeCycle == null || activeCycle.id != original.salaryCycleId) {
      throw const TransactionRuleViolation('历史工资周期中的流水默认只读。');
    }
    WithdrawalPolicy.withdrawableCents(
      original: original,
      existingWithdrawals: const [],
    );
    return original;
  }
}
