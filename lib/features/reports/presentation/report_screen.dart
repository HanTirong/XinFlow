import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/reports/domain/cycle_report.dart';
import 'package:xinflow/features/reports/domain/cross_cycle_report.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';

final class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

final class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _selectedCycleId;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(salaryCyclesProvider);
    final categories = switch (ref.watch(allCategoriesProvider)) {
      AsyncData(:final value) => value,
      _ => const <Category>[],
    };

    return SafeArea(
      child: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('周期读取失败：$error')),
        data: (cycles) {
          if (cycles.isEmpty) return const Center(child: Text('还没有工资周期。'));
          final selected = cycles.firstWhere(
            (cycle) => cycle.id == _selectedCycleId,
            orElse: () => cycles.first,
          );
          final report = ref.watch(cycleReportProvider(selected.id));
          final crossCycle = ref.watch(crossCycleReportProvider).value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  '工资周期报告',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SalaryCycleSelector(
                  cycle: selected,
                  onTap: () => _chooseCycle(cycles, selected),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: report.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text('报告生成失败：$error')),
                  data: (value) => _ReportBody(
                    report: value,
                    categories: categories,
                    crossCycle: crossCycle,
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
    final cycleId = await showSalaryCyclePicker(
      context: context,
      cycles: cycles,
      selectedCycleId: selected.id,
    );
    if (cycleId != null && mounted) {
      setState(() => _selectedCycleId = cycleId);
    }
  }
}

