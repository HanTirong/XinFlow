import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

abstract interface class ClosedCycleCorrectionRepository {
  Future<TransactionEntry?> getTransaction(String transactionId);

  Future<List<TransactionEntry>> listRefundsFor(String transactionId);

  Future<void> insertAndRecalculate(TransactionEntry entry);

  Future<void> updateAllocationAndRecalculate(TransactionEntry entry);

  Future<void> softDeleteAllocationGroupAndRecalculate({
    required String transactionId,
    required DateTime deletedAt,
  });
}
