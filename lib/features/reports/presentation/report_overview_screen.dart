import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/home/presentation/flow_breakdown_screen.dart';
import 'package:xinflow/features/reports/domain/cycle_report.dart';
import 'package:xinflow/features/reports/presentation/report_insights_screen.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    this.hideAmounts = false,
    this.showPrivacyToggle = false,
    this.onToggleAmounts,
    super.key,
  });

  final bool hideAmounts;
  final bool showPrivacyToggle;
  final VoidCallback? onToggleAmounts;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

final class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _selectedCycleId;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(salaryCyclesProvider);
    final categories =
        ref.watch(allCategoriesProvider).value ?? const <Category>[];
    return SafeArea(
      child: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('周期读取失败：$error')),
        data: (cycles) {
          if (cycles.isEmpty) return const Center(child: Text('还没有工资周期。'));
          final ordered = [...cycles]
            ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
          final selectedIndex = _selectedCycleId == null
              ? ordered.indexWhere(
                  (cycle) => cycle.status == SalaryCycleStatus.active,
                )
              : ordered.indexWhere((cycle) => cycle.id == _selectedCycleId);
          final index = selectedIndex < 0 ? ordered.length - 1 : selectedIndex;
          final selected = ordered[index];
          final report = ref.watch(cycleReportProvider(selected.id));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '工资周期报告',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (widget.showPrivacyToggle)
                      IconButton(
                        tooltip: widget.hideAmounts ? '临时显示金额' : '隐藏金额',
                        onPressed: widget.onToggleAmounts,
                        icon: Icon(
                          widget.hideAmounts
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                  ],
                ),
              ),
              _CycleStrip(
                cycles: ordered,
                selectedIndex: index,
                onSelect: (cycle) =>
                    setState(() => _selectedCycleId = cycle.id),
                onAllCycles: () => _chooseCycle(ordered, selected),
              ),
              Expanded(
                child: report.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('报告生成失败：$error')),
                  data: (value) => _OverviewBody(
                    report: value,
                    categories: categories,
                    hideAmounts: widget.hideAmounts,
                    onViewCategories: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FlowBreakdownScreen(
                          cycle: selected,
                          flowType: FlowType.expense,
                          hideAmounts: widget.hideAmounts,
                        ),
                      ),
                    ),
                    onViewComparison: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReportInsightsScreen(
                          report: value,
                          hideAmounts: widget.hideAmounts,
                          initialTab: ReportInsightTab.comparison,
                        ),
                      ),
                    ),
                    onViewTrends: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReportInsightsScreen(
                          report: value,
                          hideAmounts: widget.hideAmounts,
                          initialTab: ReportInsightTab.trends,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _chooseCycle(
    List<SalaryCycle> cycles,
    SalaryCycle selected,
  ) async {
    final id = await showSalaryCyclePicker(
      context: context,
      cycles: cycles.reversed.toList(),
      selectedCycleId: selected.id,
    );
    if (id != null && mounted) setState(() => _selectedCycleId = id);
  }
}

final class _CycleStrip extends StatelessWidget {
  const _CycleStrip({
    required this.cycles,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAllCycles,
  });

  final List<SalaryCycle> cycles;
  final int selectedIndex;
  final ValueChanged<SalaryCycle> onSelect;
  final VoidCallback onAllCycles;

  @override
  Widget build(BuildContext context) {
    final selected = cycles[selectedIndex];
    final first = math.max(0, math.min(selectedIndex - 1, cycles.length - 3));
    final last = math.min(cycles.length, first + 3);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = first; i < last; i++) ...[
                if (i > first) const SizedBox(width: 7),
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(cycles[i]),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: i == selectedIndex
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${cycles[i].startedAt.month}/${cycles[i].startedAt.day}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            '～${cycles[i].expectedPayDate.previousDay.month}/${cycles[i].expectedPayDate.previousDay.day}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${selected.status == SalaryCycleStatus.active ? '当前' : '历史'} · ${formatSalaryCycleRange(selected)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(onPressed: onAllCycles, child: const Text('全部周期')),
            ],
          ),
        ],
      ),
    );
  }
}

