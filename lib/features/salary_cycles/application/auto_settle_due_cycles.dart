import 'package:drift/drift.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/date/payday_calculator.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';

/// Catches up at the first opportunity after a local calendar boundary.
final class AutoSettleDueCycles {
  const AutoSettleDueCycles({
    required this.database,
    required this.clock,
    required this.idGenerator,
  });

  final AppDatabase database;
  final Clock clock;
  final IdGenerator idGenerator;

  Future<int> execute() => database.transaction(() async {
    final settings = await database
        .select(database.appSettingRecords)
        .getSingleOrNull();
    if (settings == null || !settings.onboardingCompleted) return 0;

    final initialActive =
        await (database.select(database.salaryCycleRecords)..where(
              (row) => row.status.equals('active') & row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (initialActive == null) throw StateError('没有活动工资周期，自动结算已停止。');
    SalaryCycleRecord active = initialActive;

    final now = clock.now();
    final today = LocalDate.fromDateTime(now);
    final currentStart = PaydayCalculator.cycleStartOnOrBefore(
      today: today,
      salaryDay: 10,
    );
    final initialStart = LocalDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(active.startedAt),
    );
    // Backups can restore an older schema's stretched active period.
    if (settings.salaryDay != 10 ||
        LocalDate.parse(active.expectedPayDate).day != 10 ||
        (initialStart.compareTo(currentStart) < 0 &&
            LocalDate.parse(active.expectedPayDate).compareTo(currentStart) >
                0)) {
      await database.adoptTenthDayCycles(now: now);
      final adjustedActive =
          await (database.select(database.salaryCycleRecords)..where(
                (row) => row.status.equals('active') & row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (adjustedActive == null) throw StateError('工资周期调整失败。');
      active = adjustedActive;
    }

    final activeStart = LocalDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(active.startedAt),
    );
    if (activeStart.compareTo(today) > 0) return 0;

    final stamp = now.toUtc().millisecondsSinceEpoch;
    var count = 0;
    while (LocalDate.parse(active.expectedPayDate).compareTo(today) <= 0) {
      if (count >= 120) throw StateError('手机日期与工资周期相差过大，请检查系统日期。');
      final end = LocalDate.parse(active.expectedPayDate);
      final rows =
          await (database.select(database.transactionRecords)..where(
                (row) =>
                    row.salaryCycleId.equals(active.id) &
                    row.deletedAt.isNull(),
              ))
              .get();
      if (rows.any(
        (row) =>
            row.entryKind == 'allocation' &&
            LocalDate.parse(row.occurredOn).compareTo(end) >= 0,
      )) {
        throw StateError('旧周期含有切换日之后的账单，请先核对这些记录。');
      }
      final summary = SalarySummary.fromTransactions(
        salaryCents: active.salaryCents,
        carryoverCents: active.carryoverCents,
        transactions: rows.map((row) => row.toDomain()),
      );
      final closed =
          await (database.update(database.salaryCycleRecords)..where(
                (row) => row.id.equals(active.id) & row.status.equals('active'),
              ))
              .write(
                SalaryCycleRecordsCompanion(
                  status: const Value('closed'),
                  closedAt: Value(stamp),
                  finalRemainingCents: Value(summary.remainingCents),
                  updatedAt: Value(stamp),
                ),
              );
      if (closed != 1) throw StateError('活动工资周期已变化，自动结算已回滚。');

      final nextEnd = PaydayCalculator.forNextCycle(
        confirmedDate: end,
        salaryDay: 10,
      );
      final startAt = DateTime(
        end.year,
        end.month,
        end.day,
      ).toUtc().millisecondsSinceEpoch;
      final id = idGenerator.next();
      await database
          .into(database.salaryCycleRecords)
          .insert(
            SalaryCycleRecordsCompanion.insert(
              id: id,
              salaryCents: 0,
              salaryPending: const Value(true),
              startedAt: startAt,
              expectedPayDate: nextEnd.toString(),
              status: 'active',
              createdAt: stamp,
              updatedAt: stamp,
            ),
          );
      active = await (database.select(
        database.salaryCycleRecords,
      )..where((row) => row.id.equals(id))).getSingle();
      count++;
    }
    return count;
  });
}
