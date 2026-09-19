// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SalaryCycleRecordsTable extends SalaryCycleRecords
    with TableInfo<$SalaryCycleRecordsTable, SalaryCycleRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalaryCycleRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryCentsMeta = const VerificationMeta(
    'salaryCents',
  );
  @override
  late final GeneratedColumn<int> salaryCents = GeneratedColumn<int>(
    'salary_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (salary_cents >= 0)',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedPayDateMeta = const VerificationMeta(
    'expectedPayDate',
  );
  @override
  late final GeneratedColumn<String> expectedPayDate = GeneratedColumn<String>(
    'expected_pay_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<int> closedAt = GeneratedColumn<int>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'active\', \'closed\'))',
  );
  static const VerificationMeta _finalRemainingCentsMeta =
      const VerificationMeta('finalRemainingCents');
  @override
  late final GeneratedColumn<int> finalRemainingCents = GeneratedColumn<int>(
    'final_remaining_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    salaryCents,
    startedAt,
    expectedPayDate,
    closedAt,
    status,
    finalRemainingCents,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'salary_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalaryCycleRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('salary_cents')) {
      context.handle(
        _salaryCentsMeta,
        salaryCents.isAcceptableOrUnknown(
          data['salary_cents']!,
          _salaryCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salaryCentsMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('expected_pay_date')) {
      context.handle(
        _expectedPayDateMeta,
        expectedPayDate.isAcceptableOrUnknown(
          data['expected_pay_date']!,
          _expectedPayDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedPayDateMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('final_remaining_cents')) {
      context.handle(
        _finalRemainingCentsMeta,
        finalRemainingCents.isAcceptableOrUnknown(
          data['final_remaining_cents']!,
          _finalRemainingCentsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalaryCycleRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalaryCycleRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      salaryCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_cents'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      expectedPayDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_pay_date'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      finalRemainingCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_remaining_cents'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SalaryCycleRecordsTable createAlias(String alias) {
    return $SalaryCycleRecordsTable(attachedDatabase, alias);
  }
}

class SalaryCycleRecord extends DataClass
    implements Insertable<SalaryCycleRecord> {
  final String id;
  final int salaryCents;
  final int startedAt;
  final String expectedPayDate;
  final int? closedAt;
  final String status;
  final int? finalRemainingCents;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const SalaryCycleRecord({
    required this.id,
    required this.salaryCents,
    required this.startedAt,
    required this.expectedPayDate,
    this.closedAt,
    required this.status,
    this.finalRemainingCents,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['salary_cents'] = Variable<int>(salaryCents);
    map['started_at'] = Variable<int>(startedAt);
    map['expected_pay_date'] = Variable<String>(expectedPayDate);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(closedAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || finalRemainingCents != null) {
      map['final_remaining_cents'] = Variable<int>(finalRemainingCents);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  SalaryCycleRecordsCompanion toCompanion(bool nullToAbsent) {
    return SalaryCycleRecordsCompanion(
      id: Value(id),
      salaryCents: Value(salaryCents),
      startedAt: Value(startedAt),
      expectedPayDate: Value(expectedPayDate),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      status: Value(status),
      finalRemainingCents: finalRemainingCents == null && nullToAbsent
          ? const Value.absent()
          : Value(finalRemainingCents),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SalaryCycleRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalaryCycleRecord(
      id: serializer.fromJson<String>(json['id']),
      salaryCents: serializer.fromJson<int>(json['salaryCents']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      expectedPayDate: serializer.fromJson<String>(json['expectedPayDate']),
      closedAt: serializer.fromJson<int?>(json['closedAt']),
      status: serializer.fromJson<String>(json['status']),
      finalRemainingCents: serializer.fromJson<int?>(
        json['finalRemainingCents'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'salaryCents': serializer.toJson<int>(salaryCents),
      'startedAt': serializer.toJson<int>(startedAt),
      'expectedPayDate': serializer.toJson<String>(expectedPayDate),
      'closedAt': serializer.toJson<int?>(closedAt),
      'status': serializer.toJson<String>(status),
      'finalRemainingCents': serializer.toJson<int?>(finalRemainingCents),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  SalaryCycleRecord copyWith({
    String? id,
    int? salaryCents,
    int? startedAt,
    String? expectedPayDate,
    Value<int?> closedAt = const Value.absent(),
    String? status,
    Value<int?> finalRemainingCents = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => SalaryCycleRecord(
    id: id ?? this.id,
    salaryCents: salaryCents ?? this.salaryCents,
    startedAt: startedAt ?? this.startedAt,
    expectedPayDate: expectedPayDate ?? this.expectedPayDate,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    status: status ?? this.status,
    finalRemainingCents: finalRemainingCents.present
        ? finalRemainingCents.value
        : this.finalRemainingCents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SalaryCycleRecord copyWithCompanion(SalaryCycleRecordsCompanion data) {
    return SalaryCycleRecord(
      id: data.id.present ? data.id.value : this.id,
      salaryCents: data.salaryCents.present
          ? data.salaryCents.value
          : this.salaryCents,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      expectedPayDate: data.expectedPayDate.present
          ? data.expectedPayDate.value
          : this.expectedPayDate,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      status: data.status.present ? data.status.value : this.status,
      finalRemainingCents: data.finalRemainingCents.present
          ? data.finalRemainingCents.value
          : this.finalRemainingCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalaryCycleRecord(')
          ..write('id: $id, ')
          ..write('salaryCents: $salaryCents, ')
          ..write('startedAt: $startedAt, ')
          ..write('expectedPayDate: $expectedPayDate, ')
          ..write('closedAt: $closedAt, ')
          ..write('status: $status, ')
          ..write('finalRemainingCents: $finalRemainingCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    salaryCents,
    startedAt,
    expectedPayDate,
    closedAt,
    status,
    finalRemainingCents,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalaryCycleRecord &&
          other.id == this.id &&
          other.salaryCents == this.salaryCents &&
          other.startedAt == this.startedAt &&
          other.expectedPayDate == this.expectedPayDate &&
          other.closedAt == this.closedAt &&
          other.status == this.status &&
          other.finalRemainingCents == this.finalRemainingCents &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SalaryCycleRecordsCompanion extends UpdateCompanion<SalaryCycleRecord> {
  final Value<String> id;
  final Value<int> salaryCents;
  final Value<int> startedAt;
  final Value<String> expectedPayDate;
  final Value<int?> closedAt;
  final Value<String> status;
  final Value<int?> finalRemainingCents;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SalaryCycleRecordsCompanion({
    this.id = const Value.absent(),
    this.salaryCents = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.expectedPayDate = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.finalRemainingCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalaryCycleRecordsCompanion.insert({
    required String id,
    required int salaryCents,
    required int startedAt,
    required String expectedPayDate,
    this.closedAt = const Value.absent(),
    required String status,
    this.finalRemainingCents = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       salaryCents = Value(salaryCents),
       startedAt = Value(startedAt),
       expectedPayDate = Value(expectedPayDate),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SalaryCycleRecord> custom({
    Expression<String>? id,
    Expression<int>? salaryCents,
    Expression<int>? startedAt,
    Expression<String>? expectedPayDate,
    Expression<int>? closedAt,
    Expression<String>? status,
    Expression<int>? finalRemainingCents,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (salaryCents != null) 'salary_cents': salaryCents,
      if (startedAt != null) 'started_at': startedAt,
      if (expectedPayDate != null) 'expected_pay_date': expectedPayDate,
      if (closedAt != null) 'closed_at': closedAt,
      if (status != null) 'status': status,
      if (finalRemainingCents != null)
        'final_remaining_cents': finalRemainingCents,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalaryCycleRecordsCompanion copyWith({
    Value<String>? id,
    Value<int>? salaryCents,
    Value<int>? startedAt,
    Value<String>? expectedPayDate,
    Value<int?>? closedAt,
    Value<String>? status,
    Value<int?>? finalRemainingCents,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SalaryCycleRecordsCompanion(
      id: id ?? this.id,
      salaryCents: salaryCents ?? this.salaryCents,
      startedAt: startedAt ?? this.startedAt,
      expectedPayDate: expectedPayDate ?? this.expectedPayDate,
      closedAt: closedAt ?? this.closedAt,
      status: status ?? this.status,
      finalRemainingCents: finalRemainingCents ?? this.finalRemainingCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (salaryCents.present) {
      map['salary_cents'] = Variable<int>(salaryCents.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (expectedPayDate.present) {
      map['expected_pay_date'] = Variable<String>(expectedPayDate.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(closedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (finalRemainingCents.present) {
      map['final_remaining_cents'] = Variable<int>(finalRemainingCents.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalaryCycleRecordsCompanion(')
          ..write('id: $id, ')
          ..write('salaryCents: $salaryCents, ')
          ..write('startedAt: $startedAt, ')
          ..write('expectedPayDate: $expectedPayDate, ')
          ..write('closedAt: $closedAt, ')
          ..write('status: $status, ')
          ..write('finalRemainingCents: $finalRemainingCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryRecordsTable extends CategoryRecords
    with TableInfo<$CategoryRecordsTable, CategoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flowTypeMeta = const VerificationMeta(
    'flowType',
  );
  @override
  late final GeneratedColumn<String> flowType = GeneratedColumn<String>(
    'flow_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (flow_type IN (\'expense\', \'saving\', \'investment\'))',
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    name,
    flowType,
    iconKey,
    sortOrder,
    isSystem,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('flow_type')) {
      context.handle(
        _flowTypeMeta,
        flowType.isAcceptableOrUnknown(data['flow_type']!, _flowTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_flowTypeMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    } else if (isInserting) {
      context.missing(_isSystemMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      flowType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flow_type'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CategoryRecordsTable createAlias(String alias) {
    return $CategoryRecordsTable(attachedDatabase, alias);
  }
}

class CategoryRecord extends DataClass implements Insertable<CategoryRecord> {
  final String id;
  final String? parentId;
  final String name;
  final String flowType;
  final String iconKey;
  final int sortOrder;
  final bool isSystem;
  final bool isActive;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const CategoryRecord({
    required this.id,
    this.parentId,
    required this.name,
    required this.flowType,
    required this.iconKey,
    required this.sortOrder,
    required this.isSystem,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['flow_type'] = Variable<String>(flowType);
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_system'] = Variable<bool>(isSystem);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  CategoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return CategoryRecordsCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      flowType: Value(flowType),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
      isSystem: Value(isSystem),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CategoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRecord(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      flowType: serializer.fromJson<String>(json['flowType']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'flowType': serializer.toJson<String>(flowType),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isSystem': serializer.toJson<bool>(isSystem),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  CategoryRecord copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? name,
    String? flowType,
    String? iconKey,
    int? sortOrder,
    bool? isSystem,
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => CategoryRecord(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    flowType: flowType ?? this.flowType,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
    isSystem: isSystem ?? this.isSystem,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CategoryRecord copyWithCompanion(CategoryRecordsCompanion data) {
    return CategoryRecord(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      flowType: data.flowType.present ? data.flowType.value : this.flowType,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRecord(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('flowType: $flowType, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSystem: $isSystem, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    name,
    flowType,
    iconKey,
    sortOrder,
    isSystem,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRecord &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.flowType == this.flowType &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder &&
          other.isSystem == this.isSystem &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CategoryRecordsCompanion extends UpdateCompanion<CategoryRecord> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String> flowType;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  final Value<bool> isSystem;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const CategoryRecordsCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.flowType = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryRecordsCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    required String flowType,
    required String iconKey,
    required int sortOrder,
    required bool isSystem,
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       flowType = Value(flowType),
       iconKey = Value(iconKey),
       sortOrder = Value(sortOrder),
       isSystem = Value(isSystem),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRecord> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? flowType,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
    Expression<bool>? isSystem,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (flowType != null) 'flow_type': flowType,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isSystem != null) 'is_system': isSystem,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? name,
    Value<String>? flowType,
    Value<String>? iconKey,
    Value<int>? sortOrder,
    Value<bool>? isSystem,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CategoryRecordsCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      flowType: flowType ?? this.flowType,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (flowType.present) {
      map['flow_type'] = Variable<String>(flowType.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('flowType: $flowType, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSystem: $isSystem, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionRecordsTable extends TransactionRecords
    with TableInfo<$TransactionRecordsTable, TransactionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryCycleIdMeta = const VerificationMeta(
    'salaryCycleId',
  );
  @override
  late final GeneratedColumn<String> salaryCycleId = GeneratedColumn<String>(
    'salary_cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES salary_cycles (id)',
    ),
  );
  static const VerificationMeta _entryKindMeta = const VerificationMeta(
    'entryKind',
  );
  @override
  late final GeneratedColumn<String> entryKind = GeneratedColumn<String>(
    'entry_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (entry_kind IN (\'allocation\', \'refund\'))',
  );
  static const VerificationMeta _flowTypeMeta = const VerificationMeta(
    'flowType',
  );
  @override
  late final GeneratedColumn<String> flowType = GeneratedColumn<String>(
    'flow_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (flow_type IN (\'expense\', \'saving\', \'investment\'))',
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount_cents > 0)',
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _subcategoryIdMeta = const VerificationMeta(
    'subcategoryId',
  );
  @override
  late final GeneratedColumn<String> subcategoryId = GeneratedColumn<String>(
    'subcategory_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _reversesTransactionIdMeta =
      const VerificationMeta('reversesTransactionId');
  @override
  late final GeneratedColumn<String> reversesTransactionId =
      GeneratedColumn<String>(
        'reverses_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transactions (id)',
        ),
      );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredOnMeta = const VerificationMeta(
    'occurredOn',
  );
  @override
  late final GeneratedColumn<String> occurredOn = GeneratedColumn<String>(
    'occurred_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    salaryCycleId,
    entryKind,
    flowType,
    amountCents,
    categoryId,
    subcategoryId,
    reversesTransactionId,
    occurredAt,
    occurredOn,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('salary_cycle_id')) {
      context.handle(
        _salaryCycleIdMeta,
        salaryCycleId.isAcceptableOrUnknown(
          data['salary_cycle_id']!,
          _salaryCycleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salaryCycleIdMeta);
    }
    if (data.containsKey('entry_kind')) {
      context.handle(
        _entryKindMeta,
        entryKind.isAcceptableOrUnknown(data['entry_kind']!, _entryKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entryKindMeta);
    }
    if (data.containsKey('flow_type')) {
      context.handle(
        _flowTypeMeta,
        flowType.isAcceptableOrUnknown(data['flow_type']!, _flowTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_flowTypeMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('subcategory_id')) {
      context.handle(
        _subcategoryIdMeta,
        subcategoryId.isAcceptableOrUnknown(
          data['subcategory_id']!,
          _subcategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('reverses_transaction_id')) {
      context.handle(
        _reversesTransactionIdMeta,
        reversesTransactionId.isAcceptableOrUnknown(
          data['reverses_transaction_id']!,
          _reversesTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('occurred_on')) {
      context.handle(
        _occurredOnMeta,
        occurredOn.isAcceptableOrUnknown(data['occurred_on']!, _occurredOnMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredOnMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      salaryCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary_cycle_id'],
      )!,
      entryKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_kind'],
      )!,
      flowType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flow_type'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      subcategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory_id'],
      ),
      reversesTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reverses_transaction_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      occurredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_on'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransactionRecordsTable createAlias(String alias) {
    return $TransactionRecordsTable(attachedDatabase, alias);
  }
}

class TransactionRecord extends DataClass
    implements Insertable<TransactionRecord> {
  final String id;
  final String salaryCycleId;
  final String entryKind;
  final String flowType;
  final int amountCents;
  final String categoryId;
  final String? subcategoryId;
  final String? reversesTransactionId;
  final int occurredAt;
  final String occurredOn;
  final String? note;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const TransactionRecord({
    required this.id,
    required this.salaryCycleId,
    required this.entryKind,
    required this.flowType,
    required this.amountCents,
    required this.categoryId,
    this.subcategoryId,
    this.reversesTransactionId,
    required this.occurredAt,
    required this.occurredOn,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['salary_cycle_id'] = Variable<String>(salaryCycleId);
    map['entry_kind'] = Variable<String>(entryKind);
    map['flow_type'] = Variable<String>(flowType);
    map['amount_cents'] = Variable<int>(amountCents);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || subcategoryId != null) {
      map['subcategory_id'] = Variable<String>(subcategoryId);
    }
    if (!nullToAbsent || reversesTransactionId != null) {
      map['reverses_transaction_id'] = Variable<String>(reversesTransactionId);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    map['occurred_on'] = Variable<String>(occurredOn);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TransactionRecordsCompanion toCompanion(bool nullToAbsent) {
    return TransactionRecordsCompanion(
      id: Value(id),
      salaryCycleId: Value(salaryCycleId),
      entryKind: Value(entryKind),
      flowType: Value(flowType),
      amountCents: Value(amountCents),
      categoryId: Value(categoryId),
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
      reversesTransactionId: reversesTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(reversesTransactionId),
      occurredAt: Value(occurredAt),
      occurredOn: Value(occurredOn),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TransactionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRecord(
      id: serializer.fromJson<String>(json['id']),
      salaryCycleId: serializer.fromJson<String>(json['salaryCycleId']),
      entryKind: serializer.fromJson<String>(json['entryKind']),
      flowType: serializer.fromJson<String>(json['flowType']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      subcategoryId: serializer.fromJson<String?>(json['subcategoryId']),
      reversesTransactionId: serializer.fromJson<String?>(
        json['reversesTransactionId'],
      ),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      occurredOn: serializer.fromJson<String>(json['occurredOn']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'salaryCycleId': serializer.toJson<String>(salaryCycleId),
      'entryKind': serializer.toJson<String>(entryKind),
      'flowType': serializer.toJson<String>(flowType),
      'amountCents': serializer.toJson<int>(amountCents),
      'categoryId': serializer.toJson<String>(categoryId),
      'subcategoryId': serializer.toJson<String?>(subcategoryId),
      'reversesTransactionId': serializer.toJson<String?>(
        reversesTransactionId,
      ),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'occurredOn': serializer.toJson<String>(occurredOn),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  TransactionRecord copyWith({
    String? id,
    String? salaryCycleId,
    String? entryKind,
    String? flowType,
    int? amountCents,
    String? categoryId,
    Value<String?> subcategoryId = const Value.absent(),
    Value<String?> reversesTransactionId = const Value.absent(),
    int? occurredAt,
    String? occurredOn,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => TransactionRecord(
    id: id ?? this.id,
    salaryCycleId: salaryCycleId ?? this.salaryCycleId,
    entryKind: entryKind ?? this.entryKind,
    flowType: flowType ?? this.flowType,
    amountCents: amountCents ?? this.amountCents,
    categoryId: categoryId ?? this.categoryId,
    subcategoryId: subcategoryId.present
        ? subcategoryId.value
        : this.subcategoryId,
    reversesTransactionId: reversesTransactionId.present
        ? reversesTransactionId.value
        : this.reversesTransactionId,
    occurredAt: occurredAt ?? this.occurredAt,
    occurredOn: occurredOn ?? this.occurredOn,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TransactionRecord copyWithCompanion(TransactionRecordsCompanion data) {
    return TransactionRecord(
      id: data.id.present ? data.id.value : this.id,
      salaryCycleId: data.salaryCycleId.present
          ? data.salaryCycleId.value
          : this.salaryCycleId,
      entryKind: data.entryKind.present ? data.entryKind.value : this.entryKind,
      flowType: data.flowType.present ? data.flowType.value : this.flowType,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      reversesTransactionId: data.reversesTransactionId.present
          ? data.reversesTransactionId.value
          : this.reversesTransactionId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRecord(')
          ..write('id: $id, ')
          ..write('salaryCycleId: $salaryCycleId, ')
          ..write('entryKind: $entryKind, ')
          ..write('flowType: $flowType, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('reversesTransactionId: $reversesTransactionId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    salaryCycleId,
    entryKind,
    flowType,
    amountCents,
    categoryId,
    subcategoryId,
    reversesTransactionId,
    occurredAt,
    occurredOn,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRecord &&
          other.id == this.id &&
          other.salaryCycleId == this.salaryCycleId &&
          other.entryKind == this.entryKind &&
          other.flowType == this.flowType &&
          other.amountCents == this.amountCents &&
          other.categoryId == this.categoryId &&
          other.subcategoryId == this.subcategoryId &&
          other.reversesTransactionId == this.reversesTransactionId &&
          other.occurredAt == this.occurredAt &&
          other.occurredOn == this.occurredOn &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionRecordsCompanion extends UpdateCompanion<TransactionRecord> {
  final Value<String> id;
  final Value<String> salaryCycleId;
  final Value<String> entryKind;
  final Value<String> flowType;
  final Value<int> amountCents;
  final Value<String> categoryId;
  final Value<String?> subcategoryId;
  final Value<String?> reversesTransactionId;
  final Value<int> occurredAt;
  final Value<String> occurredOn;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TransactionRecordsCompanion({
    this.id = const Value.absent(),
    this.salaryCycleId = const Value.absent(),
    this.entryKind = const Value.absent(),
    this.flowType = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.reversesTransactionId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionRecordsCompanion.insert({
    required String id,
    required String salaryCycleId,
    required String entryKind,
    required String flowType,
    required int amountCents,
    required String categoryId,
    this.subcategoryId = const Value.absent(),
    this.reversesTransactionId = const Value.absent(),
    required int occurredAt,
    required String occurredOn,
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       salaryCycleId = Value(salaryCycleId),
       entryKind = Value(entryKind),
       flowType = Value(flowType),
       amountCents = Value(amountCents),
       categoryId = Value(categoryId),
       occurredAt = Value(occurredAt),
       occurredOn = Value(occurredOn),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransactionRecord> custom({
    Expression<String>? id,
    Expression<String>? salaryCycleId,
    Expression<String>? entryKind,
    Expression<String>? flowType,
    Expression<int>? amountCents,
    Expression<String>? categoryId,
    Expression<String>? subcategoryId,
    Expression<String>? reversesTransactionId,
    Expression<int>? occurredAt,
    Expression<String>? occurredOn,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (salaryCycleId != null) 'salary_cycle_id': salaryCycleId,
      if (entryKind != null) 'entry_kind': entryKind,
      if (flowType != null) 'flow_type': flowType,
      if (amountCents != null) 'amount_cents': amountCents,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (reversesTransactionId != null)
        'reverses_transaction_id': reversesTransactionId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? salaryCycleId,
    Value<String>? entryKind,
    Value<String>? flowType,
    Value<int>? amountCents,
    Value<String>? categoryId,
    Value<String?>? subcategoryId,
    Value<String?>? reversesTransactionId,
    Value<int>? occurredAt,
    Value<String>? occurredOn,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TransactionRecordsCompanion(
      id: id ?? this.id,
      salaryCycleId: salaryCycleId ?? this.salaryCycleId,
      entryKind: entryKind ?? this.entryKind,
      flowType: flowType ?? this.flowType,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      reversesTransactionId:
          reversesTransactionId ?? this.reversesTransactionId,
      occurredAt: occurredAt ?? this.occurredAt,
      occurredOn: occurredOn ?? this.occurredOn,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (salaryCycleId.present) {
      map['salary_cycle_id'] = Variable<String>(salaryCycleId.value);
    }
    if (entryKind.present) {
      map['entry_kind'] = Variable<String>(entryKind.value);
    }
    if (flowType.present) {
      map['flow_type'] = Variable<String>(flowType.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<String>(subcategoryId.value);
    }
    if (reversesTransactionId.present) {
      map['reverses_transaction_id'] = Variable<String>(
        reversesTransactionId.value,
      );
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<String>(occurredOn.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('salaryCycleId: $salaryCycleId, ')
          ..write('entryKind: $entryKind, ')
          ..write('flowType: $flowType, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('reversesTransactionId: $reversesTransactionId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingRecordsTable extends AppSettingRecords
    with TableInfo<$AppSettingRecordsTable, AppSettingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL CHECK (singleton_id = 1)',
  );
  static const VerificationMeta _salaryDayMeta = const VerificationMeta(
    'salaryDay',
  );
  @override
  late final GeneratedColumn<int> salaryDay = GeneratedColumn<int>(
    'salary_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (salary_day BETWEEN 1 AND 31)',
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'CNY\' CHECK (currency_code = \'CNY\')',
    defaultValue: const CustomExpression('\'CNY\''),
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'system\' CHECK (theme_mode IN (\'system\', \'light\', \'dark\'))',
    defaultValue: const CustomExpression('\'system\''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    salaryDay,
    currencyCode,
    onboardingCompleted,
    themeMode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('salary_day')) {
      context.handle(
        _salaryDayMeta,
        salaryDay.isAcceptableOrUnknown(data['salary_day']!, _salaryDayMeta),
      );
    } else if (isInserting) {
      context.missing(_salaryDayMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_onboardingCompletedMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  AppSettingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRecord(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      salaryDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_day'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingRecordsTable createAlias(String alias) {
    return $AppSettingRecordsTable(attachedDatabase, alias);
  }
}

class AppSettingRecord extends DataClass
    implements Insertable<AppSettingRecord> {
  final int singletonId;
  final int salaryDay;
  final String currencyCode;
  final bool onboardingCompleted;
  final String themeMode;
  final int updatedAt;
  const AppSettingRecord({
    required this.singletonId,
    required this.salaryDay,
    required this.currencyCode,
    required this.onboardingCompleted,
    required this.themeMode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['salary_day'] = Variable<int>(salaryDay);
    map['currency_code'] = Variable<String>(currencyCode);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['theme_mode'] = Variable<String>(themeMode);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingRecordsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingRecordsCompanion(
      singletonId: Value(singletonId),
      salaryDay: Value(salaryDay),
      currencyCode: Value(currencyCode),
      onboardingCompleted: Value(onboardingCompleted),
      themeMode: Value(themeMode),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRecord(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      salaryDay: serializer.fromJson<int>(json['salaryDay']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'salaryDay': serializer.toJson<int>(salaryDay),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'themeMode': serializer.toJson<String>(themeMode),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSettingRecord copyWith({
    int? singletonId,
    int? salaryDay,
    String? currencyCode,
    bool? onboardingCompleted,
    String? themeMode,
    int? updatedAt,
  }) => AppSettingRecord(
    singletonId: singletonId ?? this.singletonId,
    salaryDay: salaryDay ?? this.salaryDay,
    currencyCode: currencyCode ?? this.currencyCode,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    themeMode: themeMode ?? this.themeMode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingRecord copyWithCompanion(AppSettingRecordsCompanion data) {
    return AppSettingRecord(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      salaryDay: data.salaryDay.present ? data.salaryDay.value : this.salaryDay,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRecord(')
          ..write('singletonId: $singletonId, ')
          ..write('salaryDay: $salaryDay, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singletonId,
    salaryDay,
    currencyCode,
    onboardingCompleted,
    themeMode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRecord &&
          other.singletonId == this.singletonId &&
          other.salaryDay == this.salaryDay &&
          other.currencyCode == this.currencyCode &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.themeMode == this.themeMode &&
          other.updatedAt == this.updatedAt);
}

class AppSettingRecordsCompanion extends UpdateCompanion<AppSettingRecord> {
  final Value<int> singletonId;
  final Value<int> salaryDay;
  final Value<String> currencyCode;
  final Value<bool> onboardingCompleted;
  final Value<String> themeMode;
  final Value<int> updatedAt;
  const AppSettingRecordsCompanion({
    this.singletonId = const Value.absent(),
    this.salaryDay = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingRecordsCompanion.insert({
    this.singletonId = const Value.absent(),
    required int salaryDay,
    this.currencyCode = const Value.absent(),
    required bool onboardingCompleted,
    this.themeMode = const Value.absent(),
    required int updatedAt,
  }) : salaryDay = Value(salaryDay),
       onboardingCompleted = Value(onboardingCompleted),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingRecord> custom({
    Expression<int>? singletonId,
    Expression<int>? salaryDay,
    Expression<String>? currencyCode,
    Expression<bool>? onboardingCompleted,
    Expression<String>? themeMode,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (salaryDay != null) 'salary_day': salaryDay,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (themeMode != null) 'theme_mode': themeMode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingRecordsCompanion copyWith({
    Value<int>? singletonId,
    Value<int>? salaryDay,
    Value<String>? currencyCode,
    Value<bool>? onboardingCompleted,
    Value<String>? themeMode,
    Value<int>? updatedAt,
  }) {
    return AppSettingRecordsCompanion(
      singletonId: singletonId ?? this.singletonId,
      salaryDay: salaryDay ?? this.salaryDay,
      currencyCode: currencyCode ?? this.currencyCode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      themeMode: themeMode ?? this.themeMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (salaryDay.present) {
      map['salary_day'] = Variable<int>(salaryDay.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRecordsCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('salaryDay: $salaryDay, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $SalaryCycleRecordsTable salaryCycleRecords =
      $SalaryCycleRecordsTable(this);
  late final $CategoryRecordsTable categoryRecords = $CategoryRecordsTable(
    this,
  );
  late final $TransactionRecordsTable transactionRecords =
      $TransactionRecordsTable(this);
  late final $AppSettingRecordsTable appSettingRecords =
      $AppSettingRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    salaryCycleRecords,
    categoryRecords,
    transactionRecords,
    appSettingRecords,
  ];
}
