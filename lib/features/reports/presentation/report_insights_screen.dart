import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/reports/domain/cycle_report.dart';
import 'package:xinflow/features/reports/domain/cross_cycle_report.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

enum ReportInsightTab { comparison, trends }

final class ReportInsightsScreen extends ConsumerStatefulWidget {
  const ReportInsightsScreen({
    required this.report,
    required this.hideAmounts,
    required this.initialTab,
    super.key,
  });

  final CycleReport report;
  final bool hideAmounts;
  final ReportInsightTab initialTab;

  @override
  ConsumerState<ReportInsightsScreen> createState() =>
      _ReportInsightsScreenState();
}

final class _ReportInsightsScreenState
    extends ConsumerState<ReportInsightsScreen> {
  late ReportInsightTab tab;
  FlowType flowType = FlowType.expense;

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报告分析')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              SegmentedButton<ReportInsightTab>(
                segments: const [
                  ButtonSegment(
                    value: ReportInsightTab.comparison,
                    label: Text('上期对比'),
                  ),
                  ButtonSegment(
                    value: ReportInsightTab.trends,
                    label: Text('长期趋势'),
                  ),
                ],
                selected: {tab},
                onSelectionChanged: (selection) =>
                    setState(() => tab = selection.first),
              ),
              const SizedBox(height: 18),
              if (tab == ReportInsightTab.comparison)
                _Comparison(
                  report: widget.report,
                  hideAmounts: widget.hideAmounts,
                )
              else
                ref
                    .watch(crossCycleReportProvider)
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('趋势读取失败：$error')),
                      data: (trend) => _Trends(
                        report: widget.report,
                        trend: trend,
                        hideAmounts: widget.hideAmounts,
                        flowType: flowType,
                        onFlowChanged: (type) =>
                            setState(() => flowType = type),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Comparison extends StatelessWidget {
  const _Comparison({required this.report, required this.hideAmounts});

  final CycleReport report;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final previous = report.previousSummary;
    if (previous == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: Text('尚无可比较的上一工资周期')),
      );
    }
    final current = report.summary;
    final values = [
      ('工资', current.salaryCents, previous.salaryCents),
      ('净消费', current.netExpenseCents, previous.netExpenseCents),
      ('存款', current.savingCents, previous.savingCents),
      ('理财', current.investmentCents, previous.investmentCents),
      ('最终剩余', current.remainingCents, previous.remainingCents),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('两期对比', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          '本期 ${formatSalaryCycleRange(report.cycle)}\n'
          '上期 ${formatSalaryCycleRange(report.previousCycle!)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 15),
        for (final item in values) ...[
          _ComparisonCard(
            label: item.$1,
            current: item.$2,
            previous: item.$3,
            hideAmounts: hideAmounts,
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

final class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.label,
    required this.current,
    required this.previous,
    required this.hideAmounts,
  });

  final String label;
  final int current;
  final int previous;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final max = current > previous ? current : previous;
    final canChart = !hideAmounts && current >= 0 && previous >= 0 && max > 0;
    final difference = current - previous;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                hideAmounts
                    ? '••••'
                    : '${difference > 0 ? '+' : ''}${Money.fromCents(difference).format()}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ValueBar(
            label: '本期',
            value: current,
            max: max,
            color: colors.primary,
            hideAmounts: hideAmounts,
            canChart: canChart,
          ),
          const SizedBox(height: 6),
          _ValueBar(
            label: '上期',
            value: previous,
            max: max,
            color: colors.onSurfaceVariant,
            hideAmounts: hideAmounts,
            canChart: canChart,
          ),
        ],
      ),
    );
  }
}

final class _ValueBar extends StatelessWidget {
  const _ValueBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.hideAmounts,
    required this.canChart,
  });

  final String label;
  final int value;
  final int max;
  final Color color;
  final bool hideAmounts;
  final bool canChart;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 36,
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: canChart ? value / max : 0,
            minHeight: 7,
            color: color,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 78,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(hideAmounts ? '••••' : Money.fromCents(value).format()),
        ),
      ),
    ],
  );
}

final class _Trends extends StatelessWidget {
  const _Trends({
    required this.report,
    required this.trend,
    required this.hideAmounts,
    required this.flowType,
    required this.onFlowChanged,
  });

  final CycleReport report;
  final CrossCycleReport trend;
  final bool hideAmounts;
  final FlowType flowType;
  final ValueChanged<FlowType> onFlowChanged;

  @override
  Widget build(BuildContext context) {
    final points = trend.points.reversed.take(6).toList().reversed.toList();
    final values = [for (final point in points) _value(point.summary)];
    final positive = values.where((value) => value > 0);
    final max = positive.isEmpty ? 0 : positive.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('近六个工资周期', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 11),
        Wrap(
          spacing: 7,
          children: [
            for (final type in FlowType.values)
              ChoiceChip(
                label: Text(switch (type) {
                  FlowType.expense => '净消费',
                  FlowType.saving => '存款',
                  FlowType.investment => '理财',
                }),
                selected: flowType == type,
                onSelected: (_) => onFlowChanged(type),
              ),
          ],
        ),
        const SizedBox(height: 11),
        if (points.length < 2)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('至少两个已确认工资的周期才能形成趋势')),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (var i = 0; i < points.length; i++) ...[
                  if (i > 0) const SizedBox(height: 13),
                  Row(
                    children: [
                      SizedBox(
                        width: 57,
                        child: Text(
                          '${points[i].cycle.startedAt.year % 100}/'
                          '${points[i].cycle.startedAt.month}/'
                          '${points[i].cycle.startedAt.day}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: hideAmounts || max <= 0 || values[i] < 0
                                ? 0
                                : values[i] / max,
                            minHeight: 12,
                            color: points[i].cycle.id == report.cycle.id
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            hideAmounts
                                ? '••••'
                                : Money.fromCents(values[i]).format(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '选中的工资周期以品牌色标记；负向净值只显示金额，不参与柱形占比。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  int _value(SalarySummary summary) => switch (flowType) {
    FlowType.expense => summary.netExpenseCents,
    FlowType.saving => summary.savingCents,
    FlowType.investment => summary.investmentCents,
  };
}
