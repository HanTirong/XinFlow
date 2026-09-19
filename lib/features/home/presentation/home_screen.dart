import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

typedef AddAllocationCallback = void Function([String? categoryId]);

final class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.snapshot,
    required this.onAddAllocation,
    super.key,
  });

  final HomeSnapshot snapshot;
  final AddAllocationCallback onAddAllocation;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList.list(
                children: [
                  _Header(snapshot: snapshot),
                  const SizedBox(height: 20),
                  _SalaryCard(snapshot: snapshot),
                  const SizedBox(height: 16),
                  _ShortcutCard(
                    shortcuts: snapshot.shortcuts,
                    onAddAllocation: onAddAllocation,
                  ),
                  const SizedBox(height: 16),
                  _RecentCard(entries: snapshot.recentTransactions),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _Header extends StatelessWidget {
  const _Header({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final start = snapshot.cycle.startedAt;
    final expected = snapshot.cycle.expectedPayDate;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                '当前工资周期：${start.month}月${start.day}日'
                ' - ${expected.month}月${expected.day}日',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '查看工资周期',
          onPressed: () => _showPendingMessage(context, '工资周期页面'),
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
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      '预览数据',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

final class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = snapshot.summary;
    final remaining = Money.fromCents(summary.remainingCents);
    final progress = summary.remainingRatio.clamp(0.0, 1.0).toDouble();
    final isDeficit = summary.remainingCents < 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [colors.surfaceContainerHigh, colors.surfaceContainer]
              : [const Color(0xFFF1F7FF), const Color(0xFFE4F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? colors.outlineVariant : const Color(0xFFDCEAFF),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeficit ? '本期工资已超出' : '本期工资剩余',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        remaining.format(),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: isDeficit
                                  ? colors.error
                                  : isDark
                                  ? colors.primary
                                  : AppColors.primaryDark,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox.square(
                dimension: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: colors.surfaceContainerHighest,
                      color: isDeficit ? colors.error : colors.primary,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(math.max(0, progress) * 100).round()}%',
                          maxLines: 1,
                          style: TextStyle(
                            color: isDark
                                ? colors.primary
                                : AppColors.primaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '剩余',
                          maxLines: 1,
                          style: TextStyle(
                            color: isDark
                                ? colors.primary
                                : AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: '本期工资',
                  value: Money.fromCents(summary.salaryCents).format(),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: '已分配',
                  value: Money.fromCents(summary.allocatedCents).format(),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: '距下次发薪',
                  value: '${snapshot.daysUntilPayday} 天',
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
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
}

final class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcuts, required this.onAddAllocation});

  final List<CategoryShortcut> shortcuts;
  final AddAllocationCallback onAddAllocation;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: '快速记一笔',
    trailing: TextButton(
      onPressed: () => _showPendingMessage(context, '快捷分类管理'),
      child: const Text('自定义'),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shortcuts.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth < 340 ? 3 : 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (context, index) => _ShortcutTile(
          shortcut: shortcuts[index],
          onTap: () => onAddAllocation(shortcuts[index].id),
        ),
      ),
    ),
  );
}

final class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut, required this.onTap});

  final CategoryShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appearance = _shortcutAppearance(context, shortcut.id);

    return Material(
      color: appearance.background,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(appearance.icon, color: appearance.foreground, size: 28),
              const SizedBox(height: 8),
              Text(
                shortcut.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.entries});

  final List<TransactionEntry> entries;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: '最近记录',
    trailing: TextButton(
      onPressed: () => _showPendingMessage(context, '流水页面'),
      child: const Text('全部记录'),
    ),
    child: Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _RecentRow(entry: entries[index]),
          if (index != entries.length - 1) const Divider(height: 20),
        ],
      ],
    ),
  );
}

final class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry});

  final TransactionEntry entry;

  @override
  Widget build(BuildContext context) {
    final appearance = _shortcutAppearance(context, entry.categoryId);
    final category = _categoryLabel(entry.categoryId);
    final time = entry.occurredAt;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: appearance.background,
          foregroundColor: appearance.foreground,
          child: Icon(appearance.icon, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                '${time.month}月${time.day}日 '
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Text(
          '- ${Money.fromCents(entry.amountCents).format()}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

final class _ShortcutAppearance {
  const _ShortcutAppearance({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}

_ShortcutAppearance _shortcutAppearance(BuildContext context, String id) {
  final base = switch (id) {
    DefaultCategoryIds.food || 'food' => const _ShortcutAppearance(
      icon: Icons.restaurant_rounded,
      foreground: Color(0xFFF97355),
      background: Color(0xFFFFF0EB),
    ),
    DefaultCategoryIds.shopping || 'shopping' => const _ShortcutAppearance(
      icon: Icons.shopping_bag_rounded,
      foreground: Color(0xFFE95786),
      background: Color(0xFFFFEDF3),
    ),
    DefaultCategoryIds.housing || 'housing' => const _ShortcutAppearance(
      icon: Icons.home_rounded,
      foreground: Color(0xFF3B82F6),
      background: Color(0xFFEDF5FF),
    ),
    DefaultCategoryIds.transport || 'transport' => const _ShortcutAppearance(
      icon: Icons.directions_bus_rounded,
      foreground: Color(0xFF0F9F6E),
      background: Color(0xFFECF9F4),
    ),
    DefaultCategoryIds.digital || 'digital' => const _ShortcutAppearance(
      icon: Icons.laptop_mac_rounded,
      foreground: Color(0xFF8B5CF6),
      background: Color(0xFFF3EFFF),
    ),
    DefaultCategoryIds.saving || 'saving' => const _ShortcutAppearance(
      icon: Icons.savings_rounded,
      foreground: Color(0xFFF59E0B),
      background: Color(0xFFFFF6E5),
    ),
    DefaultCategoryIds.investment || 'investment' => const _ShortcutAppearance(
      icon: Icons.bar_chart_rounded,
      foreground: Color(0xFF0891B2),
      background: Color(0xFFEAF9FC),
    ),
    _ => const _ShortcutAppearance(
      icon: Icons.more_horiz_rounded,
      foreground: Color(0xFF667085),
      background: Color(0xFFF1F3F6),
    ),
  };
  if (Theme.of(context).brightness != Brightness.dark) {
    return base;
  }
  final foreground = Color.lerp(base.foreground, Colors.white, 0.18)!;
  return _ShortcutAppearance(
    icon: base.icon,
    foreground: foreground,
    background: Color.alphaBlend(
      base.foreground.withAlpha(42),
      Theme.of(context).colorScheme.surfaceContainerHigh,
    ),
  );
}

String _categoryLabel(String id) => switch (id) {
  DefaultCategoryIds.food || 'food' => '饮食 / 外食',
  DefaultCategoryIds.shopping || 'shopping' => '购物 / 超市',
  DefaultCategoryIds.housing || 'housing' => '住房',
  DefaultCategoryIds.transport || 'transport' => '交通',
  DefaultCategoryIds.digital || 'digital' => '数字服务 / AI 软件',
  DefaultCategoryIds.saving || 'saving' => '存款',
  DefaultCategoryIds.investment || 'investment' => '理财',
  _ => '其他',
};

void _showPendingMessage(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$feature将在后续里程碑接入。')));
}
