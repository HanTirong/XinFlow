import 'package:xinflow/features/budgets/domain/budget.dart';

abstract interface class BudgetRepository {
  Stream<List<Budget>> watchForCycle(String cycleId);

  Future<void> save(Budget budget);

  Future<void> delete(String budgetId);
}
