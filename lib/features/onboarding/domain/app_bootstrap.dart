import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

final class AppBootstrap {
  const AppBootstrap._({this.settings, this.activeCycle});

  const AppBootstrap.needsOnboarding() : this._();

  const AppBootstrap.ready({
    required AppSettings settings,
    required SalaryCycle activeCycle,
  }) : this._(settings: settings, activeCycle: activeCycle);

  final AppSettings? settings;
  final SalaryCycle? activeCycle;

  bool get needsOnboarding => settings == null && activeCycle == null;
  bool get isReady => settings != null && activeCycle != null;
}

final class InconsistentBootstrapData implements Exception {
  const InconsistentBootstrapData();

  @override
  String toString() => '设置和活动工资周期状态不一致，已停止金额写入。';
}
