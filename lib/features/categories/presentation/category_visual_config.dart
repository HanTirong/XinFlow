import 'package:flutter/material.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

@immutable
final class CategoryVisualConfig {
  const CategoryVisualConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.darkIconColor,
    required this.backgroundColor,
    required this.type,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color darkIconColor;
  final Color backgroundColor;
  final FlowType type;

  Color resolvedIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkIconColor
        : iconColor;
  }

  Color resolvedBackgroundColor(BuildContext context) {
    return AppThemeTokens.of(context).categorySurface;
  }

  CategoryVisualConfig copyWith({String? name, FlowType? type}) =>
      CategoryVisualConfig(
        id: id,
        name: name ?? this.name,
        icon: icon,
        iconColor: iconColor,
        darkIconColor: darkIconColor,
        backgroundColor: backgroundColor,
        type: type ?? this.type,
      );
}

abstract final class CategoryVisuals {
  static const Map<String, CategoryVisualConfig> builtIn = {
    DefaultCategoryIds.food: CategoryVisualConfig(
      id: DefaultCategoryIds.food,
      name: '饮食',
      icon: Icons.restaurant_rounded,
      iconColor: Color(0xFFE76442),
      darkIconColor: Color(0xFFFF8464),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
    DefaultCategoryIds.shopping: CategoryVisualConfig(
      id: DefaultCategoryIds.shopping,
      name: '购物',
      icon: Icons.shopping_bag_rounded,
      iconColor: Color(0xFFD93F7C),
      darkIconColor: Color(0xFFFF5C9F),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
    DefaultCategoryIds.housing: CategoryVisualConfig(
      id: DefaultCategoryIds.housing,
      name: '住房',
      icon: Icons.home_rounded,
      iconColor: Color(0xFF477CD7),
      darkIconColor: Color(0xFF78A5FF),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
    DefaultCategoryIds.transport: CategoryVisualConfig(
      id: DefaultCategoryIds.transport,
      name: '交通',
      icon: Icons.directions_bus_rounded,
      iconColor: Color(0xFF278769),
      darkIconColor: Color(0xFF65D6AA),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
    DefaultCategoryIds.digital: CategoryVisualConfig(
      id: DefaultCategoryIds.digital,
      name: '数字服务',
      icon: Icons.laptop_mac_rounded,
      iconColor: Color(0xFF7453C8),
      darkIconColor: Color(0xFFA879FF),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
    DefaultCategoryIds.saving: CategoryVisualConfig(
      id: DefaultCategoryIds.saving,
      name: '存款',
      icon: Icons.savings_rounded,
      iconColor: Color(0xFFB77A0A),
      darkIconColor: Color(0xFFFFC34D),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.saving,
    ),
    DefaultCategoryIds.investment: CategoryVisualConfig(
      id: DefaultCategoryIds.investment,
      name: '理财',
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF15869B),
      darkIconColor: Color(0xFF48CADC),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.investment,
    ),
    DefaultCategoryIds.travel: CategoryVisualConfig(
      id: DefaultCategoryIds.travel,
      name: '旅行',
      icon: Icons.flight_takeoff_rounded,
      iconColor: Color(0xFF5B5BD6),
      darkIconColor: Color(0xFF9696FF),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
    DefaultCategoryIds.fixedExpense: CategoryVisualConfig(
      id: DefaultCategoryIds.fixedExpense,
      name: '固定开支',
      icon: Icons.calendar_month_rounded,
      iconColor: Color(0xFFC46617),
      darkIconColor: Color(0xFFFFA65C),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
    DefaultCategoryIds.other: CategoryVisualConfig(
      id: DefaultCategoryIds.other,
      name: '其他',
      icon: Icons.more_horiz_rounded,
      iconColor: Color(0xFF657086),
      darkIconColor: Color(0xFFC5CCDB),
      backgroundColor: AppPalette.lightSecondaryCard,
      type: FlowType.expense,
    ),
  };

  static CategoryVisualConfig resolve({
    required String categoryId,
    Iterable<Category> categories = const [],
    String? fallbackName,
    FlowType fallbackType = FlowType.expense,
  }) {
    Category? category;
    for (final candidate in categories) {
      if (candidate.id == categoryId) {
        category = candidate;
        break;
      }
    }

    final configured = builtIn[categoryId];
    if (category != null) {
      final colors = colorsForKey(category.colorKey, category.flowType);
      return CategoryVisualConfig(
        id: category.id,
        name: category.name,
        icon: iconForKey(category.iconKey),
        iconColor: colors.$1,
        darkIconColor: colors.$2,
        backgroundColor: colors.$3,
        type: category.flowType,
      );
    }
    if (configured != null) {
      return configured.copyWith(name: fallbackName);
    }

    final type = category?.flowType ?? fallbackType;
    final colors = _fallbackColors(type);
    return CategoryVisualConfig(
      id: categoryId,
      name: category?.name ?? fallbackName ?? '其他',
      icon: iconForKey(category?.iconKey),
      iconColor: colors.$1,
      darkIconColor: colors.$2,
      backgroundColor: colors.$3,
      type: type,
    );
  }

  static IconData iconForKey(String? iconKey) => switch (iconKey) {
    'restaurant' || 'food' => Icons.restaurant_rounded,
    'shopping_bag' || 'shopping' => Icons.shopping_bag_rounded,
    'home' || 'housing' => Icons.home_rounded,
    'directions_bus' || 'transport' => Icons.directions_bus_rounded,
    'laptop' || 'digital' => Icons.laptop_mac_rounded,
    'savings' || 'saving' => Icons.savings_rounded,
    'bar_chart' || 'investment' => Icons.bar_chart_rounded,
    'flight_takeoff' || 'travel' => Icons.flight_takeoff_rounded,
    'calendar_month' || 'fixed' => Icons.calendar_month_rounded,
    'more_horiz' || 'other' => Icons.more_horiz_rounded,
    'medical' => Icons.medical_services_rounded,
    'school' => Icons.school_rounded,
    'pets' => Icons.pets_rounded,
    'sports' => Icons.sports_basketball_rounded,
    _ => Icons.category_rounded,
  };

  static (Color, Color, Color) colorsForKey(
    String colorKey,
    FlowType fallbackType,
  ) => switch (colorKey) {
    'coral' => (
      const Color(0xFFE76442),
      const Color(0xFFFF8464),
      AppPalette.lightSecondaryCard,
    ),
    'pink' => (
      const Color(0xFFD93F7C),
      const Color(0xFFFF5C9F),
      AppPalette.lightSecondaryCard,
    ),
    'blue' => (
      const Color(0xFF477CD7),
      const Color(0xFF78A5FF),
      AppPalette.lightSecondaryCard,
    ),
    'green' => (
      const Color(0xFF278769),
      const Color(0xFF65D6AA),
      AppPalette.lightSecondaryCard,
    ),
    'purple' => (
      const Color(0xFF7453C8),
      const Color(0xFFA879FF),
      AppPalette.lightSecondaryCard,
    ),
    'amber' => (
      const Color(0xFFB77A0A),
      const Color(0xFFFFC34D),
      AppPalette.lightSecondaryCard,
    ),
    'cyan' => (
      const Color(0xFF15869B),
      const Color(0xFF48CADC),
      AppPalette.lightSecondaryCard,
    ),
    'indigo' => (
      const Color(0xFF5B5BD6),
      const Color(0xFF9696FF),
      AppPalette.lightSecondaryCard,
    ),
    'orange' => (
      const Color(0xFFC46617),
      const Color(0xFFFFA65C),
      AppPalette.lightSecondaryCard,
    ),
    _ => _fallbackColors(fallbackType),
  };

  static (Color, Color, Color) _fallbackColors(FlowType type) => switch (type) {
    FlowType.expense => (
      const Color(0xFF657086),
      const Color(0xFFC5CCDB),
      AppPalette.lightSecondaryCard,
    ),
    FlowType.saving => (
      const Color(0xFFB77A0A),
      const Color(0xFFFFC34D),
      AppPalette.lightSecondaryCard,
    ),
    FlowType.investment => (
      const Color(0xFF15869B),
      const Color(0xFF48CADC),
      AppPalette.lightSecondaryCard,
    ),
  };
}

final class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    required this.config,
    this.size = 42,
    this.iconSize = 20,
    super.key,
  });

  final CategoryVisualConfig config;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: config.resolvedBackgroundColor(context),
      shape: BoxShape.circle,
    ),
    child: Icon(
      config.icon,
      size: iconSize,
      color: config.resolvedIconColor(context),
    ),
  );
}
