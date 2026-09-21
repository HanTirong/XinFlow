import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/core/id/uuid_id_generator.dart';
import 'package:xinflow/features/backup/application/xinflow_backup_service.dart';
import 'package:xinflow/features/budgets/data/budget_repository.dart';
import 'package:xinflow/features/budgets/data/drift_budget_repository.dart';
import 'package:xinflow/features/budgets/domain/budget.dart';
import 'package:xinflow/features/categories/data/category_repository.dart';
import 'package:xinflow/features/categories/data/drift_category_repository.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/onboarding/application/complete_onboarding.dart';
import 'package:xinflow/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:xinflow/features/onboarding/data/onboarding_repository.dart';
import 'package:xinflow/features/onboarding/domain/app_bootstrap.dart';
import 'package:xinflow/features/reports/domain/cycle_report.dart';
import 'package:xinflow/features/reports/domain/cross_cycle_report.dart';
import 'package:xinflow/features/salary_cycles/data/drift_salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/data/drift_closed_cycle_correction_repository.dart';
import 'package:xinflow/features/salary_cycles/application/close_and_start_next_cycle.dart';
import 'package:xinflow/features/salary_cycles/application/correct_closed_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/settings/data/drift_settings_repository.dart';
import 'package:xinflow/features/settings/data/settings_repository.dart';
import 'package:xinflow/features/settings/data/local_data_service.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/security/application/device_authenticator.dart';
import 'package:xinflow/features/transactions/application/create_allocation.dart';
import 'package:xinflow/features/transactions/application/create_refund.dart';
import 'package:xinflow/features/transactions/application/create_withdrawal.dart';
import 'package:xinflow/features/transactions/application/delete_allocation.dart';
import 'package:xinflow/features/transactions/application/update_allocation.dart';
import 'package:xinflow/features/transactions/data/drift_transaction_repository.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final deviceAuthenticatorProvider = Provider<DeviceAuthenticator>(
  (ref) => LocalDeviceAuthenticator(),
);

final deviceAuthenticationSessionProvider =
    Provider<DeviceAuthenticationSession>(
      (ref) => DeviceAuthenticationSession(),
    );

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>((ref) => UuidIdGenerator());

final backupServiceProvider = Provider<XinFlowBackupService>(
  (ref) => XinFlowBackupService(
    database: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => DriftBudgetRepository(ref.watch(appDatabaseProvider)),
);

final cycleBudgetsProvider = StreamProvider.family<List<Budget>, String>(
  (ref, cycleId) => ref.watch(budgetRepositoryProvider).watchForCycle(cycleId),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => DriftOnboardingRepository(ref.watch(appDatabaseProvider)),
);

final salaryCycleRepositoryProvider = Provider<SalaryCycleRepository>(
  (ref) => DriftSalaryCycleRepository(ref.watch(appDatabaseProvider)),
);

final closeAndStartNextCycleProvider = Provider<CloseAndStartNextCycle>(
  (ref) => CloseAndStartNextCycle(
    salaryCycles: ref.watch(salaryCycleRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final correctClosedCycleProvider = Provider<CorrectClosedCycle>(
  (ref) => CorrectClosedCycle(
    categories: ref.watch(categoryRepositoryProvider),
    repository: DriftClosedCycleCorrectionRepository(
      ref.watch(appDatabaseProvider),
      clock: ref.watch(clockProvider),
    ),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final salaryCyclesProvider = FutureProvider<List<SalaryCycle>>((ref) async {
  final repository = ref.watch(salaryCycleRepositoryProvider);
  final active = await repository.getActiveCycle();
  final closed = await repository.listClosedCycles();
  return [?active, ...closed];
});

final cycleTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, String>(
      (ref, cycleId) => ref
          .watch(transactionRepositoryProvider)
          .watchCycleTransactions(cycleId)
          .map(
            (entries) => entries
                .where((entry) => !entry.isDeleted)
                .toList(growable: false),
          ),
    );

final cycleReportProvider = FutureProvider.family<CycleReport, String>((
  ref,
  cycleId,
) async {
  final cycles = await ref.watch(salaryCyclesProvider.future);
  final cycle = cycles.singleWhere((item) => item.id == cycleId);
  final entries = await ref.watch(cycleTransactionsProvider(cycleId).future);
  final chronological = [...cycles]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final index = chronological.indexWhere((item) => item.id == cycleId);
  SalaryCycle? previousCycle;
  SalarySummary? previousSummary;
  if (index > 0) {
    previousCycle = chronological[index - 1];
    final previousEntries = await ref
        .watch(transactionRepositoryProvider)
        .listCycleTransactions(previousCycle.id);
    previousSummary = SalarySummary.fromTransactions(
      salaryCents: previousCycle.salaryCents,
      carryoverCents: previousCycle.carryoverCents,
      transactions: previousEntries,
    );
  }
  return CycleReport.fromData(
    cycle: cycle,
    transactions: entries,
    previousCycle: previousCycle,
    previousSummary: previousSummary,
  );
});

final crossCycleReportProvider = FutureProvider<CrossCycleReport>((ref) async {
  final cycles = [...await ref.watch(salaryCyclesProvider.future)]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final points = <CycleTrendPoint>[];
  final categoryByCycle = <String, Map<String, int>>{};
  for (final cycle in cycles) {
    final entries = await ref
        .watch(transactionRepositoryProvider)
        .listCycleTransactions(cycle.id);
    points.add(
      CycleTrendPoint(
        cycle: cycle,
        summary: SalarySummary.fromTransactions(
          salaryCents: cycle.salaryCents,
          carryoverCents: cycle.carryoverCents,
          transactions: entries,
        ),
      ),
    );
    final totals = <String, int>{};
    for (final entry in entries.where(
      (entry) => !entry.isDeleted && entry.flowType == FlowType.expense,
    )) {
      totals.update(
        entry.categoryId,
        (value) =>
            value +
            (entry.entryKind == EntryKind.refund
                ? -entry.amountCents
                : entry.amountCents),
        ifAbsent: () => entry.entryKind == EntryKind.refund
            ? -entry.amountCents
            : entry.amountCents,
      );
    }
    categoryByCycle[cycle.id] = totals;
  }
  final categoryIds = categoryByCycle.values
      .expand((totals) => totals.keys)
      .toSet();
  final current = cycles.isEmpty
      ? const <String, int>{}
      : categoryByCycle[cycles.last.id]!;
  final previous = cycles.length < 2
      ? const <String, int>{}
      : categoryByCycle[cycles[cycles.length - 2].id]!;
  final trends = [
    for (final categoryId in categoryIds)
      CategoryTrend(
        categoryId: categoryId,
        currentCents: current[categoryId] ?? 0,
        previousCents: previous[categoryId] ?? 0,
        totalCents: categoryByCycle.values.fold<int>(
          0,
          (total, values) => total + (values[categoryId] ?? 0),
        ),
      ),
  ]..sort((a, b) => b.totalCents.compareTo(a.totalCents));
  return CrossCycleReport(points: points, categoryTrends: trends);
});

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => DriftTransactionRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(appDatabaseProvider)),
);

final activeCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).listActive(),
);

final allCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).listAll(),
);

