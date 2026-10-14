import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/onboarding/application/complete_onboarding.dart';
import 'package:xinflow/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:xinflow/features/salary_cycles/application/auto_settle_due_cycles.dart';
import 'package:xinflow/features/salary_cycles/application/salary_entry_service.dart';
import 'package:xinflow/features/salary_cycles/data/drift_salary_cycle_repository.dart';

void main() {
  test(
    'repairs a stretched cycle without losing allocations or linked refunds',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final clock = _MutableClock(DateTime(2026, 9, 19, 9));
      await CompleteOnboarding(
        repository: DriftOnboardingRepository(database),
        clock: clock,
        idGenerator: _Ids(),
      ).execute(salaryDay: 10, salaryCents: 850000);
      final original = (await DriftSalaryCycleRepository(
        database,
      ).getActiveCycle())!;
      await database
          .update(database.salaryCycleRecords)
          .write(
            const SalaryCycleRecordsCompanion(
              expectedPayDate: Value('2026-11-10'),
            ),
          );
      Future<void> addEntry(
        String id,
        String day,
        int cents, {
        String? reverses,
      }) => database
          .into(database.transactionRecords)
          .insert(
            TransactionRecordsCompanion.insert(
              id: id,
              salaryCycleId: original.id,
              entryKind: reverses == null ? 'allocation' : 'refund',
              flowType: 'expense',
              amountCents: cents,
              categoryId: DefaultCategoryIds.food,
              reversesTransactionId: Value(reverses),
              occurredAt: DateTime.parse(day).millisecondsSinceEpoch,
              occurredOn: day,
              createdAt: 1,
              updatedAt: 1,
            ),
          )
          .then((_) {});
      await addEntry('september', '2026-09-20', 100);
      await addEntry('october', '2026-10-12', 200);
      await addEntry('refund', '2026-10-13', 50, reverses: 'october');

      await database.transaction(
        () => database.repairTenthDayCycles(now: DateTime(2026, 10, 14)),
      );
      final cycles = await database.select(database.salaryCycleRecords).get();
      expect(cycles, hasLength(2));
      final old = cycles.singleWhere((cycle) => cycle.id == original.id);
      final active = cycles.singleWhere((cycle) => cycle.status == 'active');
      expect(old.expectedPayDate, '2026-10-10');
      expect(old.finalRemainingCents, 849900);
      expect(
        LocalDate.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(active.startedAt),
        ),
        const LocalDate(2026, 10, 10),
      );
      expect(active.expectedPayDate, '2026-11-10');
      expect(active.salaryPending, isTrue);
      final entries = await database.select(database.transactionRecords).get();
      expect(
        entries.singleWhere((row) => row.id == 'september').salaryCycleId,
        original.id,
      );
      expect(
        entries.singleWhere((row) => row.id == 'october').salaryCycleId,
        active.id,
      );
      expect(
        entries.singleWhere((row) => row.id == 'refund').salaryCycleId,
        active.id,
      );

      await database.transaction(
        () => database.repairTenthDayCycles(now: DateTime(2026, 10, 14)),
      );
      expect(
        await database.select(database.salaryCycleRecords).get(),
        hasLength(2),
      );
    },
  );

  test('settles once on the tenth and waits for the actual salary', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final clock = _MutableClock(DateTime(2026, 9, 19, 9));
    final ids = _Ids();
    await CompleteOnboarding(
      repository: DriftOnboardingRepository(database),
      clock: clock,
      idGenerator: ids,
    ).execute(salaryDay: 10, salaryCents: 850000);

    clock.value = DateTime(2026, 10, 10, 9);
    final settle = AutoSettleDueCycles(
      database: database,
      clock: clock,
      idGenerator: ids,
    );
    expect(await settle.execute(), 1);
    expect(await settle.execute(), 0);

    final repository = DriftSalaryCycleRepository(database);
    final active = (await repository.getActiveCycle())!;
    final closed = (await repository.listClosedCycles()).single;
    expect(
      LocalDate.fromDateTime(active.startedAt),
      const LocalDate(2026, 10, 10),
    );
    expect(active.expectedPayDate, const LocalDate(2026, 11, 10));
    expect(active.salaryPending, isTrue);
    expect(active.salaryCents, 0);
    expect(closed.finalRemainingCents, 850000);
    expect(active.carryoverCents, 0);

    final salary = SalaryEntryService(database, clock);
    expect(await salary.availableCarryover(active.id), 850000);
    await salary.saveAmount(cycleId: active.id, salaryCents: 900000);
    final saved = (await repository.getActiveCycle())!;
    expect(saved.salaryPending, isFalse);
    expect(saved.salaryCents, 900000);
    expect(saved.carryoverCents, 0);
  });

  test('creates every missed month and keeps salaries pending', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final clock = _MutableClock(DateTime(2026, 9, 19, 9));
    final ids = _Ids();
    await CompleteOnboarding(
      repository: DriftOnboardingRepository(database),
      clock: clock,
      idGenerator: ids,
    ).execute(salaryDay: 10, salaryCents: 850000);

    clock.value = DateTime(2026, 12, 11, 9);
    final settle = AutoSettleDueCycles(
      database: database,
      clock: clock,
      idGenerator: ids,
    );
    expect(await settle.execute(), 3);
    expect(await settle.execute(), 0);
    final pending = await SalaryEntryService(database, clock).pendingCycles();
    expect(pending, hasLength(3));
    expect(pending.first.expectedPayDate, const LocalDate(2027, 1, 10));
    expect(
      await database.select(database.salaryCycleRecords).get(),
      hasLength(4),
    );
  });
}

final class _MutableClock implements Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

final class _Ids implements IdGenerator {
  var _next = 0;

  @override
  String next() => 'cycle-${_next++}';
}
