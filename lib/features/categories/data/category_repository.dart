import 'package:xinflow/features/categories/domain/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> listActive();

  Future<List<Category>> listAll();

  Future<Category?> getById(String id);

  Future<void> add(Category category);

  Future<void> updateNameAndState({
    required String id,
    required String name,
    required bool isActive,
  });

  Future<void> update(Category category);

  Future<void> reorder(List<Category> categories);
}
