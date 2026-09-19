import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class Category {
  Category({
    required this.id,
    required this.name,
    required this.flowType,
    required this.iconKey,
    required this.sortOrder,
    required this.isSystem,
    this.parentId,
    this.isActive = true,
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
  final int sortOrder;
  final bool isSystem;
  final bool isActive;

  bool get isTopLevel => parentId == null;
}
