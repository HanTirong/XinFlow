import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

enum BackupImportMode { merge, replace }

final class BackupArtifact {
  const BackupArtifact({
    required this.fileName,
    required this.bytes,
    required this.counts,
  });

  final String fileName;
  final Uint8List bytes;
  final BackupCounts counts;
}

final class BackupCounts {
  const BackupCounts({
    required this.categories,
    required this.cycles,
    required this.transactions,
  });

  final int categories;
  final int cycles;
  final int transactions;
}

final class BackupChangeSummary {
  const BackupChangeSummary({
    required this.inserts,
    required this.updates,
    required this.skips,
    required this.conflicts,
    required this.deletedMarkers,
  });

  final int inserts;
  final int updates;
  final int skips;
  final int conflicts;
  final int deletedMarkers;

  BackupChangeSummary operator +(BackupChangeSummary other) =>
      BackupChangeSummary(
        inserts: inserts + other.inserts,
        updates: updates + other.updates,
        skips: skips + other.skips,
        conflicts: conflicts + other.conflicts,
        deletedMarkers: deletedMarkers + other.deletedMarkers,
      );
}

final class BackupImportPreview {
  const BackupImportPreview._(
    this._payload, {
    required this.exportedAt,
    required this.counts,
    required this.changes,
    required this.hasDifferentActiveCycle,
  });

  final DateTime exportedAt;
  final BackupCounts counts;
  final BackupChangeSummary changes;
  final _BackupPayload _payload;
  final bool hasDifferentActiveCycle;
}

final class BackupImportResult {
  const BackupImportResult({required this.mode, required this.counts});

  final BackupImportMode mode;
  final BackupCounts counts;
}

final class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class XinFlowBackupService {
  const XinFlowBackupService({required this._database, required this._clock});

  static const backupVersion = 1;
  static const maximumBackupBytes = 50 * 1024 * 1024;
  static const maximumManifestBytes = 1024 * 1024;
  static const maximumEntityCount = 100000;

  final AppDatabase _database;
  final Clock _clock;

  Future<BackupArtifact> exportBackup() async {
    final settings = await _database.select(_database.appSettingRecords).get();
    final categories = await _database.select(_database.categoryRecords).get();
    final cycles = await _database.select(_database.salaryCycleRecords).get();
    final transactions = await _database
        .select(_database.transactionRecords)
        .get();
    if (settings.length != 1) {
      throw StateError('设置表状态异常，无法导出备份。');
    }

    categories.sort((a, b) => a.id.compareTo(b.id));
    cycles.sort((a, b) => a.id.compareTo(b.id));
    transactions.sort((a, b) => a.id.compareTo(b.id));
    final data = <String, Object?>{
      'settings': settings.map((row) => row.toJson()).toList(),
      'categories': categories.map((row) => row.toJson()).toList(),
      'salaryCycles': cycles.map((row) => row.toJson()).toList(),
      'transactions': transactions.map((row) => row.toJson()).toList(),
    };
    final dataText = jsonEncode(data);
    final dataBytes = utf8.encode(dataText);
    final digest = sha256.convert(dataBytes).toString();
    final exportedAt = _clock.now().toUtc();
    final manifest = jsonEncode({
      'format': 'xinflow-backup',
      'backupVersion': backupVersion,
      'appVersion': '0.1.0',
      'databaseSchemaVersion': _database.schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'currencyCode': 'CNY',
      'dataFile': 'data.json',
      'dataSha256': digest,
    });

    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest.json', manifest))
      ..addFile(ArchiveFile.bytes('data.json', dataBytes))
      ..addFile(ArchiveFile.string('checksum.sha256', '$digest  data.json\n'));
    final bytes = ZipEncoder().encodeBytes(archive);
    final timestamp =
        '${exportedAt.year.toString().padLeft(4, '0')}'
        '${exportedAt.month.toString().padLeft(2, '0')}'
        '${exportedAt.day.toString().padLeft(2, '0')}-'
        '${exportedAt.hour.toString().padLeft(2, '0')}'
        '${exportedAt.minute.toString().padLeft(2, '0')}'
        '${exportedAt.second.toString().padLeft(2, '0')}';
    return BackupArtifact(
      fileName: 'xinflow-backup-$timestamp.xinflow',
      bytes: bytes,
      counts: BackupCounts(
        categories: categories.length,
        cycles: cycles.length,
        transactions: transactions.length,
      ),
    );
  }

