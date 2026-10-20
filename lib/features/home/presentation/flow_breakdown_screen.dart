import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/home/domain/flow_breakdown.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class FlowBreakdownScreen extends ConsumerWidget {
  const FlowBreakdownScreen({
    required this.cycle,
    required this.flowType,
    required this.hideAmounts,
    super.key,
  });

  final SalaryCycle cycle;
  final FlowType flowType;
  final bool hideAmounts;

  String get _title => switch (flowType) {
    FlowType.expense => '净消费',
    FlowType.saving => '存款',
    FlowType.investment => '理财',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(cycleTransactionsProvider(cycle.id));
    final categories = ref.watch(allCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text('$_title明细')),
      body: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('明细读取失败：$error')),
        data: (entries) => categories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('分类读取失败：$error')),
          data: (items) => _BreakdownBody(
            cycle: cycle,
            title: _title,
            flowType: flowType,
            hideAmounts: hideAmounts,
            categories: items,
            breakdown: FlowBreakdown.calculate(
              flowType: flowType,
              transactions: entries,
              categories: items,
            ),
          ),
        ),
      ),
    );
  }
}

final class _BreakdownBody extends StatelessWidget {
  const _BreakdownBody({
    required this.cycle,
    required this.title,
    required this.flowType,
    required this.hideAmounts,
    required this.categories,
    required this.breakdown,
  });

  final SalaryCycle cycle;
  final String title;
  final FlowType flowType;
  final bool hideAmounts;
  final List<Category> categories;
  final FlowBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final flattened =
        flowType != FlowType.expense && breakdown.groups.length == 1;
    final chartValues = flattened
        ? breakdown.groups.first.children.map((item) => item.cents).toList()
        : breakdown.groups.map((group) => group.totalCents).toList();
    final chartIds = flattened
        ? breakdown.groups.first.children
              .map((item) => item.categoryId)
              .toList()
        : breakdown.groups.map((group) => group.categoryId).toList();
    final chartAvailable =
        !hideAmounts &&
        breakdown.totalCents > 0 &&
        chartValues.isNotEmpty &&
        chartValues.every((value) => value >= 0);
    final chartColors = [
      for (var index = 0; index < chartIds.length; index++)
        _visual(
          chartIds[index] ?? breakdown.groups.first.categoryId,
        ).resolvedIconColor(context),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('当前工资周期', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(
              formatSalaryCycleRange(cycle),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '本期$title',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 7),
                  FittedBox(
                    child: Text(
                      _money(breakdown.totalCents),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (chartAvailable) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 176,
                      height: 176,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          values: chartValues,
                          colors: chartColors,
                          trackColor: colors.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pie_chart_rounded,
                                color: colors.primary,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${chartValues.where((value) => value > 0).length} 类',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('分类构成', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (breakdown.groups.isEmpty)
              _emptyCard(context)
            else if (flattened)
              for (final item in breakdown.groups.first.children) ...[
                _BreakdownRow(
                  name: item.name,
                  cents: item.cents,
                  totalCents: breakdown.totalCents,
                  visual: _visual(
                    item.categoryId ?? breakdown.groups.first.categoryId,
                  ),
                  hideAmounts: hideAmounts,
                  showRatio: chartAvailable,
                ),
                const SizedBox(height: 9),
              ]
            else
              for (final group in breakdown.groups) ...[
                _GroupCard(
                  group: group,
                  categories: categories,
                  flowType: flowType,
                  totalCents: breakdown.totalCents,
                  hideAmounts: hideAmounts,
                  showRatio: chartAvailable,
                ),
                const SizedBox(height: 9),
              ],
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Text('本期还没有这类记录'),
  );

  String _money(int cents) =>
      hideAmounts ? '••••' : Money.fromCents(cents).format();

  CategoryVisualConfig _visual(String categoryId) => CategoryVisuals.resolve(
    categoryId: categoryId,
    categories: categories,
    fallbackType: flowType,
  );
}

final class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.categories,
    required this.flowType,
    required this.totalCents,
    required this.hideAmounts,
    required this.showRatio,
  });

  final FlowBreakdownGroup group;
  final List<Category> categories;
  final FlowType flowType;
  final int totalCents;
  final bool hideAmounts;
  final bool showRatio;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.resolve(
      categoryId: group.categoryId,
      categories: categories,
      fallbackType: flowType,
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: _BreakdownRow(
          name: group.name,
          cents: group.totalCents,
          totalCents: totalCents,
          visual: visual,
          hideAmounts: hideAmounts,
          showRatio: showRatio,
          embedded: true,
        ),
        children: [
          const Divider(),
          for (final child in group.children)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _BreakdownRow(
                name: child.name,
                cents: child.cents,
                totalCents: group.totalCents,
                visual: CategoryVisuals.resolve(
                  categoryId: child.categoryId ?? group.categoryId,
                  categories: categories,
                  fallbackType: flowType,
                ),
                hideAmounts: hideAmounts,
                showRatio:
                    showRatio &&
                    group.totalCents > 0 &&
                    group.children.every((item) => item.cents >= 0),
                embedded: true,
                compact: true,
              ),
            ),
        ],
      ),
    );
  }
}

final class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.name,
    required this.cents,
    required this.totalCents,
    required this.visual,
    required this.hideAmounts,
    required this.showRatio,
    this.embedded = false,
    this.compact = false,
  });

  final String name;
  final int cents;
  final int totalCents;
  final CategoryVisualConfig visual;
  final bool hideAmounts;
  final bool showRatio;
  final bool embedded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = visual.resolvedIconColor(context);
    final ratio = showRatio && totalCents > 0 ? cents / totalCents : 0.0;
    return Container(
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(14),
      decoration: embedded
          ? null
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 42,
            height: compact ? 34 : 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(visual.icon, color: color, size: compact ? 19 : 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.titleSmall,
                ),
                if (showRatio) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0).toDouble(),
                      minHeight: 5,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hideAmounts ? '••••' : Money.fromCents(cents).format(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (showRatio)
                Text(
                  '${(ratio * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  final List<int> values;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor);
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = math.pi * 2 * values[i] / total;
      canvas.drawArc(rect, start, sweep, false, paint..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.trackColor != trackColor;
}
