import 'package:flutter/material.dart';
import 'package:xinflow/features/home/domain/home_snapshot.dart';
import 'package:xinflow/features/home/presentation/home_screen.dart';
import 'package:xinflow/shared/presentation/placeholder_page.dart';

final class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

final class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomeScreen(snapshot: HomeSnapshot.preview(DateTime.now())),
    const PlaceholderPage(
      icon: Icons.receipt_long_outlined,
      title: '流水',
      description: '流水列表将在数据库接入后实现。',
    ),
    const PlaceholderPage(
      icon: Icons.pie_chart_outline_rounded,
      title: '月报',
      description: '这里将展示一个完整工资周期的数据。',
    ),
    const PlaceholderPage(
      icon: Icons.person_outline_rounded,
      title: '我的',
      description: '发薪日、分类、备份与恢复设置将在这里管理。',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _selectedIndex, children: _pages),
    floatingActionButton: _selectedIndex == 0
        ? FloatingActionButton.extended(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('记一笔将在数据库接入后开放。')));
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('记一笔'),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: '流水',
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_outline_rounded),
          selectedIcon: Icon(Icons.pie_chart_rounded),
          label: '月报',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: '我的',
        ),
      ],
    ),
  );
}
