import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';

void main() {
  test(
    'default category IDs are unique and child types match their parents',
    () {
      final categories = DefaultCategories.values;
      final ids = categories.map((category) => category.id).toSet();
      final byId = {for (final category in categories) category.id: category};

      expect(ids.length, categories.length);

      for (final category in categories.where((value) => !value.isTopLevel)) {
        final parent = byId[category.parentId];
        expect(parent, isNotNull, reason: 'Missing parent for ${category.id}');
        expect(category.flowType, parent!.flowType);
      }
    },
  );

  test('contains the eight agreed top-level categories', () {
    final names = DefaultCategories.values
        .where((category) => category.isTopLevel)
        .map((category) => category.name)
        .toList();

    expect(names, ['饮食', '购物', '住房', '交通', '数字服务', '存款', '理财', '其他']);
  });
}
