import 'package:drift/drift.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/features/budgets/data/budget_repository.dart';
import 'package:xinflow/features/budgets/domain/budget.dart';

final class DriftBudgetRepository implements BudgetRepository {
  const DriftBudgetRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<Budget>> watchForCycle(String cycleId) =>
      (_database.select(_database.budgetRecords)
            ..where((row) => row.salaryCycleId.equals(cycleId))
            ..orderBy([(row) => OrderingTerm.asc(row.categoryId)]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (row) => Budget(
                    id: row.id,
                    salaryCycleId: row.salaryCycleId,
                    categoryId: row.categoryId,
                    limitCents: row.limitCents,
                  ),
                )
                .toList(growable: false),
          );

  @override
  Future<void> save(Budget budget) async {
    if (budget.limitCents <= 0) throw ArgumentError('预算必须大于 0。');
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final existing =
        await (_database.select(_database.budgetRecords)..where(
              (row) =>
                  row.salaryCycleId.equals(budget.salaryCycleId) &
                  (budget.categoryId == null
                      ? row.categoryId.isNull()
                      : row.categoryId.equals(budget.categoryId!)),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await _database
          .into(_database.budgetRecords)
          .insert(
            BudgetRecordsCompanion.insert(
              id: budget.id,
              salaryCycleId: budget.salaryCycleId,
              categoryId: Value(budget.categoryId),
              limitCents: budget.limitCents,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(
        _database.budgetRecords,
      )..where((row) => row.id.equals(existing.id))).write(
        BudgetRecordsCompanion(
          limitCents: Value(budget.limitCents),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> delete(String budgetId) => (_database.delete(
    _database.budgetRecords,
  )..where((row) => row.id.equals(budgetId))).go();
}
