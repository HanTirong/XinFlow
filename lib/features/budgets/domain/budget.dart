final class Budget {
  const Budget({
    required this.id,
    required this.salaryCycleId,
    required this.limitCents,
    this.categoryId,
  });

  final String id;
  final String salaryCycleId;
  final String? categoryId;
  final int limitCents;

  bool get isOverall => categoryId == null;
}

final class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spentCents});

  final Budget budget;
  final int spentCents;

  double get ratio =>
      budget.limitCents == 0 ? 0 : spentCents / budget.limitCents;
  bool get isNearLimit => ratio >= 0.8 && ratio < 1;
  bool get isExceeded => ratio >= 1;
}