  Future<BackupImportPreview> previewImport(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maximumBackupBytes) {
      throw const BackupFormatException('备份文件为空或超过 50MB 限制。');
    }
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const BackupFormatException('文件不是有效的 XinFlow ZIP 备份。');
    }
    final names = archive.files.map((file) => file.name).toSet();
    const expected = {'manifest.json', 'data.json', 'checksum.sha256'};
    if (names.length != expected.length || !names.containsAll(expected)) {
      throw const BackupFormatException('备份缺少 manifest、data 或 checksum 文件。');
    }
    for (final file in archive.files) {
      final limit = file.name == 'data.json'
          ? maximumBackupBytes
          : maximumManifestBytes;
      if (file.size > limit) {
        throw BackupFormatException('备份中的 ${file.name} 超过大小限制。');
      }
    }
    final manifest = _decodeObject(_readText(archive, 'manifest.json'));
    if (manifest['format'] != 'xinflow-backup' ||
        manifest['backupVersion'] != backupVersion ||
        manifest['currencyCode'] != 'CNY') {
      throw const BackupFormatException('备份格式、版本或币种不受支持。');
    }
    final schemaVersion = manifest['databaseSchemaVersion'];
    if (schemaVersion is! int || schemaVersion > _database.schemaVersion) {
      throw const BackupFormatException('备份来自更新的数据库版本，当前应用无法恢复。');
    }
    final dataText = _readText(archive, 'data.json');
    final actualDigest = sha256.convert(utf8.encode(dataText)).toString();
    if (manifest['dataSha256'] != actualDigest) {
      throw const BackupFormatException('data.json 的 SHA-256 校验失败。');
    }
    final checksumText = _readText(archive, 'checksum.sha256').trim();
    if (!checksumText.startsWith(actualDigest)) {
      throw const BackupFormatException('checksum.sha256 与数据不一致。');
    }

    final payload = _BackupPayload.fromJson(_decodeObject(dataText));
    _validatePayload(payload);
    final exportedAt = DateTime.tryParse('${manifest['exportedAt']}');
    if (exportedAt == null) {
      throw const BackupFormatException('备份导出时间无效。');
    }
    final localActive =
        await (_database.select(_database.salaryCycleRecords)..where(
              (row) =>
                  row.status.equals(SalaryCycleStatus.active.name) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    final importedActive = payload.cycles
        .where(
          (row) =>
              row.status == SalaryCycleStatus.active.name &&
              row.deletedAt == null,
        )
        .firstOrNull;
    final changes = await _previewChanges(payload);
    return BackupImportPreview._(
      payload,
      exportedAt: exportedAt.toUtc(),
      counts: payload.counts,
      changes: changes,
      hasDifferentActiveCycle:
          localActive != null &&
          importedActive != null &&
          localActive.id != importedActive.id,
    );
  }

  Future<BackupImportResult> importBackup(
    BackupImportPreview preview, {
    required BackupImportMode mode,
  }) async {
    if (mode == BackupImportMode.merge && preview.hasDifferentActiveCycle) {
      throw const BackupFormatException('本机与备份包含不同的活动工资周期，请选择覆盖恢复。');
    }
    await _database.transaction(() async {
      if (mode == BackupImportMode.replace) {
        await _database.delete(_database.transactionRecords).go();
        await _database.delete(_database.salaryCycleRecords).go();
        await _database.delete(_database.categoryRecords).go();
        await _database.delete(_database.appSettingRecords).go();
      }
      await _importPayload(
        preview._payload,
        merge: mode == BackupImportMode.merge,
      );
    });
    return BackupImportResult(mode: mode, counts: preview.counts);
  }

  Future<void> _importPayload(
    _BackupPayload payload, {
    required bool merge,
  }) async {
    Future<void> upsertSettings(AppSettingRecord row) async {
      if (merge) {
        final local = await _database
            .select(_database.appSettingRecords)
            .getSingleOrNull();
        if (local != null &&
            (local.updatedAt >= row.updatedAt || _same(local, row))) {
          return;
        }
      }
      await _database
          .into(_database.appSettingRecords)
          .insertOnConflictUpdate(row);
    }

    Future<void> upsertCategory(CategoryRecord row) async {
      if (merge) {
        final local = await (_database.select(
          _database.categoryRecords,
        )..where((item) => item.id.equals(row.id))).getSingleOrNull();
        if (local != null &&
            (local.updatedAt >= row.updatedAt || _same(local, row))) {
          return;
        }
      }
      await _database
          .into(_database.categoryRecords)
          .insertOnConflictUpdate(row);
    }

    Future<void> upsertCycle(SalaryCycleRecord row) async {
      if (merge) {
        final local = await (_database.select(
          _database.salaryCycleRecords,
        )..where((item) => item.id.equals(row.id))).getSingleOrNull();
        if (local != null &&
            (local.updatedAt >= row.updatedAt || _same(local, row))) {
          return;
        }
      }
      await _database
          .into(_database.salaryCycleRecords)
          .insertOnConflictUpdate(row);
    }

    Future<void> upsertTransaction(TransactionRecord row) async {
      if (merge) {
        final local = await (_database.select(
          _database.transactionRecords,
        )..where((item) => item.id.equals(row.id))).getSingleOrNull();
        if (local != null &&
            (local.updatedAt >= row.updatedAt || _same(local, row))) {
          return;
        }
      }
      await _database
          .into(_database.transactionRecords)
          .insertOnConflictUpdate(row);
    }

    await upsertSettings(payload.settings.single);
    for (final row in payload.categories.where((row) => row.parentId == null)) {
      await upsertCategory(row);
    }
    for (final row in payload.categories.where((row) => row.parentId != null)) {
      await upsertCategory(row);
    }
    for (final row in payload.cycles.where(
      (row) => row.status != SalaryCycleStatus.active.name,
    )) {
      await upsertCycle(row);
    }
    for (final row in payload.cycles.where(
      (row) => row.status == SalaryCycleStatus.active.name,
    )) {
      await upsertCycle(row);
    }
    for (final row in payload.transactions.where(
      (row) => row.entryKind != EntryKind.refund.name,
    )) {
      await upsertTransaction(row);
    }
    for (final row in payload.transactions.where(
      (row) => row.entryKind == EntryKind.refund.name,
    )) {
      await upsertTransaction(row);
    }
  }

  Future<BackupChangeSummary> _previewChanges(_BackupPayload payload) async {
    final localSettings = await _database
        .select(_database.appSettingRecords)
        .get();
    final localCategories = await _database
        .select(_database.categoryRecords)
        .get();
    final localCycles = await _database
        .select(_database.salaryCycleRecords)
        .get();
    final localTransactions = await _database
        .select(_database.transactionRecords)
        .get();
    return _summarizeChanges<AppSettingRecord>(
          imported: payload.settings,
          local: localSettings,
          idOf: (row) => row.singletonId,
          updatedAtOf: (row) => row.updatedAt,
          deletedAtOf: (_) => null,
        ) +
        _summarizeChanges<CategoryRecord>(
          imported: payload.categories,
          local: localCategories,
          idOf: (row) => row.id,
          updatedAtOf: (row) => row.updatedAt,
          deletedAtOf: (row) => row.deletedAt,
        ) +
        _summarizeChanges<SalaryCycleRecord>(
          imported: payload.cycles,
          local: localCycles,
          idOf: (row) => row.id,
          updatedAtOf: (row) => row.updatedAt,
          deletedAtOf: (row) => row.deletedAt,
        ) +
        _summarizeChanges<TransactionRecord>(
          imported: payload.transactions,
          local: localTransactions,
          idOf: (row) => row.id,
          updatedAtOf: (row) => row.updatedAt,
          deletedAtOf: (row) => row.deletedAt,
        );
  }

  BackupChangeSummary _summarizeChanges<T extends DataClass>({
    required Iterable<T> imported,
    required Iterable<T> local,
    required Object Function(T row) idOf,
    required int Function(T row) updatedAtOf,
    required int? Function(T row) deletedAtOf,
  }) {
    final localById = {for (final row in local) idOf(row): row};
    var inserts = 0;
    var updates = 0;
    var skips = 0;
    var conflicts = 0;
    var deletedMarkers = 0;
    for (final row in imported) {
      if (deletedAtOf(row) != null) deletedMarkers++;
      final existing = localById[idOf(row)];
      if (existing == null) {
        inserts++;
      } else if (_same(existing, row) ||
          updatedAtOf(existing) > updatedAtOf(row)) {
        skips++;
      } else if (updatedAtOf(existing) < updatedAtOf(row)) {
        updates++;
      } else {
        conflicts++;
      }
    }
    return BackupChangeSummary(
      inserts: inserts,
      updates: updates,
      skips: skips,
      conflicts: conflicts,
      deletedMarkers: deletedMarkers,
    );
  }

  bool _same(DataClass first, DataClass second) =>
      jsonEncode(first.toJson()) == jsonEncode(second.toJson());

  String _readText(Archive archive, String name) {
    final file = archive.files.where((entry) => entry.name == name).firstOrNull;
    final bytes = file?.readBytes();
    if (bytes == null) throw BackupFormatException('备份中的 $name 无法读取。');
    try {
      return utf8.decode(bytes);
    } on Object {
      throw BackupFormatException('备份中的 $name 不是有效 UTF-8。');
    }
  }

  Map<String, dynamic> _decodeObject(String text) {
    try {
      final value = jsonDecode(text);
      if (value is Map<String, dynamic>) return value;
    } on Object {
      // Converted to a stable product error below.
    }
    throw const BackupFormatException('备份 JSON 结构无效。');
  }

  void _validatePayload(_BackupPayload payload) {
    if (payload.settings.length != 1) {
      throw const BackupFormatException('备份必须包含且只能包含一条设置记录。');
    }
    if (payload.categories.length +
            payload.cycles.length +
            payload.transactions.length >
        maximumEntityCount) {
      throw const BackupFormatException('备份实体数量超过 100000 条限制。');
    }
    final settings = payload.settings.single;
    if (settings.singletonId != 1 ||
        settings.salaryDay < 1 ||
        settings.salaryDay > 31 ||
        settings.currencyCode != 'CNY' ||
        !settings.onboardingCompleted ||
        !AppThemePreference.values.any(
          (value) => value.name == settings.themeMode,
        )) {
      throw const BackupFormatException('备份设置记录不符合当前版本约束。');
    }
    _ensureUnique(payload.categories.map((row) => row.id), '分类');
    _ensureUnique(payload.cycles.map((row) => row.id), '工资周期');
    _ensureUnique(payload.transactions.map((row) => row.id), '流水');
    final categoryIds = payload.categories.map((row) => row.id).toSet();
    final cycleIds = payload.cycles.map((row) => row.id).toSet();
    final transactionIds = payload.transactions.map((row) => row.id).toSet();
    final categoriesById = {
      for (final category in payload.categories) category.id: category,
    };
    final transactionsById = {
      for (final transaction in payload.transactions)
        transaction.id: transaction,
    };
    for (final category in payload.categories) {
      if (category.name.trim().isEmpty ||
          !FlowType.values.any((value) => value.name == category.flowType)) {
        throw const BackupFormatException('备份包含无效分类。');
      }
      if (category.parentId != null &&
          !categoryIds.contains(category.parentId)) {
        throw const BackupFormatException('备份包含找不到上级的二级分类。');
      }
      final parent = categoriesById[category.parentId];
      if (parent != null &&
          (parent.parentId != null || parent.flowType != category.flowType)) {
        throw const BackupFormatException('备份分类层级或性质不一致。');
      }
    }
    for (final cycle in payload.cycles) {
      if (cycle.salaryCents < 0 ||
          !_isValidDate(cycle.expectedPayDate) ||
          !SalaryCycleStatus.values.any(
            (value) => value.name == cycle.status,
          )) {
        throw const BackupFormatException('备份包含无效工资周期。');
      }
    }
    for (final transaction in payload.transactions) {
      if (transaction.amountCents <= 0 ||
          !_isValidDate(transaction.occurredOn) ||
          !EntryKind.values.any(
            (value) => value.name == transaction.entryKind,
          ) ||
          !FlowType.values.any((value) => value.name == transaction.flowType)) {
        throw const BackupFormatException('备份包含无效流水字段。');
      }
      if (!cycleIds.contains(transaction.salaryCycleId) ||
          !categoryIds.contains(transaction.categoryId) ||
          (transaction.subcategoryId != null &&
              !categoryIds.contains(transaction.subcategoryId))) {
        throw const BackupFormatException('备份流水引用了不存在的周期或分类。');
      }
      if (transaction.entryKind == EntryKind.refund.name &&
          !transactionIds.contains(transaction.reversesTransactionId)) {
        throw const BackupFormatException('备份退款引用了不存在的原消费。');
      }
      final category = categoriesById[transaction.categoryId];
      final subcategory = categoriesById[transaction.subcategoryId];
      if (category?.parentId != null ||
          (subcategory != null &&
              subcategory.parentId != transaction.categoryId)) {
        throw const BackupFormatException('备份流水的分类层级无效。');
      }
      if (transaction.entryKind == EntryKind.refund.name) {
        final original = transactionsById[transaction.reversesTransactionId];
        if (original == null ||
            original.entryKind != EntryKind.allocation.name ||
            original.flowType != FlowType.expense.name ||
            original.salaryCycleId != transaction.salaryCycleId ||
            original.categoryId != transaction.categoryId) {
          throw const BackupFormatException('备份退款与原消费不匹配。');
        }
      } else if (transaction.reversesTransactionId != null) {
        throw const BackupFormatException('普通流水不能包含退款关联。');
      }
    }
    for (final original in payload.transactions.where(
      (row) => row.entryKind == EntryKind.allocation.name,
    )) {
      final refunded = payload.transactions
          .where(
            (row) =>
                row.entryKind == EntryKind.refund.name &&
                row.reversesTransactionId == original.id &&
                row.deletedAt == null,
          )
          .fold<int>(0, (sum, row) => sum + row.amountCents);
      if (refunded > original.amountCents) {
        throw const BackupFormatException('备份中的累计退款超过原消费金额。');
      }
    }
    final activeCount = payload.cycles
        .where(
          (row) =>
              row.status == SalaryCycleStatus.active.name &&
              row.deletedAt == null,
        )
        .length;
    if (activeCount != 1) {
      throw const BackupFormatException('备份必须包含且只能包含一个活动工资周期。');
    }
  }

  void _ensureUnique(Iterable<String> ids, String label) {
    final values = ids.toList();
    if (values.toSet().length != values.length) {
      throw BackupFormatException('备份包含重复的$label ID。');
    }
  }

  bool _isValidDate(String value) {
    try {
      LocalDate.parse(value);
      return true;
    } on FormatException {
      return false;
    }
  }
}

