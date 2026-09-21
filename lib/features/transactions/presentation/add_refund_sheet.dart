import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class AddRefundSheet extends ConsumerStatefulWidget {
  const AddRefundSheet({
    required this.original,
    this.historicalCycle,
    super.key,
  });

  final TransactionEntry original;
  final SalaryCycle? historicalCycle;

  @override
  ConsumerState<AddRefundSheet> createState() => _AddRefundSheetState();
}

final class _AddRefundSheetState extends ConsumerState<AddRefundSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late final Future<int> _reversibleCents;
  late LocalDate _occurredOn;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _occurredOn = widget.original.occurredOn;
    final isRefund = widget.original.flowType == FlowType.expense;
    _reversibleCents = widget.historicalCycle == null
        ? isRefund
              ? ref
                    .read(createRefundProvider)
                    .refundableCents(widget.original.id)
              : ref
                    .read(createWithdrawalProvider)
                    .withdrawableCents(widget.original.id)
        : isRefund
        ? ref
              .read(correctClosedCycleProvider)
              .refundableCents(widget.original.id)
        : ref
              .read(correctClosedCycleProvider)
              .withdrawableCents(widget.original.id);
  }

  Future<void> _selectDate() async {
    final cycle = widget.historicalCycle!;
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(
        _occurredOn.year,
        _occurredOn.month,
        _occurredOn.day,
      ),
      firstDate: DateTime(
        cycle.startedAt.year,
        cycle.startedAt.month,
        cycle.startedAt.day,
      ),
      lastDate: DateTime(
        cycle.expectedPayDate.year,
        cycle.expectedPayDate.month,
        cycle.expectedPayDate.day,
      ).subtract(const Duration(days: 1)),
    );
    if (selected != null && mounted) {
      setState(() => _occurredOn = LocalDate.fromDateTime(selected));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save(int maximumCents) async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final amount = Money.parse(_amountController.text).cents;
    if (amount > maximumCents) {
      setState(() {
        _errorMessage =
            '$_actionName不能超过 ${Money.fromCents(maximumCents).format()}。';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      if (widget.historicalCycle == null && _isRefund) {
        await ref
            .read(createRefundProvider)
            .execute(
              transactionId: widget.original.id,
              amountCents: amount,
              note: _noteController.text,
            );
      } else if (widget.historicalCycle == null) {
        await ref
            .read(createWithdrawalProvider)
            .execute(
              transactionId: widget.original.id,
              amountCents: amount,
              note: _noteController.text,
            );
      } else if (_isRefund) {
        await ref
            .read(correctClosedCycleProvider)
            .createRefund(
              transactionId: widget.original.id,
              amountCents: amount,
              occurredOn: _occurredOn,
              note: _noteController.text,
            );
      } else {
        await ref
            .read(correctClosedCycleProvider)
            .createWithdrawal(
              transactionId: widget.original.id,
              amountCents: amount,
              occurredOn: _occurredOn,
              note: _noteController.text,
            );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = '$_actionName保存失败：$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
    future: _reversibleCents,
    builder: (context, snapshot) {
      final maximum = snapshot.data;
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
                  Text(
                    widget.historicalCycle == null
                        ? '记录$_actionName'
                        : '补记历史$_actionName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    maximum == null
                        ? '正在计算可$_actionName金额…'
                        : '原$_sourceName ${Money.fromCents(widget.original.amountCents).format()}，'
                              '尚可$_actionName ${Money.fromCents(maximum).format()}。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.historicalCycle != null) ...[
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text('$_actionName日期'),
                      subtitle: Text(_occurredOn.toString()),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _selectDate,
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: '$_actionName金额',
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
                            : '$_actionName金额必须大于 0。';
                      } on FormatException catch (error) {
                        return error.message;
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: '$_actionName备注（可选）',
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: maximum == null || maximum <= 0 || _isSaving
                        ? null
                        : () => _save(maximum),
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.currency_exchange_rounded),
                    label: Text(_isSaving ? '正在保存…' : '确认$_actionName'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  bool get _isRefund => widget.original.flowType == FlowType.expense;

  String get _actionName => _isRefund ? '退款' : '提取';

  String get _sourceName => switch (widget.original.flowType) {
    FlowType.expense => '消费',
    FlowType.saving => '存款',
    FlowType.investment => '理财',
  };
}
