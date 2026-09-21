import 'package:drift/drift.dart';
import 'package:xinflow/core/database/app_database.dart';

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

  Future<void> clearAll() => _database.clearUserData();

  Future<int> _pragmaInt(String name) async {
    final row = await _database.customSelect('PRAGMA $name').getSingle();
    return row.data.values.single as int;
  }
}
