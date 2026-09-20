import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/date/payday_calculator.dart';

void main() {
  group('PaydayCalculator', () {
    test('keeps today when today is the configured payday', () {
      const today = LocalDate(2026, 9, 15);

      expect(
        PaydayCalculator.nextOnOrAfter(today: today, salaryDay: 15),
        today,
      );
      expect(PaydayCalculator.daysUntilNext(today: today, salaryDay: 15), 0);
    });

    test('moves to next month after this month payday', () {
      expect(
        PaydayCalculator.nextOnOrAfter(
          today: const LocalDate(2026, 9, 16),
          salaryDay: 15,
        ),
        const LocalDate(2026, 10, 15),
      );
    });

    test('finds the cycle start on or before today', () {
      expect(
        PaydayCalculator.cycleStartOnOrBefore(
          today: const LocalDate(2026, 9, 19),
          salaryDay: 10,
        ),
        const LocalDate(2026, 9, 10),
      );
      expect(
        PaydayCalculator.cycleStartOnOrBefore(
          today: const LocalDate(2026, 9, 9),
          salaryDay: 10,
        ),
        const LocalDate(2026, 8, 10),
      );
    });

    test('cycle start clamps to the final day of a short month', () {
      expect(
        PaydayCalculator.cycleStartOnOrBefore(
          today: const LocalDate(2027, 2, 28),
          salaryDay: 31,
        ),
        const LocalDate(2027, 2, 28),
      );
    });

    test('clamps day 31 to the final day of a short month', () {
      expect(
        PaydayCalculator.nextOnOrAfter(
          today: const LocalDate(2027, 2, 1),
          salaryDay: 31,
        ),
        const LocalDate(2027, 2, 28),
      );
      expect(
        PaydayCalculator.nextOnOrAfter(
          today: const LocalDate(2028, 2, 1),
          salaryDay: 31,
        ),
        const LocalDate(2028, 2, 29),
      );
    });

    test('rejects an invalid configured payday', () {
      expect(
        () => PaydayCalculator.nextOnOrAfter(
          today: const LocalDate(2026, 9, 1),
          salaryDay: 0,
        ),
        throwsRangeError,
      );
    });

    test('new cycles always target the following calendar month', () {
      expect(
        PaydayCalculator.forNextCycle(
          confirmedDate: const LocalDate(2026, 9, 13),
          salaryDay: 15,
        ),
        const LocalDate(2026, 10, 15),
      );
      expect(
        PaydayCalculator.forNextCycle(
          confirmedDate: const LocalDate(2026, 12, 31),
          salaryDay: 31,
        ),
        const LocalDate(2027, 1, 31),
      );
    });
  });
}
