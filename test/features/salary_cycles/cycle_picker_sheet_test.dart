import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/salary_cycles/presentation/cycle_picker_sheet.dart';

void main() {
  testWidgets('selects an existing salary cycle with the wheel picker', (
    tester,
  ) async {
    final cycles = [
      SalaryCycle(
        id: 'current',
        salaryCents: 1300000,
        startedAt: DateTime(2026, 9, 10),
        expectedPayDate: const LocalDate(2026, 10, 10),
        status: SalaryCycleStatus.active,
      ),
      SalaryCycle(
        id: 'previous',
        salaryCents: 1200000,
        startedAt: DateTime(2026, 8, 10),
        expectedPayDate: const LocalDate(2026, 9, 10),
        status: SalaryCycleStatus.closed,
        closedAt: DateTime(2026, 9, 10),
        finalRemainingCents: 50000,
      ),
    ];
    var selected = 'current';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                final result = await showSalaryCyclePicker(
                  context: context,
                  cycles: cycles,
                  selectedCycleId: selected,
                );
                if (result != null) selected = result;
              },
              child: const Text('选择周期'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('选择周期'));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('2026-09-10 ～ 2026-10-10'), findsOneWidget);
    expect(find.text('2026-08-10 ～ 2026-09-10'), findsOneWidget);

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -70));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(selected, 'previous');
    expect(find.text('选择工资周期'), findsNothing);
  });
}
