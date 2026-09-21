import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/categories/data/category_repository.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/refund_policy.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';
import 'package:xinflow/features/transactions/domain/withdrawal_policy.dart';

final class UpdateAllocation {
  const UpdateAllocation({
    required this.categories,
    required this.salaryCycles,
    required this.transactions,
  });

  final CategoryRepository categories;
  final SalaryCycleRepository salaryCycles;
  final TransactionRepository transactions;

  Future<TransactionEntry> execute({
    required String transactionId,
    required int amountCents,
    required String categoryId,
    String? subcategoryId,
    required LocalDate occurredOn,
    String? note,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents', '金额必须大于 0。');
    }
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.length > 200) {
      throw ArgumentError.value(note, 'note', '备注不能超过 200 个字符。');
    }

    final current = await transactions.getById(transactionId);
    if (current == null || current.isDeleted) {
      throw StateError('要修改的流水不存在或已经删除。');
    }
    if (current.entryKind != EntryKind.allocation) {
      throw StateError('冲减记录不能通过普通流水入口修改。');
    }
    final activeCycle = await salaryCycles.getActiveCycle();
    if (activeCycle == null || activeCycle.id != current.salaryCycleId) {
      throw StateError('历史工资周期中的流水默认只读。');
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

    final updated = TransactionEntry(
      id: current.id,
      salaryCycleId: current.salaryCycleId,
      entryKind: current.entryKind,
      flowType: category.flowType,
      amountCents: amountCents,
      categoryId: category.id,
      subcategoryId: subcategoryId,
      occurredAt: current.occurredAt,
      occurredOn: occurredOn,
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    final refunds = await transactions.listRefundsFor(transactionId);
    final activeRefunds = refunds.where(
      (entry) => !entry.isDeleted && entry.entryKind == EntryKind.refund,
    );
    final activeWithdrawals = refunds.where(
      (entry) => !entry.isDeleted && entry.entryKind == EntryKind.withdrawal,
    );
    if (updated.flowType == FlowType.expense) {
      if (RefundPolicy.refundableCents(
            original: updated,
            existingRefunds: activeRefunds,
          ) <
          0) {
        throw const TransactionRuleViolation('修改后的消费金额不能小于累计退款金额。');
      }
    } else if (activeRefunds.isNotEmpty) {
      throw const TransactionRuleViolation('已有退款的消费流水不能改为存款或理财。');
    }
    if (updated.flowType != FlowType.expense) {
      if (WithdrawalPolicy.withdrawableCents(
            original: updated,
            existingWithdrawals: activeWithdrawals,
          ) <
          0) {
        throw const TransactionRuleViolation('修改后的金额不能小于累计提取金额。');
      }
    } else if (activeWithdrawals.isNotEmpty) {
      throw const TransactionRuleViolation('已有提取记录的流水不能改为消费。');
    }
    await transactions.update(updated);
    return updated;
  }
}
