import 'package:flutter/material.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/budgets/domain/budget.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/presentation/transaction_amount_formatter.dart';

typedef AddAllocationCallback = void Function([String? categoryId]);

final class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.snapshot,
    required this.onAddAllocation,
    required this.onSalaryReceived,
    required this.onBrowseCycles,
    required this.onEditCategories,
    required this.onViewAllTransactions,
    required this.onEditTransaction,
    this.hideAmounts = false,
    this.amountsRevealed = false,
    this.onToggleAmounts,
    this.budgetProgress = const [],
    this.backupReminderDue = false,
    this.categories = const [],
    super.key,
  });

  final HomeSnapshot snapshot;
  final AddAllocationCallback onAddAllocation;
  final VoidCallback onSalaryReceived;
  final VoidCallback onBrowseCycles;
  final VoidCallback onEditCategories;
  final VoidCallback onViewAllTransactions;
  final ValueChanged<TransactionEntry> onEditTransaction;
  final List<Category> categories;
  final bool hideAmounts;
  final bool amountsRevealed;
  final VoidCallback? onToggleAmounts;
  final List<BudgetProgress> budgetProgress;
  final bool backupReminderDue;

  @override
  Widget build(BuildContext context) {
    final configuredShortcuts = categories
        .where(
          (category) =>
              category.isTopLevel && category.isActive && category.showOnHome,
        )
        .map(
          (category) => CategoryShortcut(id: category.id, label: category.name),
        )
        .toList(growable: false);
    return _AmountPrivacy(
      hidden: hideAmounts && !amountsRevealed,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  sliver: SliverList.list(
                    children: [
                      _Header(
                        snapshot: snapshot,
                        onBrowseCycles: onBrowseCycles,
                        showPrivacyToggle: hideAmounts,
                        amountsRevealed: amountsRevealed,
                        onToggleAmounts: onToggleAmounts,
                      ),
                      const SizedBox(height: 18),
                      _SalaryCard(
                        snapshot: snapshot,
                        onSalaryReceived: onSalaryReceived,
                      ),
                      if (_reminders.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ReminderCard(messages: _reminders),
                      ],
                      const SizedBox(height: 14),
                      _ShortcutCard(
                        shortcuts: configuredShortcuts.isEmpty
                            ? snapshot.shortcuts
                            : configuredShortcuts,
                        categories: categories,
                        onAddAllocation: onAddAllocation,
                        onEditCategories: onEditCategories,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onAddAllocation,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('记一笔'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RecentCard(
                        entries: snapshot.recentTransactions,
                        categories: categories,
                        onViewAll: onViewAllTransactions,
                        onEdit: onEditTransaction,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _reminders {
    final messages = <String>[];
    if (snapshot.daysUntilPayday <= 3) {
      messages.add('距离预计发薪日还有 ${snapshot.daysUntilPayday} 天。');
    }
    if (backupReminderDue) {
      messages.add('本地备份已到提醒时间，建议导出一份加密备份。');
    }
    if (snapshot.summary.availableCents > 0 &&
        snapshot.summary.remainingRatio <= 0.1) {
      messages.add('本周期剩余不足可用金额的 10%，请留意后续支出。');
    }
    final unusuallyLarge = snapshot.recentTransactions.where(
      (entry) =>
          entry.flowType == FlowType.expense &&
          entry.entryKind == EntryKind.allocation &&
          entry.amountCents >= snapshot.summary.availableCents * 0.3,
    );
    if (unusuallyLarge.isNotEmpty) messages.add('检测到一笔较大消费，请确认记录是否准确。');
    for (final progress in budgetProgress.where(
      (item) => item.isNearLimit || item.isExceeded,
    )) {
      messages.add(progress.isExceeded ? '有一项预算已经超出上限。' : '有一项预算已使用超过 80%。');
    }
    return messages.toSet().toList(growable: false);
  }
}

final class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

final class _Header extends StatelessWidget {
  const _Header({
    required this.snapshot,
    required this.onBrowseCycles,
    required this.showPrivacyToggle,
    required this.amountsRevealed,
    required this.onToggleAmounts,
  });

  final HomeSnapshot snapshot;
  final VoidCallback onBrowseCycles;
  final bool showPrivacyToggle;
  final bool amountsRevealed;
  final VoidCallback? onToggleAmounts;

  @override
  Widget build(BuildContext context) {
    final start = snapshot.cycle.startedAt;
    final expected = snapshot.cycle.expectedPayDate;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('薪流', style: Theme.of(context).textTheme.headlineSmall),
                  if (snapshot.isPreview) ...[
                    const SizedBox(width: 8),
                    const _PreviewBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onBrowseCycles,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${start.month}月${start.day}日 - '
                        '${expected.month}月${expected.day}日',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: muted),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showPrivacyToggle)
          IconButton(
            tooltip: amountsRevealed ? '隐藏金额' : '临时显示金额',
            onPressed: onToggleAmounts,
            icon: Icon(
              amountsRevealed
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
          ),
        IconButton(
          tooltip: '查看工资周期',
          onPressed: onBrowseCycles,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ],
    );
  }
}

final class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      '预览数据',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

final class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.snapshot, required this.onSalaryReceived});

  final HomeSnapshot snapshot;
  final VoidCallback onSalaryReceived;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = snapshot.summary;
    final progress = summary.remainingRatio.clamp(0.0, 1.0).toDouble();
    final isDeficit = summary.remainingCents < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeficit ? '本期工资已超出' : '本期工资剩余',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _privateMoney(context, summary.remainingCents),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: isDeficit ? colors.error : colors.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onSalaryReceived,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '距离下次发薪',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${snapshot.daysUntilPayday}天',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              color: isDeficit ? colors.error : colors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: '本期工资',
                  value: _privateMoney(context, summary.salaryCents),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: '已记录',
                  value: _privateMoney(context, summary.allocatedCents),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: '剩余比例',
                  value: '${(progress * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FlowMetric(
                  categoryId: DefaultCategoryIds.food,
                  label: '净消费',
                  cents: summary.netExpenseCents,
                ),
              ),
              Expanded(
                child: _FlowMetric(
                  categoryId: DefaultCategoryIds.saving,
                  label: '存款',
                  cents: summary.savingCents,
                ),
              ),
              Expanded(
                child: _FlowMetric(
                  categoryId: DefaultCategoryIds.investment,
                  label: '理财',
                  cents: summary.investmentCents,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: Theme.of(context).textTheme.titleSmall),
      ),
    ],
  );
}

