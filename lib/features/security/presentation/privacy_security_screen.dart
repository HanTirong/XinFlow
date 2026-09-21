import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';

final class PrivacySecurityCard extends StatelessWidget {
  const PrivacySecurityCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.privacy_tip_outlined),
      title: const Text('隐私与本地安全'),
      subtitle: const Text('隐藏金额、应用锁与本地数据说明'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PrivacySecurityScreen()),
      ),
    ),
  );
}

final class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('隐私与本地安全')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.visibility_off_outlined),
                        title: const Text('默认隐藏金额'),
                        subtitle: const Text('首页金额以圆点显示，可临时点眼睛查看。'),
                        value: settings.hideAmounts,
                        onChanged: (value) => ref
                            .read(settingsRepositoryProvider)
                            .updatePrivacy(hideAmounts: value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint_rounded),
                        title: const Text('应用锁'),
                        subtitle: const Text('使用系统指纹、人脸或设备密码验证。'),
                        value: settings.appLockEnabled,
                        onChanged: (value) => _setAppLock(context, ref, value),
                      ),
                      if (settings.appLockEnabled)
                        ListTile(
                          leading: const Icon(Icons.timer_outlined),
                          title: const Text('自动锁定'),
                          trailing: DropdownButton<int>(
                            value: settings.autoLockMinutes,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('立即')),
                              DropdownMenuItem(value: 1, child: Text('1 分钟')),
                              DropdownMenuItem(value: 5, child: Text('5 分钟')),
                              DropdownMenuItem(value: 15, child: Text('15 分钟')),
                              DropdownMenuItem(value: 30, child: Text('30 分钟')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(settingsRepositoryProvider)
                                    .updatePrivacy(autoLockMinutes: value);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('隐私说明', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      '薪流的工资周期、流水、分类、预算和设置默认仅保存在本机。'
                      '应用不包含账号系统、云同步、广告追踪或自动账单上传。\n\n'
                      '导出的 .xinflow 文件由你自行保管；启用密码备份后，文件内容使用密码派生密钥加密。'
                      '忘记备份密码后无法恢复。\n\n'
                      '系统身份验证由 Android 或 iOS 提供，薪流不会读取或保存你的指纹、人脸和设备密码。',
                      style: TextStyle(height: 1.6),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _setAppLock(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (!enabled) {
      await ref
          .read(settingsRepositoryProvider)
          .updatePrivacy(appLockEnabled: false);
      return;
    }
    final authenticator = ref.read(deviceAuthenticatorProvider);
    final available = await authenticator.isAvailable();
    if (!available) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('此设备未配置可用的系统身份验证。')));
      }
      return;
    }
    final authenticated = await ref
        .read(deviceAuthenticationSessionProvider)
        .authenticate(authenticator);
    if (authenticated) {
      await ref
          .read(settingsRepositoryProvider)
          .updatePrivacy(appLockEnabled: true);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('身份验证未通过，应用锁没有启用。')));
    }
  }
}
