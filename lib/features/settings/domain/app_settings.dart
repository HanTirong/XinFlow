enum AppThemePreference { system, light, dark }

final class AppSettings {
  AppSettings({
    required this.salaryDay,
    required this.updatedAt,
    this.currencyCode = 'CNY',
    this.onboardingCompleted = true,
    this.themePreference = AppThemePreference.system,
    this.hideAmounts = false,
    this.appLockEnabled = false,
    this.autoLockMinutes = 5,
    this.lastBackupAt,
    this.backupReminderDays = 7,
  }) {
    if (salaryDay < 1 || salaryDay > 31) {
      throw RangeError.range(salaryDay, 1, 31, 'salaryDay');
    }
    if (currencyCode != 'CNY') {
      throw ArgumentError.value(currencyCode, 'currencyCode', 'V1 仅支持 CNY。');
    }
    if (autoLockMinutes < 0) {
      throw ArgumentError.value(autoLockMinutes, 'autoLockMinutes');
    }
    if (backupReminderDays < 1 || backupReminderDays > 365) {
      throw RangeError.range(backupReminderDays, 1, 365, 'backupReminderDays');
    }
  }

  final int salaryDay;
  final String currencyCode;
  final bool onboardingCompleted;
  final AppThemePreference themePreference;
  final bool hideAmounts;
  final bool appLockEnabled;
  final int autoLockMinutes;
  final DateTime? lastBackupAt;
  final int backupReminderDays;
  final DateTime updatedAt;
}
