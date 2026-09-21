import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/features/navigation/presentation/main_shell.dart';
import 'package:xinflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/security/presentation/app_lock_gate.dart';

final class XinFlowApp extends ConsumerWidget {
  const XinFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupProvider);
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