final class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.categories,
    required this.crossCycle,
  });

  final CycleReport report;
  final List<Category> categories;
  final CrossCycleReport? crossCycle;

  @override
  Widget build(BuildContext context) {
    final summary = report.summary;
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final expenseEntries = report.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dailyEntries = report.dailyNetExpense.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.75,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _MetricCard(label: '工资', cents: summary.salaryCents),
            _MetricCard(label: '净消费', cents: summary.netExpenseCents),
            _MetricCard(label: '存款', cents: summary.savingCents),
            _MetricCard(label: '理财', cents: summary.investmentCents),
            _MetricCard(label: '最终剩余', cents: summary.remainingCents),
            _MetricCard(label: '已分配', cents: summary.allocatedCents),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: '消费分类占比',
          child: expenseEntries.isEmpty
              ? const Text('当前周期还没有消费记录。')
              : Column(
                  children: [
                    for (final entry in expenseEntries)
                      _CategoryBar(
                        config: CategoryVisuals.resolve(
                          categoryId: entry.key,
                          categories: categories,
                          fallbackName: categoryById[entry.key]?.name,
                        ),
                        cents: entry.value,
                        totalCents: summary.netExpenseCents,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '每日净消费趋势',
          child: dailyEntries.isEmpty
              ? const Text('当前周期还没有每日消费数据。')
              : Column(
                  children: [
                    _DailyTrendChart(entries: dailyEntries),
                    const SizedBox(height: 8),
                    for (final entry in dailyEntries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${entry.key.month}月${entry.key.day}日'),
                        trailing: Text(
                          Money.fromCents(entry.value).format(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '与上一周期对比',
          child: report.previousSummary == null
              ? const Text('没有更早的工资周期可供比较。')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '本期 ${_cycleRange(report.cycle)}\n'
                      '上期 ${_cycleRange(report.previousCycle!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ComparisonRow(
                      label: '工资',
                      current: summary.salaryCents,
                      previous: report.previousSummary!.salaryCents,
                    ),
                    _ComparisonRow(
                      label: '净消费',
                      current: summary.netExpenseCents,
                      previous: report.previousSummary!.netExpenseCents,
                      currentSalary: summary.salaryCents,
                      previousSalary: report.previousSummary!.salaryCents,
                    ),
                    _ComparisonRow(
                      label: '存款',
                      current: summary.savingCents,
                      previous: report.previousSummary!.savingCents,
                      currentSalary: summary.salaryCents,
                      previousSalary: report.previousSummary!.salaryCents,
                    ),
                    _ComparisonRow(
                      label: '理财',
                      current: summary.investmentCents,
                      previous: report.previousSummary!.investmentCents,
                      currentSalary: summary.salaryCents,
                      previousSalary: report.previousSummary!.salaryCents,
                    ),
                    _ComparisonRow(
                      label: '最终剩余',
                      current: summary.remainingCents,
                      previous: report.previousSummary!.remainingCents,
                      currentSalary: summary.salaryCents,
                      previousSalary: report.previousSummary!.salaryCents,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '跨周期趋势与平均值',
          child: crossCycle == null
              ? const LinearProgressIndicator()
              : crossCycle!.points.length < 2
              ? const Text('至少需要两个工资周期才能形成长期趋势。')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AverageChip(
                          label: '平均工资',
                          cents: crossCycle!.averageSalaryCents,
                        ),
                        _AverageChip(
                          label: '平均消费',
                          cents: crossCycle!.averageExpenseCents,
                        ),
                        _AverageChip(
                          label: '平均存款',
                          cents: crossCycle!.averageSavingCents,
                        ),
                        _AverageChip(
                          label: '平均理财',
                          cents: crossCycle!.averageInvestmentCents,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final point in crossCycle!.points.reversed.take(6))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_cycleRange(point.cycle)),
                        subtitle: Text(
                          '消费 ${Money.fromCents(point.summary.netExpenseCents).format()} · '
                          '存款 ${Money.fromCents(point.summary.savingCents).format()} · '
                          '理财 ${Money.fromCents(point.summary.investmentCents).format()}',
                        ),
                        trailing: Text(
                          Money.fromCents(point.summary.salaryCents).format(),
                        ),
                      ),
                    if (crossCycle!.categoryTrends.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        '长期消费分类变化',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final trend in crossCycle!.categoryTrends.take(5))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            categoryById[trend.categoryId]?.name ?? '其他',
                          ),
                          subtitle: Text(
                            '累计 ${Money.fromCents(trend.totalCents).format()}',
                          ),
                          trailing: Text(
                            '${trend.changeCents >= 0 ? '+' : '-'}'
                            '${Money.fromCents(trend.changeCents.abs()).format()}',
                            style: TextStyle(
                              color: trend.changeCents > 0
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

final class _AverageChip extends StatelessWidget {
  const _AverageChip({required this.label, required this.cents});

  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text('$label ${Money.fromCents(cents).format()}'));
}

final class _DailyTrendChart extends StatelessWidget {
  const _DailyTrendChart({required this.entries});

  final List<MapEntry<LocalDate, int>> entries;

  @override
  Widget build(BuildContext context) {
    final first = entries.first.key;
    final last = entries.last.key;
    return Semantics(
      label:
          '每日净消费趋势，共 ${entries.length} 天，'
          '从 ${first.month}月${first.day}日到 ${last.month}月${last.day}日',
      image: true,
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: CustomPaint(
          painter: _DailyTrendPainter(
            entries: entries,
            lineColor: Theme.of(context).colorScheme.primary,
            gridColor: Theme.of(context).colorScheme.outlineVariant,
            labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

final class _DailyTrendPainter extends CustomPainter {
  const _DailyTrendPainter({
    required this.entries,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<MapEntry<LocalDate, int>> entries;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 12.0;
    const bottom = 28.0;
    const horizontal = 8.0;
    final chartHeight = size.height - top - bottom;
    final values = entries.map((entry) => entry.value.toDouble()).toList();
    final minimum = math.min(0.0, values.reduce(math.min));
    final maximum = math.max(0.0, values.reduce(math.max));
    final span = math.max(1.0, maximum - minimum);
    double yFor(double value) => top + (maximum - value) / span * chartHeight;
    final zeroY = yFor(0);

    canvas.drawLine(
      Offset(horizontal, zeroY),
      Offset(size.width - horizontal, zeroY),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );

    final path = Path();
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : horizontal +
                index * (size.width - horizontal * 2) / (values.length - 1);
      final point = Offset(x, yFor(values[index]));
      points.add(point);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final pointPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    _paintLabel(
      canvas,
      '${entries.first.key.month}/${entries.first.key.day}',
      Offset(horizontal, size.height - 20),
      TextAlign.left,
    );
    if (entries.length > 1) {
      _paintLabel(
        canvas,
        '${entries.last.key.month}/${entries.last.key.day}',
        Offset(size.width - horizontal, size.height - 20),
        TextAlign.right,
      );
    }
  }

  void _paintLabel(Canvas canvas, String text, Offset anchor, TextAlign align) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    final dx = align == TextAlign.right ? anchor.dx - painter.width : anchor.dx;
    painter.paint(canvas, Offset(dx, anchor.dy));
  }

  @override
  bool shouldRepaint(covariant _DailyTrendPainter oldDelegate) =>
      oldDelegate.entries != entries ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor;
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.cents});

  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              Money.fromCents(cents).format(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

final class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.config,
    required this.cents,
    required this.totalCents,
  });

  final CategoryVisualConfig config;
  final int cents;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final ratio = totalCents <= 0 ? 0.0 : (cents / totalCents).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              CategoryIconBadge(config: config, size: 36, iconSize: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  config.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                Money.fromCents(cents).format(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ratio,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(
              context,
            ).progressIndicatorTheme.linearTrackColor,
          ),
        ],
      ),
    );
  }
}

final class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.previous,
    this.currentSalary,
    this.previousSalary,
  });

  final String label;
  final int current;
  final int previous;
  final int? currentSalary;
  final int? previousSalary;

  @override
  Widget build(BuildContext context) {
    final difference = current - previous;
    final sign = difference > 0 ? '+' : '';
    final ratioDifference = currentSalary == null || previousSalary == null
        ? null
        : _ratio(current, currentSalary!) - _ratio(previous, previousSalary!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('上期 ${Money.fromCents(previous).format()}'),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign${Money.fromCents(difference).format()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (ratioDifference != null)
            Text(
              '${ratioDifference >= 0 ? '+' : ''}'
              '${(ratioDifference * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

double _ratio(int cents, int salaryCents) =>
    salaryCents == 0 ? 0 : cents / salaryCents;

String _cycleRange(SalaryCycle cycle) {
  final start = LocalDate.fromDateTime(cycle.startedAt);
  return '$start ～ ${cycle.expectedPayDate}';
}
