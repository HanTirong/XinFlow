import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

const _iconChoices = <String, IconData>{
  'category': Icons.category_rounded,
  'restaurant': Icons.restaurant_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'home': Icons.home_rounded,
  'directions_bus': Icons.directions_bus_rounded,
  'laptop': Icons.laptop_mac_rounded,
  'savings': Icons.savings_rounded,
  'bar_chart': Icons.bar_chart_rounded,
  'flight_takeoff': Icons.flight_takeoff_rounded,
  'calendar_month': Icons.calendar_month_rounded,
  'medical': Icons.medical_services_rounded,
  'school': Icons.school_rounded,
  'pets': Icons.pets_rounded,
  'sports': Icons.sports_basketball_rounded,
  'more_horiz': Icons.more_horiz_rounded,
};

const _colorChoices = <String, Color>{
  'neutral': Color(0xFF657086),
  'coral': Color(0xFFE76442),
  'pink': Color(0xFFD93F7C),
  'blue': Color(0xFF477CD7),
  'green': Color(0xFF278769),
  'purple': Color(0xFF7453C8),
  'amber': Color(0xFFB77A0A),
  'cyan': Color(0xFF15869B),
  'indigo': Color(0xFF5B5BD6),
  'orange': Color(0xFFC46617),
};

Future<void> showCategoryManagementSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CategoryManagementSheet(),
    );

final class CategoryManagementCard extends ConsumerWidget {
  const CategoryManagementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.category_outlined),
        title: const Text('分类管理'),
        subtitle: Text(
          categories.when(
            data: (value) => '${value.length} 个分类，可调整图标、颜色与顺序',
            loading: () => '正在读取分类…',
            error: (_, _) => '分类读取失败',
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => showCategoryManagementSheet(context),
      ),
    );
  }
}

final class _CategoryManagementSheet extends ConsumerWidget {
  const _CategoryManagementSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider);
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '分类管理',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: categories.value == null
                      ? null
                      : () => _edit(context, ref, categories.value!),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新增'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '一级分类可加入首页快捷区；二级分类可更换所属一级分类。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: categories.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
                data: (items) => ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final category = items[index];
                    final siblings = items
                        .where((item) => item.parentId == category.parentId)
                        .toList();
                    final siblingIndex = siblings.indexWhere(
                      (item) => item.id == category.id,
                    );
                    final parent = category.parentId == null
                        ? null
                        : items
                              .where((item) => item.id == category.parentId)
                              .firstOrNull;
                    final visual = CategoryVisuals.resolve(
                      categoryId: category.id,
                      categories: items,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.only(
                        left: category.isTopLevel ? 0 : 28,
                      ),
                      leading: CategoryIconBadge(config: visual),
                      title: Text(category.name),
                      subtitle: Text(
                        [
                          _flowLabel(category.flowType),
                          if (parent != null) '上级：${parent.name}',
                          if (category.showOnHome) '首页快捷项',
                          if (!category.isActive) '已停用',
                        ].join(' · '),
                      ),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: '上移',
                            onPressed: siblingIndex <= 0
                                ? null
                                : () => _move(ref, siblings, siblingIndex, -1),
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                          IconButton(
                            tooltip: '下移',
                            onPressed: siblingIndex >= siblings.length - 1
                                ? null
                                : () => _move(ref, siblings, siblingIndex, 1),
                            icon: const Icon(Icons.arrow_downward_rounded),
                          ),
                          IconButton(
                            tooltip: '编辑',
                            onPressed: () =>
                                _edit(context, ref, items, category: category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _move(
    WidgetRef ref,
    List<Category> siblings,
    int index,
    int delta,
  ) async {
    final reordered = [...siblings];
    final item = reordered.removeAt(index);
    reordered.insert(index + delta, item);
    await ref.read(categoryRepositoryProvider).reorder(reordered);
    _refresh(ref);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories, {
    Category? category,
  }) async {
    var name = category?.name ?? '';
    var flowType = category?.flowType ?? FlowType.expense;
    var parentId = category?.parentId;
    var iconKey = category?.iconKey ?? 'category';
    var colorKey = category?.colorKey ?? 'neutral';
    var active = category?.isActive ?? true;
    var showOnHome = category?.showOnHome ?? false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final parents = categories.where(
            (item) =>
                item.isTopLevel &&
                item.isActive &&
                item.flowType == flowType &&
                item.id != category?.id,
          );
          if (parentId != null && !parents.any((item) => item.id == parentId)) {
            parentId = null;
          }
          return AlertDialog(
            title: Text(category == null ? '新增分类' : '编辑分类'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    onChanged: (value) => name = value,
                    autofocus: true,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: '分类名称'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<FlowType>(
                    initialValue: flowType,
                    decoration: const InputDecoration(labelText: '性质'),
                    items: FlowType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_flowLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: category == null
                        ? (value) => setState(() {
                            flowType = value!;
                            parentId = null;
                          })
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: parentId,
                    decoration: const InputDecoration(labelText: '上级分类（可选）'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('作为一级分类'),
                      ),
                      for (final parent in parents)
                        DropdownMenuItem(
                          value: parent.id,
                          child: Text(parent.name),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      parentId = value;
                      if (value != null) showOnHome = false;
                    }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: iconKey,
                    decoration: const InputDecoration(labelText: '图标'),
                    items: [
                      for (final entry in _iconChoices.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value),
                              const SizedBox(width: 10),
                              Text(entry.key),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => iconKey = value!),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final entry in _colorChoices.entries)
                        ChoiceChip(
                          selected: colorKey == entry.key,
                          label: CircleAvatar(
                            radius: 9,
                            backgroundColor: entry.value,
                          ),
                          onSelected: (_) =>
                              setState(() => colorKey = entry.key),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('用于新流水'),
                    value: active,
                    onChanged: (value) => setState(() => active = value),
                  ),
                  if (parentId == null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('显示在首页快捷区'),
                      value: showOnHome,
                      onChanged: (value) => setState(() => showOnHome = value),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
    final trimmed = name.trim();
    if (confirmed != true || trimmed.isEmpty) return;
    final siblings = categories.where((item) => item.parentId == parentId);
    final sortOrder =
        category?.sortOrder ??
        siblings.fold<int>(
              0,
              (max, item) => item.sortOrder > max ? item.sortOrder : max,
            ) +
            10;
    final updated = Category(
      id: category?.id ?? ref.read(idGeneratorProvider).next(),
      parentId: parentId,
      name: trimmed,
      flowType: flowType,
      iconKey: iconKey,
      colorKey: colorKey,
      sortOrder: sortOrder,
      isSystem: category?.isSystem ?? false,
      isActive: active,
      showOnHome: parentId == null && showOnHome,
    );
    if (category == null) {
      await ref.read(categoryRepositoryProvider).add(updated);
    } else {
      await ref.read(categoryRepositoryProvider).update(updated);
    }
    _refresh(ref);
  }

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(allCategoriesProvider)
      ..invalidate(activeCategoriesProvider)
      ..invalidate(homeSnapshotProvider);
  }
}

String _flowLabel(FlowType flowType) => switch (flowType) {
  FlowType.expense => '消费',
  FlowType.saving => '存款',
  FlowType.investment => '理财',
};
