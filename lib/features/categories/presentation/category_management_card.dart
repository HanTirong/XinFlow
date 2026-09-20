import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

Future<void> showCategoryManagementSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CategoryManagementSheet(),
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
            data: (value) => '${value.length} 个一级和二级分类',
            loading: () => '正在读取分类…',
            error: (error, stackTrace) => '分类读取失败',
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
      heightFactor: 0.88,
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
                      : () => _addCategory(context, ref, categories.value!),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新增'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: categories.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('$error')),
                data: (items) => ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final category = items[index];
                    final parent = category.parentId == null
                        ? null
                        : items
                              .where((item) => item.id == category.parentId)
                              .firstOrNull;
                    return ListTile(
                      contentPadding: EdgeInsets.only(
                        left: category.isTopLevel ? 0 : 28,
                      ),
                      leading: Icon(
                        category.isTopLevel
                            ? Icons.folder_outlined
                            : Icons.subdirectory_arrow_right_rounded,
                      ),
                      title: Text(category.name),
                      subtitle: Text(
                        [
                          _flowLabel(category.flowType),
                          if (parent != null) '上级：${parent.name}',
                          if (!category.isActive) '已停用',
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editCategory(context, ref, category),
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

  Future<void> _addCategory(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) async {
    final nameController = TextEditingController();
    var flowType = FlowType.expense;
    String? parentId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final parents = categories.where(
            (category) =>
                category.isTopLevel &&
                category.isActive &&
                category.flowType == flowType,
          );
          if (parentId != null &&
              !parents.any((category) => category.id == parentId)) {
            parentId = null;
          }
          return AlertDialog(
            title: const Text('新增分类'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: '分类名称'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FlowType>(
                    initialValue: flowType,
                    decoration: const InputDecoration(labelText: '性质'),
                    items: const [
                      DropdownMenuItem(
                        value: FlowType.expense,
                        child: Text('消费'),
                      ),
                      DropdownMenuItem(
                        value: FlowType.saving,
                        child: Text('存款'),
                      ),
                      DropdownMenuItem(
                        value: FlowType.investment,
                        child: Text('理财'),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      flowType = value!;
                      parentId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: ValueKey(flowType),
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
                    onChanged: (value) => setState(() => parentId = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('新增'),
              ),
            ],
          );
        },
      ),
    );
    final name = nameController.text.trim();
    nameController.dispose();
    if (confirmed != true || name.isEmpty) return;

    final siblings = categories.where(
      (category) => category.parentId == parentId,
    );
    final sortOrder =
        siblings.fold<int>(
          0,
          (highest, category) =>
              category.sortOrder > highest ? category.sortOrder : highest,
        ) +
        10;
    await ref
        .read(categoryRepositoryProvider)
        .add(
          Category(
            id: ref.read(idGeneratorProvider).next(),
            parentId: parentId,
            name: name,
            flowType: flowType,
            iconKey: 'category',
            sortOrder: sortOrder,
            isSystem: false,
          ),
        );
    ref
      ..invalidate(allCategoriesProvider)
      ..invalidate(activeCategoriesProvider);
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final controller = TextEditingController(text: category.name);
    var isActive = category.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 30,
                decoration: const InputDecoration(labelText: '分类名称'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('用于新流水'),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (confirmed != true || name.isEmpty) return;
    await ref
        .read(categoryRepositoryProvider)
        .updateNameAndState(id: category.id, name: name, isActive: isActive);
    ref
      ..invalidate(allCategoriesProvider)
      ..invalidate(activeCategoriesProvider);
  }
}

String _flowLabel(FlowType flowType) => switch (flowType) {
  FlowType.expense => '消费',
  FlowType.saving => '存款',
  FlowType.investment => '理财',
};
