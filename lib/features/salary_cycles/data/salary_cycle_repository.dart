import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';

abstract interface class SalaryCycleRepository {
  Stream<SalaryCycle?> watchActiveCycle();

  Future<SalaryCycle?> getActiveCycle();

  Future<List<SalaryCycle>> listClosedCycles();

  /// Atomically closes the current cycle and inserts its successor.
  Future<void> replaceActiveCycle({
    required SalaryCycle closedCycle,
    required SalaryCycle newActiveCycle,
  });
}