final class _OverviewBody extends StatelessWidget {
  const _OverviewBody({
    required this.report,
    required this.categories,
    required this.hideAmounts,
    required this.onViewCategories,
    required this.onViewComparison,
    required this.onViewTrends,
  });

  final CycleReport report;
  final List<Category> categories;
  final bool hideAmounts;
  final VoidCallback onViewCategories;
  final VoidCallback onViewComparison;
  final VoidCallback onViewTrends;

  @override
  Widget build(BuildContext context) {
    final topCategories = report.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = topCategories.take(3).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        _OverviewCard(
          summary: report.summary,
          salaryPending: report.cycle.salaryPending,
          hideAmounts: hideAmounts,
        ),
        const SizedBox(height: 12),
        _Panel(
          title: '每日净消费',
          trailing: '点选日期查看',
          child: report.dailyNetExpense.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(child: Text('本期还没有消费记录')),
                )
              : hideAmounts
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(child: Text('金额已隐藏')),
                )
              : _DailyBarChart(report: report),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: '主要消费分类',
          trailing: '查看明细 ›',
          onTap: onViewCategories,
          child: visible.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('本期还没有消费分类')),
                )
              : Column(
                  children: [
                    for (final entry in visible)
                      _CategoryRow(
                        categoryId: entry.key,
                        cents: entry.value,
                        maxCents: visible.first.value,
                        categories: categories,
                        hideAmounts: hideAmounts,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onViewComparison,
                child: const Text('与上一周期对比'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton(
                onPressed: onViewTrends,
                child: const Text('长期趋势'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.summary,
    required this.salaryPending,
    required this.hideAmounts,
  });

  final SalarySummary summary;
  final bool salaryPending;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final values = [
      summary.netExpenseCents,
      summary.savingCents,
      summary.investmentCents,
      summary.remainingCents,
    ];
    final segmentColors = [
      CategoryVisuals.resolve(
        categoryId: DefaultCategoryIds.food,
      ).resolvedIconColor(context),
      CategoryVisuals.resolve(
        categoryId: DefaultCategoryIds.saving,
      ).resolvedIconColor(context),
      CategoryVisuals.resolve(
        categoryId: DefaultCategoryIds.investment,
      ).resolvedIconColor(context),
      colors.primary,
    ];
    final canChart =
        !salaryPending &&
        !hideAmounts &&
        summary.availableCents > 0 &&
        values.every((value) => value >= 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
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
                      '本期最终剩余',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        salaryPending
                            ? '待填写工资'
                            : _money(summary.remainingCents, hideAmounts),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: summary.remainingCents < 0
                                  ? colors.error
                                  : colors.primary,
                            ),
                      ),
                    ),
                    if (summary.carryoverCents > 0 && !hideAmounts)
                      Text(
                        '含结转 ${Money.fromCents(summary.carryoverCents).format()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (canChart)
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: values,
                      colors: segmentColors,
                      trackColor: colors.surfaceContainerHighest,
                    ),
                  ),
                ),
            ],
          ),
          if (salaryPending || (!canChart && !hideAmounts)) ...[
            const SizedBox(height: 10),
            Text(
              salaryPending ? '填写工资后展示工资去向占比' : '存在负向净值，工资去向不显示占比图',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: segmentColors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              ['净消费', '存款', '理财'][i],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money(values[i], hideAmounts),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
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
      ..strokeWidth = 12;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor);
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = math.pi * 2 * values[i] / total;
      if (sweep > 0) {
        canvas.drawArc(rect, start, sweep, false, paint..color = colors[i]);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.trackColor != trackColor;
}

final class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.trailing,
    required this.child,
    this.onTap,
  });

  final String title;
  final String trailing;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (onTap == null)
              Text(trailing, style: Theme.of(context).textTheme.bodySmall)
            else
              TextButton(onPressed: onTap, child: Text(trailing)),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

