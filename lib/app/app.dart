import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/features/navigation/presentation/main_shell.dart';
import 'package:xinflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/security/presentation/app_lock_gate.dart';
import 'package:xinflow/features/reminders/application/daily_reminder_notifications.dart';

final class XinFlowApp extends ConsumerStatefulWidget {
  const XinFlowApp({super.key});

  @override
  ConsumerState<XinFlowApp> createState() => _XinFlowAppState();
}

final class _XinFlowAppState extends ConsumerState<XinFlowApp>
    with WidgetsBindingObserver {
  String? _reminderSignature;
  Timer? _dateCheckTimer;
  bool _checkingDate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextDateCheck();
  }

  @override
  void dispose() {
    _dateCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkDate());
      _scheduleNextDateCheck();
    }
  }

  void _scheduleNextDateCheck() {
    _dateCheckTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 2);
    _dateCheckTimer = Timer(next.difference(now), () {
      unawaited(_checkDate());
      _scheduleNextDateCheck();
    });
  }

  Future<void> _checkDate() async {
    if (_checkingDate || !mounted) return;
    _checkingDate = true;
    try {
      final changed = await ref.read(autoSettleDueCyclesProvider).execute();
      if (changed > 0 && mounted) {
        ref
          ..invalidate(homeSnapshotProvider)
          ..invalidate(salaryCyclesProvider)
          ..invalidate(pendingSalaryCyclesProvider)
          ..invalidate(currentCycleTransactionsProvider)
          ..invalidate(cycleReportProvider)
          ..invalidate(crossCycleReportProvider);
      }
    } on Object catch (error) {
      debugPrint('Salary cycle date check failed: $error');
    } finally {
      _checkingDate = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(startupProvider);
    final reminderSettings = ref.watch(appSettingsProvider);
    if (reminderSettings is AsyncData<AppSettings?>) {
      final settings = reminderSettings.value;
      final signature = settings == null
          ? 'off'
          : '${settings.dailyReminderEnabled}:${settings.dailyReminderHour}:'
                '${settings.dailyReminderMinute}';
      if (_reminderSignature != signature) {
        _reminderSignature = signature;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            DailyReminderNotifications.instance.sync(settings).catchError((
              Object error,
            ) {
              debugPrint('Daily reminder scheduling failed: $error');
            }),
          );
        });
      }
    }
    final themePreference = switch (ref.watch(themePreferenceProvider)) {
      AsyncData(:final value) => value,
      _ => AppThemePreference.system,
    };

    return MaterialApp(
      title: '薪流',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themePreference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: startup.when(
        loading: () => const _StartupLoading(),
        error: (error, stackTrace) => _StartupError(
          message: error.toString(),
          onRetry: () => ref.invalidate(startupProvider),
        ),
        data: (bootstrap) {
          if (bootstrap.needsOnboarding) {
            return OnboardingScreen(
              onSubmit: ({required salaryDay, required salaryCents}) async {
                await ref
                    .read(completeOnboardingProvider)
                    .execute(salaryDay: salaryDay, salaryCents: salaryCents);
                ref.invalidate(startupProvider);
              },
            );
          }
          return const AppLockGate(child: MainShell());
        },
      ),
    );
  }
}

final class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

final class _StartupError extends StatelessWidget {
  const _StartupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              Text('无法读取本地数据', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      ),
    ),
  );
}
