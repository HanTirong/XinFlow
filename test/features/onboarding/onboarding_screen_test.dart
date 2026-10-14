import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('validates and submits the first salary cycle', (tester) async {
    int? submittedDay;
    int? submittedSalary;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OnboardingScreen(
          onSubmit: ({required salaryDay, required salaryCents}) async {
            submittedDay = salaryDay;
            submittedSalary = salaryCents;
          },
        ),
      ),
    );

    expect(find.text('建立第一个工资周期'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '本期到账工资'),
      '8500.50',
    );
    await tester.tap(find.text('开始记录工资流向'));
    await tester.pump();

    expect(submittedDay, 10);
    expect(submittedSalary, 850050);
  });

  testWidgets('shows the fixed cycle and rejects an invalid salary', (
    tester,
  ) async {
    var submissionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OnboardingScreen(
          onSubmit: ({required salaryDay, required salaryCents}) async {
            submissionCount++;
          },
        ),
      ),
    );

    expect(find.text('每月 10 日至次月 9 日'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '本期到账工资'), '');
    await tester.tap(find.text('开始记录工资流向'));
    await tester.pump();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(submissionCount, 0);
  });
}
