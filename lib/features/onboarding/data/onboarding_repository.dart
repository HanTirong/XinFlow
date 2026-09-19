import 'package:xinflow/features/onboarding/domain/app_bootstrap.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

abstract interface class OnboardingRepository {
  Future<AppBootstrap> loadBootstrap();

  Future<void> complete({
    required AppSettings settings,
    required SalaryCycle initialCycle,
  });
}
