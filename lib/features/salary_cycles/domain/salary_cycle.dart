import 'package:xinflow/core/date/local_date.dart';

enum SalaryCycleStatus { active, closed }

final class SalaryCycle {
  SalaryCycle({
    required this.id,
    required this.salaryCents,
    required this.startedAt,
    required this.expectedPayDate,
    required this.status,
    this.carryoverCents = 0,
    this.salaryPending = false,
    this.closedAt,
    this.finalRemainingCents,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', '工资周期 ID 不能为空。');
    }
    if (salaryCents < 0) {
      throw ArgumentError.value(salaryCents, 'salaryCents', '工资不能小于 0。');
    }
    if (salaryPending && salaryCents != 0) {
      throw ArgumentError('待填写工资的周期不能包含已确认的工资金额。');
    }
    if (carryoverCents < 0) {
      throw ArgumentError.value(carryoverCents, 'carryoverCents', '结转不能小于 0。');
    }
    if (status == SalaryCycleStatus.active &&
        (closedAt != null || finalRemainingCents != null)) {
      throw ArgumentError('活动周期不能包含封存时间或最终剩余。');
    }
    if (status == SalaryCycleStatus.closed &&
        (closedAt == null || finalRemainingCents == null)) {
      throw ArgumentError('封存周期必须包含封存时间和最终剩余。');
    }
  }

  final String id;
  final int salaryCents;
  final int carryoverCents;
  final bool salaryPending;
  final DateTime startedAt;
  final LocalDate expectedPayDate;
  final SalaryCycleStatus status;
  final DateTime? closedAt;
  final int? finalRemainingCents;

  bool containsDate(LocalDate date) {
    final start = LocalDate.fromDateTime(startedAt);
    return date.compareTo(start) >= 0 && date.compareTo(expectedPayDate) < 0;
  }

  static SalaryCycle? forDate(Iterable<SalaryCycle> cycles, LocalDate date) {
    SalaryCycle? match;
    for (final cycle in cycles) {
      if (!cycle.containsDate(date)) continue;
      if (match != null) {
        throw StateError('该日期对应多个工资周期，请先检查周期设置。');
      }
      match = cycle;
    }
    return match;
  }

  SalaryCycle close({required DateTime at, required int remainingCents}) {
    if (status != SalaryCycleStatus.active) {
      throw StateError('只有活动工资周期可以被封存。');
    }

    return SalaryCycle(
      id: id,
      salaryCents: salaryCents,
      carryoverCents: carryoverCents,
      salaryPending: salaryPending,
      startedAt: startedAt,
      expectedPayDate: expectedPayDate,
      status: SalaryCycleStatus.closed,
      closedAt: at,
      finalRemainingCents: remainingCents,
    );
  }
}
