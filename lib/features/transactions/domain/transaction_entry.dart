import 'package:xinflow/core/date/local_date.dart';

enum FlowType { expense, saving, investment }

enum EntryKind { allocation, refund, withdrawal }

final class TransactionEntry {
  TransactionEntry({
    required this.id,
    required this.salaryCycleId,
    required this.entryKind,
    required this.flowType,
    required this.amountCents,
    required this.categoryId,
    required this.occurredAt,
    required this.occurredOn,
    this.subcategoryId,
    this.reversesTransactionId,
    this.note,
    this.deletedAt,
  }) {
    if (id.isEmpty || salaryCycleId.isEmpty || categoryId.isEmpty) {
      throw ArgumentError('流水 ID、工资周期 ID 和分类 ID 不能为空。');
    }
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents', '金额必须大于 0。');
    }
    if (note != null && note!.length > 200) {
      throw ArgumentError.value(note, 'note', '备注不能超过 200 个字符。');
    }
    if (entryKind == EntryKind.refund &&
        (flowType != FlowType.expense || reversesTransactionId == null)) {
      throw ArgumentError('退款必须属于消费，并关联原消费记录。');
    }
    if (entryKind == EntryKind.withdrawal &&
        (flowType == FlowType.expense || reversesTransactionId == null)) {
      throw ArgumentError('提取必须属于存款或理财，并关联原分配记录。');
    }
    if (entryKind == EntryKind.allocation && reversesTransactionId != null) {
      throw ArgumentError('普通分配记录不能关联被冲减流水。');
    }
  }

  final String id;
  final String salaryCycleId;
  final EntryKind entryKind;
  final FlowType flowType;
  final int amountCents;
  final String categoryId;
  final String? subcategoryId;
  final String? reversesTransactionId;
  final DateTime occurredAt;
  final LocalDate occurredOn;
  final String? note;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
}
