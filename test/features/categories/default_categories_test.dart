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

  test('contains the nine agreed top-level categories', () {
    final names = DefaultCategories.values
        .where((category) => category.isTopLevel)
        .map((category) => category.name)
        .toList();

    expect(names, [
      '饮食',
      '购物',
      '住房',
      '交通',
      '数字服务',
      '存款',
      '理财',
      '旅行',
      '其他',
    ]);
    final travelChildren = DefaultCategories.values
        .where((category) => category.parentId == DefaultCategoryIds.travel)
        .map((category) => category.name)
        .toList();
    expect(travelChildren, [
      '酒店住宿',
      '机票／火车票',
      '当地交通',
      '景点门票',
      '旅行餐饮',
      '签证／保险',
      '旅行购物',
      '其他旅行支出',
    ]);
  });
}
