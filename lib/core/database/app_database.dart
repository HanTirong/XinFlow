import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/date/payday_calculator.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';

part 'app_database.g.dart';

typedef CycleUndoPreviewRecord = ({
  SalaryCycleRecord active,
  SalaryCycleRecord previous,
  int transactionCount,
  int budgetCount,
});

class SalaryCycleRecords extends Table {
  @override
  String get tableName => 'salary_cycles';

  TextColumn get id => text()();
  IntColumn get salaryCents =>
      integer().customConstraint('NOT NULL CHECK (salary_cents >= 0)')();
  BoolColumn get salaryPending =>
      boolean().withDefault(const Constant(false))();
  IntColumn get carryoverCents => integer().customConstraint(
    'NOT NULL DEFAULT 0 CHECK (carryover_cents >= 0)',
  )();
  IntColumn get startedAt => integer()();
  TextColumn get expectedPayDate => text()();
  IntColumn get closedAt => integer().nullable()();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('active', 'closed'))",
  )();
  IntColumn get finalRemainingCents => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK ((status = 'active' AND closed_at IS NULL "
        'AND final_remaining_cents IS NULL) OR '
        "(status = 'closed' AND closed_at IS NOT NULL "
        'AND final_remaining_cents IS NOT NULL))',
  ];
}

