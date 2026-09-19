import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';

part 'app_database.g.dart';

class SalaryCycleRecords extends Table {
  @override
  String get tableName => 'salary_cycles';

  TextColumn get id => text()();
  IntColumn get salaryCents =>
      integer().customConstraint('NOT NULL CHECK (salary_cents >= 0)')();
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
  IntColumn get sortOrder => integer()();
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
    "NOT NULL CHECK (entry_kind IN ('allocation', 'refund'))",
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
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

@DriftDatabase(
  tables: [
    SalaryCycleRecords,
    CategoryRecords,
    TransactionRecords,
    AppSettingRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'xinflow'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

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
      await _seedDefaultCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

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
            sortOrder: category.sortOrder,
            isSystem: category.isSystem,
            isActive: Value(category.isActive),
            createdAt: now,
            updatedAt: now,
          ),
      ]);
    });
  }
}
