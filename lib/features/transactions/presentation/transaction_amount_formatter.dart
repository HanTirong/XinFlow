import 'package:xinflow/core/money/money.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

String formatTransactionAmount(TransactionEntry entry) {
  final sign = entry.entryKind == EntryKind.refund ? '+' : '-';
  return '$sign ${Money.fromCents(entry.amountCents).format()}';
}
