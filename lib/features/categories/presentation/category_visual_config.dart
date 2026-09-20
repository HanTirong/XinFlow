import 'package:flutter/material.dart';
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
    required this.backgroundColor,
    required this.type,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final FlowType type;

  Color resolvedIconColor(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) return iconColor;
    return Color.lerp(iconColor, Colors.white, 0.28)!;
  }

  Color resolvedBackgroundColor(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return backgroundColor;
    }
    return Color.alphaBlend(
      iconColor.withAlpha(34),
      Theme.of(context).colorScheme.surfaceContainerHigh,
    );
  }

  CategoryVisualConfig copyWith({String? name, FlowType? type}) =>
      CategoryVisualConfig(
        id: id,
        name: name ?? this.name,
        icon: icon,
        iconColor: iconColor,
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
      iconColor: Color(0xFFB86149),
      backgroundColor: Color(0xFFF7EBE7),
      type: FlowType.expense,
    ),
    DefaultCategoryIds.shopping: CategoryVisualConfig(
      id: DefaultCategoryIds.shopping,
      name: '购物',
      icon: Icons.shopping_bag_rounded,
      iconColor: Color(0xFFB55777),
      backgroundColor: Color(0xFFF7EAF0),
      type: FlowType.expense,
    ),
    DefaultCategoryIds.housing: CategoryVisualConfig(
      id: DefaultCategoryIds.housing,
      name: '住房',
      icon: Icons.home_rounded,
      iconColor: Color(0xFF527BB5),
      backgroundColor: Color(0xFFEAF0F7),
      type: FlowType.expense,
    ),
    DefaultCategoryIds.transport: CategoryVisualConfig(
      id: DefaultCategoryIds.transport,
      name: '交通',
      icon: Icons.directions_bus_rounded,
      iconColor: Color(0xFF4C826C),
      backgroundColor: Color(0xFFE8F1ED),
      type: FlowType.expense,
    ),
    DefaultCategoryIds.digital: CategoryVisualConfig(
      id: DefaultCategoryIds.digital,
      name: '数字服务',
      icon: Icons.laptop_mac_rounded,
      iconColor: Color(0xFF7364A8),
      backgroundColor: Color(0xFFEFEDF6),
      type: FlowType.expense,
    ),
    DefaultCategoryIds.saving: CategoryVisualConfig(
      id: DefaultCategoryIds.saving,
      name: '存款',
      icon: Icons.savings_rounded,
      iconColor: Color(0xFFA77932),
      backgroundColor: Color(0xFFF6F0E5),
      type: FlowType.saving,
    ),
    DefaultCategoryIds.investment: CategoryVisualConfig(
      id: DefaultCategoryIds.investment,
      name: '理财',
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF3F7C8C),
      backgroundColor: Color(0xFFE8F2F4),
      type: FlowType.investment,
    ),
    DefaultCategoryIds.other: CategoryVisualConfig(
      id: DefaultCategoryIds.other,
      name: '其他',
      icon: Icons.more_horiz_rounded,
      iconColor: Color(0xFF667085),
      backgroundColor: Color(0xFFEEF0F3),
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
    if (configured != null) {
      return configured.copyWith(
        name: category?.name,
        type: category?.flowType,
      );
    }

    final type = category?.flowType ?? fallbackType;
    final colors = _fallbackColors(type);
    return CategoryVisualConfig(
      id: categoryId,
      name: category?.name ?? fallbackName ?? '其他',
      icon: _iconForKey(category?.iconKey),
      iconColor: colors.$1,
      backgroundColor: colors.$2,
      type: type,
    );
  }

  static IconData _iconForKey(String? iconKey) => switch (iconKey) {
    'restaurant' || 'food' => Icons.restaurant_rounded,
    'shopping_bag' || 'shopping' => Icons.shopping_bag_rounded,
    'home' || 'housing' => Icons.home_rounded,
    'directions_bus' || 'transport' => Icons.directions_bus_rounded,
    'laptop' || 'digital' => Icons.laptop_mac_rounded,
    'savings' || 'saving' => Icons.savings_rounded,
    'bar_chart' || 'investment' => Icons.bar_chart_rounded,
    'more_horiz' || 'other' => Icons.more_horiz_rounded,
    _ => Icons.category_rounded,
  };

  static (Color, Color) _fallbackColors(FlowType type) => switch (type) {
    FlowType.expense => (const Color(0xFF667085), const Color(0xFFEEF0F3)),
    FlowType.saving => (const Color(0xFFA77932), const Color(0xFFF6F0E5)),
    FlowType.investment => (const Color(0xFF3F7C8C), const Color(0xFFE8F2F4)),
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
