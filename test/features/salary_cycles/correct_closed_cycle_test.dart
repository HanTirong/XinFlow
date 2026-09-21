import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/categories/data/drift_category_repository.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/onboarding/application/complete_onboarding.dart';
import 'package:xinflow/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:xinflow/features/salary_cycles/application/close_and_start_next_cycle.dart';
import 'package:xinflow/features/salary_cycles/application/correct_closed_cycle.dart';
import 'package:xinflow/features/salary_cycles/data/drift_closed_cycle_correction_repository.dart';
import 'package:xinflow/features/salary_cycles/data/drift_salary_cycle_repository.dart';
import 'package:xinflow/features/transactions/application/create_allocation.dart';
import 'package:xinflow/features/transactions/data/drift_transaction_repository.dart';

void main() {
  late AppDatabase database;
  late _FixedClock clock;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    clock = _FixedClock(DateTime.utc(2026, 10, 10, 12));
  });

  tearDown(() => database.close());

  test(
    'historical corrections atomically refresh the closed balance only',
    () async {
      final salaryCycles = DriftSalaryCycleRepository(database);
      final transactions = DriftTransactionRepository(database, clock: clock);
      final categories = DriftCategoryRepository(database);
      await CompleteOnboarding(
        repository: DriftOnboardingRepository(database),
        clock: _FixedClock(DateTime.utc(2026, 9, 10, 9)),
        idGenerator: const _FixedIdGenerator('cycle-closed'),
      ).execute(salaryDay: 10, salaryCents: 100000);
      await CreateAllocation(
        categories: categories,
        salaryCycles: salaryCycles,
        transactions: transactions,
        clock: clock,
        idGenerator: const _FixedIdGenerator('expense-1'),
      ).execute(
        amountCents: 10000,
        categoryId: DefaultCategoryIds.food,
        occurredOn: const LocalDate(2026, 9, 20),
      );
      await CloseAndStartNextCycle(
        salaryCycles: salaryCycles,
        transactions: transactions,
        clock: clock,
        idGenerator: const _FixedIdGenerator('cycle-active'),
      ).execute(newSalaryCents: 120000, salaryDay: 10);

      final correction = CorrectClosedCycle(
        categories: categories,
        repository: DriftClosedCycleCorrectionRepository(
          database,
          clock: clock,
        ),
        clock: clock,
        idGenerator: _SequenceIdGenerator(['saving-1', 'refund-1']),
      );
      await correction.createAllocation(
        cycleId: 'cycle-closed',
        amountCents: 20000,
        categoryId: DefaultCategoryIds.saving,
        occurredOn: const LocalDate(2026, 9, 25),
      );
      expect(await _closedRemaining(database), 70000);

      await correction.updateAllocation(
        transactionId: 'expense-1',
        amountCents: 15000,
        categoryId: DefaultCategoryIds.food,
        occurredOn: const LocalDate(2026, 9, 20),
      );
      expect(await _closedRemaining(database), 65000);

      await correction.createRefund(
        transactionId: 'expense-1',
        amountCents: 5000,
        occurredOn: const LocalDate(2026, 9, 28),
      );
      expect(await _closedRemaining(database), 70000);

      await correction.deleteAllocation('expense-1');
      expect(await _closedRemaining(database), 80000);
      expect((await salaryCycles.getActiveCycle())!.id, 'cycle-active');
      final deletedEntries = (await transactions.listCycleTransactions(
        'cycle-closed',
      )).where((entry) => entry.id == 'expense-1' || entry.id == 'refund-1');
      expect(deletedEntries.every((entry) => entry.isDeleted), isTrue);
    },
  );

  test('rejects correction attempts against the active cycle', () async {
    await CompleteOnboarding(
      repository: DriftOnboardingRepository(database),
      clock: clock,
      idGenerator: const _FixedIdGenerator('cycle-active'),
    ).execute(salaryDay: 10, salaryCents: 100000);
    final correction = CorrectClosedCycle(
      categories: DriftCategoryRepository(database),
      repository: DriftClosedCycleCorrectionRepository(database, clock: clock),
      clock: clock,
      idGenerator: const _FixedIdGenerator('should-not-exist'),
    );

    await expectLater(
      correction.createAllocation(
        cycleId: 'cycle-active',
        amountCents: 1000,
        categoryId: DefaultCategoryIds.food,
        occurredOn: const LocalDate(2026, 10, 10),
      ),
      throwsStateError,
    );
    expect(await database.select(database.transactionRecords).get(), isEmpty);
  });
}

Future<int?> _closedRemaining(AppDatabase database) async {
  final row = await (database.select(
    database.salaryCycleRecords,
  )..where((row) => row.id.equals('cycle-closed'))).getSingle();
  return row.finalRemainingCents;
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator(this.value);

  final String value;

  @override
  String next() => value;
}

final class _SequenceIdGenerator implements IdGenerator {
  _SequenceIdGenerator(this.values);

  final List<String> values;
  var _index = 0;

  @override
  String next() => values[_index++];
}
