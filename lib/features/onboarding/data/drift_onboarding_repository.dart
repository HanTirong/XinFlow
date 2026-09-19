import 'package:drift/drift.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/features/onboarding/data/onboarding_repository.dart';
import 'package:xinflow/features/onboarding/domain/app_bootstrap.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

final class DriftOnboardingRepository implements OnboardingRepository {
  const DriftOnboardingRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppBootstrap> loadBootstrap() async {
    final settings = await _database
        .select(_database.appSettingRecords)
        .getSingleOrNull();
    final activeCycle =
        await (_database.select(_database.salaryCycleRecords)..where(
              (row) =>
                  row.status.equals(SalaryCycleStatus.active.name) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();

    if (settings == null && activeCycle == null) {
      return const AppBootstrap.needsOnboarding();
    }
    if (settings == null ||
        !settings.onboardingCompleted ||
        activeCycle == null) {
      throw const InconsistentBootstrapData();
    }

    return AppBootstrap.ready(
      settings: settings.toDomain(),
      activeCycle: activeCycle.toDomain(),
    );
  }

  @override
  Future<void> complete({
    required AppSettings settings,
    required SalaryCycle initialCycle,
  }) => _database.transaction(() async {
    final settingsExist =
        await _database.select(_database.appSettingRecords).getSingleOrNull() !=
        null;
    final activeCycleExists =
        await (_database.select(_database.salaryCycleRecords)..where(
              (row) =>
                  row.status.equals(SalaryCycleStatus.active.name) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull() !=
        null;

    if (settingsExist || activeCycleExists) {
      throw StateError('首次设置已经完成，不能重复创建工资周期。');
    }
    if (!settings.onboardingCompleted ||
        initialCycle.status != SalaryCycleStatus.active) {
      throw ArgumentError('首次设置必须同时创建完成状态和活动工资周期。');
    }

    final updatedAt = settings.updatedAt.toUtc().millisecondsSinceEpoch;
    await _database
        .into(_database.appSettingRecords)
        .insert(
          AppSettingRecordsCompanion.insert(
            singletonId: const Value(1),
            salaryDay: settings.salaryDay,
            currencyCode: Value(settings.currencyCode),
            onboardingCompleted: settings.onboardingCompleted,
            themeMode: Value(settings.themePreference.name),
            updatedAt: updatedAt,
          ),
        );
    await _database
        .into(_database.salaryCycleRecords)
        .insert(
          SalaryCycleRecordsCompanion.insert(
            id: initialCycle.id,
            salaryCents: initialCycle.salaryCents,
            startedAt: initialCycle.startedAt.toUtc().millisecondsSinceEpoch,
            expectedPayDate: initialCycle.expectedPayDate.toString(),
            status: initialCycle.status.name,
            createdAt: updatedAt,
            updatedAt: updatedAt,
          ),
        );
  });
}
