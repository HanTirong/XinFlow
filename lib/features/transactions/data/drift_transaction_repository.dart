import 'package:drift/drift.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/database/database_mappers.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

final class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(
    this._database, {
    this.clock = const SystemClock(),
  });

  final AppDatabase _database;
  final Clock clock;

  @override
  Stream<List<TransactionEntry>> watchCycleTransactions(String salaryCycleId) =>
      (_database.select(_database.transactionRecords)
            ..where((row) => row.salaryCycleId.equals(salaryCycleId))
            ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)]))
          .watch()
          .map(
            (rows) => rows.map((row) => row.toDomain()).toList(growable: false),
          );

  @override
  Future<List<TransactionEntry>> listCycleTransactions(
    String salaryCycleId,
  ) async {
    final rows =
        await (_database.select(_database.transactionRecords)
              ..where((row) => row.salaryCycleId.equals(salaryCycleId))
              ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)]))
            .get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<TransactionEntry?> getById(String transactionId) async {
    final row = await (_database.select(
      _database.transactionRecords,
    )..where((row) => row.id.equals(transactionId))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> add(TransactionEntry entry) async {
    final now = clock.now().toUtc().millisecondsSinceEpoch;
    await _database
        .into(_database.transactionRecords)
        .insert(
          TransactionRecordsCompanion.insert(
            id: entry.id,
            salaryCycleId: entry.salaryCycleId,
            entryKind: entry.entryKind.name,
            flowType: entry.flowType.name,
            amountCents: entry.amountCents,
            categoryId: entry.categoryId,
            subcategoryId: Value(entry.subcategoryId),
            reversesTransactionId: Value(entry.reversesTransactionId),
            occurredAt: entry.occurredAt.toUtc().millisecondsSinceEpoch,
            occurredOn: entry.occurredOn.toString(),
            note: Value(entry.note),
            createdAt: now,
            updatedAt: now,
            deletedAt: Value(entry.deletedAt?.toUtc().millisecondsSinceEpoch),
          ),
        );
  }

  @override
  Future<void> update(TransactionEntry entry) async {
    final updatedRows =
        await (_database.update(
          _database.transactionRecords,
        )..where((row) => row.id.equals(entry.id))).write(
          TransactionRecordsCompanion(
            salaryCycleId: Value(entry.salaryCycleId),
            entryKind: Value(entry.entryKind.name),
            flowType: Value(entry.flowType.name),
            amountCents: Value(entry.amountCents),
            categoryId: Value(entry.categoryId),
            subcategoryId: Value(entry.subcategoryId),
            reversesTransactionId: Value(entry.reversesTransactionId),
            occurredAt: Value(entry.occurredAt.toUtc().millisecondsSinceEpoch),
            occurredOn: Value(entry.occurredOn.toString()),
            note: Value(entry.note),
            updatedAt: Value(clock.now().toUtc().millisecondsSinceEpoch),
            deletedAt: Value(entry.deletedAt?.toUtc().millisecondsSinceEpoch),
          ),
        );
    if (updatedRows != 1) {
      throw StateError('要修改的流水不存在。');
    }
  }

  @override
  Future<void> softDelete({
    required String transactionId,
    required DateTime deletedAt,
  }) async {
    final timestamp = deletedAt.toUtc().millisecondsSinceEpoch;
    final updatedRows =
        await (_database.update(_database.transactionRecords)..where(
              (row) => row.id.equals(transactionId) & row.deletedAt.isNull(),
            ))
            .write(
              TransactionRecordsCompanion(
                deletedAt: Value(timestamp),
                updatedAt: Value(timestamp),
              ),
            );
    if (updatedRows != 1) {
      throw StateError('要删除的流水不存在或已经删除。');
    }
  }

  @override
  Future<void> softDeleteAllocationGroup({
    required String transactionId,
    required DateTime deletedAt,
  }) => _database.transaction(() async {
    final timestamp = deletedAt.toUtc().millisecondsSinceEpoch;
    final originalRows =
        await (_database.update(_database.transactionRecords)..where(
              (row) =>
                  row.id.equals(transactionId) &
                  row.entryKind.equals(EntryKind.allocation.name) &
                  row.deletedAt.isNull(),
            ))
            .write(
              TransactionRecordsCompanion(
                deletedAt: Value(timestamp),
                updatedAt: Value(timestamp),
              ),
            );
    if (originalRows != 1) {
      throw StateError('要删除的流水不存在或已经删除。');
    }

    await (_database.update(_database.transactionRecords)..where(
          (row) =>
              row.reversesTransactionId.equals(transactionId) &
              row.entryKind.equals(EntryKind.refund.name) &
              row.deletedAt.isNull(),
        ))
        .write(
          TransactionRecordsCompanion(
            deletedAt: Value(timestamp),
            updatedAt: Value(timestamp),
          ),
        );
  });
}
