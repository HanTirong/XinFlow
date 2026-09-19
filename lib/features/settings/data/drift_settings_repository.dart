import 'package:drift/drift.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/features/settings/data/settings_repository.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

final class DriftSettingsRepository implements SettingsRepository {
  const DriftSettingsRepository(this._database);

  final AppDatabase _database;

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
}
