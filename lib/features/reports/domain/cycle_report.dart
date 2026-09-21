import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class CycleReport {
  const CycleReport({
    required this.cycle,
    required this.summary,
    required this.expenseByCategory,
    required this.dailyNetExpense,
    this.previousCycle,
    this.previousSummary,
  }) : assert(
         (previousCycle == null) == (previousSummary == null),
         'Previous cycle and summary must be provided together.',
       );

  factory CycleReport.fromData({
    required SalaryCycle cycle,
    required Iterable<TransactionEntry> transactions,
    SalaryCycle? previousCycle,
    SalarySummary? previousSummary,
  }) {
    final active = transactions.where((entry) => !entry.isDeleted).toList();
    final categoryTotals = <String, int>{};
    final dailyTotals = <LocalDate, int>{};
    for (final entry in active.where(
      (entry) => entry.flowType == FlowType.expense,
    )) {
      final sign = entry.entryKind == EntryKind.refund ? -1 : 1;
      categoryTotals.update(
        entry.categoryId,
        (value) => value + sign * entry.amountCents,
        ifAbsent: () => sign * entry.amountCents,
      );
      dailyTotals.update(
        entry.occurredOn,
        (value) => value + sign * entry.amountCents,
        ifAbsent: () => sign * entry.amountCents,
      );
    }
    categoryTotals.removeWhere((key, value) => value <= 0);

    return CycleReport(
      cycle: cycle,
      summary: SalarySummary.fromTransactions(
        salaryCents: cycle.salaryCents,
        carryoverCents: cycle.carryoverCents,
        transactions: active,
      ),
      expenseByCategory: Map.unmodifiable(categoryTotals),
      dailyNetExpense: Map.unmodifiable(dailyTotals),
      previousCycle: previousCycle,
      previousSummary: previousSummary,
    );
  }

  final SalaryCycle cycle;
  final SalarySummary summary;
  final Map<String, int> expenseByCategory;
  final Map<LocalDate, int> dailyNetExpense;
  final SalaryCycle? previousCycle;
  final SalarySummary? previousSummary;
}
