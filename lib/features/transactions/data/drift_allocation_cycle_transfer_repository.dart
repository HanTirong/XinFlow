import 'package:drift/drift.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/transactions/data/allocation_cycle_transfer_repository.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/domain/withdrawal_policy.dart';

final class DriftAllocationCycleTransferRepository
    implements AllocationCycleTransferRepository {
  const DriftAllocationCycleTransferRepository(
    this._database, {
    this.clock = const SystemClock(),
  });

  final AppDatabase _database;
  final Clock clock;

  @override
  Future<void> moveToClosedCycle(TransactionEntry updated) =>
      _database.transaction(() async {
        final original = await (_database.select(
          _database.transactionRecords,
        )..where((row) => row.id.equals(updated.id))).getSingleOrNull();
        if (original == null ||
            original.deletedAt != null ||
            original.entryKind != EntryKind.allocation.name ||
            original.salaryCycleId == updated.salaryCycleId) {
          throw StateError('要转移的流水不存在或状态已经变化。');
        }
        final source =
            await (_database.select(_database.salaryCycleRecords)..where(
                  (row) =>
                      row.id.equals(original.salaryCycleId) &
                      row.status.equals('active') &
                      row.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        final target =
            await (_database.select(_database.salaryCycleRecords)..where(
                  (row) =>
                      row.id.equals(updated.salaryCycleId) &
                      row.status.equals('closed') &
                      row.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (source == null || target == null) {
          throw StateError('工资周期已变化，请重新打开流水后再试。');
        }
        final targetStart = LocalDate.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(target.startedAt),
        );
        final targetEnd = LocalDate.parse(target.expectedPayDate);
        if (updated.occurredOn.compareTo(targetStart) < 0 ||
            updated.occurredOn.compareTo(targetEnd) >= 0) {
          throw StateError('所选日期不属于目标工资周期。');
        }

        final linkedRows = await (_database.select(
          _database.transactionRecords,
        )..where((row) => row.reversesTransactionId.equals(updated.id))).get();
        final linked = linkedRows
            .where((row) => row.deletedAt == null)
            .map((row) => row.toDomain())
            .toList(growable: false);
        final refunds = linked.where(
          (entry) => entry.entryKind == EntryKind.refund,
        );
        final withdrawals = linked.where(
          (entry) => entry.entryKind == EntryKind.withdrawal,
        );
        if (updated.flowType == FlowType.expense) {
          if (withdrawals.isNotEmpty ||
              RefundPolicy.refundableCents(
                    original: updated,
                    existingRefunds: refunds,
                  ) <
                  0) {
            throw const TransactionRuleViolation('流水金额或类型与关联记录冲突。');
          }
        } else if (refunds.isNotEmpty ||
            WithdrawalPolicy.withdrawableCents(
                  original: updated,
                  existingWithdrawals: withdrawals,
                ) <
                0) {
          throw const TransactionRuleViolation('流水金额或类型与关联记录冲突。');
        }

        final stamp = clock.now().toUtc().millisecondsSinceEpoch;
        final count =
            await (_database.update(_database.transactionRecords)..where(
                  (row) =>
                      row.id.equals(updated.id) &
                      row.salaryCycleId.equals(source.id) &
                      row.deletedAt.isNull(),
                ))
                .write(
                  TransactionRecordsCompanion(
                    salaryCycleId: Value(target.id),
                    flowType: Value(updated.flowType.name),
                    amountCents: Value(updated.amountCents),
                    categoryId: Value(updated.categoryId),
                    subcategoryId: Value(updated.subcategoryId),
                    occurredOn: Value(updated.occurredOn.toString()),
                    note: Value(updated.note),
                    updatedAt: Value(stamp),
                  ),
                );
        if (count != 1) {
          throw StateError('流水已变化，跨周期修改已取消。');
        }
        await (_database.update(
          _database.transactionRecords,
        )..where((row) => row.reversesTransactionId.equals(updated.id))).write(
          TransactionRecordsCompanion(
            salaryCycleId: Value(target.id),
            updatedAt: Value(stamp),
          ),
        );

        final targetRows = await (_database.select(
          _database.transactionRecords,
        )..where((row) => row.salaryCycleId.equals(target.id))).get();
        final summary = SalarySummary.fromTransactions(
          salaryCents: target.salaryCents,
          carryoverCents: target.carryoverCents,
          transactions: targetRows.map((row) => row.toDomain()),
        );
        final updatedTarget =
            await (_database.update(_database.salaryCycleRecords)..where(
                  (row) =>
                      row.id.equals(target.id) &
                      row.status.equals('closed') &
                      row.deletedAt.isNull(),
                ))
                .write(
                  SalaryCycleRecordsCompanion(
                    finalRemainingCents: Value(summary.remainingCents),
                    updatedAt: Value(stamp),
                  ),
                );
        if (updatedTarget != 1) {
          throw StateError('历史周期已变化，跨周期修改已取消。');
        }
      });
}
