import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

abstract interface class AllocationCycleTransferRepository {
  /// Atomically moves an active-cycle allocation and its linked records.
  Future<void> moveToClosedCycle(TransactionEntry updated);
}
