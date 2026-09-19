import 'package:xinflow/features/categories/domain/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> listActive();

  Future<Category?> getById(String id);
}
