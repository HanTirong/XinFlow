import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';
import 'package:xinflow/features/backup/application/xinflow_backup_service.dart';

final class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

final class _BackupCardState extends ConsumerState<BackupCard> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('导出 XinFlow 备份'),
            subtitle: const Text('工资周期、流水、分类与设置会写入一个带完整性校验的文件'),
            trailing: _isWorking
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_upload_outlined),
            onTap: _isWorking ? null : _exportBackup,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('导入 XinFlow 备份'),
            subtitle: const Text('仅支持本应用导出的 .xinflow 文件，恢复前会先校验'),
            trailing: const Icon(Icons.file_download_outlined),
            onTap: _isWorking ? null : _importBackup,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('数据默认只保存在本机；只有你主动导出时才会创建备份文件。')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _isWorking = true);
    try {
      final artifact = await ref.read(backupServiceProvider).exportBackup();
      final uri = await FilePicker.saveFile(
        dialogTitle: '保存 XinFlow 备份',
        fileName: artifact.fileName,
        bytes: artifact.bytes,
        mimeType: 'application/zip',
      );
      if (uri == null || !mounted) return;
      _showMessage(
        '备份已导出：${artifact.counts.cycles} 个周期、'
        '${artifact.counts.transactions} 条流水。',
      );
    } on Object catch (error) {
      if (mounted) _showMessage('导出失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isWorking = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: '选择 XinFlow 备份',
        type: FileType.custom,
        allowedExtensions: const ['xinflow'],
      );
      if (file == null || !mounted) return;
      final preview = await ref
          .read(backupServiceProvider)
          .previewImport(await file.readAsBytes());
      if (!mounted) return;
      final mode = await _chooseImportMode(preview);
      if (mode == null || !mounted) return;
      final result = await ref
          .read(backupServiceProvider)
          .importBackup(preview, mode: mode);
      _refreshAllData();
      if (!mounted) return;
      _showMessage(
        '${mode == BackupImportMode.merge ? '合并' : '覆盖'}恢复完成：'
        '${result.counts.cycles} 个周期、${result.counts.transactions} 条流水。',
      );
    } on Object catch (error) {
      if (mounted) _showMessage('导入失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<BackupImportMode?> _chooseImportMode(BackupImportPreview preview) =>
      showDialog<BackupImportMode>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入备份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('导出时间：${_formatDateTime(preview.exportedAt.toLocal())}'),
              const SizedBox(height: 8),
              Text(
                '${preview.counts.categories} 个分类 · '
                '${preview.counts.cycles} 个周期 · '
                '${preview.counts.transactions} 条流水',
              ),
              const SizedBox(height: 8),
              Text(
                '预计新增 ${preview.changes.inserts} · '
                '更新 ${preview.changes.updates} · '
                '跳过 ${preview.changes.skips} · '
                '冲突 ${preview.changes.conflicts}',
              ),
              if (preview.changes.deletedMarkers > 0)
                Text('包含 ${preview.changes.deletedMarkers} 条删除标记'),
              const SizedBox(height: 12),
              Text(
                preview.hasDifferentActiveCycle
                    ? '本机与备份的活动周期不同，只能覆盖恢复。覆盖会先清空本机数据。'
                    : '合并会按 ID 和更新时间保留较新的记录；覆盖会先清空本机数据。',
                style: TextStyle(
                  color: preview.hasDifferentActiveCycle
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            if (!preview.hasDifferentActiveCycle)
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(BackupImportMode.merge),
                child: const Text('合并'),
              ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(BackupImportMode.replace),
              child: const Text('覆盖恢复'),
            ),
          ],
        ),
      );

  void _refreshAllData() {
    ref
      ..invalidate(startupProvider)
      ..invalidate(themePreferenceProvider)
      ..invalidate(homeSnapshotProvider)
      ..invalidate(currentCycleTransactionsProvider)
      ..invalidate(salaryCyclesProvider)
      ..invalidate(cycleTransactionsProvider)
      ..invalidate(cycleReportProvider)
      ..invalidate(activeCategoriesProvider)
      ..invalidate(allCategoriesProvider);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }
}

String _formatDateTime(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
