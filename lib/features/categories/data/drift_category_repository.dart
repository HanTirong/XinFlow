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
  Future<List<Category>> listAll() async {
    final rows =
        await (_database.select(_database.categoryRecords)
              ..where((row) => row.deletedAt.isNull())
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

  @override
  Future<void> add(Category category) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (category.parentId != null) {
      final parent = await getById(category.parentId!);
      if (parent == null ||
          !parent.isTopLevel ||
          parent.flowType != category.flowType) {
        throw ArgumentError('二级分类必须关联相同性质的有效一级分类。');
      }
    }
    await _database
        .into(_database.categoryRecords)
        .insert(
          CategoryRecordsCompanion.insert(
            id: category.id,
            parentId: Value(category.parentId),
            name: category.name.trim(),
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

  @override
  Future<void> updateNameAndState({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('分类名称不能为空。');
    final affected =
        await (_database.update(
          _database.categoryRecords,
        )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
          CategoryRecordsCompanion(
            name: Value(name.trim()),
            isActive: Value(isActive),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
    if (affected != 1) throw StateError('分类不存在或已经删除。');
  }

  @override
  Future<void> update(Category category) async {
    if (category.name.trim().isEmpty) throw ArgumentError('分类名称不能为空。');
    if (category.parentId != null) {
      final parent = await getById(category.parentId!);
      if (parent == null ||
          !parent.isTopLevel ||
          parent.flowType != category.flowType ||
          parent.id == category.id) {
        throw ArgumentError('二级分类必须关联相同性质的有效一级分类。');
      }
    }
    final affected =
        await (_database.update(_database.categoryRecords)..where(
              (row) => row.id.equals(category.id) & row.deletedAt.isNull(),
            ))
            .write(
              CategoryRecordsCompanion(
                parentId: Value(category.parentId),
                name: Value(category.name.trim()),
                iconKey: Value(category.iconKey),
                colorKey: Value(category.colorKey),
                sortOrder: Value(category.sortOrder),
                showOnHome: Value(category.showOnHome),
                isActive: Value(category.isActive),
                updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
              ),
            );
    if (affected != 1) throw StateError('分类不存在或已经删除。');
  }

  @override
  Future<void> reorder(List<Category> categories) =>
      _database.transaction(() async {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        for (var index = 0; index < categories.length; index++) {
          await (_database.update(
            _database.categoryRecords,
          )..where((row) => row.id.equals(categories[index].id))).write(
            CategoryRecordsCompanion(
              sortOrder: Value((index + 1) * 10),
              updatedAt: Value(now),
            ),
          );
        }
      });
}
