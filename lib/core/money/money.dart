/// An immutable amount represented in the smallest CNY unit (fen).
///
/// XinFlow never uses floating-point values for persisted or calculated money.
final class Money implements Comparable<Money> {
  const Money.fromCents(this.cents);

  static const Money zero = Money.fromCents(0);

  final int cents;

  /// Parses a non-negative decimal amount with at most two fraction digits.
  factory Money.parse(String input) {
    final normalized = input.trim().replaceAll(',', '');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);

    if (match == null) {
      throw const FormatException('金额必须是非负数，且最多包含两位小数。');
    }

    final wholeYuan = int.parse(match.group(1)!);
    final fractionText = match.group(2) ?? '';
    final fractionCents = switch (fractionText.length) {
      0 => 0,
      1 => int.parse(fractionText) * 10,
      _ => int.parse(fractionText),
    };

    return Money.fromCents(wholeYuan * 100 + fractionCents);
  }

  Money operator +(Money other) => Money.fromCents(cents + other.cents);

  Money operator -(Money other) => Money.fromCents(cents - other.cents);

  Money operator -() => Money.fromCents(-cents);

  bool get isNegative => cents < 0;

  bool get isZero => cents == 0;

  String format({String symbol = '¥', bool alwaysShowCents = false}) {
    final absoluteCents = cents.abs();
    final wholeYuan = absoluteCents ~/ 100;
    final fractionCents = absoluteCents % 100;
    final groupedYuan = _groupThousands(wholeYuan.toString());
    final fraction = fractionCents == 0 && !alwaysShowCents
        ? ''
        : '.${fractionCents.toString().padLeft(2, '0')}';
    final sign = cents < 0 ? '-' : '';

    return '$sign$symbol$groupedYuan$fraction';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && cents == other.cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => format(alwaysShowCents: true);

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}
