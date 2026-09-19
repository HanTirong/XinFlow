import 'package:drift/drift.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/features/categories/data/category_repository.dart';
import 'package:xinflow/features/categories/domain/category.dart';

final class DriftCategoryRepository implements CategoryRepository {
  const DriftCategoryRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Category>> listActive() async {
    final rows =
        await (_database.select(_database.categoryRecords)
              ..where(
                (row) => row.isActive.equals(true) & row.deletedAt.isNull(),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.parentId),
                (row) => OrderingTerm.asc(row.sortOrder),
              ]))
            .get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<Category?> getById(String id) async {
    final row =
        await (_database.select(_database.categoryRecords)..where(
              (row) =>
                  row.id.equals(id) &
                  row.isActive.equals(true) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row?.toDomain();
  }
}
