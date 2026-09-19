import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/date/payday_calculator.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/domain/cycle_transition.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';

final class NoActiveSalaryCycle implements Exception {
  const NoActiveSalaryCycle();

  @override
  String toString() => '没有可以封存的活动工资周期。';
}

final class CloseAndStartNextCycle {
  const CloseAndStartNextCycle({
    required this.salaryCycles,
    required this.transactions,
    required this.clock,
    required this.idGenerator,
  });

  final SalaryCycleRepository salaryCycles;
  final TransactionRepository transactions;
  final Clock clock;
  final IdGenerator idGenerator;

  Future<CycleTransition> execute({
    required int newSalaryCents,
    required int salaryDay,
  }) async {
    final activeCycle = await salaryCycles.getActiveCycle();
    if (activeCycle == null) {
      throw const NoActiveSalaryCycle();
    }

    final entries = await transactions.listCycleTransactions(activeCycle.id);
    final summary = SalarySummary.fromTransactions(
      salaryCents: activeCycle.salaryCents,
      transactions: entries,
    );
    final confirmedAt = clock.now();
    final confirmedDate = LocalDate.fromDateTime(confirmedAt);
    final transition = SalaryCyclePolicy.closeAndStartNext(
      currentCycle: activeCycle,
      currentSummary: summary,
      newCycleId: idGenerator.next(),
      newSalaryCents: newSalaryCents,
      confirmedAt: confirmedAt,
      nextExpectedPayDate: PaydayCalculator.forNextCycle(
        confirmedDate: confirmedDate,
        salaryDay: salaryDay,
      ),
    );

    await salaryCycles.replaceActiveCycle(
      closedCycle: transition.closedCycle,
      newActiveCycle: transition.newActiveCycle,
    );
    return transition;
  }
}
