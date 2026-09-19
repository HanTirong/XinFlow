import 'package:xinflow/features/settings/domain/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Stream<AppThemePreference> watchThemePreference();

  Future<void> updateThemePreference(AppThemePreference preference);

  Future<void> updateSalaryDay(int salaryDay);
}
