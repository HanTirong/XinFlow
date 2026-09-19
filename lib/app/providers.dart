import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/core/id/uuid_id_generator.dart';
import 'package:xinflow/features/categories/data/category_repository.dart';
import 'package:xinflow/features/categories/data/drift_category_repository.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/onboarding/application/complete_onboarding.dart';
import 'package:xinflow/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:xinflow/features/onboarding/data/onboarding_repository.dart';
import 'package:xinflow/features/onboarding/domain/app_bootstrap.dart';
import 'package:xinflow/features/salary_cycles/data/drift_salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/settings/data/drift_settings_repository.dart';
import 'package:xinflow/features/settings/data/settings_repository.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/transactions/data/drift_transaction_repository.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/application/create_allocation.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>((ref) => UuidIdGenerator());

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => DriftOnboardingRepository(ref.watch(appDatabaseProvider)),
);

final salaryCycleRepositoryProvider = Provider<SalaryCycleRepository>(
  (ref) => DriftSalaryCycleRepository(ref.watch(appDatabaseProvider)),
);

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

final createAllocationProvider = Provider<CreateAllocation>(
  (ref) => CreateAllocation(
    categories: ref.watch(categoryRepositoryProvider),
    salaryCycles: ref.watch(salaryCycleRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
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
