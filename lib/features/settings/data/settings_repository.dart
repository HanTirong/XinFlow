import 'package:xinflow/features/settings/domain/app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppThemePreference> watchThemePreference();

  Future<void> updateThemePreference(AppThemePreference preference);
}
