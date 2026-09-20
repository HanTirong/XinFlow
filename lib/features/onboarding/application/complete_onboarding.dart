import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/date/payday_calculator.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/onboarding/data/onboarding_repository.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

final class CompleteOnboarding {
  const CompleteOnboarding({
    required this.repository,
    required this.clock,
    required this.idGenerator,
  });

  final OnboardingRepository repository;
  final Clock clock;
  final IdGenerator idGenerator;

  Future<void> execute({
    required int salaryDay,
    required int salaryCents,
  }) async {
    if (salaryDay < 1 || salaryDay > 31) {
      throw RangeError.range(salaryDay, 1, 31, 'salaryDay');
    }
    if (salaryCents < 0) {
      throw ArgumentError.value(salaryCents, 'salaryCents', '工资不能小于 0。');
    }

    final now = clock.now();
    final confirmedDate = LocalDate.fromDateTime(now);
    final cycleStart = PaydayCalculator.cycleStartOnOrBefore(
      today: confirmedDate,
      salaryDay: salaryDay,
    );
    final settings = AppSettings(salaryDay: salaryDay, updatedAt: now);
    final initialCycle = SalaryCycle(
      id: idGenerator.next(),
      salaryCents: salaryCents,
      startedAt: _atStartOfDay(cycleStart, useUtc: now.isUtc),
      expectedPayDate: PaydayCalculator.forNextCycle(
        confirmedDate: cycleStart,
        salaryDay: salaryDay,
      ),
      status: SalaryCycleStatus.active,
    );

    await repository.complete(settings: settings, initialCycle: initialCycle);
  }

  DateTime _atStartOfDay(LocalDate date, {required bool useUtc}) => useUtc
      ? DateTime.utc(date.year, date.month, date.day)
      : DateTime(date.year, date.month, date.day);
}
