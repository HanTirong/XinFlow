import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/core/id/uuid_id_generator.dart';
import 'package:xinflow/features/backup/application/xinflow_backup_service.dart';
import 'package:xinflow/features/categories/data/category_repository.dart';
import 'package:xinflow/features/categories/data/drift_category_repository.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/onboarding/application/complete_onboarding.dart';
import 'package:xinflow/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:xinflow/features/onboarding/data/onboarding_repository.dart';
import 'package:xinflow/features/onboarding/domain/app_bootstrap.dart';
import 'package:xinflow/features/reports/domain/cycle_report.dart';
import 'package:xinflow/features/salary_cycles/data/drift_salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/application/close_and_start_next_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_summary.dart';
import 'package:xinflow/features/settings/data/drift_settings_repository.dart';
import 'package:xinflow/features/settings/data/settings_repository.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/transactions/application/create_allocation.dart';
import 'package:xinflow/features/transactions/application/create_refund.dart';
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

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>((ref) => UuidIdGenerator());

final backupServiceProvider = Provider<XinFlowBackupService>(
  (ref) => XinFlowBackupService(
    database: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
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
  SalarySummary? previousSummary;
  if (index > 0) {
    final previous = chronological[index - 1];
    final previousEntries = await ref
        .watch(transactionRepositoryProvider)
        .listCycleTransactions(previous.id);
    previousSummary = SalarySummary.fromTransactions(
      salaryCents: previous.salaryCents,
      transactions: previousEntries,
    );
  }
  return CycleReport.fromData(
    cycle: cycle,
    transactions: entries,
    previousSummary: previousSummary,
  );
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
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
);

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
