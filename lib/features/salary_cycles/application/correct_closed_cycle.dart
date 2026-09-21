import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/categories/data/category_repository.dart';
import 'package:xinflow/features/salary_cycles/data/closed_cycle_correction_repository.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/domain/withdrawal_policy.dart';

final class CorrectClosedCycle {
  const CorrectClosedCycle({
    required this.categories,
    required this.repository,
    required this.clock,
    required this.idGenerator,
  });

  final CategoryRepository categories;
  final ClosedCycleCorrectionRepository repository;
  final Clock clock;
  final IdGenerator idGenerator;

  Future<int> refundableCents(String transactionId) async {
    final original = await _loadAllocation(transactionId);
    return RefundPolicy.refundableCents(
      original: original,
      existingRefunds: await repository.listRefundsFor(transactionId),
    );
  }

  Future<int> withdrawableCents(String transactionId) async {
    final original = await _loadAllocation(transactionId);
    return WithdrawalPolicy.withdrawableCents(
      original: original,
      existingWithdrawals: await repository.listRefundsFor(transactionId),
    );
  }

  Future<TransactionEntry> createAllocation({
    required String cycleId,
    required int amountCents,
    required String categoryId,
    String? subcategoryId,
    required LocalDate occurredOn,
    String? note,
  }) async {
    _validateAmount(amountCents);
    final trimmedNote = _validateNote(note);
    final category = await _validateCategory(categoryId, subcategoryId);
    final now = clock.now();
    final entry = TransactionEntry(
      id: idGenerator.next(),
      salaryCycleId: cycleId,
      entryKind: EntryKind.allocation,
      flowType: category.$1,
      amountCents: amountCents,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      occurredAt: now,
      occurredOn: occurredOn,
      note: trimmedNote,
    );
    await repository.insertAndRecalculate(entry);
    return entry;
  }

  Future<TransactionEntry> updateAllocation({
    required String transactionId,
    required int amountCents,
    required String categoryId,
    String? subcategoryId,
    required LocalDate occurredOn,
    String? note,
  }) async {
    _validateAmount(amountCents);
    final current = await _loadAllocation(transactionId);
    final trimmedNote = _validateNote(note);
    final category = await _validateCategory(categoryId, subcategoryId);
    final updated = TransactionEntry(
      id: current.id,
      salaryCycleId: current.salaryCycleId,
      entryKind: current.entryKind,
      flowType: category.$1,
      amountCents: amountCents,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      occurredAt: current.occurredAt,
      occurredOn: occurredOn,
      note: trimmedNote,
    );
    await repository.updateAllocationAndRecalculate(updated);
    return updated;
  }

  Future<void> deleteAllocation(String transactionId) async {
    await _loadAllocation(transactionId);
    await repository.softDeleteAllocationGroupAndRecalculate(
      transactionId: transactionId,
      deletedAt: clock.now(),
    );
  }

  Future<TransactionEntry> createRefund({
    required String transactionId,
    required int amountCents,
    required LocalDate occurredOn,
    String? note,
  }) async {
    _validateAmount(amountCents);
    final original = await _loadAllocation(transactionId);
    RefundPolicy.ensureCanRefund(
      original: original,
      existingRefunds: await repository.listRefundsFor(transactionId),
      refundCents: amountCents,
    );
    final trimmedNote = _validateNote(note);
    final now = clock.now();
    final refund = TransactionEntry(
      id: idGenerator.next(),
      salaryCycleId: original.salaryCycleId,
      entryKind: EntryKind.refund,
      flowType: FlowType.expense,
      amountCents: amountCents,
      categoryId: original.categoryId,
      subcategoryId: original.subcategoryId,
      reversesTransactionId: original.id,
      occurredAt: now,
      occurredOn: occurredOn,
      note: trimmedNote,
    );
    await repository.insertAndRecalculate(refund);
    return refund;
  }

  Future<TransactionEntry> createWithdrawal({
    required String transactionId,
    required int amountCents,
    required LocalDate occurredOn,
    String? note,
  }) async {
    _validateAmount(amountCents);
    final original = await _loadAllocation(transactionId);
    WithdrawalPolicy.ensureCanWithdraw(
      original: original,
      existingWithdrawals: await repository.listRefundsFor(transactionId),
      withdrawalCents: amountCents,
    );
    final now = clock.now();
    final withdrawal = TransactionEntry(
      id: idGenerator.next(),
      salaryCycleId: original.salaryCycleId,
      entryKind: EntryKind.withdrawal,
      flowType: original.flowType,
      amountCents: amountCents,
      categoryId: original.categoryId,
      subcategoryId: original.subcategoryId,
      reversesTransactionId: original.id,
      occurredAt: now,
      occurredOn: occurredOn,
      note: _validateNote(note),
    );
    await repository.insertAndRecalculate(withdrawal);
    return withdrawal;
  }

  Future<TransactionEntry> _loadAllocation(String transactionId) async {
    final entry = await repository.getTransaction(transactionId);
    if (entry == null || entry.isDeleted) {
      throw StateError('要修正的历史流水不存在或已经删除。');
    }
    if (entry.entryKind != EntryKind.allocation) {
      throw StateError('冲减记录不能通过普通流水入口修改。');
    }
    return entry;
  }

  Future<(FlowType, String?)> _validateCategory(
    String categoryId,
    String? subcategoryId,
  ) async {
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
    return (category.flowType, subcategoryId);
  }

  void _validateAmount(int amountCents) {
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents', '金额必须大于 0。');
    }
  }

  String? _validateNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed != null && trimmed.length > 200) {
      throw ArgumentError.value(note, 'note', '备注不能超过 200 个字符。');
    }
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
