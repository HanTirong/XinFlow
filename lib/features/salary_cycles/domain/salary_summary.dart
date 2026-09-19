import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class SalarySummary {
  const SalarySummary({
    required this.salaryCents,
    required this.expenseAllocatedCents,
    required this.expenseRefundedCents,
    required this.savingCents,
    required this.investmentCents,
  });

  factory SalarySummary.fromTransactions({
    required int salaryCents,
    required Iterable<TransactionEntry> transactions,
  }) {
    if (salaryCents < 0) {
      throw ArgumentError.value(salaryCents, 'salaryCents');
    }

    var expenseAllocatedCents = 0;
    var expenseRefundedCents = 0;
    var savingCents = 0;
    var investmentCents = 0;

    for (final entry in transactions.where((entry) => !entry.isDeleted)) {
      if (entry.entryKind == EntryKind.refund) {
        expenseRefundedCents += entry.amountCents;
        continue;
      }

      switch (entry.flowType) {
        case FlowType.expense:
          expenseAllocatedCents += entry.amountCents;
        case FlowType.saving:
          savingCents += entry.amountCents;
        case FlowType.investment:
          investmentCents += entry.amountCents;
      }
    }

    return SalarySummary(
      salaryCents: salaryCents,
      expenseAllocatedCents: expenseAllocatedCents,
      expenseRefundedCents: expenseRefundedCents,
      savingCents: savingCents,
      investmentCents: investmentCents,
    );
  }

  final int salaryCents;
  final int expenseAllocatedCents;
  final int expenseRefundedCents;
  final int savingCents;
  final int investmentCents;

  int get netExpenseCents => expenseAllocatedCents - expenseRefundedCents;

  int get allocatedCents => netExpenseCents + savingCents + investmentCents;

  int get remainingCents => salaryCents - allocatedCents;

  double get remainingRatio =>
      salaryCents == 0 ? 0 : remainingCents / salaryCents;
}
