import 'package:xinflow/core/database/app_database.dart';
import 'package:xinflow/core/date/local_date.dart';
import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/salary_cycles/domain/salary_cycle.dart';
import 'package:xinflow/features/settings/domain/app_settings.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

extension SalaryCycleRecordMapper on SalaryCycleRecord {
  SalaryCycle toDomain() => SalaryCycle(
    id: id,
    salaryCents: salaryCents,
    startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt),
    expectedPayDate: LocalDate.parse(expectedPayDate),
    status: SalaryCycleStatus.values.byName(status),
    closedAt: closedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(closedAt!),
    finalRemainingCents: finalRemainingCents,
  );
}

extension AppSettingRecordMapper on AppSettingRecord {
  AppSettings toDomain() => AppSettings(
    salaryDay: salaryDay,
    currencyCode: currencyCode,
    onboardingCompleted: onboardingCompleted,
    themePreference: AppThemePreference.values.byName(themeMode),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
  );
}

extension CategoryRecordMapper on CategoryRecord {
  Category toDomain() => Category(
    id: id,
    parentId: parentId,
    name: name,
    flowType: FlowType.values.byName(flowType),
    iconKey: iconKey,
    sortOrder: sortOrder,
    isSystem: isSystem,
    isActive: isActive,
  );
}

extension TransactionRecordMapper on TransactionRecord {
  TransactionEntry toDomain() => TransactionEntry(
    id: id,
    salaryCycleId: salaryCycleId,
    entryKind: EntryKind.values.byName(entryKind),
    flowType: FlowType.values.byName(flowType),
    amountCents: amountCents,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    reversesTransactionId: reversesTransactionId,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(occurredAt),
    occurredOn: LocalDate.parse(occurredOn),
    note: note,
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}
