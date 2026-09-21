import 'package:drift/drift.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/date/payday_calculator.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/data/settings_repository.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

final class DriftSettingsRepository implements SettingsRepository {
  const DriftSettingsRepository(this._database, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final AppDatabase _database;
  final Clock _clock;

  @override
  Future<AppSettings> load() async {
    final settings = await _database
        .select(_database.appSettingRecords)
        .getSingleOrNull();
    if (settings == null) throw StateError('尚未完成首次设置。');
    return settings.toDomain();
  }

  @override
  Stream<AppSettings?> watch() => _database
      .select(_database.appSettingRecords)
      .watchSingleOrNull()
      .map((row) => row?.toDomain());

  @override
  Stream<AppThemePreference> watchThemePreference() => _database
      .select(_database.appSettingRecords)
      .watchSingleOrNull()
      .map(
        (settings) => settings == null
            ? AppThemePreference.system
            : AppThemePreference.values.byName(settings.themeMode),
      );

  @override
  Future<void> updateThemePreference(AppThemePreference preference) async {
    final affected =
        await (_database.update(
          _database.appSettingRecords,
        )..where((row) => row.singletonId.equals(1))).write(
          AppSettingRecordsCompanion(
            themeMode: Value(preference.name),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
    if (affected != 1) {
      throw StateError('尚未完成首次设置，无法保存主题。');
    }
  }

  @override
  Future<void> updateSalaryDay(int salaryDay) async {
    if (salaryDay < 1 || salaryDay > 31) {
      throw RangeError.range(salaryDay, 1, 31, 'salaryDay');
    }
    final now = _clock.now();
    final today = LocalDate.fromDateTime(now);
    final cycleStart = PaydayCalculator.cycleStartOnOrBefore(
      today: today,
      salaryDay: salaryDay,
    );
    final expectedPayDate = PaydayCalculator.forNextCycle(
      confirmedDate: cycleStart,
      salaryDay: salaryDay,
    );
    final startedAt = now.isUtc
        ? DateTime.utc(cycleStart.year, cycleStart.month, cycleStart.day)
        : DateTime(cycleStart.year, cycleStart.month, cycleStart.day);

    await _database.transaction(() async {
      final affected =
          await (_database.update(
            _database.appSettingRecords,
          )..where((row) => row.singletonId.equals(1))).write(
            AppSettingRecordsCompanion(
              salaryDay: Value(salaryDay),
              updatedAt: Value(now.toUtc().millisecondsSinceEpoch),
            ),
          );
      if (affected != 1) throw StateError('尚未完成首次设置。');

      await (_database.update(_database.salaryCycleRecords)..where(
            (row) =>
                row.status.equals(SalaryCycleStatus.active.name) &
                row.deletedAt.isNull(),
          ))
          .write(
            SalaryCycleRecordsCompanion(
              startedAt: Value(startedAt.toUtc().millisecondsSinceEpoch),
              expectedPayDate: Value(expectedPayDate.toString()),
              updatedAt: Value(now.toUtc().millisecondsSinceEpoch),
            ),
          );
    });
  }

  @override
  Future<void> updatePrivacy({
    bool? hideAmounts,
    bool? appLockEnabled,
    int? autoLockMinutes,
    int? backupReminderDays,
  }) async {
    if (autoLockMinutes != null && autoLockMinutes < 0) {
      throw ArgumentError.value(autoLockMinutes, 'autoLockMinutes');
    }
    if (backupReminderDays != null &&
        (backupReminderDays < 1 || backupReminderDays > 365)) {
      throw RangeError.range(backupReminderDays, 1, 365, 'backupReminderDays');
    }
    final affected =
        await (_database.update(
          _database.appSettingRecords,
        )..where((row) => row.singletonId.equals(1))).write(
          AppSettingRecordsCompanion(
            hideAmounts: hideAmounts == null
                ? const Value.absent()
                : Value(hideAmounts),
            appLockEnabled: appLockEnabled == null
                ? const Value.absent()
                : Value(appLockEnabled),
            autoLockMinutes: autoLockMinutes == null
                ? const Value.absent()
                : Value(autoLockMinutes),
            backupReminderDays: backupReminderDays == null
                ? const Value.absent()
                : Value(backupReminderDays),
            updatedAt: Value(_clock.now().toUtc().millisecondsSinceEpoch),
          ),
        );
    if (affected != 1) throw StateError('尚未完成首次设置。');
  }

  @override
  Future<void> markBackupCreated(DateTime at) async {
    final affected =
        await (_database.update(
          _database.appSettingRecords,
        )..where((row) => row.singletonId.equals(1))).write(
          AppSettingRecordsCompanion(
            lastBackupAt: Value(at.toUtc().millisecondsSinceEpoch),
            updatedAt: Value(at.toUtc().millisecondsSinceEpoch),
          ),
        );
    if (affected != 1) throw StateError('尚未完成首次设置。');
  }
}
