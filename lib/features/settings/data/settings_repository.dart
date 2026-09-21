import 'package:xinflow/features/settings/domain/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Stream<AppSettings?> watch();

  Stream<AppThemePreference> watchThemePreference();

  Future<void> updateThemePreference(AppThemePreference preference);

  Future<void> updateSalaryDay(int salaryDay);

  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  });

  Future<void> updatePrivacy({
    bool? hideAmounts,
    bool? appLockEnabled,
    int? autoLockMinutes,
    int? backupReminderDays,
  });

  Future<void> markBackupCreated(DateTime at);
}
