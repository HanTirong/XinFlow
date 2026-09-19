import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/app/app.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/id/id_generator.dart';

void main() {
  testWidgets('moves from onboarding to a persisted real home snapshot', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          clockProvider.overrideWithValue(
            _FixedClock(DateTime.utc(2026, 9, 19, 9)),
          ),
          idGeneratorProvider.overrideWithValue(
            const _FixedIdGenerator('cycle-initial'),
          ),
        ],
        child: const XinFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('建立第一个工资周期'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '本期到账工资'),
      '8500',
    );
    await tester.tap(find.text('开始记录工资流向'));
    await tester.pumpAndSettle();

    expect(find.text('本期工资剩余'), findsOneWidget);
    expect(find.text('¥8,500'), findsNWidgets(2));
    expect(find.text('预览数据'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('记一笔'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '28.60');
    await tester.tap(find.widgetWithText(ChoiceChip, '饮食'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('¥8,471.40'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('- ¥28.60'), findsOneWidget);
    expect(find.text('已记入本期工资流向。'), findsOneWidget);

    final settings = await database.select(database.appSettingRecords).get();
    final cycles = await database.select(database.salaryCycleRecords).get();
    final transactions = await database
        .select(database.transactionRecords)
        .get();
    expect(settings, hasLength(1));
    expect(cycles, hasLength(1));
    expect(transactions, hasLength(1));

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('外观'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      (await database.select(database.appSettingRecords).getSingle()).themeMode,
      'dark',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator(this.value);

  final String value;

  @override
  String next() => value;
}
