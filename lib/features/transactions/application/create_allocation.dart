import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/categories/data/category_repository.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class CreateAllocation {
  const CreateAllocation({
    required this.categories,
    required this.salaryCycles,
    required this.transactions,
    required this.clock,
    required this.idGenerator,
  });

  final CategoryRepository categories;
  final SalaryCycleRepository salaryCycles;
  final TransactionRepository transactions;
  final Clock clock;
  final IdGenerator idGenerator;

  Future<TransactionEntry> execute({
    required int amountCents,
    required String categoryId,
    String? subcategoryId,
    LocalDate? occurredOn,
    String? note,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents', '金额必须大于 0。');
    }
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.length > 200) {
      throw ArgumentError.value(note, 'note', '备注不能超过 200 个字符。');
    }

    final cycle = await salaryCycles.getActiveCycle();
    if (cycle == null) {
      throw StateError('当前没有可记账的工资周期。');
    }
    final category = await categories.getById(categoryId);
    if (category == null || !category.isTopLevel) {
      throw ArgumentError.value(categoryId, 'categoryId', '请选择有效的一级分类。');
    }

    if (subcategoryId != null) {
      final subcategory = await categories.getById(subcategoryId);
      if (subcategory == null ||
          subcategory.parentId != category.id ||
          subcategory.flowType != category.flowType) {
        throw ArgumentError.value(
          subcategoryId,
          'subcategoryId',
          '二级分类与一级分类不匹配。',
        );
      }
    }

    final now = clock.now();
    final entry = TransactionEntry(
      id: idGenerator.next(),
      salaryCycleId: cycle.id,
      entryKind: EntryKind.allocation,
      flowType: category.flowType,
      amountCents: amountCents,
      categoryId: category.id,
      subcategoryId: subcategoryId,
      occurredAt: now,
      occurredOn: occurredOn ?? LocalDate.fromDateTime(now),
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    await transactions.add(entry);
    return entry;
  }
}