final class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.cents,
    required this.maxCents,
    required this.categories,
    required this.hideAmounts,
  });

  final String categoryId;
  final int cents;
  final int maxCents;
  final List<Category> categories;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.resolve(
      categoryId: categoryId,
      categories: categories,
    );
    final color = visual.resolvedIconColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              visual.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: hideAmounts || maxCents <= 0 ? 0 : cents / maxCents,
                minHeight: 6,
                color: color,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(_money(cents, hideAmounts)),
            ),
          ),
        ],
      ),
    );
  }
}

final class _DailyBarChart extends StatefulWidget {
  const _DailyBarChart({required this.report});

  final CycleReport report;

  @override
  State<_DailyBarChart> createState() => _DailyBarChartState();
}

final class _DailyBarChartState extends State<_DailyBarChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final start = LocalDate.fromDateTime(widget.report.cycle.startedAt).asUtc;
    final end = widget.report.cycle.expectedPayDate.previousDay.asUtc;
    final days = <LocalDate>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      days.add(LocalDate.fromDateTime(day));
    }
    if (days.isEmpty) return const Text('周期日期尚未设置');
    final values = [
      for (final day in days) widget.report.dailyNetExpense[day] ?? 0,
    ];
    final picked = selectedIndex != null && selectedIndex! < days.length
        ? selectedIndex
        : null;
    return Column(
      children: [
        SizedBox(
          height: 19,
          child: Text(
            picked == null
                ? '点击柱形查看当日金额'
                : '${days[picked].month}月${days[picked].day}日  ${Money.fromCents(values[picked]).format()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapDown: (details) => setState(() {
              selectedIndex =
                  (details.localPosition.dx /
                          constraints.maxWidth *
                          days.length)
                      .floor()
                      .clamp(0, days.length - 1);
            }),
            child: Semantics(
              label:
                  '每日净消费柱形图，从${days.first.month}月${days.first.day}日到${days.last.month}月${days.last.day}日',
              image: true,
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(
                  painter: _DailyBarPainter(
                    values: values,
                    selectedIndex: picked,
                    color: Theme.of(context).colorScheme.primary,
                    selectedColor: CategoryVisuals.resolve(
                      categoryId: DefaultCategoryIds.food,
                    ).resolvedIconColor(context),
                    trackColor: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${days.first.month}/${days.first.day}'),
            Text('${days.last.month}/${days.last.day}'),
          ],
        ),
      ],
    );
  }
}

final class _DailyBarPainter extends CustomPainter {
  const _DailyBarPainter({
    required this.values,
    required this.selectedIndex,
    required this.color,
    required this.selectedColor,
    required this.trackColor,
  });

  final List<int> values;
  final int? selectedIndex;
  final Color color;
  final Color selectedColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final highest = math.max(0, values.reduce(math.max));
    final lowest = math.min(0, values.reduce(math.min));
    final span = math.max(1, highest - lowest);
    final zeroY = 8 + highest / span * (size.height - 16);
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = trackColor
        ..strokeWidth = 1,
    );
    final slot = size.width / values.length;
    final barWidth = math.max(2.0, slot * 0.58);
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final y = zeroY - values[i] / span * (size.height - 16);
      final rect = Rect.fromLTWH(
        i * slot + (slot - barWidth) / 2,
        math.min(y, zeroY),
        barWidth,
        math.max(2, (y - zeroY).abs()),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = i == selectedIndex ? selectedColor : color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DailyBarPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.color != color ||
      oldDelegate.selectedColor != selectedColor ||
      oldDelegate.trackColor != trackColor;
}

String _money(int cents, bool hidden) =>
    hidden ? '••••' : Money.fromCents(cents).format();
