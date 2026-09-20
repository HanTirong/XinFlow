import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/cycle_transition.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';

void main() {
  test(
    'closes the old cycle and never rolls remaining money into the new one',
    () {
      final current = SalaryCycle(
        id: 'cycle-1',
        salaryCents: 1000000,
        startedAt: DateTime.utc(2026, 8, 15),
        expectedPayDate: const LocalDate(2026, 9, 15),
        status: SalaryCycleStatus.active,
      );
      const summary = SalarySummary(
        salaryCents: 1000000,
        expenseAllocatedCents: 400000,
        expenseRefundedCents: 0,
        savingCents: 100000,
        investmentCents: 100000,
      );

      final transition = SalaryCyclePolicy.closeAndStartNext(
        currentCycle: current,
        currentSummary: summary,
        newCycleId: 'cycle-2',
        newSalaryCents: 1200000,
        confirmedAt: DateTime.utc(2026, 9, 15, 9),
        newCycleStartedAt: DateTime.utc(2026, 9, 15),
        nextExpectedPayDate: const LocalDate(2026, 10, 15),
      );

      expect(transition.closedCycle.status, SalaryCycleStatus.closed);
      expect(transition.closedCycle.finalRemainingCents, 400000);
      expect(transition.newActiveCycle.status, SalaryCycleStatus.active);
      expect(transition.newActiveCycle.salaryCents, 1200000);
      expect(transition.newActiveCycle.startedAt, DateTime.utc(2026, 9, 15));
    },
  );

  test('rejects transitioning a cycle that is already closed', () {
    final closed = SalaryCycle(
      id: 'cycle-1',
      salaryCents: 1000000,
      startedAt: DateTime.utc(2026, 8, 15),
      expectedPayDate: const LocalDate(2026, 9, 15),
      status: SalaryCycleStatus.closed,
      closedAt: DateTime.utc(2026, 9, 15),
      finalRemainingCents: 400000,
    );
    const summary = SalarySummary(
      salaryCents: 1000000,
      expenseAllocatedCents: 600000,
      expenseRefundedCents: 0,
      savingCents: 0,
      investmentCents: 0,
    );

    expect(
      () => SalaryCyclePolicy.closeAndStartNext(
        currentCycle: closed,
        currentSummary: summary,
        newCycleId: 'cycle-2',
        newSalaryCents: 1200000,
        confirmedAt: DateTime.utc(2026, 9, 15, 9),
        newCycleStartedAt: DateTime.utc(2026, 9, 15),
        nextExpectedPayDate: const LocalDate(2026, 10, 15),
      ),
      throwsStateError,
    );
  });
}
