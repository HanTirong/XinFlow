import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';

final class CycleTransition {
  const CycleTransition({
    required this.closedCycle,
    required this.newActiveCycle,
  });

  final SalaryCycle closedCycle;
  final SalaryCycle newActiveCycle;
}

final class SalaryCyclePolicy {
  const SalaryCyclePolicy._();

  /// Closes [currentCycle] and creates the next salary pool. Positive remaining
  /// money is only included when [carryPositiveRemaining] is explicitly true.
  static CycleTransition closeAndStartNext({
    required SalaryCycle currentCycle,
    required SalarySummary currentSummary,
    required String newCycleId,
    required int newSalaryCents,
    required DateTime confirmedAt,
    required DateTime newCycleStartedAt,
    required LocalDate nextExpectedPayDate,
    bool carryPositiveRemaining = false,
  }) {
    if (currentCycle.status != SalaryCycleStatus.active) {
      throw StateError('当前工资周期已经封存。');
    }
    if (newCycleId.isEmpty) {
      throw ArgumentError.value(newCycleId, 'newCycleId', '新周期 ID 不能为空。');
    }
    if (newCycleId == currentCycle.id) {
      throw ArgumentError.value(newCycleId, 'newCycleId', '新旧周期 ID 不能相同。');
    }
    if (currentSummary.salaryCents != currentCycle.salaryCents) {
      throw ArgumentError('周期工资与汇总工资不一致。');
    }
    if (newSalaryCents < 0) {
      throw ArgumentError.value(newSalaryCents, 'newSalaryCents');
    }

    final closedCycle = currentCycle.close(
      at: confirmedAt,
      remainingCents: currentSummary.remainingCents,
    );
    final newCycle = SalaryCycle(
      id: newCycleId,
      salaryCents: newSalaryCents,
      carryoverCents:
          carryPositiveRemaining && currentSummary.remainingCents > 0
          ? currentSummary.remainingCents
          : 0,
      startedAt: newCycleStartedAt,
      expectedPayDate: nextExpectedPayDate,
      status: SalaryCycleStatus.active,
    );

    return CycleTransition(closedCycle: closedCycle, newActiveCycle: newCycle);
  }
}
