import 'package:flutter/material.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';

Future<String?> showSalaryCyclePicker({
  required BuildContext context,
  required List<SalaryCycle> cycles,
  required String selectedCycleId,
}) {
  if (cycles.isEmpty) return Future.value();
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (context) => _SalaryCyclePickerSheet(
      cycles: cycles,
      selectedCycleId: selectedCycleId,
    ),
  );
}

String formatSalaryCycleRange(SalaryCycle cycle) {
  final start = LocalDate.fromDateTime(cycle.startedAt);
  return '$start ～ ${cycle.expectedPayDate}';
}

final class SalaryCycleSelector extends StatelessWidget {
  const SalaryCycleSelector({
    required this.cycle,
    required this.onTap,
    this.showStatus = true,
    super.key,
  });

  final SalaryCycle cycle;
  final VoidCallback onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showStatus)
                    Text(
                      cycle.status == SalaryCycleStatus.active
                          ? '当前工资周期'
                          : '历史工资周期',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    formatSalaryCycleRange(cycle),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    ),
  );
}

final class _SalaryCyclePickerSheet extends StatefulWidget {
  const _SalaryCyclePickerSheet({
    required this.cycles,
    required this.selectedCycleId,
  });

  final List<SalaryCycle> cycles;
  final String selectedCycleId;

  @override
  State<_SalaryCyclePickerSheet> createState() =>
      _SalaryCyclePickerSheetState();
}

final class _SalaryCyclePickerSheetState
    extends State<_SalaryCyclePickerSheet> {
  late int _selectedIndex;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    final index = widget.cycles.indexWhere(
      (cycle) => cycle.id == widget.selectedCycleId,
    );
    _selectedIndex = index < 0 ? 0 : index;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      heightFactor: 0.56,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '选择工资周期',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: 58,
                    physics: const FixedExtentScrollPhysics(),
                    diameterRatio: 1.6,
                    perspective: 0.002,
                    onSelectedItemChanged: (index) =>
                        setState(() => _selectedIndex = index),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.cycles.length,
                      builder: (context, index) {
                        final selected = index == _selectedIndex;
                        return Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  color: selected
                                      ? colors.onPrimaryContainer
                                      : colors.onSurfaceVariant.withAlpha(125),
                                  fontSize: selected ? 17 : 15,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                            child: Text(
                              formatSalaryCycleRange(widget.cycles[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(widget.cycles[_selectedIndex].id),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
}