final class _FlowMetric extends StatelessWidget {
  const _FlowMetric({
    required this.categoryId,
    required this.label,
    required this.cents,
  });

  final String categoryId;
  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.resolve(categoryId: categoryId);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              visual.icon,
              size: 15,
              color: visual.resolvedIconColor(context),
            ),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _privateMoney(context, cents),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

final class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.shortcuts,
    required this.categories,
    required this.onAddAllocation,
    required this.onEditCategories,
  });

  final List<CategoryShortcut> shortcuts;
  final List<Category> categories;
  final AddAllocationCallback onAddAllocation;
  final VoidCallback onEditCategories;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: '快速记一笔',
    trailing: TextButton(
      onPressed: onEditCategories,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text('编辑分类'), Icon(Icons.chevron_right_rounded, size: 18)],
      ),
    ),
    child: GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shortcuts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) => _ShortcutTile(
        shortcut: shortcuts[index],
        categories: categories,
        onTap: () => onAddAllocation(shortcuts[index].id),
      ),
    ),
  );
}

final class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.shortcut,
    required this.categories,
    required this.onTap,
  });

  final CategoryShortcut shortcut;
  final List<Category> categories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = CategoryVisuals.resolve(
      categoryId: shortcut.id,
      categories: categories,
      fallbackName: shortcut.label,
    );
    return Material(
      color: config.resolvedBackgroundColor(context),
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                config.icon,
                color: config.resolvedIconColor(context),
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                shortcut.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.entries,
    required this.categories,
    required this.onViewAll,
    required this.onEdit,
  });

  final List<TransactionEntry> entries;
  final List<Category> categories;
  final VoidCallback onViewAll;
  final ValueChanged<TransactionEntry> onEdit;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: '最近记录',
    trailing: TextButton(
      onPressed: onViewAll,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text('全部记录'), Icon(Icons.chevron_right_rounded, size: 18)],
      ),
    ),
    child: entries.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              '还没有记录，先记下第一笔工资流向吧。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        : Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                _RecentRow(
                  entry: entries[index],
                  categories: categories,
                  onTap: entries[index].entryKind == EntryKind.allocation
                      ? () => onEdit(entries[index])
                      : null,
                ),
                if (index != entries.length - 1) const Divider(height: 18),
              ],
            ],
          ),
  );
}

final class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry, required this.categories, this.onTap});

  final TransactionEntry entry;
  final List<Category> categories;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final config = CategoryVisuals.resolve(
      categoryId: entry.categoryId,
      categories: categories,
      fallbackType: entry.flowType,
    );
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final time = entry.occurredAt;
    final detail = _entryDetail(entry, categoryById);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            CategoryIconBadge(config: config),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _AmountPrivacy.of(context)
                      ? '¥ ••••'
                      : formatTransactionAmount(entry),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${time.month}月${time.day}日 '
                  '${time.hour.toString().padLeft(2, '0')}:'
                  '${time.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _AmountPrivacy extends InheritedWidget {
  const _AmountPrivacy({required this.hidden, required super.child});

  final bool hidden;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AmountPrivacy>()?.hidden ??
      false;

  @override
  bool updateShouldNotify(_AmountPrivacy oldWidget) =>
      hidden != oldWidget.hidden;
}

String _privateMoney(BuildContext context, int cents) =>
    _AmountPrivacy.of(context) ? '¥ ••••' : Money.fromCents(cents).format();

final class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.trailing,
  });

  final String title;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            trailing,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

String _entryDetail(
  TransactionEntry entry,
  Map<String, Category> categoryById,
) {
  final subcategory = entry.subcategoryId == null
      ? null
      : categoryById[entry.subcategoryId!]?.name;
  final note = entry.note?.trim();
  if (subcategory != null && note != null && note.isNotEmpty) {
    return '$subcategory · $note';
  }
  if (subcategory != null) return subcategory;
  if (note != null && note.isNotEmpty) return note;
  return switch (entry.entryKind) {
    EntryKind.refund => '退款',
    EntryKind.withdrawal => '提取',
    EntryKind.allocation => '未填写备注',
  };
}