class CategoryRecords extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get parentId =>
      text().nullable().references(CategoryRecords, #id)();
  TextColumn get name => text()();
  TextColumn get flowType => text().customConstraint(
    "NOT NULL CHECK (flow_type IN ('expense', 'saving', 'investment'))",
  )();
  TextColumn get iconKey => text()();
  TextColumn get colorKey => text().withDefault(const Constant('neutral'))();
  IntColumn get sortOrder => integer()();
  BoolColumn get showOnHome => boolean().withDefault(const Constant(false))();
  BoolColumn get isSystem => boolean()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TransactionRecords extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get salaryCycleId => text().references(SalaryCycleRecords, #id)();
  TextColumn get entryKind => text().customConstraint(
    "NOT NULL CHECK (entry_kind IN ('allocation', 'refund', 'withdrawal'))",
  )();
  TextColumn get flowType => text().customConstraint(
    "NOT NULL CHECK (flow_type IN ('expense', 'saving', 'investment'))",
  )();
  IntColumn get amountCents =>
      integer().customConstraint('NOT NULL CHECK (amount_cents > 0)')();
  @ReferenceName('categoryTransactions')
  TextColumn get categoryId => text().references(CategoryRecords, #id)();
  @ReferenceName('subcategoryTransactions')
  TextColumn get subcategoryId =>
      text().nullable().references(CategoryRecords, #id)();
  TextColumn get reversesTransactionId =>
      text().nullable().references(TransactionRecords, #id)();
  IntColumn get occurredAt => integer()();
  TextColumn get occurredOn => text()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK ((entry_kind = 'allocation' AND reverses_transaction_id IS NULL) "
        "OR (entry_kind = 'refund' AND flow_type = 'expense' "
        'AND reverses_transaction_id IS NOT NULL) '
        "OR (entry_kind = 'withdrawal' "
        "AND flow_type IN ('saving', 'investment') "
        'AND reverses_transaction_id IS NOT NULL))',
  ];
}

class AppSettingRecords extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get singletonId =>
      integer().customConstraint('NOT NULL CHECK (singleton_id = 1)')();
  IntColumn get salaryDay => integer().customConstraint(
    'NOT NULL CHECK (salary_day BETWEEN 1 AND 31)',
  )();
  TextColumn get currencyCode => text().customConstraint(
    "NOT NULL DEFAULT 'CNY' CHECK (currency_code = 'CNY')",
  )();
  BoolColumn get onboardingCompleted => boolean()();
  TextColumn get themeMode => text().customConstraint(
    "NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('system', 'light', 'dark'))",
  )();
  BoolColumn get hideAmounts => boolean().withDefault(const Constant(false))();
  BoolColumn get appLockEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get autoLockMinutes => integer().customConstraint(
    'NOT NULL DEFAULT 5 CHECK (auto_lock_minutes >= 0)',
  )();
  IntColumn get lastBackupAt => integer().nullable()();
  IntColumn get backupReminderDays => integer().customConstraint(
    'NOT NULL DEFAULT 7 CHECK (backup_reminder_days BETWEEN 1 AND 365)',
  )();
  BoolColumn get dailyReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get dailyReminderHour => integer().customConstraint(
    'NOT NULL DEFAULT 21 CHECK (daily_reminder_hour BETWEEN 0 AND 23)',
  )();
  IntColumn get dailyReminderMinute => integer().customConstraint(
    'NOT NULL DEFAULT 0 CHECK (daily_reminder_minute BETWEEN 0 AND 59)',
  )();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

class BudgetRecords extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get salaryCycleId => text().references(SalaryCycleRecords, #id)();
  TextColumn get categoryId =>
      text().nullable().references(CategoryRecords, #id)();
  IntColumn get limitCents =>
      integer().customConstraint('NOT NULL CHECK (limit_cents > 0)')();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {salaryCycleId, categoryId},
  ];
}

@DriftDatabase(
  tables: [
    SalaryCycleRecords,
    CategoryRecords,
    TransactionRecords,
    AppSettingRecords,
    BudgetRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'xinflow'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement('''
        CREATE UNIQUE INDEX one_active_salary_cycle
        ON salary_cycles(status)
        WHERE status = 'active' AND deleted_at IS NULL
      ''');
      await customStatement('''
        CREATE UNIQUE INDEX unique_active_category_name
        ON categories(COALESCE(parent_id, ''), name)
        WHERE deleted_at IS NULL
      ''');
      await _createBudgetScopeIndex();
      await _seedDefaultCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await _alignCyclesToSalaryDay();
      if (from < 3) {
        if (!await _columnExists('salary_cycles', 'carryover_cents')) {
          await migrator.addColumn(
            salaryCycleRecords,
            salaryCycleRecords.carryoverCents,
          );
        }
        if (!await _columnExists('categories', 'color_key')) {
          await migrator.addColumn(categoryRecords, categoryRecords.colorKey);
        }
        if (!await _columnExists('categories', 'show_on_home')) {
          await migrator.addColumn(categoryRecords, categoryRecords.showOnHome);
        }
        if (!await _columnExists('app_settings', 'hide_amounts')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.hideAmounts,
          );
        }
        if (!await _columnExists('app_settings', 'app_lock_enabled')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.appLockEnabled,
          );
        }
        if (!await _columnExists('app_settings', 'auto_lock_minutes')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.autoLockMinutes,
          );
        }
        if (!await _columnExists('app_settings', 'last_backup_at')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.lastBackupAt,
          );
        }
        if (!await _columnExists('app_settings', 'backup_reminder_days')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.backupReminderDays,
          );
        }
        if (!await _transactionTableSupportsWithdrawal()) {
          await migrator.alterTable(TableMigration(transactionRecords));
        }
        if (!await _tableExists('budgets')) {
          await migrator.createTable(budgetRecords);
        }
        await _createBudgetScopeIndex();
        for (final category in DefaultCategories.values.where(
          (item) => item.showOnHome,
        )) {
          await (update(
            categoryRecords,
          )..where((row) => row.id.equals(category.id))).write(
            CategoryRecordsCompanion(
              colorKey: Value(category.colorKey),
              showOnHome: const Value(true),
            ),
          );
        }
      }
      if (from < 4) {
        if (!await _columnExists('app_settings', 'daily_reminder_enabled')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.dailyReminderEnabled,
          );
        }
        if (!await _columnExists('app_settings', 'daily_reminder_hour')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.dailyReminderHour,
          );
        }
        if (!await _columnExists('app_settings', 'daily_reminder_minute')) {
          await migrator.addColumn(
            appSettingRecords,
            appSettingRecords.dailyReminderMinute,
          );
        }
      }
      if (from < 5) await _seedTravelCategories();
      if (from < 6) await _seedFixedExpenseCategory();
      if (from < 7) {
        if (!await _columnExists('salary_cycles', 'salary_pending')) {
          await migrator.addColumn(
            salaryCycleRecords,
            salaryCycleRecords.salaryPending,
          );
        }
        await adoptTenthDayCycles();
      }
      if (from < 8) await repairTenthDayCycles();
    },
  );

  Future<void> adoptTenthDayCycles({DateTime? now}) async {
    final settings = await select(appSettingRecords).getSingleOrNull();
    if (settings == null) return;
    final instant = now ?? DateTime.now();
    if (settings.salaryDay != 10) {
      await (update(
        appSettingRecords,
      )..where((row) => row.singletonId.equals(1))).write(
        AppSettingRecordsCompanion(
          salaryDay: const Value(10),
          updatedAt: Value(instant.toUtc().millisecondsSinceEpoch),
        ),
      );
    }
    await repairTenthDayCycles(now: instant);
  }

  /// Repairs the old migration that extended one active cycle across paydays.
  /// Called inside the upgrade/startup transaction; repeating it is harmless.
  Future<void> repairTenthDayCycles({DateTime? now}) async {
    final instant = now ?? DateTime.now();
    final stamp = instant.toUtc().millisecondsSinceEpoch;
    final today = LocalDate.fromDateTime(instant);
    final currentStart = PaydayCalculator.cycleStartOnOrBefore(
      today: today,
      salaryDay: 10,
    );
    final initialActive =
        await (select(salaryCycleRecords)..where(
              (row) => row.status.equals('active') & row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (initialActive == null) return;
    var active = initialActive;
    var start = LocalDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(active.startedAt),
    );
    if (start.compareTo(today) > 0) return;

    var boundary = PaydayCalculator.forNextCycle(
      confirmedDate: PaydayCalculator.cycleStartOnOrBefore(
        today: start,
        salaryDay: 10,
      ),
      salaryDay: 10,
    );
    var splitCount = 0;
    while (boundary.compareTo(currentStart) <= 0) {
      if (++splitCount > 120) {
        throw StateError('工资周期与手机日期相差过大，请检查系统日期。');
      }
      final oldRows = await (select(
        transactionRecords,
      )..where((row) => row.salaryCycleId.equals(active.id))).get();
      final movedAllocations = oldRows
          .where(
            (row) =>
                row.entryKind == 'allocation' &&
                LocalDate.parse(row.occurredOn).compareTo(boundary) >= 0,
          )
          .map((row) => row.id)
          .toSet();
      final newId = const Uuid().v7();
      final nextBoundary = PaydayCalculator.forNextCycle(
        confirmedDate: boundary,
        salaryDay: 10,
      );
      final movingRows = oldRows.where(
        (row) =>
            movedAllocations.contains(row.id) ||
            movedAllocations.contains(row.reversesTransactionId),
      );
      final movingIds = movingRows.map((row) => row.id).toSet();
      final remainingRows = oldRows.where(
        (row) => !movingIds.contains(row.id) && row.deletedAt == null,
      );
      final summary = SalarySummary.fromTransactions(
        salaryCents: active.salaryCents,
        carryoverCents: active.carryoverCents,
        transactions: remainingRows.map((row) => row.toDomain()),
      );
      await (update(
        salaryCycleRecords,
      )..where((row) => row.id.equals(active.id))).write(
        SalaryCycleRecordsCompanion(
          expectedPayDate: Value(boundary.toString()),
          status: const Value('closed'),
          closedAt: Value(stamp),
          finalRemainingCents: Value(summary.remainingCents),
          updatedAt: Value(stamp),
        ),
      );
      await into(salaryCycleRecords).insert(
        SalaryCycleRecordsCompanion.insert(
          id: newId,
          salaryCents: 0,
          salaryPending: const Value(true),
          startedAt: DateTime(
            boundary.year,
            boundary.month,
            boundary.day,
          ).toUtc().millisecondsSinceEpoch,
          expectedPayDate: nextBoundary.toString(),
          status: 'active',
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );
      for (final row in movingRows) {
        await (update(
          transactionRecords,
        )..where((item) => item.id.equals(row.id))).write(
          TransactionRecordsCompanion(
            salaryCycleId: Value(newId),
            updatedAt: Value(stamp),
          ),
        );
      }
      active = await (select(
        salaryCycleRecords,
      )..where((row) => row.id.equals(newId))).getSingle();
      start = boundary;
      boundary = nextBoundary;
    }
    final expectedEnd = PaydayCalculator.forNextCycle(
      confirmedDate: PaydayCalculator.cycleStartOnOrBefore(
        today: start,
        salaryDay: 10,
      ),
      salaryDay: 10,
    );
    if (active.expectedPayDate != expectedEnd.toString()) {
      await (update(
        salaryCycleRecords,
      )..where((row) => row.id.equals(active.id))).write(
        SalaryCycleRecordsCompanion(
          expectedPayDate: Value(expectedEnd.toString()),
          updatedAt: Value(stamp),
        ),
      );
    }
  }

  Future<void> _alignCyclesToSalaryDay() async {
    final settings = await select(appSettingRecords).getSingleOrNull();
    if (settings == null) return;
    final cycles = await (select(
      salaryCycleRecords,
    )..orderBy([(row) => OrderingTerm.asc(row.startedAt)])).get();
    LocalDate? previousStart;
    LocalDate? previousEnd;
    for (final cycle in cycles) {
      final oldDate = LocalDate.fromDateTime(
        DateTime.fromMillisecondsSinceEpoch(cycle.startedAt),
      );
      var start = PaydayCalculator.cycleStartOnOrBefore(
        today: oldDate,
        salaryDay: settings.salaryDay,
      );
      if (previousStart != null && start.compareTo(previousStart) <= 0) {
        start = previousEnd!;
      }
      final end = PaydayCalculator.forNextCycle(
        confirmedDate: start,
        salaryDay: settings.salaryDay,
      );
      final localStart = DateTime(start.year, start.month, start.day);
      await (update(
        salaryCycleRecords,
      )..where((row) => row.id.equals(cycle.id))).write(
        SalaryCycleRecordsCompanion(
          startedAt: Value(localStart.toUtc().millisecondsSinceEpoch),
          expectedPayDate: Value(end.toString()),
        ),
      );
      previousStart = start;
      previousEnd = end;
    }
  }

  Future<bool> _columnExists(String table, String column) async {
    final rows = await customSelect("PRAGMA table_info('$table')").get();
    return rows.any((row) => row.read<String>('name') == column);
  }

  Future<bool> _tableExists(String table) async {
    final row = await customSelect(
      'SELECT 1 AS found FROM sqlite_master WHERE type = ? AND name = ?',
      variables: [Variable('table'), Variable(table)],
    ).getSingleOrNull();
    return row != null;
  }

  Future<bool> _transactionTableSupportsWithdrawal() async {
    final row = await customSelect(
      'SELECT sql FROM sqlite_master WHERE type = ? AND name = ?',
      variables: [const Variable('table'), const Variable('transactions')],
    ).getSingleOrNull();
    return row?.read<String>('sql').contains('withdrawal') ?? false;
  }

  Future<void> _createBudgetScopeIndex() => customStatement('''
    CREATE UNIQUE INDEX IF NOT EXISTS unique_budget_scope
    ON budgets(salary_cycle_id, COALESCE(category_id, ''))
  ''');

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(categoryRecords, [
        for (final category in DefaultCategories.values)
          CategoryRecordsCompanion.insert(
            id: category.id,
            parentId: Value(category.parentId),
            name: category.name,
            flowType: category.flowType.name,
            iconKey: category.iconKey,
            colorKey: Value(category.colorKey),
            sortOrder: category.sortOrder,
            showOnHome: Value(category.showOnHome),
            isSystem: category.isSystem,
            isActive: Value(category.isActive),
            createdAt: now,
            updatedAt: now,
          ),
      ]);
    });
  }

  Future<void> _seedTravelCategories() async {
    final travel = DefaultCategories.values.singleWhere(
      (category) => category.id == DefaultCategoryIds.travel,
    );
    final existingById = await (select(
      categoryRecords,
    )..where((row) => row.id.equals(travel.id))).getSingleOrNull();

    var parentId = travel.id;
    if (existingById == null) {
      final existingByName =
          await (select(categoryRecords)..where(
                (row) =>
                    row.parentId.isNull() &
                    row.name.equals(travel.name) &
                    row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (existingByName != null && existingByName.flowType == 'expense') {
        parentId = existingByName.id;
      } else {
        await _insertDefaultCategory(
          travel,
          name: existingByName == null ? travel.name : '旅行支出',
        );
      }
    }

    for (final child in DefaultCategories.values.where(
      (category) => category.parentId == DefaultCategoryIds.travel,
    )) {
      final childById = await (select(
        categoryRecords,
      )..where((row) => row.id.equals(child.id))).getSingleOrNull();
      if (childById != null) continue;
      final childByName =
          await (select(categoryRecords)..where(
                (row) =>
                    row.parentId.equals(parentId) &
                    row.name.equals(child.name) &
                    row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (childByName == null) {
        await _insertDefaultCategory(child, parentId: parentId);
      }
    }
  }

  Future<void> _seedFixedExpenseCategory() async {
    final fixedExpense = DefaultCategories.values.singleWhere(
      (category) => category.id == DefaultCategoryIds.fixedExpense,
    );
    final existingById = await (select(
      categoryRecords,
    )..where((row) => row.id.equals(fixedExpense.id))).getSingleOrNull();
    if (existingById != null) return;

    final existingByName =
        await (select(categoryRecords)..where(
              (row) =>
                  row.parentId.isNull() &
                  row.name.equals(fixedExpense.name) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (existingByName != null && existingByName.flowType == 'expense') return;

    await _insertDefaultCategory(
      fixedExpense,
      name: existingByName == null ? fixedExpense.name : '固定支出',
    );
  }

  Future<void> _insertDefaultCategory(
    Category category, {
    String? parentId,
    String? name,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await into(categoryRecords).insert(
      CategoryRecordsCompanion.insert(
        id: category.id,
        parentId: Value(parentId ?? category.parentId),
        name: name ?? category.name,
        flowType: category.flowType.name,
        iconKey: category.iconKey,
        colorKey: Value(category.colorKey),
        sortOrder: category.sortOrder,
        showOnHome: Value(category.showOnHome),
        isSystem: category.isSystem,
        isActive: Value(category.isActive),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> clearUserData() => transaction(() async {
    await delete(budgetRecords).go();
    await delete(transactionRecords).go();
    await delete(salaryCycleRecords).go();
    await delete(appSettingRecords).go();
    await delete(categoryRecords).go();
    await _seedDefaultCategories();
  });

  Future<void> deleteClosedCycle(String cycleId) => transaction(() async {
    final cycle =
        await (select(salaryCycleRecords)..where(
              (row) =>
                  row.id.equals(cycleId) &
                  row.status.equals('closed') &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (cycle == null) throw StateError('只能删除已封存的工资周期。');
    await (delete(
      budgetRecords,
    )..where((row) => row.salaryCycleId.equals(cycleId))).go();
    await (delete(
      transactionRecords,
    )..where((row) => row.salaryCycleId.equals(cycleId))).go();
    await (delete(
      salaryCycleRecords,
    )..where((row) => row.id.equals(cycleId))).go();
  });

  Future<CycleUndoPreviewRecord?> previewLatestCycleUndo() async {
    final active =
        await (select(salaryCycleRecords)..where(
              (row) => row.status.equals('active') & row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (active == null) return null;

    final previous =
        await (select(salaryCycleRecords)
              ..where(
                (row) => row.status.equals('closed') & row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (previous == null) return null;

    final counts = await customSelect(
      '''
        SELECT
          (SELECT COUNT(*) FROM transactions WHERE salary_cycle_id = ?) AS transaction_count,
          (SELECT COUNT(*) FROM budgets WHERE salary_cycle_id = ?) AS budget_count
      ''',
      variables: [Variable(active.id), Variable(active.id)],
    ).getSingle();
    return (
      active: active,
      previous: previous,
      transactionCount: counts.read<int>('transaction_count'),
      budgetCount: counts.read<int>('budget_count'),
    );
  }

  Future<void> undoLatestCycleTransition() => transaction(() async {
    final preview = await previewLatestCycleUndo();
    if (preview == null) {
      throw StateError('没有可以撤销的工资周期切换。');
    }
    if (preview.transactionCount > 0 || preview.budgetCount > 0) {
      throw StateError('当前周期已有流水或预算，请先清理后再撤销。');
    }

    final deleted =
        await (delete(salaryCycleRecords)..where(
              (row) =>
                  row.id.equals(preview.active.id) &
                  row.status.equals('active') &
                  row.deletedAt.isNull(),
            ))
            .go();
    if (deleted != 1) throw StateError('当前工资周期已发生变化，撤销已取消。');

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final restored =
        await (update(salaryCycleRecords)..where(
              (row) =>
                  row.id.equals(preview.previous.id) &
                  row.status.equals('closed') &
                  row.deletedAt.isNull(),
            ))
            .write(
              SalaryCycleRecordsCompanion(
                status: const Value('active'),
                closedAt: const Value(null),
                finalRemainingCents: const Value(null),
                updatedAt: Value(now),
              ),
            );
    if (restored != 1) throw StateError('上一工资周期已发生变化，撤销已取消。');

    final activeCount = await customSelect(
      "SELECT COUNT(*) AS count FROM salary_cycles WHERE status = 'active' AND deleted_at IS NULL",
    ).getSingle();
    if (activeCount.read<int>('count') != 1) {
      throw StateError('工资周期状态异常，撤销已回滚。');
    }
  });
}
