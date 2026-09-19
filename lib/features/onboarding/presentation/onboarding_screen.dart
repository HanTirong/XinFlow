import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/core/money/money.dart';

typedef OnboardingSubmit =
    Future<void> Function({required int salaryDay, required int salaryCents});

final class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onSubmit, super.key});

  final OnboardingSubmit onSubmit;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaryDayController = TextEditingController(text: '15');
  final _salaryController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _salaryDayController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final salary = Money.parse(_salaryController.text);
      await widget.onSubmit(
        salaryDay: int.parse(_salaryDayController.text),
        salaryCents: salary.cents,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = switch (error) {
          FormatException(:final message) => message,
          _ => '保存失败，请检查输入后重试。',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: 36),
                  Text(
                    '建立第一个工资周期',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '这些信息只保存在你的设备中。发薪日仅用于预计日期，不会自动切换工资周期。',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _salaryDayController,
                    decoration: const InputDecoration(
                      labelText: '固定发薪日',
                      hintText: '1 - 31',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final day = int.tryParse(value ?? '');
                      if (day == null || day < 1 || day > 31) {
                        return '请输入 1 至 31 之间的日期。';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(
                      labelText: '本期到账工资',
                      hintText: '例如 8500.00',
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
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.warning),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(_isSubmitting ? '正在保存…' : '开始记录工资流向'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      const SizedBox(width: 14),
      Text('薪流', style: Theme.of(context).textTheme.headlineSmall),
    ],
  );
}
