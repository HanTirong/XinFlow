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
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 21,
    this.dailyReminderMinute = 0,
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
    if (dailyReminderHour < 0 || dailyReminderHour > 23) {
      throw RangeError.range(dailyReminderHour, 0, 23, 'dailyReminderHour');
    }
    if (dailyReminderMinute < 0 || dailyReminderMinute > 59) {
      throw RangeError.range(dailyReminderMinute, 0, 59, 'dailyReminderMinute');
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
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final DateTime updatedAt;
}
