import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class Category {
  Category({
    required this.id,
    required this.name,
    required this.flowType,
    required this.iconKey,
    this.colorKey = 'neutral',
    required this.sortOrder,
    required this.isSystem,
    this.parentId,
    this.isActive = true,
    this.showOnHome = false,
  }) {
    if (id.isEmpty || name.trim().isEmpty || iconKey.isEmpty) {
      throw ArgumentError('分类 ID、名称和图标键不能为空。');
    }
  }

  final String id;
  final String? parentId;
  final String name;
  final FlowType flowType;
  final String iconKey;
  final String colorKey;
  final int sortOrder;
  final bool isSystem;
  final bool isActive;
  final bool showOnHome;

  bool get isTopLevel => parentId == null;

  Category copyWith({
    String? parentId,
    bool clearParent = false,
    String? name,
    String? iconKey,
    String? colorKey,
    int? sortOrder,
    bool? isActive,
    bool? showOnHome,
  }) => Category(
    id: id,
    parentId: clearParent ? null : parentId ?? this.parentId,
    name: name ?? this.name,
    flowType: flowType,
    iconKey: iconKey ?? this.iconKey,
    colorKey: colorKey ?? this.colorKey,
    sortOrder: sortOrder ?? this.sortOrder,
    isSystem: isSystem,
    isActive: isActive ?? this.isActive,
    showOnHome: showOnHome ?? this.showOnHome,
  );
}
