import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/money/money.dart';

void main() {
  group('Money.parse', () {
    test('parses whole yuan and decimal amounts into cents', () {
      expect(Money.parse('12').cents, 1200);
      expect(Money.parse('12.3').cents, 1230);
      expect(Money.parse('12.34').cents, 1234);
      expect(Money.parse('1,234.56').cents, 123456);
    });

    test('rejects negatives and more than two decimal places', () {
      expect(() => Money.parse('-1'), throwsFormatException);
      expect(() => Money.parse('1.234'), throwsFormatException);
      expect(() => Money.parse(''), throwsFormatException);
    });
  });

  group('Money.format', () {
    test('adds grouping and hides zero cents by default', () {
      expect(const Money.fromCents(123456).format(), '¥1,234.56');
      expect(const Money.fromCents(123400).format(), '¥1,234');
      expect(const Money.fromCents(-123400).format(), '-¥1,234');
    });

    test('can always show cents', () {
      expect(
        const Money.fromCents(1200).format(alwaysShowCents: true),
        '¥12.00',
      );
    });
  });
}
