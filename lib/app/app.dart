import 'package:flutter/material.dart';
import 'package:xinflow/app/theme/app_theme.dart';
import 'package:xinflow/features/navigation/presentation/main_shell.dart';

final class XinFlowApp extends StatelessWidget {
  const XinFlowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '薪流',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: const MainShell(),
  );
}
