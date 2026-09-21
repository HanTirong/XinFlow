import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

void main() {
  test('built-in categories have one complete shared visual configuration', () {
    expect(CategoryVisuals.builtIn, hasLength(8));

    final food = CategoryVisuals.resolve(categoryId: DefaultCategoryIds.food);
    final shopping = CategoryVisuals.resolve(
      categoryId: DefaultCategoryIds.shopping,
    );

    expect(food.name, '饮食');
    expect(food.icon, Icons.restaurant_rounded);
    expect(food.type, FlowType.expense);
    expect(shopping.name, '购物');
    expect(shopping.icon, Icons.shopping_bag_rounded);
    expect(food.icon, isNot(shopping.icon));
    expect(food.iconColor, isNot(shopping.iconColor));
    expect(food.darkIconColor, const Color(0xFFFF8464));
    expect(shopping.darkIconColor, const Color(0xFFFF5C9F));
    expect(food.backgroundColor, shopping.backgroundColor);
  });

  test('renamed and custom categories keep using the central resolver', () {
    final renamed = Category(
      id: DefaultCategoryIds.food,
      name: '餐饮',
      flowType: FlowType.expense,
      iconKey: 'restaurant',
      sortOrder: 10,
      isSystem: true,
    );
    final custom = Category(
      id: 'custom.saving',
      name: '旅行基金',
      flowType: FlowType.saving,
      iconKey: 'savings',
      sortOrder: 90,
      isSystem: false,
    );

    final renamedConfig = CategoryVisuals.resolve(
      categoryId: renamed.id,
      categories: [renamed],
    );
    final customConfig = CategoryVisuals.resolve(
      categoryId: custom.id,
      categories: [custom],
    );

    expect(renamedConfig.name, '餐饮');
    expect(renamedConfig.icon, Icons.restaurant_rounded);
    expect(customConfig.name, '旅行基金');
    expect(customConfig.icon, Icons.savings_rounded);
    expect(customConfig.type, FlowType.saving);
  });
}
