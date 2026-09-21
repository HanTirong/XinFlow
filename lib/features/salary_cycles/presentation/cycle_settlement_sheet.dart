import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';

final class CycleSettlementSheet extends ConsumerStatefulWidget {
  const CycleSettlementSheet({
    required this.snapshot,
    required this.salaryDay,
    super.key,
  });

  final HomeSnapshot snapshot;
  final int salaryDay;

  @override
  ConsumerState<CycleSettlementSheet> createState() =>
      _CycleSettlementSheetState();
}

final class _CycleSettlementSheetState
    extends ConsumerState<CycleSettlementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _salaryController = TextEditingController();
  bool _isSaving = false;
  bool _carryPositiveRemaining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(closeAndStartNextCycleProvider)
          .execute(
            newSalaryCents: Money.parse(_salaryController.text).cents,
            salaryDay: widget.salaryDay,
            carryPositiveRemaining: _carryPositiveRemaining,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = '工资周期切换失败：$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.snapshot.summary;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('确认工资到账', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: '上期工资',
                          value: Money.fromCents(summary.salaryCents).format(),
                        ),
                        _SummaryRow(
                          label: '净消费',
                          value: Money.fromCents(
                            summary.netExpenseCents,
                          ).format(),
                        ),
                        _SummaryRow(
                          label: '存款与理财',
                          value: Money.fromCents(
                            summary.savingCents + summary.investmentCents,
                          ).format(),
                        ),
                        const Divider(),
                        _SummaryRow(
                          label: '上期最终剩余',
                          value: Money.fromCents(
                            summary.remainingCents,
                          ).format(),
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _salaryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '新到账工资',
                    prefixText: '¥ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (value) {
                    try {
                      return Money.parse(value ?? '').cents > 0
                          ? null
                          : '工资金额必须大于 0。';
                    } on FormatException catch (error) {
                      return error.message;
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (summary.remainingCents > 0)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('将上期正余额结转到新周期'),
                    subtitle: Text(
                      '结转 ${Money.fromCents(summary.remainingCents).format()}，默认不结转。',
                    ),
                    value: _carryPositiveRemaining,
                    onChanged: _isSaving
                        ? null
                        : (value) =>
                              setState(() => _carryPositiveRemaining = value),
                  ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _carryPositiveRemaining
                        ? '上期正余额将作为独立结转金额计入新周期，不会改写新到账工资。'
                        : '上期剩余不会自动计入新周期。旧周期会封存，新周期只以本次到账工资作为初始金额。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _confirm,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_rounded),
                  label: Text(_isSaving ? '正在切换…' : '确认并开始新周期'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: emphasized
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}
