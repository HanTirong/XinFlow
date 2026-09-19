import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('shows the core salary information and shortcuts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: HomeScreen(
            snapshot: HomeSnapshot.preview(DateTime(2026, 9, 19, 12)),
          ),
        ),
      ),
    );

    expect(find.text('本期工资剩余'), findsOneWidget);
    expect(find.text('¥6,380'), findsOneWidget);
    expect(find.text('快速记一笔'), findsOneWidget);
    expect(find.text('饮食'), findsOneWidget);
    expect(find.text('存款'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('最近记录'), findsOneWidget);
  });
}
