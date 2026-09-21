import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class SalarySummary {
  const SalarySummary({
    required this.salaryCents,
    this.carryoverCents = 0,
    required this.expenseAllocatedCents,
    required this.expenseRefundedCents,
    required this.savingCents,
    required this.investmentCents,
  });

  factory SalarySummary.fromTransactions({
    required int salaryCents,
    int carryoverCents = 0,
    required Iterable<TransactionEntry> transactions,
  }) {
    if (salaryCents < 0 || carryoverCents < 0) {
      throw ArgumentError.value(salaryCents, 'salaryCents');
    }

    var expenseAllocatedCents = 0;
    var expenseRefundedCents = 0;
    var savingCents = 0;
    var investmentCents = 0;
    var savingWithdrawnCents = 0;
    var investmentWithdrawnCents = 0;

    for (final entry in transactions.where((entry) => !entry.isDeleted)) {
      if (entry.entryKind == EntryKind.refund) {
        expenseRefundedCents += entry.amountCents;
        continue;
      }
      if (entry.entryKind == EntryKind.withdrawal) {
        if (entry.flowType == FlowType.saving) {
          savingWithdrawnCents += entry.amountCents;
        } else if (entry.flowType == FlowType.investment) {
          investmentWithdrawnCents += entry.amountCents;
        }
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
      carryoverCents: carryoverCents,
      expenseAllocatedCents: expenseAllocatedCents,
      expenseRefundedCents: expenseRefundedCents,
      savingCents: savingCents - savingWithdrawnCents,
      investmentCents: investmentCents - investmentWithdrawnCents,
    );
  }

  final int salaryCents;
  final int carryoverCents;
  final int expenseAllocatedCents;
  final int expenseRefundedCents;
  final int savingCents;
  final int investmentCents;

  int get netExpenseCents => expenseAllocatedCents - expenseRefundedCents;

  int get allocatedCents => netExpenseCents + savingCents + investmentCents;

  int get availableCents => salaryCents + carryoverCents;

  int get remainingCents => availableCents - allocatedCents;

  double get remainingRatio =>
      availableCents == 0 ? 0 : remainingCents / availableCents;
}
