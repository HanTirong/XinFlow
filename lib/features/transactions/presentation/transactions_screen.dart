import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/categories/presentation/category_visual_config.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/presentation/transaction_amount_formatter.dart';

typedef EditAllocationCallback = void Function(TransactionEntry entry);
typedef AddHistoricalAllocationCallback = void Function(SalaryCycle cycle);
typedef EditHistoricalAllocationCallback =
    void Function(SalaryCycle cycle, TransactionEntry entry);

enum _FlowFilter { all, expense, saving, investment }

final class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    required this.onAdd,
    required this.onEdit,
    required this.onAddHistorical,
    required this.onEditHistorical,
    super.key,
  });

  final VoidCallback onAdd;
  final EditAllocationCallback onEdit;
  final AddHistoricalAllocationCallback onAddHistorical;
  final EditHistoricalAllocationCallback onEditHistorical;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

final class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _FlowFilter _filter = _FlowFilter.all;
  String? _selectedCycleId;
  String? _correctionCycleId;
  DateTimeRange? _dateRange;
  String? _categoryId;
  String _keyword = '';
  int? _minimumCents;
  int? _maximumCents;
  int _page = 1;

  static const _pageSize = 50;

  @override
  Widget build(BuildContext context) {
    final cycles = switch (ref.watch(salaryCyclesProvider)) {
      AsyncData(:final value) => value,
      _ => const <SalaryCycle>[],
    };
    final selectedCycle = cycles.isEmpty
        ? null
        : cycles.firstWhere(
            (cycle) => cycle.id == _selectedCycleId,
            orElse: () => cycles.first,
          );
    final transactions = selectedCycle == null
        ? const AsyncValue<List<TransactionEntry>>.data([])
        : ref.watch(cycleTransactionsProvider(selectedCycle.id));
    final categories = switch (ref.watch(allCategoriesProvider)) {
      AsyncData(:final value) => value,
      _ => const <Category>[],
    };
    final isClosed = selectedCycle?.status == SalaryCycleStatus.closed;
    final isCorrecting = isClosed && _correctionCycleId == selectedCycle?.id;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              selectedCycle?.status == SalaryCycleStatus.closed
                  ? isCorrecting
                        ? '修正历史周期'
                        : '历史周期流水'
                  : '当前周期流水',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<_FlowFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _FlowFilter.all, label: Text('全部')),
                ButtonSegment(value: _FlowFilter.expense, label: Text('消费')),
                ButtonSegment(value: _FlowFilter.saving, label: Text('存款')),
                ButtonSegment(value: _FlowFilter.investment, label: Text('理财')),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) =>
                  setState(() => _filter = selection.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAdvancedFilters(categories),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(_hasAdvancedFilters ? '高级筛选（已启用）' : '高级筛选'),
                ),
                if (_hasAdvancedFilters) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearAdvancedFilters,
                    child: const Text('清除'),
                  ),
                ],
              ],
            ),
          ),
          if (cycles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SalaryCycleSelector(
                cycle: selectedCycle!,
                onTap: () => _chooseCycle(cycles, selectedCycle),
              ),
            ),
          if (isClosed)
            _HistoryCorrectionBanner(
              isCorrecting: isCorrecting,
              onEnable: () => _enableCorrection(selectedCycle!),
              onDisable: () => setState(() => _correctionCycleId = null),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: transactions.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => _LoadError(
                      error: error,
                      onRetry: selectedCycle == null
                          ? () => ref.invalidate(salaryCyclesProvider)
                          : () => ref.invalidate(
                              cycleTransactionsProvider(selectedCycle.id),
                            ),
                    ),
                    data: (entries) {
                      final allFiltered = _filtered(entries);
                      return _TransactionList(
                        entries: allFiltered
                            .take(_page * _pageSize)
                            .toList(growable: false),
                        categories: categories,
                        hasMore: allFiltered.length > _page * _pageSize,
                        onLoadMore: () => setState(() => _page++),
                        onEdit:
                            selectedCycle?.status == SalaryCycleStatus.active
                            ? widget.onEdit
                            : isCorrecting
                            ? (entry) =>
                                  widget.onEditHistorical(selectedCycle!, entry)
                            : null,
                      );
                    },
                  ),
                ),
                if (selectedCycle != null && (!isClosed || isCorrecting))
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: FloatingActionButton.extended(
                      onPressed: isCorrecting
                          ? () => widget.onAddHistorical(selectedCycle)
                          : widget.onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(isCorrecting ? '补记流水' : '记一笔'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionEntry> _filtered(List<TransactionEntry> entries) {
    final result = entries
        .where((entry) {
          final type = switch (_filter) {
            _FlowFilter.all => null,
            _FlowFilter.expense => FlowType.expense,
            _FlowFilter.saving => FlowType.saving,
            _FlowFilter.investment => FlowType.investment,
          };
          if (type != null && entry.flowType != type) return false;
          if (_categoryId != null && entry.categoryId != _categoryId) {
            return false;
          }
          if (_keyword.isNotEmpty &&
              !(entry.note ?? '').toLowerCase().contains(
                _keyword.toLowerCase(),
              )) {
            return false;
          }
          if (_minimumCents != null && entry.amountCents < _minimumCents!) {
            return false;
          }
          if (_maximumCents != null && entry.amountCents > _maximumCents!) {
            return false;
          }
          if (_dateRange != null) {
            final start = LocalDate.fromDateTime(_dateRange!.start);
            final end = LocalDate.fromDateTime(_dateRange!.end);
            if (entry.occurredOn.compareTo(start) < 0 ||
                entry.occurredOn.compareTo(end) > 0) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
    result.sort((a, b) {
      final dateOrder = b.occurredOn.compareTo(a.occurredOn);
      return dateOrder != 0 ? dateOrder : b.occurredAt.compareTo(a.occurredAt);
    });
    return result;
  }

  bool get _hasAdvancedFilters =>
      _dateRange != null ||
      _categoryId != null ||
      _keyword.isNotEmpty ||
      _minimumCents != null ||
      _maximumCents != null;

  void _clearAdvancedFilters() => setState(() {
    _dateRange = null;
    _categoryId = null;
    _keyword = '';
    _minimumCents = null;
    _maximumCents = null;
    _page = 1;
  });

  Future<void> _showAdvancedFilters(List<Category> categories) async {
    var keyword = _keyword;
    var minimum = _minimumCents == null
        ? ''
        : (_minimumCents! / 100).toStringAsFixed(2);
    var maximum = _maximumCents == null
        ? ''
        : (_maximumCents! / 100).toStringAsFixed(2);
    var categoryId = _categoryId;
    var range = _dateRange;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('高级筛选'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.date_range_rounded),
                  title: const Text('日期范围'),
                  subtitle: Text(
                    range == null
                        ? '不限'
                        : '${LocalDate.fromDateTime(range!.start)} ～ ${LocalDate.fromDateTime(range!.end)}',
                  ),
                  onTap: () async {
                    final selected = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: range,
                    );
                    if (selected != null) {
                      setDialogState(() => range = selected);
                    }
                  },
                  trailing: range == null
                      ? null
                      : IconButton(
                          onPressed: () => setDialogState(() => range = null),
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: '一级分类'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部分类')),
                    for (final category in categories.where(
                      (item) => item.isTopLevel,
                    ))
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => categoryId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: keyword,
                  onChanged: (value) => keyword = value,
                  decoration: const InputDecoration(
                    labelText: '备注关键词',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: minimum,
                        onChanged: (value) => minimum = value,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: '最低金额'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: maximum,
                        onChanged: (value) => maximum = value,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: '最高金额'),
                      ),
                    ),
                  ],
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
              child: const Text('应用'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        final minimumCents = _parseOptionalMoney(minimum);
        final maximumCents = _parseOptionalMoney(maximum);
        if (minimumCents != null &&
            maximumCents != null &&
            minimumCents > maximumCents) {
          throw const FormatException('最低金额不能高于最高金额。');
        }
        setState(() {
          _dateRange = range;
          _categoryId = categoryId;
          _keyword = keyword.trim();
          _minimumCents = minimumCents;
          _maximumCents = maximumCents;
          _page = 1;
        });
      } on FormatException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('金额筛选无效：${error.message}')));
        }
      }
    }
  }

  int? _parseOptionalMoney(String input) =>
      input.trim().isEmpty ? null : Money.parse(input).cents;

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
      setState(() {
        _selectedCycleId = cycleId;
        _correctionCycleId = null;
      });
    }
  }

  Future<void> _enableCorrection(SalaryCycle cycle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('进入历史修正模式？'),
        content: const Text(
          '修正历史流水会重新计算该周期的最终余额，但不会改变当前周期。'
          '所有修改都会保留软删除或关联退款记录。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('进入修正'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _correctionCycleId = cycle.id);
    }
  }
}

