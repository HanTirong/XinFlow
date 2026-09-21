import 'package:drift/drift.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/data/closed_cycle_correction_repository.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/domain/withdrawal_policy.dart';

final class DriftClosedCycleCorrectionRepository
    implements ClosedCycleCorrectionRepository {
  const DriftClosedCycleCorrectionRepository(
    this._database, {
    this.clock = const SystemClock(),
  });

  final AppDatabase _database;
  final Clock clock;

  @override
  Future<TransactionEntry?> getTransaction(String transactionId) async {
    final row = await (_database.select(
      _database.transactionRecords,
    )..where((row) => row.id.equals(transactionId))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<TransactionEntry>> listRefundsFor(String transactionId) async {
    final rows =
        await (_database.select(_database.transactionRecords)
              ..where((row) => row.reversesTransactionId.equals(transactionId))
              ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)]))
            .get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> insertAndRecalculate(TransactionEntry entry) =>
      _database.transaction(() async {
        final cycle = await _requireClosedCycle(entry.salaryCycleId);
        _ensureDateInCycle(entry.occurredOn, cycle);
        if (entry.entryKind == EntryKind.refund) {
          final original = await getTransaction(entry.reversesTransactionId!);
          if (original == null || original.salaryCycleId != cycle.id) {
            throw const TransactionRuleViolation('原消费记录不存在或不属于该历史周期。');
          }
          final refunds = await listRefundsFor(original.id);
          RefundPolicy.ensureCanRefund(
            original: original,
            existingRefunds: refunds,
            refundCents: entry.amountCents,
          );
        } else if (entry.entryKind == EntryKind.withdrawal) {
          final original = await getTransaction(entry.reversesTransactionId!);
          if (original == null || original.salaryCycleId != cycle.id) {
            throw const TransactionRuleViolation('原存款或理财记录不存在或不属于该历史周期。');
          }
          WithdrawalPolicy.ensureCanWithdraw(
            original: original,
            existingWithdrawals: await listRefundsFor(original.id),
            withdrawalCents: entry.amountCents,
          );
        }

        final timestamp = clock.now().toUtc().millisecondsSinceEpoch;
        await _database
            .into(_database.transactionRecords)
            .insert(
              TransactionRecordsCompanion.insert(
                id: entry.id,
                salaryCycleId: entry.salaryCycleId,
                entryKind: entry.entryKind.name,
                flowType: entry.flowType.name,
                amountCents: entry.amountCents,
                categoryId: entry.categoryId,
                subcategoryId: Value(entry.subcategoryId),
                reversesTransactionId: Value(entry.reversesTransactionId),
                occurredAt: entry.occurredAt.toUtc().millisecondsSinceEpoch,
                occurredOn: entry.occurredOn.toString(),
                note: Value(entry.note),
                createdAt: timestamp,
                updatedAt: timestamp,
              ),
            );
        await _recalculate(cycle, timestamp);
      });

  @override
  Future<void> updateAllocationAndRecalculate(TransactionEntry entry) =>
      _database.transaction(() async {
        final cycle = await _requireClosedCycle(entry.salaryCycleId);
        _ensureDateInCycle(entry.occurredOn, cycle);
        final refunds = await listRefundsFor(entry.id);
        final activeRefunds = refunds.where(
          (refund) => !refund.isDeleted && refund.entryKind == EntryKind.refund,
        );
        final activeWithdrawals = refunds.where(
          (entry) =>
              !entry.isDeleted && entry.entryKind == EntryKind.withdrawal,
        );
        if (entry.flowType == FlowType.expense) {
          if (RefundPolicy.refundableCents(
                original: entry,
                existingRefunds: activeRefunds,
              ) <
              0) {
            throw const TransactionRuleViolation('修改后的消费金额不能小于累计退款金额。');
          }
        } else if (activeRefunds.isNotEmpty) {
          throw const TransactionRuleViolation('已有退款的消费流水不能改为存款或理财。');
        }
        if (entry.flowType != FlowType.expense) {
          if (WithdrawalPolicy.withdrawableCents(
                original: entry,
                existingWithdrawals: activeWithdrawals,
              ) <
              0) {
            throw const TransactionRuleViolation('修改后的金额不能小于累计提取金额。');
          }
        } else if (activeWithdrawals.isNotEmpty) {
          throw const TransactionRuleViolation('已有提取记录的流水不能改为消费。');
        }

        final timestamp = clock.now().toUtc().millisecondsSinceEpoch;
        final updatedRows =
            await (_database.update(_database.transactionRecords)..where(
                  (row) =>
                      row.id.equals(entry.id) &
                      row.salaryCycleId.equals(cycle.id) &
                      row.entryKind.equals(EntryKind.allocation.name) &
                      row.deletedAt.isNull(),
                ))
                .write(
                  TransactionRecordsCompanion(
                    flowType: Value(entry.flowType.name),
                    amountCents: Value(entry.amountCents),
                    categoryId: Value(entry.categoryId),
                    subcategoryId: Value(entry.subcategoryId),
                    occurredOn: Value(entry.occurredOn.toString()),
                    note: Value(entry.note),
                    updatedAt: Value(timestamp),
                  ),
                );
        if (updatedRows != 1) {
          throw StateError('要修正的历史流水不存在或已经删除。');
        }
        await _recalculate(cycle, timestamp);
      });

  @override
  Future<void> softDeleteAllocationGroupAndRecalculate({
    required String transactionId,
    required DateTime deletedAt,
  }) => _database.transaction(() async {
    final original = await getTransaction(transactionId);
    if (original == null || original.isDeleted) {
      throw StateError('要删除的历史流水不存在或已经删除。');
    }
    final cycle = await _requireClosedCycle(original.salaryCycleId);
    final timestamp = deletedAt.toUtc().millisecondsSinceEpoch;
    final updatedRows =
        await (_database.update(_database.transactionRecords)..where(
              (row) =>
                  row.id.equals(transactionId) &
                  row.entryKind.equals(EntryKind.allocation.name) &
                  row.deletedAt.isNull(),
            ))
            .write(
              TransactionRecordsCompanion(
                deletedAt: Value(timestamp),
                updatedAt: Value(timestamp),
              ),
            );
    if (updatedRows != 1) {
      throw StateError('要删除的历史流水不存在或已经删除。');
    }
    await (_database.update(_database.transactionRecords)..where(
          (row) =>
              row.reversesTransactionId.equals(transactionId) &
              row.deletedAt.isNull(),
        ))
        .write(
          TransactionRecordsCompanion(
            deletedAt: Value(timestamp),
            updatedAt: Value(timestamp),
          ),
        );
    await _recalculate(cycle, timestamp);
  });

  Future<SalaryCycleRecord> _requireClosedCycle(String cycleId) async {
    final cycle =
        await (_database.select(_database.salaryCycleRecords)..where(
              (row) =>
                  row.id.equals(cycleId) &
                  row.status.equals(SalaryCycleStatus.closed.name) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (cycle == null) {
      throw StateError('只能修正已经封存的工资周期。');
    }
    return cycle;
  }

  Future<void> _recalculate(SalaryCycleRecord cycle, int timestamp) async {
    final transactionRows = await (_database.select(
      _database.transactionRecords,
    )..where((row) => row.salaryCycleId.equals(cycle.id))).get();
    final summary = SalarySummary.fromTransactions(
      salaryCents: cycle.salaryCents,
      carryoverCents: cycle.carryoverCents,
      transactions: transactionRows.map((row) => row.toDomain()),
    );
    final updatedRows =
        await (_database.update(_database.salaryCycleRecords)..where(
              (row) =>
                  row.id.equals(cycle.id) &
                  row.status.equals(SalaryCycleStatus.closed.name) &
                  row.deletedAt.isNull(),
            ))
            .write(
              SalaryCycleRecordsCompanion(
                finalRemainingCents: Value(summary.remainingCents),
                updatedAt: Value(timestamp),
              ),
            );
    if (updatedRows != 1) {
      throw StateError('历史周期状态已变化，本次修正已取消。');
    }
  }

  void _ensureDateInCycle(LocalDate date, SalaryCycleRecord cycle) {
    final start = LocalDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(cycle.startedAt),
    );
    final end = LocalDate.parse(cycle.expectedPayDate);
    if (date.compareTo(start) < 0 || date.compareTo(end) >= 0) {
      throw ArgumentError.value(date, 'occurredOn', '历史流水日期必须位于所选工资周期内。');
    }
  }
}