final createAllocationProvider = Provider<CreateAllocation>(
  (ref) => CreateAllocation(
    categories: ref.watch(categoryRepositoryProvider),
    salaryCycles: ref.watch(salaryCycleRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final createRefundProvider = Provider<CreateRefund>(
  (ref) => CreateRefund(
    salaryCycles: ref.watch(salaryCycleRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final createWithdrawalProvider = Provider<CreateWithdrawal>(
  (ref) => CreateWithdrawal(
    salaryCycles: ref.watch(salaryCycleRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final updateAllocationProvider = Provider<UpdateAllocation>(
  (ref) => UpdateAllocation(
    categories: ref.watch(categoryRepositoryProvider),
    salaryCycles: ref.watch(salaryCycleRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  ),
);

final deleteAllocationProvider = Provider<DeleteAllocation>(
  (ref) => DeleteAllocation(
    salaryCycles: ref.watch(salaryCycleRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final currentCycleTransactionsProvider = StreamProvider<List<TransactionEntry>>(
  (ref) async* {
    final cycle = await ref
        .watch(salaryCycleRepositoryProvider)
        .getActiveCycle();
    if (cycle == null) {
      yield const [];
      return;
    }
    yield* ref
        .watch(transactionRepositoryProvider)
        .watchCycleTransactions(cycle.id)
        .map(
          (entries) => entries
              .where((entry) => !entry.isDeleted)
              .toList(growable: false),
        );
  },
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final localDataServiceProvider = Provider<LocalDataService>(
  (ref) => LocalDataService(ref.watch(appDatabaseProvider)),
);

final localDataOverviewProvider = FutureProvider<LocalDataOverview>(
  (ref) => ref.watch(localDataServiceProvider).overview(),
);

final appSettingsProvider = StreamProvider<AppSettings?>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final themePreferenceProvider = StreamProvider<AppThemePreference>(
  (ref) => ref.watch(settingsRepositoryProvider).watchThemePreference(),
);

final completeOnboardingProvider = Provider<CompleteOnboarding>(
  (ref) => CompleteOnboarding(
    repository: ref.watch(onboardingRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final startupProvider = FutureProvider<AppBootstrap>(
  (ref) => ref.watch(onboardingRepositoryProvider).loadBootstrap(),
);

final homeSnapshotProvider = StreamProvider<HomeSnapshot>((ref) async* {
  final cycle = await ref.watch(salaryCycleRepositoryProvider).getActiveCycle();
  if (cycle == null) {
    throw const InconsistentBootstrapData();
  }

  final transactions = ref.watch(transactionRepositoryProvider);
  await for (final entries in transactions.watchCycleTransactions(cycle.id)) {
    yield HomeSnapshot.fromData(
      cycle: cycle,
      transactions: entries,
      now: ref.read(clockProvider).now(),
    );
  }
});
