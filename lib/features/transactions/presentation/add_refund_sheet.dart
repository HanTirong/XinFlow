import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class AddRefundSheet extends ConsumerStatefulWidget {
  const AddRefundSheet({required this.original, super.key});

  final TransactionEntry original;

  @override
  ConsumerState<AddRefundSheet> createState() => _AddRefundSheetState();
}

final class _AddRefundSheetState extends ConsumerState<AddRefundSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late final Future<int> _refundableCents;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refundableCents = ref
        .read(createRefundProvider)
        .refundableCents(widget.original.id);
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
        _errorMessage = '退款不能超过 ${Money.fromCents(maximumCents).format()}。';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(createRefundProvider)
          .execute(
            transactionId: widget.original.id,
            amountCents: amount,
            note: _noteController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = '退款保存失败：$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
    future: _refundableCents,
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
                  Text('记录退款', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    maximum == null
                        ? '正在计算可退款金额…'
                        : '原消费 ${Money.fromCents(widget.original.amountCents).format()}，'
                              '尚可退款 ${Money.fromCents(maximum).format()}。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '退款金额',
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
                            : '退款金额必须大于 0。';
                      } on FormatException catch (error) {
                        return error.message;
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: '退款备注（可选）',
                      prefixIcon: Icon(Icons.notes_rounded),
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
                    label: Text(_isSaving ? '正在保存…' : '确认退款'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
