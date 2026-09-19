/// A calendar date without a time or time zone.
final class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day)
    : assert(month >= 1 && month <= 12),
      assert(day >= 1 && day <= 31);

  factory LocalDate.fromDateTime(DateTime value) =>
      LocalDate(value.year, value.month, value.day);

  factory LocalDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('日期必须使用 YYYY-MM-DD 格式。');
    }

    final date = LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );

    if (date.day > daysInMonth(date.year, date.month)) {
      throw FormatException('不存在的日期：$value');
    }

    return date;
  }

  final int year;
  final int month;
  final int day;

  DateTime get asUtc => DateTime.utc(year, month, day);

  int daysUntil(LocalDate other) => other.asUtc.difference(asUtc).inDays;

  @override
  int compareTo(LocalDate other) => asUtc.compareTo(other.asUtc);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDate &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    return DateTime.utc(year, month + 1).subtract(const Duration(days: 1)).day;
  }
}