final class _HistoryCorrectionBanner extends StatelessWidget {
  const _HistoryCorrectionBanner({
    required this.isCorrecting,
    required this.onEnable,
    required this.onDisable,
  });

  final bool isCorrecting;
  final VoidCallback onEnable;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Icon(
              isCorrecting ? Icons.edit_note_rounded : Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCorrecting ? '历史修正模式已开启' : '历史周期默认只读',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: isCorrecting ? onDisable : onEnable,
              child: Text(isCorrecting ? '完成' : '修正历史周期'),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.entries,
    required this.categories,
    required this.onEdit,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<TransactionEntry> entries;
  final List<Category> categories;
  final EditAllocationCallback? onEdit;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState();
    }
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: entries.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: OutlinedButton(
                onPressed: onLoadMore,
                child: const Text('加载更多'),
              ),
            ),
          );
        }
        final entry = entries[index];
        final showDate =
            index == 0 || entries[index - 1].occurredOn != entry.occurredOn;
        final category = categoryById[entry.categoryId];
        final subcategory = entry.subcategoryId == null
            ? null
            : categoryById[entry.subcategoryId];
        final visual = CategoryVisuals.resolve(
          categoryId: entry.categoryId,
          categories: categories,
          fallbackName: category?.name,
          fallbackType: entry.flowType,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) ...[
              if (index != 0) const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                child: Text(
                  '${entry.occurredOn.month}月${entry.occurredOn.day}日',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: entry.entryKind == EntryKind.allocation && onEdit != null
                    ? () => onEdit!(entry)
                    : null,
                leading: CategoryIconBadge(config: visual),
                title: Text(
                  visual.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  [
                        if (subcategory != null) subcategory.name,
                        if (entry.note != null) entry.note!,
                      ].isEmpty
                      ? _flowLabel(entry.flowType)
                      : [
                          if (subcategory != null) subcategory.name,
                          if (entry.note != null) entry.note!,
                        ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTransactionAmount(entry),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: entry.entryKind != EntryKind.allocation
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    if (entry.entryKind == EntryKind.allocation &&
                        onEdit != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text('还没有流水', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('点击右下角“记一笔”开始记录。'),
        ],
      ),
    ),
  );
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('流水加载失败'),
        const SizedBox(height: 8),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}

String _flowLabel(FlowType flowType) => switch (flowType) {
  FlowType.expense => '消费',
  FlowType.saving => '存款',
  FlowType.investment => '理财',
};
