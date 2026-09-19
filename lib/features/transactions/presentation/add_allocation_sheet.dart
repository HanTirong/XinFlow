import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/categories/domain/category.dart';

final class AddAllocationSheet extends ConsumerStatefulWidget {
  const AddAllocationSheet({this.initialCategoryId, super.key});

  final String? initialCategoryId;

  @override
  ConsumerState<AddAllocationSheet> createState() => _AddAllocationSheetState();
}

final class _AddAllocationSheetState extends ConsumerState<AddAllocationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _categoryId;
  String? _subcategoryId;
  late LocalDate _occurredOn;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _occurredOn = LocalDate.fromDateTime(ref.read(clockProvider).now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initial = DateTime(
      _occurredOn.year,
      _occurredOn.month,
      _occurredOn.day,
    );
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected != null && mounted) {
      setState(() => _occurredOn = LocalDate.fromDateTime(selected));
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _errorMessage = '请选择一级分类。');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(createAllocationProvider)
          .execute(
            amountCents: Money.parse(_amountController.text).cents,
            categoryId: _categoryId!,
            subcategoryId: _subcategoryId,
            occurredOn: _occurredOn,
            note: _noteController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = switch (error) {
          FormatException(:final message) => message,
          ArgumentError(:final message) => message?.toString(),
          _ => '保存失败，请稍后重试。',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(activeCategoriesProvider);
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
                Text('记一笔', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '金额',
                    prefixText: '¥ ',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (value) {
                    try {
                      final amount = Money.parse(value ?? '');
                      return amount.cents > 0 ? null : '金额必须大于 0。';
                    } on FormatException catch (error) {
                      return error.message;
                    }
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 18),
                Text('分类', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                categories.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text('分类读取失败：$error'),
                  data: _buildCategoryFields,
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: const Text('日期与备注'),
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('记账日期'),
                      subtitle: Text(_occurredOn.toString()),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _selectDate,
                    ),
                    TextFormField(
                      controller: _noteController,
                      maxLength: 200,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '备注（可选）',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
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
                  onPressed: _isSaving || categories.isLoading ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? '正在保存…' : '保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFields(List<Category> categories) {
    final topLevel = categories.where((category) => category.isTopLevel);
    final children = categories.where(
      (category) => category.parentId == _categoryId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in topLevel)
              ChoiceChip(
                label: Text(category.name),
                selected: _categoryId == category.id,
                onSelected: (_) => setState(() {
                  _categoryId = category.id;
                  _subcategoryId = null;
                  _errorMessage = null;
                }),
              ),
          ],
        ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            initialValue: _subcategoryId,
            decoration: const InputDecoration(labelText: '二级分类（可选）'),
            items: [
              const DropdownMenuItem(value: null, child: Text('不选择')),
              for (final category in children)
                DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: (value) => setState(() => _subcategoryId = value),
          ),
        ],
      ],
    );
  }
}
