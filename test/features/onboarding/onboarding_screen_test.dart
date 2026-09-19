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

    expect(submittedDay, 15);
    expect(submittedSalary, 850050);
  });

  testWidgets('rejects an invalid payday before submitting', (tester) async {
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

    await tester.enterText(find.widgetWithText(TextFormField, '固定发薪日'), '32');
    await tester.enterText(
      find.widgetWithText(TextFormField, '本期到账工资'),
      '8500',
    );
    await tester.tap(find.text('开始记录工资流向'));
    await tester.pump();

    expect(find.text('请输入 1 至 31 之间的日期。'), findsOneWidget);
    expect(submissionCount, 0);
  });
}
