import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Text('我的', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dark_mode_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '外观',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '可跟随手机系统，也可以固定使用浅色或深色模式。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  preference.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => Text(
                      '主题设置读取失败：$error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    data: (selected) => SegmentedButton<AppThemePreference>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AppThemePreference.system,
                          icon: Icon(Icons.settings_brightness_outlined),
                          label: Text('跟随系统'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('浅色'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('深色'),
                        ),
                      ],
                      selected: {selected},
                      onSelectionChanged: (selection) async {
                        final next = selection.single;
                        try {
                          await ref
                              .read(settingsRepositoryProvider)
                              .updateThemePreference(next);
                        } on Object catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text('保存主题失败：$error')),
                            );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('更多设置'),
              subtitle: Text('发薪日、分类、备份与恢复将在后续里程碑开放。'),
            ),
          ),
        ],
      ),
    );
  }
}
