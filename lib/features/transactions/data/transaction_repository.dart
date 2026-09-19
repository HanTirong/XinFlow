import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

abstract interface class TransactionRepository {
  Stream<List<TransactionEntry>> watchCycleTransactions(String salaryCycleId);

  Future<List<TransactionEntry>> listCycleTransactions(String salaryCycleId);

  Future<TransactionEntry?> getById(String transactionId);

  Future<void> add(TransactionEntry entry);

  Future<void> update(TransactionEntry entry);

  Future<void> softDelete({
    required String transactionId,
    required DateTime deletedAt,
  });

  Future<void> softDeleteAllocationGroup({
    required String transactionId,
    required DateTime deletedAt,
  });
}
