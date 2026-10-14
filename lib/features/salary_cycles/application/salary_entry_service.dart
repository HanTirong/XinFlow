import 'package:drift/drift.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';

final class SalaryEntryService {
  const SalaryEntryService(this.database, this.clock);

  final AppDatabase database;
  final Clock clock;

  Future<List<SalaryCycle>> pendingCycles() async {
    final rows =
        await (database.select(database.salaryCycleRecords)
              ..where(
                (row) =>
                    row.salaryPending.equals(true) & row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
            .get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  Future<int> availableCarryover(String cycleId) async {
    final cycle =
        await (database.select(database.salaryCycleRecords)
              ..where((row) => row.id.equals(cycleId) & row.deletedAt.isNull()))
            .getSingleOrNull();
    if (cycle == null || cycle.status != 'active') return 0;
    final start = LocalDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(cycle.startedAt),
    );
    final previous =
        await (database.select(database.salaryCycleRecords)
              ..where(
                (row) =>
                    row.status.equals('closed') &
                    row.expectedPayDate.equals(start.toString()) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    final remaining = previous?.finalRemainingCents ?? 0;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> saveAmount({
    required String cycleId,
    required int salaryCents,
    bool carryPositiveRemaining = false,
  }) => database.transaction(() async {
    if (salaryCents < 0) throw ArgumentError.value(salaryCents, 'salaryCents');
    final row =
        await (database.select(database.salaryCycleRecords)..where(
              (item) => item.id.equals(cycleId) & item.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null || (row.status == 'closed' && !row.salaryPending)) {
      throw StateError('该工资周期不能修改工资金额。');
    }
    final stamp = clock.now().toUtc().millisecondsSinceEpoch;
    var carryover = row.carryoverCents;
    if (row.status == 'active') {
      carryover = carryPositiveRemaining
          ? await availableCarryover(cycleId)
          : 0;
    }
    if (row.status == 'closed') {
      final entries =
          await (database.select(database.transactionRecords)..where(
                (item) =>
                    item.salaryCycleId.equals(cycleId) &
                    item.deletedAt.isNull(),
              ))
              .get();
      final summary = SalarySummary.fromTransactions(
        salaryCents: salaryCents,
        carryoverCents: carryover,
        transactions: entries.map((entry) => entry.toDomain()),
      );
      await (database.update(database.salaryCycleRecords)..where(
            (item) => item.id.equals(cycleId) & item.status.equals('closed'),
          ))
          .write(
            SalaryCycleRecordsCompanion(
              salaryCents: Value(salaryCents),
              salaryPending: const Value(false),
              carryoverCents: Value(carryover),
              finalRemainingCents: Value(summary.remainingCents),
              updatedAt: Value(stamp),
            ),
          );
    } else {
      await (database.update(database.salaryCycleRecords)..where(
            (item) => item.id.equals(cycleId) & item.status.equals('active'),
          ))
          .write(
            SalaryCycleRecordsCompanion(
              salaryCents: Value(salaryCents),
              salaryPending: const Value(false),
              carryoverCents: Value(carryover),
              updatedAt: Value(stamp),
            ),
          );
    }
  });
}
