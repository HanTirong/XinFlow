import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/security/application/device_authenticator.dart';
import 'package:xinflow/features/security/presentation/app_lock_gate.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

void main() {
  testWidgets('authentication prompt does not start another lock cycle', (
    tester,
  ) async {
    final authenticator = _ControlledAuthenticator();
    final session = DeviceAuthenticationSession();
    final settings = AppSettings(
      salaryDay: 10,
      updatedAt: DateTime(2026, 9, 21),
      appLockEnabled: true,
      autoLockMinutes: 0,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceAuthenticatorProvider.overrideWithValue(authenticator),
          deviceAuthenticationSessionProvider.overrideWithValue(session),
          appSettingsProvider.overrideWith((ref) => Stream.value(settings)),
        ],
        child: const MaterialApp(home: AppLockGate(child: Text('已进入薪流'))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(authenticator.calls, 1);
    expect(find.text('薪流已锁定'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(authenticator.calls, 1);

    authenticator.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('已进入薪流'), findsOneWidget);

    // A late resumed event from the system prompt is not a new app visit.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(authenticator.calls, 1);
    expect(find.text('已进入薪流'), findsOneWidget);

    // A real background transition still locks with the "立即" setting.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(authenticator.calls, 2);
    expect(find.text('薪流已锁定'), findsOneWidget);

    authenticator.complete(true);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

final class _ControlledAuthenticator implements DeviceAuthenticator {
  final List<Completer<bool>> _requests = [];

  int get calls => _requests.length;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate() {
    final request = Completer<bool>();
    _requests.add(request);
    return request.future;
  }

  void complete(bool result) => _requests.last.complete(result);
}
