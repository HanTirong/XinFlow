import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';

final class CycleTrendPoint {
  const CycleTrendPoint({required this.cycle, required this.summary});

  final SalaryCycle cycle;
  final SalarySummary summary;
}

final class CategoryTrend {
  const CategoryTrend({
    required this.categoryId,
    required this.currentCents,
    required this.previousCents,
    required this.totalCents,
  });

  final String categoryId;
  final int currentCents;
  final int previousCents;
  final int totalCents;

  int get changeCents => currentCents - previousCents;
}

final class CrossCycleReport {
  const CrossCycleReport({required this.points, required this.categoryTrends});

  final List<CycleTrendPoint> points;
  final List<CategoryTrend> categoryTrends;

  int get averageSalaryCents => _average((item) => item.salaryCents);
  int get averageExpenseCents => _average((item) => item.netExpenseCents);
  int get averageSavingCents => _average((item) => item.savingCents);
  int get averageInvestmentCents => _average((item) => item.investmentCents);

  int _average(int Function(SalarySummary summary) selector) => points.isEmpty
      ? 0
      : points.fold<int>(
              0,
              (total, point) => total + selector(point.summary),
            ) ~/
            points.length;
}
