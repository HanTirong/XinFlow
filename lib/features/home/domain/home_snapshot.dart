import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/date/payday_calculator.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class HomeSnapshot {
  const HomeSnapshot({
    required this.cycle,
    required this.summary,
    required this.daysUntilPayday,
    required this.shortcuts,
    required this.recentTransactions,
    this.isPreview = false,
  });

  factory HomeSnapshot.preview(DateTime now) {
    final today = LocalDate.fromDateTime(now);
    final expectedPayday = PaydayCalculator.nextOnOrAfter(
      today: today,
      salaryDay: 30,
    );
    final cycle = SalaryCycle(
      id: 'preview-cycle',
      salaryCents: 1700000,
      startedAt: DateTime(now.year, now.month, 1, 9),
      expectedPayDate: expectedPayday,
      status: SalaryCycleStatus.active,
    );

    final transactions = <TransactionEntry>[
      _previewEntry(
        id: 'preview-food',
        cycleId: cycle.id,
        amountCents: 3200,
        categoryId: 'food',
        occurredAt: now.subtract(const Duration(hours: 2)),
      ),
      _previewEntry(
        id: 'preview-shopping',
        cycleId: cycle.id,
        amountCents: 8600,
        categoryId: 'shopping',
        occurredAt: now.subtract(const Duration(days: 1)),
      ),
      _previewEntry(
        id: 'preview-digital',
        cycleId: cycle.id,
        amountCents: 6800,
        categoryId: 'digital',
        occurredAt: now.subtract(const Duration(days: 2)),
      ),
      _previewEntry(
        id: 'preview-saving',
        cycleId: cycle.id,
        amountCents: 100000,
        categoryId: 'saving',
        flowType: FlowType.saving,
        occurredAt: now.subtract(const Duration(days: 3)),
      ),
      _previewEntry(
        id: 'preview-housing',
        cycleId: cycle.id,
        amountCents: 943400,
        categoryId: 'housing',
        occurredAt: now.subtract(const Duration(days: 8)),
      ),
    ];

    return HomeSnapshot(
      cycle: cycle,
      summary: SalarySummary.fromTransactions(
        salaryCents: cycle.salaryCents,
        transactions: transactions,
      ),
      daysUntilPayday: PaydayCalculator.daysUntilNext(
        today: today,
        salaryDay: 30,
      ),
      shortcuts: const [
        CategoryShortcut(id: 'food', label: '饮食'),
        CategoryShortcut(id: 'shopping', label: '购物'),
        CategoryShortcut(id: 'housing', label: '住房'),
        CategoryShortcut(id: 'transport', label: '交通'),
        CategoryShortcut(id: 'digital', label: '数字服务'),
        CategoryShortcut(id: 'saving', label: '存款'),
        CategoryShortcut(id: 'investment', label: '理财'),
        CategoryShortcut(id: 'other', label: '其他'),
      ],
      recentTransactions: transactions.take(4).toList(growable: false),
      isPreview: true,
    );
  }

  factory HomeSnapshot.fromData({
    required SalaryCycle cycle,
    required Iterable<TransactionEntry> transactions,
    required DateTime now,
  }) {
    final activeTransactions = transactions
        .where((entry) => !entry.isDeleted)
        .toList(growable: false);
    final today = LocalDate.fromDateTime(now);

    return HomeSnapshot(
      cycle: cycle,
      summary: SalarySummary.fromTransactions(
        salaryCents: cycle.salaryCents,
        transactions: activeTransactions,
      ),
      daysUntilPayday: today.daysUntil(cycle.expectedPayDate).clamp(0, 99999),
      shortcuts: const [
        CategoryShortcut(id: DefaultCategoryIds.food, label: '饮食'),
        CategoryShortcut(id: DefaultCategoryIds.shopping, label: '购物'),
        CategoryShortcut(id: DefaultCategoryIds.housing, label: '住房'),
        CategoryShortcut(id: DefaultCategoryIds.transport, label: '交通'),
        CategoryShortcut(id: DefaultCategoryIds.digital, label: '数字服务'),
        CategoryShortcut(id: DefaultCategoryIds.saving, label: '存款'),
        CategoryShortcut(id: DefaultCategoryIds.investment, label: '理财'),
        CategoryShortcut(id: DefaultCategoryIds.other, label: '其他'),
      ],
      recentTransactions: activeTransactions.take(5).toList(growable: false),
    );
  }

  final SalaryCycle cycle;
  final SalarySummary summary;
  final int daysUntilPayday;
  final List<CategoryShortcut> shortcuts;
  final List<TransactionEntry> recentTransactions;
  final bool isPreview;

  static TransactionEntry _previewEntry({
    required String id,
    required String cycleId,
    required int amountCents,
    required String categoryId,
    required DateTime occurredAt,
    FlowType flowType = FlowType.expense,
  }) => TransactionEntry(
    id: id,
    salaryCycleId: cycleId,
    entryKind: EntryKind.allocation,
    flowType: flowType,
    amountCents: amountCents,
    categoryId: categoryId,
    occurredAt: occurredAt,
    occurredOn: LocalDate.fromDateTime(occurredAt),
  );
}

final class CategoryShortcut {
  const CategoryShortcut({required this.id, required this.label});

  final String id;
  final String label;
}
