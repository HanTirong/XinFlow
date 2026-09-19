enum AppThemePreference { system, light, dark }

final class AppSettings {
  AppSettings({
    required this.salaryDay,
    required this.updatedAt,
    this.currencyCode = 'CNY',
    this.onboardingCompleted = true,
    this.themePreference = AppThemePreference.system,
  }) {
    if (salaryDay < 1 || salaryDay > 31) {
      throw RangeError.range(salaryDay, 1, 31, 'salaryDay');
    }
    if (currencyCode != 'CNY') {
      throw ArgumentError.value(currencyCode, 'currencyCode', 'V1 仅支持 CNY。');
    }
  }

  final int salaryDay;
  final String currencyCode;
  final bool onboardingCompleted;
  final AppThemePreference themePreference;
  final DateTime updatedAt;
}
