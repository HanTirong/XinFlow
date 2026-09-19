import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/core/clock/clock.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/core/id/id_generator.dart';
import 'package:xinflow/features/salary_cycles/application/close_and_start_next_cycle.dart';
import 'package:xinflow/features/salary_cycles/data/salary_cycle_repository.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/transactions/data/transaction_repository.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

void main() {
  test(
    'persists one atomic cycle replacement with no balance rollover',
    () async {
      final activeCycle = SalaryCycle(
        id: 'cycle-1',
        salaryCents: 1000000,
        startedAt: DateTime.utc(2026, 8, 15),
        expectedPayDate: const LocalDate(2026, 9, 15),
        status: SalaryCycleStatus.active,
      );
      final cycles = _FakeSalaryCycleRepository(activeCycle);
      final transactions = _FakeTransactionRepository([
        TransactionEntry(
          id: 'expense-1',
          salaryCycleId: activeCycle.id,
          entryKind: EntryKind.allocation,
          flowType: FlowType.expense,
          amountCents: 400000,
          categoryId: 'food',
          occurredAt: DateTime.utc(2026, 9, 1),
          occurredOn: const LocalDate(2026, 9, 1),
        ),
      ]);
      final useCase = CloseAndStartNextCycle(
        salaryCycles: cycles,
        transactions: transactions,
        clock: _FixedClock(DateTime.utc(2026, 9, 13, 9)),
        idGenerator: _FixedIdGenerator('cycle-2'),
      );

      final transition = await useCase.execute(
        newSalaryCents: 1200000,
        salaryDay: 15,
      );

      expect(cycles.replaceCallCount, 1);
      expect(transition.closedCycle.finalRemainingCents, 600000);
      expect(transition.newActiveCycle.salaryCents, 1200000);
      expect(
        transition.newActiveCycle.expectedPayDate,
        const LocalDate(2026, 10, 15),
      );
    },
  );

  test('fails without writing when no active cycle exists', () async {
    final cycles = _FakeSalaryCycleRepository(null);
    final useCase = CloseAndStartNextCycle(
      salaryCycles: cycles,
      transactions: _FakeTransactionRepository(const []),
      clock: _FixedClock(DateTime.utc(2026, 9, 13, 9)),
      idGenerator: _FixedIdGenerator('cycle-2'),
    );

    await expectLater(
      useCase.execute(newSalaryCents: 1200000, salaryDay: 15),
      throwsA(isA<NoActiveSalaryCycle>()),
    );
    expect(cycles.replaceCallCount, 0);
  });
}

final class _FakeSalaryCycleRepository implements SalaryCycleRepository {
  _FakeSalaryCycleRepository(this.activeCycle);

  SalaryCycle? activeCycle;
  int replaceCallCount = 0;

  @override
  Future<SalaryCycle?> getActiveCycle() async => activeCycle;

  @override
  Future<List<SalaryCycle>> listClosedCycles() async => const [];

  @override
  Future<void> replaceActiveCycle({
    required SalaryCycle closedCycle,
    required SalaryCycle newActiveCycle,
  }) async {
    replaceCallCount++;
    activeCycle = newActiveCycle;
  }

  @override
  Stream<SalaryCycle?> watchActiveCycle() => Stream.value(activeCycle);
}

final class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository(this.entries);

  final List<TransactionEntry> entries;

  @override
  Future<TransactionEntry?> getById(String transactionId) async {
    for (final entry in entries) {
      if (entry.id == transactionId) return entry;
    }
    return null;
  }

  @override
  Future<List<TransactionEntry>> listRefundsFor(String transactionId) async =>
      entries
          .where((entry) => entry.reversesTransactionId == transactionId)
          .toList(growable: false);

  @override
  Future<void> add(TransactionEntry entry) => throw UnimplementedError();

  @override
  Future<List<TransactionEntry>> listCycleTransactions(
    String salaryCycleId,
  ) async => entries
      .where((entry) => entry.salaryCycleId == salaryCycleId)
      .toList(growable: false);

  @override
  Future<void> softDelete({
    required String transactionId,
    required DateTime deletedAt,
  }) => throw UnimplementedError();

  @override
  Future<void> softDeleteAllocationGroup({
    required String transactionId,
    required DateTime deletedAt,
  }) => throw UnimplementedError();

  @override
  Future<void> update(TransactionEntry entry) => throw UnimplementedError();

  @override
  Stream<List<TransactionEntry>> watchCycleTransactions(String salaryCycleId) =>
      Stream.value(
        entries
            .where((entry) => entry.salaryCycleId == salaryCycleId)
            .toList(growable: false),
      );
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator(this.value);

  final String value;

  @override
  String next() => value;
}
