import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class DeleteAllocation {
  const DeleteAllocation({
    required this.salaryCycles,
    required this.transactions,
    required this.clock,
  });

  final SalaryCycleRepository salaryCycles;
  final TransactionRepository transactions;
  final Clock clock;

  Future<void> execute(String transactionId) async {
    final current = await transactions.getById(transactionId);
    if (current == null || current.isDeleted) {
      throw StateError('要删除的流水不存在或已经删除。');
    }
    if (current.entryKind != EntryKind.allocation) {
      throw StateError('退款记录不能通过普通流水入口删除。');
    }
    final activeCycle = await salaryCycles.getActiveCycle();
    if (activeCycle == null || activeCycle.id != current.salaryCycleId) {
      throw StateError('历史工资周期中的流水默认只读。');
    }
    await transactions.softDeleteAllocationGroup(
      transactionId: transactionId,
      deletedAt: clock.now(),
    );
  }
}
