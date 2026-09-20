import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/categories/data/drift_category_repository.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/onboarding/application/complete_onboarding.dart';
import 'package:xinflow/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:xinflow/features/salary_cycles/application/close_and_start_next_cycle.dart';
import 'package:xinflow/features/salary_cycles/data/drift_salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/data/drift_settings_repository.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/transactions/application/create_allocation.dart';
import 'package:xinflow/features/transactions/application/create_refund.dart';
import 'package:xinflow/features/transactions/application/delete_allocation.dart';
import 'package:xinflow/features/transactions/application/update_allocation.dart';
import 'package:xinflow/features/transactions/data/drift_transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';

void main() {
  late AppDatabase database;
  late DriftOnboardingRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftOnboardingRepository(database);
  });

  tearDown(() => database.close());

  test('seeds stable default categories on first open', () async {
    final rows = await database.select(database.categoryRecords).get();

    expect(rows, hasLength(DefaultCategories.values.length));
    expect(
      rows.map((row) => row.id),
      containsAll(DefaultCategories.values.map((category) => category.id)),
    );
  });

  test(
    'version 2 migration aligns an existing cycle to fixed payday',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting,
      );
      final directory = await Directory.systemTemp.createTemp(
        'xinflow_migration_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/xinflow.sqlite');
      final oldDatabase = AppDatabase.forTesting(NativeDatabase(file));
      await CompleteOnboarding(
        repository: DriftOnboardingRepository(oldDatabase),
        clock: _FixedClock(DateTime(2026, 9, 19, 9, 30)),
        idGenerator: const _FixedIdGenerator('cycle-old'),
      ).execute(salaryDay: 10, salaryCents: 1300000);
      await oldDatabase
          .update(oldDatabase.salaryCycleRecords)
          .write(
            SalaryCycleRecordsCompanion(
              startedAt: Value(DateTime(2026, 9, 19).millisecondsSinceEpoch),
              expectedPayDate: const Value('2026-10-19'),
            ),
          );
      await oldDatabase.customStatement('PRAGMA user_version = 1');
      await oldDatabase.close();

      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);
      final bootstrap = await DriftOnboardingRepository(
        upgraded,
      ).loadBootstrap();

      expect(
        LocalDate.fromDateTime(bootstrap.activeCycle!.startedAt),
        const LocalDate(2026, 9, 10),
      );
      expect(
        bootstrap.activeCycle!.expectedPayDate,
        const LocalDate(2026, 10, 10),
      );
      expect(
        await upgraded.select(upgraded.salaryCycleRecords).get(),
        hasLength(1),
      );
    },
  );

  test(
    'completes onboarding atomically and persists one active cycle',
    () async {
      final useCase = CompleteOnboarding(
        repository: repository,
        clock: _FixedClock(DateTime.utc(2026, 9, 19, 9, 30)),
        idGenerator: const _FixedIdGenerator('cycle-initial'),
      );

      await useCase.execute(salaryDay: 15, salaryCents: 850000);

      final bootstrap = await repository.loadBootstrap();
      expect(bootstrap.isReady, isTrue);
      expect(bootstrap.settings!.salaryDay, 15);
      expect(bootstrap.activeCycle!.id, 'cycle-initial');
      expect(bootstrap.activeCycle!.salaryCents, 850000);
      expect(bootstrap.activeCycle!.status, SalaryCycleStatus.active);
      expect(
        LocalDate.fromDateTime(bootstrap.activeCycle!.startedAt),
        const LocalDate(2026, 9, 15),
      );
      expect(bootstrap.activeCycle!.expectedPayDate.toString(), '2026-10-15');

      expect(
        await database.select(database.appSettingRecords).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.salaryCycleRecords).get(),
        hasLength(1),
      );
    },
  );

  test('rejects repeated onboarding without partially writing', () async {
    final useCase = CompleteOnboarding(
      repository: repository,
      clock: _FixedClock(DateTime.utc(2026, 9, 19, 9, 30)),
      idGenerator: const _FixedIdGenerator('cycle-initial'),
    );
    await useCase.execute(salaryDay: 15, salaryCents: 850000);

    await expectLater(
      useCase.execute(salaryDay: 20, salaryCents: 900000),
      throwsStateError,
    );

    expect(
      await database.select(database.appSettingRecords).get(),
      hasLength(1),
    );
    expect(
      await database.select(database.salaryCycleRecords).get(),
      hasLength(1),
    );
  });

  test('persists theme changes without altering salary settings', () async {
    final onboarding = CompleteOnboarding(
      repository: repository,
      clock: _FixedClock(DateTime.utc(2026, 9, 19, 9, 30)),
      idGenerator: const _FixedIdGenerator('cycle-initial'),
    );
    await onboarding.execute(salaryDay: 10, salaryCents: 1300000);

    final settings = DriftSettingsRepository(database);
    await settings.updateThemePreference(AppThemePreference.dark);

    final row = await database.select(database.appSettingRecords).getSingle();
    expect(row.themeMode, AppThemePreference.dark.name);
    expect(row.salaryDay, 10);
    expect(
      (await repository.loadBootstrap()).activeCycle!.salaryCents,
      1300000,
    );
  });

  test('updates salary day and manages a custom category', () async {
    final clock = _FixedClock(DateTime.utc(2026, 9, 19, 9, 30));
    await CompleteOnboarding(
      repository: repository,
      clock: clock,
      idGenerator: const _FixedIdGenerator('cycle-initial'),
    ).execute(salaryDay: 10, salaryCents: 1300000);

    final settings = DriftSettingsRepository(database, clock: clock);
    await settings.updateSalaryDay(28);
    expect((await settings.load()).salaryDay, 28);
    final realigned = await repository.loadBootstrap();
    expect(
      LocalDate.fromDateTime(realigned.activeCycle!.startedAt),
      const LocalDate(2026, 8, 28),
    );
    expect(
      realigned.activeCycle!.expectedPayDate,
      const LocalDate(2026, 9, 28),
    );

    final categories = DriftCategoryRepository(database);
    await categories.add(
      Category(
        id: 'custom.learning',
        name: '学习',
        flowType: FlowType.expense,
        iconKey: 'category',
        sortOrder: 100,
        isSystem: false,
      ),
    );
    await categories.updateNameAndState(
      id: 'custom.learning',
      name: '自我提升',
      isActive: false,
    );

    final custom = (await categories.listAll()).singleWhere(
      (category) => category.id == 'custom.learning',
    );
    expect(custom.name, '自我提升');
    expect(custom.isActive, isFalse);
    expect(await categories.getById('custom.learning'), isNull);
  });

  test('database prevents a second active salary cycle', () async {
    final timestamp = DateTime.utc(2026, 9, 19).millisecondsSinceEpoch;
    await database
        .into(database.salaryCycleRecords)
        .insert(
          SalaryCycleRecordsCompanion.insert(
            id: 'cycle-1',
            salaryCents: 100000,
            startedAt: timestamp,
            expectedPayDate: '2026-10-15',
            status: SalaryCycleStatus.active.name,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        );

    await expectLater(
      database
          .into(database.salaryCycleRecords)
          .insert(
            SalaryCycleRecordsCompanion.insert(
              id: 'cycle-2',
              salaryCents: 200000,
              startedAt: timestamp,
              expectedPayDate: '2026-10-15',
              status: SalaryCycleStatus.active.name,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('database rejects invalid persisted amounts', () async {
    final timestamp = DateTime.utc(2026, 9, 19).millisecondsSinceEpoch;

    await expectLater(
      database
          .into(database.salaryCycleRecords)
          .insert(
            SalaryCycleRecordsCompanion.insert(
              id: 'invalid-cycle',
              salaryCents: -1,
              startedAt: timestamp,
              expectedPayDate: '2026-10-15',
              status: SalaryCycleStatus.active.name,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'creates an allocation in the active cycle from a valid category',
    () async {
      final fixedClock = _FixedClock(DateTime.utc(2026, 9, 20, 8, 30));
      await CompleteOnboarding(
        repository: repository,
        clock: fixedClock,
        idGenerator: const _FixedIdGenerator('cycle-initial'),
      ).execute(salaryDay: 10, salaryCents: 1300000);

      final createAllocation = CreateAllocation(
        categories: DriftCategoryRepository(database),
        salaryCycles: DriftSalaryCycleRepository(database),
        transactions: DriftTransactionRepository(database, clock: fixedClock),
        clock: fixedClock,
        idGenerator: const _FixedIdGenerator('transaction-1'),
      );
      final entry = await createAllocation.execute(
        amountCents: 2860,
        categoryId: DefaultCategoryIds.food,
        subcategoryId: 'builtin.food.1',
        occurredOn: const LocalDate(2026, 9, 18),
        note: '午餐',
      );

      expect(entry.salaryCycleId, 'cycle-initial');
      expect(entry.flowType, FlowType.expense);
      expect(entry.occurredOn, const LocalDate(2026, 9, 18));
      final rows = await database.select(database.transactionRecords).get();
      expect(rows, hasLength(1));
      expect(rows.single.amountCents, 2860);
      expect(rows.single.note, '午餐');
    },
  );

  test('rejects a subcategory that belongs to another parent', () async {
    final fixedClock = _FixedClock(DateTime.utc(2026, 9, 20, 8, 30));
    await CompleteOnboarding(
      repository: repository,
      clock: fixedClock,
      idGenerator: const _FixedIdGenerator('cycle-initial'),
    ).execute(salaryDay: 10, salaryCents: 1300000);

    final createAllocation = CreateAllocation(
      categories: DriftCategoryRepository(database),
      salaryCycles: DriftSalaryCycleRepository(database),
      transactions: DriftTransactionRepository(database, clock: fixedClock),
      clock: fixedClock,
      idGenerator: const _FixedIdGenerator('transaction-1'),
    );

    await expectLater(
      createAllocation.execute(
        amountCents: 2860,
        categoryId: DefaultCategoryIds.food,
        subcategoryId: 'builtin.shopping.1',
      ),
      throwsArgumentError,
    );
    expect(await database.select(database.transactionRecords).get(), isEmpty);
  });

  test('updates and soft-deletes a current-cycle allocation', () async {
    final fixedClock = _FixedClock(DateTime.utc(2026, 9, 20, 8, 30));
    await CompleteOnboarding(
      repository: repository,
      clock: fixedClock,
      idGenerator: const _FixedIdGenerator('cycle-initial'),
    ).execute(salaryDay: 10, salaryCents: 1300000);

    final categories = DriftCategoryRepository(database);
    final salaryCycles = DriftSalaryCycleRepository(database);
    final transactions = DriftTransactionRepository(
      database,
      clock: fixedClock,
    );
    await CreateAllocation(
      categories: categories,
      salaryCycles: salaryCycles,
      transactions: transactions,
      clock: fixedClock,
      idGenerator: const _FixedIdGenerator('transaction-1'),
    ).execute(amountCents: 6600, categoryId: DefaultCategoryIds.food);

    final updated =
        await UpdateAllocation(
          categories: categories,
          salaryCycles: salaryCycles,
          transactions: transactions,
        ).execute(
          transactionId: 'transaction-1',
          amountCents: 8800,
          categoryId: DefaultCategoryIds.shopping,
          subcategoryId: 'builtin.shopping.1',
          occurredOn: const LocalDate(2026, 9, 18),
          note: '生活用品',
        );
    expect(updated.amountCents, 8800);
    expect(updated.categoryId, DefaultCategoryIds.shopping);
    expect((await transactions.getById('transaction-1'))!.note, '生活用品');

    await transactions.add(
      TransactionEntry(
        id: 'refund-1',
        salaryCycleId: 'cycle-initial',
        entryKind: EntryKind.refund,
        flowType: FlowType.expense,
        amountCents: 2000,
        categoryId: DefaultCategoryIds.shopping,
        subcategoryId: 'builtin.shopping.1',
        reversesTransactionId: 'transaction-1',
        occurredAt: fixedClock.now(),
        occurredOn: const LocalDate(2026, 9, 20),
      ),
    );

    await DeleteAllocation(
      salaryCycles: salaryCycles,
      transactions: transactions,
      clock: fixedClock,
    ).execute('transaction-1');

    final rows = await transactions.listCycleTransactions('cycle-initial');
    expect(rows, hasLength(2));
    expect(
      rows,
      everyElement(predicate<TransactionEntry>((row) => row.isDeleted)),
    );
  });

  test('creates a partial refund and enforces the remaining limit', () async {
    final fixedClock = _FixedClock(DateTime.utc(2026, 9, 20, 8, 30));
    await CompleteOnboarding(
      repository: repository,
      clock: fixedClock,
      idGenerator: const _FixedIdGenerator('cycle-initial'),
    ).execute(salaryDay: 10, salaryCents: 1300000);
    final salaryCycles = DriftSalaryCycleRepository(database);
    final transactions = DriftTransactionRepository(
      database,
      clock: fixedClock,
    );
    await CreateAllocation(
      categories: DriftCategoryRepository(database),
      salaryCycles: salaryCycles,
      transactions: transactions,
      clock: fixedClock,
      idGenerator: const _FixedIdGenerator('transaction-1'),
    ).execute(amountCents: 6600, categoryId: DefaultCategoryIds.food);

    final refunds = CreateRefund(
      salaryCycles: salaryCycles,
      transactions: transactions,
      clock: fixedClock,
      idGenerator: const _FixedIdGenerator('refund-1'),
    );
    await refunds.execute(
      transactionId: 'transaction-1',
      amountCents: 2000,
      note: '部分退款',
    );

    expect(await refunds.refundableCents('transaction-1'), 4600);
    await expectLater(
      refunds.execute(transactionId: 'transaction-1', amountCents: 4601),
      throwsA(isA<TransactionRuleViolation>()),
    );
    expect(await transactions.listRefundsFor('transaction-1'), hasLength(1));
  });

  test(
    'replaces the active salary cycle in one database transaction',
    () async {
      final onboarding = CompleteOnboarding(
        repository: repository,
        clock: _FixedClock(DateTime.utc(2026, 9, 19, 9, 30)),
        idGenerator: const _FixedIdGenerator('cycle-initial'),
      );
      await onboarding.execute(salaryDay: 15, salaryCents: 850000);

      final salaryCycles = DriftSalaryCycleRepository(database);
      final transition = await CloseAndStartNextCycle(
        salaryCycles: salaryCycles,
        transactions: DriftTransactionRepository(database),
        clock: _FixedClock(DateTime.utc(2026, 10, 14, 9, 30)),
        idGenerator: const _FixedIdGenerator('cycle-next'),
      ).execute(newSalaryCents: 900000, salaryDay: 15);

      expect(transition.closedCycle.finalRemainingCents, 850000);
      expect((await salaryCycles.getActiveCycle())!.id, 'cycle-next');
      final closedCycles = await salaryCycles.listClosedCycles();
      expect(closedCycles, hasLength(1));
      expect(closedCycles.single.id, 'cycle-initial');

      final rows = await database.select(database.salaryCycleRecords).get();
      expect(
        rows.where((row) => row.status == SalaryCycleStatus.active.name),
        hasLength(1),
      );
      expect(
        rows.where((row) => row.status == SalaryCycleStatus.closed.name),
        hasLength(1),
      );
    },
  );
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
