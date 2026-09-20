import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/app/app.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/reports/presentation/report_screen.dart';
import 'package:xinflow/features/settings/presentation/settings_screen.dart';

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
            _SequenceIdGenerator([
              'cycle-initial',
              'transaction-1',
              'refund-1',
              'cycle-next',
            ]),
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

    await tester.scrollUntilVisible(
      find.text('记一笔'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();
    expect(find.text('记一笔'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '28.60');
    await tester.tap(find.widgetWithText(ChoiceChip, '饮食'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
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

    await tester.tap(find.text('流水'));
    await tester.pumpAndSettle();
    expect(find.text('当前周期流水'), findsOneWidget);
    expect(find.text('- ¥28.60'), findsOneWidget);

    await tester.tap(find.text('饮食'));
    await tester.pumpAndSettle();
    expect(find.text('编辑流水'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '30.60');
    await tester.tap(find.widgetWithText(FilledButton, '保存修改'));
    await tester.pumpAndSettle();
    expect(find.text('- ¥30.60'), findsOneWidget);
    expect(find.text('流水修改已保存。'), findsOneWidget);

    await tester.tap(find.text('- ¥30.60'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录退款'));
    await tester.pumpAndSettle();
    expect(find.textContaining('尚可退款 ¥30.60'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '退款金额'), '10');
    await tester.tap(find.text('确认退款'));
    await tester.pumpAndSettle();
    expect(find.text('+ ¥10'), findsOneWidget);
    expect(find.text('退款已记录，余额已更新。'), findsOneWidget);

    await tester.tap(find.text('- ¥30.60'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除流水'));
    await tester.pumpAndSettle();
    expect(find.text('删除这笔流水？'), findsOneWidget);
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(find.text('还没有流水'), findsOneWidget);
    expect(find.text('流水已删除，余额已重新计算。'), findsOneWidget);

    final deletedTransactions = await database
        .select(database.transactionRecords)
        .get();
    expect(deletedTransactions, hasLength(2));
    expect(
      deletedTransactions,
      everyElement(
        predicate<TransactionRecord>((entry) => entry.deletedAt != null),
      ),
    );

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('¥8,500'), findsNWidgets(2));

    await tester.tap(find.text('距离下次发薪'));
    await tester.pumpAndSettle();
    expect(find.text('确认工资到账'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '新到账工资'), '9000');
    await tester.tap(find.text('确认并开始新周期'));
    await tester.pumpAndSettle();
    expect(find.text('¥9,000'), findsNWidgets(2));
    expect(find.text('新工资周期已开始。'), findsOneWidget);

    final switchedCycles = await database
        .select(database.salaryCycleRecords)
        .get();
    expect(switchedCycles, hasLength(2));
    expect(
      switchedCycles.where((cycle) => cycle.status == 'active').single.id,
      'cycle-next',
    );

    await tester.tap(find.text('月报'));
    await tester.pumpAndSettle();
    expect(find.text('工资周期报告'), findsOneWidget);
    await tester.drag(
      find.descendant(
        of: find.byType(ReportScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('与上一周期对比'), findsOneWidget);

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

    await tester.drag(
      find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('分类管理'), findsOneWidget);
    expect(find.text('导出 XinFlow 备份'), findsOneWidget);
    expect(find.text('导入 XinFlow 备份'), findsOneWidget);

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

final class _SequenceIdGenerator implements IdGenerator {
  _SequenceIdGenerator(this.values);

  final List<String> values;
  var _index = 0;

  @override
  String next() => values[_index++];
}
