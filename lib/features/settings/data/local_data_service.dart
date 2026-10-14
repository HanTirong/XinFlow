import 'package:drift/drift.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';

final class LocalDataOverview {
  const LocalDataOverview({
    required this.cycles,
    required this.transactions,
    required this.categories,
    required this.budgets,
    required this.approximateBytes,
  });

  final int cycles;
  final int transactions;
  final int categories;
  final int budgets;
  final int approximateBytes;
}

final class CycleUndoPreview {
  const CycleUndoPreview({
    required this.activeCycle,
    required this.previousCycle,
    required this.transactionCount,
    required this.budgetCount,
  });

  final SalaryCycle activeCycle;
  final SalaryCycle previousCycle;
  final int transactionCount;
  final int budgetCount;

  bool get canUndo => transactionCount == 0 && budgetCount == 0;
}

final class LocalDataService {
  const LocalDataService(this._database);

  final AppDatabase _database;

  Future<LocalDataOverview> overview() async {
    final counts = await Future.wait([
      _database.salaryCycleRecords.count().getSingle(),
      _database.transactionRecords.count().getSingle(),
      _database.categoryRecords.count().getSingle(),
      _database.budgetRecords.count().getSingle(),
    ]);
    final pageCount = await _pragmaInt('page_count');
    final pageSize = await _pragmaInt('page_size');
    return LocalDataOverview(
      cycles: counts[0],
      transactions: counts[1],
      categories: counts[2],
      budgets: counts[3],
      approximateBytes: pageCount * pageSize,
    );
  }

  Future<void> deleteClosedCycle(String cycleId) =>
      _database.deleteClosedCycle(cycleId);

  Future<CycleUndoPreview?> previewLatestCycleUndo() async {
    final preview = await _database.previewLatestCycleUndo();
    if (preview == null) return null;
    return CycleUndoPreview(
      activeCycle: preview.active.toDomain(),
      previousCycle: preview.previous.toDomain(),
      transactionCount: preview.transactionCount,
      budgetCount: preview.budgetCount,
    );
  }

  Future<void> undoLatestCycleTransition() =>
      _database.undoLatestCycleTransition();

  Future<void> clearAll() => _database.clearUserData();

  Future<int> _pragmaInt(String name) async {
    final row = await _database.customSelect('PRAGMA $name').getSingle();
    return row.data.values.single as int;
  }
}
