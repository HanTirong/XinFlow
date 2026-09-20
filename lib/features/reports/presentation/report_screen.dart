import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/reports/domain/cycle_report.dart';
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
                  data: (value) =>
                      _ReportBody(report: value, categories: categories),
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
  const _ReportBody({required this.report, required this.categories});

  final CycleReport report;
  final List<Category> categories;

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
                  children: [
                    _ComparisonRow(
                      label: '工资',
                      current: summary.salaryCents,
                      previous: report.previousSummary!.salaryCents,
                    ),
                    _ComparisonRow(
                      label: '净消费',
                      current: summary.netExpenseCents,
                      previous: report.previousSummary!.netExpenseCents,
                    ),
                    _ComparisonRow(
                      label: '最终剩余',
                      current: summary.remainingCents,
                      previous: report.previousSummary!.remainingCents,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
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
            color: config.resolvedIconColor(context),
            backgroundColor: config.resolvedBackgroundColor(context),
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
  });

  final String label;
  final int current;
  final int previous;

  @override
  Widget build(BuildContext context) {
    final difference = current - previous;
    final sign = difference > 0 ? '+' : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('上期 ${Money.fromCents(previous).format()}'),
      trailing: Text(
        '$sign${Money.fromCents(difference).format()}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
