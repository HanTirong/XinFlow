import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';

final class SalaryEntrySheet extends ConsumerStatefulWidget {
  const SalaryEntrySheet({required this.cycle, super.key});

  final SalaryCycle cycle;

  @override
  ConsumerState<SalaryEntrySheet> createState() => _SalaryEntrySheetState();
}

final class _SalaryEntrySheetState extends ConsumerState<SalaryEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _salaryController;
  late final Future<int> _availableCarryover;
  bool _carryPositiveRemaining = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carryPositiveRemaining = widget.cycle.carryoverCents > 0;
    _salaryController = TextEditingController(
      text: widget.cycle.salaryPending
          ? ''
          : (widget.cycle.salaryCents / 100).toStringAsFixed(2),
    );
    _availableCarryover = ref
        .read(salaryEntryServiceProvider)
        .availableCarryover(widget.cycle.id);
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(salaryEntryServiceProvider)
          .saveAmount(
            cycleId: widget.cycle.id,
            salaryCents: Money.parse(_salaryController.text).cents,
            carryPositiveRemaining: _carryPositiveRemaining,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = '保存工资失败：$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.cycle.salaryPending ? '填写本期到账工资' : '修改本期工资',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                formatSalaryCycleRange(widget.cycle),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.cycle.salaryPending
                    ? '周期已按日期开始。工资尚未填写，可在实际到账后补记。'
                    : '修改金额会重新计算本期剩余。',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _salaryController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '到账工资',
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
                    Money.parse(value ?? '');
                    return null;
                  } on FormatException catch (error) {
                    return error.message;
                  }
                },
              ),
              FutureBuilder<int>(
                future: _availableCarryover,
                builder: (context, snapshot) {
                  final amount = snapshot.data ?? 0;
                  if (amount <= 0) return const SizedBox.shrink();
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('结转上期正余额'),
                    subtitle: Text('${Money.fromCents(amount).format()}，默认不结转'),
                    value: _carryPositiveRemaining,
                    onChanged: _isSaving
                        ? null
                        : (value) =>
                              setState(() => _carryPositiveRemaining = value),
                  );
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? '正在保存…' : '保存工资金额'),
              ),
              if (widget.cycle.salaryPending)
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('稍后填写'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
