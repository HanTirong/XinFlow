import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/app/app.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/database/app_database.dart';

void main() {
  testWidgets('budget editor remains usable after canceling a focused dialog', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const XinFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '本期到账工资'),
      '13000',
    );
    await tester.tap(find.text('开始记录工资流向'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('预算与提醒'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();

    expect(find.text('新增预算'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(find.text('本周期预算'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(await database.select(database.budgetRecords).get(), isEmpty);

    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '预算金额'), '500');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(
      (await database.select(database.budgetRecords).get()).single.limitCents,
      50000,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
