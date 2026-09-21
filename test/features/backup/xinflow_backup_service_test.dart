import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/backup/application/xinflow_backup_service.dart';
import 'package:xinflow/features/categories/data/drift_category_repository.dart';
import 'package:xinflow/features/categories/domain/default_categories.dart';
import 'package:xinflow/features/onboarding/application/complete_onboarding.dart';
import 'package:xinflow/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:xinflow/features/salary_cycles/data/drift_salary_cycle_repository.dart';
import 'package:xinflow/features/transactions/application/create_allocation.dart';
import 'package:xinflow/features/transactions/application/create_refund.dart';
import 'package:xinflow/features/transactions/data/drift_transaction_repository.dart';

void main() {
  const clock = _FixedClock();

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test(
    'exports, validates and idempotently merges a complete backup',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await _seed(database, clock, cycleId: 'cycle-source');
      final service = XinFlowBackupService(database: database, clock: clock);

      final artifact = await service.exportBackup();
      final preview = await service.previewImport(artifact.bytes);

      expect(artifact.fileName, endsWith('.xinflow'));
      expect(preview.counts.cycles, 1);
      expect(preview.counts.transactions, 2);
      expect(preview.hasDifferentActiveCycle, isFalse);
      expect(preview.changes.inserts, 0);
      expect(preview.changes.conflicts, 0);

      await service.importBackup(preview, mode: BackupImportMode.merge);
      await service.importBackup(preview, mode: BackupImportMode.merge);
      expect(
        await database.select(database.salaryCycleRecords).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.transactionRecords).get(),
        hasLength(2),
      );
    },
  );

  test('blocks checksum damage before any database mutation', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await _seed(database, clock, cycleId: 'cycle-source');
    final service = XinFlowBackupService(database: database, clock: clock);
    final artifact = await service.exportBackup();
    final archive = ZipDecoder().decodeBytes(artifact.bytes);
    final damaged = Archive();
    for (final file in archive.files) {
      damaged.addFile(
        file.name == 'data.json'
            ? ArchiveFile.bytes(
                file.name,
                utf8.encode('{"settings":[],"tampered":true}'),
              )
            : ArchiveFile.bytes(file.name, file.readBytes()!),
      );
    }
    final before = await database.select(database.transactionRecords).get();

    await expectLater(
      service.previewImport(ZipEncoder().encodeBytes(damaged)),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.message,
          'message',
          contains('SHA-256'),
        ),
      ),
    );
    expect(await database.select(database.transactionRecords).get(), before);
  });

  test('encrypts backups and rejects missing or incorrect passwords', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await _seed(database, clock, cycleId: 'cycle-encrypted');
    final service = XinFlowBackupService(database: database, clock: clock);
    final artifact = await service.exportBackup(password: 'correct horse');

    await expectLater(
      service.previewImport(artifact.bytes),
      throwsA(isA<BackupPasswordRequired>()),
    );
    await expectLater(
      service.previewImport(artifact.bytes, password: 'wrong password'),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.message,
          'message',
          contains('密码错误'),
        ),
      ),
    );
    final preview = await service.previewImport(
      artifact.bytes,
      password: 'correct horse',
    );
    expect(preview.counts.transactions, 2);
  });

  test(
    'keeps local data for equal-time conflicts and newer deletions',
    () async {
      final source = AppDatabase.forTesting(NativeDatabase.memory());
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);
      await _seed(source, clock, cycleId: 'shared-cycle', salaryDay: 15);
      await _seed(target, clock, cycleId: 'shared-cycle', salaryDay: 20);
      final sourceService = XinFlowBackupService(
        database: source,
        clock: clock,
      );
      final targetService = XinFlowBackupService(
        database: target,
        clock: clock,
      );
      final oldBackup = await sourceService.exportBackup();

      final transactions = DriftTransactionRepository(target, clock: clock);
      await transactions.softDeleteAllocationGroup(
        transactionId: 'expense-1',
        deletedAt: DateTime.utc(2026, 9, 21),
      );
      final preview = await targetService.previewImport(oldBackup.bytes);

      expect(preview.hasDifferentActiveCycle, isFalse);
      expect(preview.changes.conflicts, greaterThanOrEqualTo(1));
      await targetService.importBackup(preview, mode: BackupImportMode.merge);
      expect(
        (await target.select(target.appSettingRecords).getSingle()).salaryDay,
        20,
      );
      expect(
        await target.select(target.transactionRecords).get(),
        everyElement(
          predicate<TransactionRecord>((row) => row.deletedAt != null),
        ),
      );
    },
  );

  test(
    'requires replace for a different active cycle and restores all data',
    () async {
      final source = AppDatabase.forTesting(NativeDatabase.memory());
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);
      await _seed(source, clock, cycleId: 'cycle-source');
      await _seed(
        target,
        clock,
        cycleId: 'cycle-target',
        withTransactions: false,
      );

      final artifact = await XinFlowBackupService(
        database: source,
        clock: clock,
      ).exportBackup();
      final targetService = XinFlowBackupService(
        database: target,
        clock: clock,
      );
      final preview = await targetService.previewImport(artifact.bytes);
      expect(preview.hasDifferentActiveCycle, isTrue);

      await expectLater(
        targetService.importBackup(preview, mode: BackupImportMode.merge),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        (await target.select(target.salaryCycleRecords).getSingle()).id,
        'cycle-target',
      );

      await targetService.importBackup(preview, mode: BackupImportMode.replace);
      final cycles = await target.select(target.salaryCycleRecords).get();
      final transactions = await target.select(target.transactionRecords).get();
      expect(cycles.single.id, 'cycle-source');
      expect(transactions, hasLength(2));
      expect(
        transactions.where((row) => row.reversesTransactionId != null),
        hasLength(1),
      );
    },
  );
}

Future<void> _seed(
  AppDatabase database,
  Clock clock, {
  required String cycleId,
  bool withTransactions = true,
  int salaryDay = 15,
}) async {
  await CompleteOnboarding(
    repository: DriftOnboardingRepository(database),
    clock: clock,
    idGenerator: _FixedIdGenerator(cycleId),
  ).execute(salaryDay: salaryDay, salaryCents: 1000000);
  if (!withTransactions) return;

  final cycles = DriftSalaryCycleRepository(database);
  final transactions = DriftTransactionRepository(database, clock: clock);
  await CreateAllocation(
    categories: DriftCategoryRepository(database),
    salaryCycles: cycles,
    transactions: transactions,
    clock: clock,
    idGenerator: const _FixedIdGenerator('expense-1'),
  ).execute(amountCents: 12000, categoryId: DefaultCategoryIds.food);
  await CreateRefund(
    salaryCycles: cycles,
    transactions: transactions,
    clock: clock,
    idGenerator: const _FixedIdGenerator('refund-1'),
  ).execute(transactionId: 'expense-1', amountCents: 2000);
}

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026, 9, 20, 12);
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator(this.value);

  final String value;

  @override
  String next() => value;
}
