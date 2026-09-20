import 'package:xinflow/core/date/local_date.dart';

final class PaydayCalculator {
  const PaydayCalculator._();

  /// Returns the configured payday that starts the cycle containing [today].
  ///
  /// The result is always on or before [today]. Short months use their final
  /// calendar day.
  static LocalDate cycleStartOnOrBefore({
    required LocalDate today,
    required int salaryDay,
  }) {
    _validateSalaryDay(salaryDay);
    final thisMonth = _dateForMonth(today.year, today.month, salaryDay);
    if (thisMonth.compareTo(today) <= 0) return thisMonth;

    final previousMonth = today.month == 1 ? 12 : today.month - 1;
    final previousYear = today.month == 1 ? today.year - 1 : today.year;
    return _dateForMonth(previousYear, previousMonth, salaryDay);
  }

  /// Returns the next configured payday on or after [today].
  ///
  /// When a month does not contain [salaryDay], its final day is used. This is
  /// a display-only estimate and must never close or create a salary cycle.
  static LocalDate nextOnOrAfter({
    required LocalDate today,
    required int salaryDay,
  }) {
    _validateSalaryDay(salaryDay);

    final thisMonth = _dateForMonth(today.year, today.month, salaryDay);
    if (today.compareTo(thisMonth) <= 0) {
      return thisMonth;
    }

    final nextMonth = today.month == 12 ? 1 : today.month + 1;
    final nextYear = today.month == 12 ? today.year + 1 : today.year;
    return _dateForMonth(nextYear, nextMonth, salaryDay);
  }

  static int daysUntilNext({
    required LocalDate today,
    required int salaryDay,
  }) => today.daysUntil(nextOnOrAfter(today: today, salaryDay: salaryDay));

  /// Returns the expected payday for the salary cycle that begins on
  /// [confirmedDate]. The result is always in the following calendar month,
  /// even when salary arrives earlier than its configured day.
  static LocalDate forNextCycle({
    required LocalDate confirmedDate,
    required int salaryDay,
  }) {
    _validateSalaryDay(salaryDay);

    final nextMonth = confirmedDate.month == 12 ? 1 : confirmedDate.month + 1;
    final nextYear = confirmedDate.month == 12
        ? confirmedDate.year + 1
        : confirmedDate.year;
    return _dateForMonth(nextYear, nextMonth, salaryDay);
  }

  static LocalDate _dateForMonth(int year, int month, int salaryDay) {
    final day = salaryDay.clamp(1, LocalDate.daysInMonth(year, month)).toInt();
    return LocalDate(year, month, day);
  }

  static void _validateSalaryDay(int salaryDay) {
    if (salaryDay < 1 || salaryDay > 31) {
      throw RangeError.range(salaryDay, 1, 31, 'salaryDay');
    }
  }
}
