import 'package:drift/drift.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';

final class DriftSalaryCycleRepository implements SalaryCycleRepository {
  const DriftSalaryCycleRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<SalaryCycle?> watchActiveCycle() =>
      (_database.select(_database.salaryCycleRecords)..where(
            (row) =>
                row.status.equals(SalaryCycleStatus.active.name) &
                row.deletedAt.isNull(),
          ))
          .watchSingleOrNull()
          .map((row) => row?.toDomain());

  @override
  Future<SalaryCycle?> getActiveCycle() async {
    final row =
        await (_database.select(_database.salaryCycleRecords)..where(
              (row) =>
                  row.status.equals(SalaryCycleStatus.active.name) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<SalaryCycle>> listClosedCycles() async {
    final rows =
        await (_database.select(_database.salaryCycleRecords)
              ..where(
                (row) =>
                    row.status.equals(SalaryCycleStatus.closed.name) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
            .get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> replaceActiveCycle({
    required SalaryCycle closedCycle,
    required SalaryCycle newActiveCycle,
  }) => _database.transaction(() async {
    if (closedCycle.status != SalaryCycleStatus.closed ||
        newActiveCycle.status != SalaryCycleStatus.active) {
      throw ArgumentError('周期切换必须同时写入一个封存周期和一个活动周期。');
    }

    final updatedAt = closedCycle.closedAt!.toUtc().millisecondsSinceEpoch;
    final updatedRows =
        await (_database.update(_database.salaryCycleRecords)..where(
              (row) =>
                  row.id.equals(closedCycle.id) &
                  row.status.equals(SalaryCycleStatus.active.name) &
                  row.deletedAt.isNull(),
            ))
            .write(
              SalaryCycleRecordsCompanion(
                status: Value(closedCycle.status.name),
                closedAt: Value(updatedAt),
                finalRemainingCents: Value(closedCycle.finalRemainingCents),
                updatedAt: Value(updatedAt),
              ),
            );
    if (updatedRows != 1) {
      throw StateError('活动工资周期已发生变化，周期切换已取消。');
    }

    final createdAt = newActiveCycle.startedAt.toUtc().millisecondsSinceEpoch;
    await _database
        .into(_database.salaryCycleRecords)
        .insert(
          SalaryCycleRecordsCompanion.insert(
            id: newActiveCycle.id,
            salaryCents: newActiveCycle.salaryCents,
            carryoverCents: Value(newActiveCycle.carryoverCents),
            startedAt: createdAt,
            expectedPayDate: newActiveCycle.expectedPayDate.toString(),
            status: newActiveCycle.status.name,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
  });
}