final class _BackupPayload {
  const _BackupPayload({
    required this.settings,
    required this.categories,
    required this.cycles,
    required this.transactions,
  });

  factory _BackupPayload.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) {
      final value = json[key];
      if (value is! List) throw BackupFormatException('备份缺少 $key 数组。');
      return value
          .map((item) {
            if (item is! Map) throw BackupFormatException('$key 包含无效记录。');
            return Map<String, dynamic>.from(item);
          })
          .toList(growable: false);
    }

    try {
      return _BackupPayload(
        settings: list(
          'settings',
        ).map(AppSettingRecord.fromJson).toList(growable: false),
        categories: list(
          'categories',
        ).map(CategoryRecord.fromJson).toList(growable: false),
        cycles: list(
          'salaryCycles',
        ).map(SalaryCycleRecord.fromJson).toList(growable: false),
        transactions: list(
          'transactions',
        ).map(TransactionRecord.fromJson).toList(growable: false),
      );
    } on BackupFormatException {
      rethrow;
    } on Object {
      throw const BackupFormatException('备份数据字段类型无效。');
    }
  }

  final List<AppSettingRecord> settings;
  final List<CategoryRecord> categories;
  final List<SalaryCycleRecord> cycles;
  final List<TransactionRecord> transactions;

  BackupCounts get counts => BackupCounts(
    categories: categories.length,
    cycles: cycles.length,
    transactions: transactions.length,
  );
}
