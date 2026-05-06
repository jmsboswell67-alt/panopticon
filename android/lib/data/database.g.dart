// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampUtcMeta = const VerificationMeta(
    'timestampUtc',
  );
  @override
  late final GeneratedColumn<int> timestampUtc = GeneratedColumn<int>(
    'timestamp_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneOffsetMeta = const VerificationMeta(
    'timezoneOffset',
  );
  @override
  late final GeneratedColumn<int> timezoneOffset = GeneratedColumn<int>(
    'timezone_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestampUtc,
    timezoneOffset,
    source,
    eventType,
    packageName,
    payloadJson,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp_utc')) {
      context.handle(
        _timestampUtcMeta,
        timestampUtc.isAcceptableOrUnknown(
          data['timestamp_utc']!,
          _timestampUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampUtcMeta);
    }
    if (data.containsKey('timezone_offset')) {
      context.handle(
        _timezoneOffsetMeta,
        timezoneOffset.isAcceptableOrUnknown(
          data['timezone_offset']!,
          _timezoneOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timezoneOffsetMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestampUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_utc'],
      )!,
      timezoneOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timezone_offset'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int id;
  final int timestampUtc;
  final int timezoneOffset;
  final String source;
  final String eventType;
  final String? packageName;
  final String? payloadJson;
  final int schemaVersion;
  const Event({
    required this.id,
    required this.timestampUtc,
    required this.timezoneOffset,
    required this.source,
    required this.eventType,
    this.packageName,
    this.payloadJson,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp_utc'] = Variable<int>(timestampUtc);
    map['timezone_offset'] = Variable<int>(timezoneOffset);
    map['source'] = Variable<String>(source);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || packageName != null) {
      map['package_name'] = Variable<String>(packageName);
    }
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      timestampUtc: Value(timestampUtc),
      timezoneOffset: Value(timezoneOffset),
      source: Value(source),
      eventType: Value(eventType),
      packageName: packageName == null && nullToAbsent
          ? const Value.absent()
          : Value(packageName),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      timestampUtc: serializer.fromJson<int>(json['timestampUtc']),
      timezoneOffset: serializer.fromJson<int>(json['timezoneOffset']),
      source: serializer.fromJson<String>(json['source']),
      eventType: serializer.fromJson<String>(json['eventType']),
      packageName: serializer.fromJson<String?>(json['packageName']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestampUtc': serializer.toJson<int>(timestampUtc),
      'timezoneOffset': serializer.toJson<int>(timezoneOffset),
      'source': serializer.toJson<String>(source),
      'eventType': serializer.toJson<String>(eventType),
      'packageName': serializer.toJson<String?>(packageName),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  Event copyWith({
    int? id,
    int? timestampUtc,
    int? timezoneOffset,
    String? source,
    String? eventType,
    Value<String?> packageName = const Value.absent(),
    Value<String?> payloadJson = const Value.absent(),
    int? schemaVersion,
  }) => Event(
    id: id ?? this.id,
    timestampUtc: timestampUtc ?? this.timestampUtc,
    timezoneOffset: timezoneOffset ?? this.timezoneOffset,
    source: source ?? this.source,
    eventType: eventType ?? this.eventType,
    packageName: packageName.present ? packageName.value : this.packageName,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      timestampUtc: data.timestampUtc.present
          ? data.timestampUtc.value
          : this.timestampUtc,
      timezoneOffset: data.timezoneOffset.present
          ? data.timezoneOffset.value
          : this.timezoneOffset,
      source: data.source.present ? data.source.value : this.source,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('timestampUtc: $timestampUtc, ')
          ..write('timezoneOffset: $timezoneOffset, ')
          ..write('source: $source, ')
          ..write('eventType: $eventType, ')
          ..write('packageName: $packageName, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestampUtc,
    timezoneOffset,
    source,
    eventType,
    packageName,
    payloadJson,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.timestampUtc == this.timestampUtc &&
          other.timezoneOffset == this.timezoneOffset &&
          other.source == this.source &&
          other.eventType == this.eventType &&
          other.packageName == this.packageName &&
          other.payloadJson == this.payloadJson &&
          other.schemaVersion == this.schemaVersion);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<int> timestampUtc;
  final Value<int> timezoneOffset;
  final Value<String> source;
  final Value<String> eventType;
  final Value<String?> packageName;
  final Value<String?> payloadJson;
  final Value<int> schemaVersion;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.timestampUtc = const Value.absent(),
    this.timezoneOffset = const Value.absent(),
    this.source = const Value.absent(),
    this.eventType = const Value.absent(),
    this.packageName = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.schemaVersion = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required int timestampUtc,
    required int timezoneOffset,
    required String source,
    required String eventType,
    this.packageName = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.schemaVersion = const Value.absent(),
  }) : timestampUtc = Value(timestampUtc),
       timezoneOffset = Value(timezoneOffset),
       source = Value(source),
       eventType = Value(eventType);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<int>? timestampUtc,
    Expression<int>? timezoneOffset,
    Expression<String>? source,
    Expression<String>? eventType,
    Expression<String>? packageName,
    Expression<String>? payloadJson,
    Expression<int>? schemaVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestampUtc != null) 'timestamp_utc': timestampUtc,
      if (timezoneOffset != null) 'timezone_offset': timezoneOffset,
      if (source != null) 'source': source,
      if (eventType != null) 'event_type': eventType,
      if (packageName != null) 'package_name': packageName,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (schemaVersion != null) 'schema_version': schemaVersion,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<int>? timestampUtc,
    Value<int>? timezoneOffset,
    Value<String>? source,
    Value<String>? eventType,
    Value<String?>? packageName,
    Value<String?>? payloadJson,
    Value<int>? schemaVersion,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      timestampUtc: timestampUtc ?? this.timestampUtc,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      source: source ?? this.source,
      eventType: eventType ?? this.eventType,
      packageName: packageName ?? this.packageName,
      payloadJson: payloadJson ?? this.payloadJson,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestampUtc.present) {
      map['timestamp_utc'] = Variable<int>(timestampUtc.value);
    }
    if (timezoneOffset.present) {
      map['timezone_offset'] = Variable<int>(timezoneOffset.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('timestampUtc: $timestampUtc, ')
          ..write('timezoneOffset: $timezoneOffset, ')
          ..write('source: $source, ')
          ..write('eventType: $eventType, ')
          ..write('packageName: $packageName, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }
}

class $AppSessionsTable extends AppSessions
    with TableInfo<$AppSessionsTable, AppSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startUtcMeta = const VerificationMeta(
    'startUtc',
  );
  @override
  late final GeneratedColumn<int> startUtc = GeneratedColumn<int>(
    'start_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<int> endUtc = GeneratedColumn<int>(
    'end_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    startUtc,
    endUtc,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('start_utc')) {
      context.handle(
        _startUtcMeta,
        startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(
        _endUtcMeta,
        endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      startUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_utc'],
      )!,
      endUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_utc'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
    );
  }

  @override
  $AppSessionsTable createAlias(String alias) {
    return $AppSessionsTable(attachedDatabase, alias);
  }
}

class AppSession extends DataClass implements Insertable<AppSession> {
  final int id;
  final String packageName;
  final int startUtc;
  final int? endUtc;
  final int? durationMs;
  const AppSession({
    required this.id,
    required this.packageName,
    required this.startUtc,
    this.endUtc,
    this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['package_name'] = Variable<String>(packageName);
    map['start_utc'] = Variable<int>(startUtc);
    if (!nullToAbsent || endUtc != null) {
      map['end_utc'] = Variable<int>(endUtc);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    return map;
  }

  AppSessionsCompanion toCompanion(bool nullToAbsent) {
    return AppSessionsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      startUtc: Value(startUtc),
      endUtc: endUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endUtc),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
    );
  }

  factory AppSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSession(
      id: serializer.fromJson<int>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      startUtc: serializer.fromJson<int>(json['startUtc']),
      endUtc: serializer.fromJson<int?>(json['endUtc']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packageName': serializer.toJson<String>(packageName),
      'startUtc': serializer.toJson<int>(startUtc),
      'endUtc': serializer.toJson<int?>(endUtc),
      'durationMs': serializer.toJson<int?>(durationMs),
    };
  }

  AppSession copyWith({
    int? id,
    String? packageName,
    int? startUtc,
    Value<int?> endUtc = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
  }) => AppSession(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc.present ? endUtc.value : this.endUtc,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
  );
  AppSession copyWithCompanion(AppSessionsCompanion data) {
    return AppSession(
      id: data.id.present ? data.id.value : this.id,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSession(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, packageName, startUtc, endUtc, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSession &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.durationMs == this.durationMs);
}

class AppSessionsCompanion extends UpdateCompanion<AppSession> {
  final Value<int> id;
  final Value<String> packageName;
  final Value<int> startUtc;
  final Value<int?> endUtc;
  final Value<int?> durationMs;
  const AppSessionsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.durationMs = const Value.absent(),
  });
  AppSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String packageName,
    required int startUtc,
    this.endUtc = const Value.absent(),
    this.durationMs = const Value.absent(),
  }) : packageName = Value(packageName),
       startUtc = Value(startUtc);
  static Insertable<AppSession> custom({
    Expression<int>? id,
    Expression<String>? packageName,
    Expression<int>? startUtc,
    Expression<int>? endUtc,
    Expression<int>? durationMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (durationMs != null) 'duration_ms': durationMs,
    });
  }

  AppSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? packageName,
    Value<int>? startUtc,
    Value<int?>? endUtc,
    Value<int?>? durationMs,
  }) {
    return AppSessionsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<int>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<int>(endUtc.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSessionsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, Notification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampUtcMeta = const VerificationMeta(
    'timestampUtc',
  );
  @override
  late final GeneratedColumn<int> timestampUtc = GeneratedColumn<int>(
    'timestamp_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removedReasonMeta = const VerificationMeta(
    'removedReason',
  );
  @override
  late final GeneratedColumn<String> removedReason = GeneratedColumn<String>(
    'removed_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestampUtc,
    packageName,
    eventType,
    title,
    body,
    category,
    priority,
    removedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Notification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp_utc')) {
      context.handle(
        _timestampUtcMeta,
        timestampUtc.isAcceptableOrUnknown(
          data['timestamp_utc']!,
          _timestampUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampUtcMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('removed_reason')) {
      context.handle(
        _removedReasonMeta,
        removedReason.isAcceptableOrUnknown(
          data['removed_reason']!,
          _removedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestampUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_utc'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      ),
      removedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}removed_reason'],
      ),
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class Notification extends DataClass implements Insertable<Notification> {
  final int id;
  final int timestampUtc;
  final String packageName;
  final String eventType;
  final String? title;
  final String? body;
  final String? category;
  final int? priority;
  final String? removedReason;
  const Notification({
    required this.id,
    required this.timestampUtc,
    required this.packageName,
    required this.eventType,
    this.title,
    this.body,
    this.category,
    this.priority,
    this.removedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp_utc'] = Variable<int>(timestampUtc);
    map['package_name'] = Variable<String>(packageName);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || body != null) {
      map['text'] = Variable<String>(body);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<int>(priority);
    }
    if (!nullToAbsent || removedReason != null) {
      map['removed_reason'] = Variable<String>(removedReason);
    }
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      timestampUtc: Value(timestampUtc),
      packageName: Value(packageName),
      eventType: Value(eventType),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      removedReason: removedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(removedReason),
    );
  }

  factory Notification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notification(
      id: serializer.fromJson<int>(json['id']),
      timestampUtc: serializer.fromJson<int>(json['timestampUtc']),
      packageName: serializer.fromJson<String>(json['packageName']),
      eventType: serializer.fromJson<String>(json['eventType']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      category: serializer.fromJson<String?>(json['category']),
      priority: serializer.fromJson<int?>(json['priority']),
      removedReason: serializer.fromJson<String?>(json['removedReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestampUtc': serializer.toJson<int>(timestampUtc),
      'packageName': serializer.toJson<String>(packageName),
      'eventType': serializer.toJson<String>(eventType),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String?>(body),
      'category': serializer.toJson<String?>(category),
      'priority': serializer.toJson<int?>(priority),
      'removedReason': serializer.toJson<String?>(removedReason),
    };
  }

  Notification copyWith({
    int? id,
    int? timestampUtc,
    String? packageName,
    String? eventType,
    Value<String?> title = const Value.absent(),
    Value<String?> body = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<int?> priority = const Value.absent(),
    Value<String?> removedReason = const Value.absent(),
  }) => Notification(
    id: id ?? this.id,
    timestampUtc: timestampUtc ?? this.timestampUtc,
    packageName: packageName ?? this.packageName,
    eventType: eventType ?? this.eventType,
    title: title.present ? title.value : this.title,
    body: body.present ? body.value : this.body,
    category: category.present ? category.value : this.category,
    priority: priority.present ? priority.value : this.priority,
    removedReason: removedReason.present
        ? removedReason.value
        : this.removedReason,
  );
  Notification copyWithCompanion(NotificationsCompanion data) {
    return Notification(
      id: data.id.present ? data.id.value : this.id,
      timestampUtc: data.timestampUtc.present
          ? data.timestampUtc.value
          : this.timestampUtc,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      category: data.category.present ? data.category.value : this.category,
      priority: data.priority.present ? data.priority.value : this.priority,
      removedReason: data.removedReason.present
          ? data.removedReason.value
          : this.removedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notification(')
          ..write('id: $id, ')
          ..write('timestampUtc: $timestampUtc, ')
          ..write('packageName: $packageName, ')
          ..write('eventType: $eventType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('removedReason: $removedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestampUtc,
    packageName,
    eventType,
    title,
    body,
    category,
    priority,
    removedReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notification &&
          other.id == this.id &&
          other.timestampUtc == this.timestampUtc &&
          other.packageName == this.packageName &&
          other.eventType == this.eventType &&
          other.title == this.title &&
          other.body == this.body &&
          other.category == this.category &&
          other.priority == this.priority &&
          other.removedReason == this.removedReason);
}

class NotificationsCompanion extends UpdateCompanion<Notification> {
  final Value<int> id;
  final Value<int> timestampUtc;
  final Value<String> packageName;
  final Value<String> eventType;
  final Value<String?> title;
  final Value<String?> body;
  final Value<String?> category;
  final Value<int?> priority;
  final Value<String?> removedReason;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.timestampUtc = const Value.absent(),
    this.packageName = const Value.absent(),
    this.eventType = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.removedReason = const Value.absent(),
  });
  NotificationsCompanion.insert({
    this.id = const Value.absent(),
    required int timestampUtc,
    required String packageName,
    required String eventType,
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.removedReason = const Value.absent(),
  }) : timestampUtc = Value(timestampUtc),
       packageName = Value(packageName),
       eventType = Value(eventType);
  static Insertable<Notification> custom({
    Expression<int>? id,
    Expression<int>? timestampUtc,
    Expression<String>? packageName,
    Expression<String>? eventType,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? category,
    Expression<int>? priority,
    Expression<String>? removedReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestampUtc != null) 'timestamp_utc': timestampUtc,
      if (packageName != null) 'package_name': packageName,
      if (eventType != null) 'event_type': eventType,
      if (title != null) 'title': title,
      if (body != null) 'text': body,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (removedReason != null) 'removed_reason': removedReason,
    });
  }

  NotificationsCompanion copyWith({
    Value<int>? id,
    Value<int>? timestampUtc,
    Value<String>? packageName,
    Value<String>? eventType,
    Value<String?>? title,
    Value<String?>? body,
    Value<String?>? category,
    Value<int?>? priority,
    Value<String?>? removedReason,
  }) {
    return NotificationsCompanion(
      id: id ?? this.id,
      timestampUtc: timestampUtc ?? this.timestampUtc,
      packageName: packageName ?? this.packageName,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      removedReason: removedReason ?? this.removedReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestampUtc.present) {
      map['timestamp_utc'] = Variable<int>(timestampUtc.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (removedReason.present) {
      map['removed_reason'] = Variable<String>(removedReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('timestampUtc: $timestampUtc, ')
          ..write('packageName: $packageName, ')
          ..write('eventType: $eventType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('removedReason: $removedReason')
          ..write(')'))
        .toString();
  }
}

class $DailyRollupsTable extends DailyRollups
    with TableInfo<$DailyRollupsTable, DailyRollup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRollupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foregroundMsMeta = const VerificationMeta(
    'foregroundMs',
  );
  @override
  late final GeneratedColumn<int> foregroundMs = GeneratedColumn<int>(
    'foreground_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _launchCountMeta = const VerificationMeta(
    'launchCount',
  );
  @override
  late final GeneratedColumn<int> launchCount = GeneratedColumn<int>(
    'launch_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    packageName,
    foregroundMs,
    launchCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_rollups';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyRollup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('foreground_ms')) {
      context.handle(
        _foregroundMsMeta,
        foregroundMs.isAcceptableOrUnknown(
          data['foreground_ms']!,
          _foregroundMsMeta,
        ),
      );
    }
    if (data.containsKey('launch_count')) {
      context.handle(
        _launchCountMeta,
        launchCount.isAcceptableOrUnknown(
          data['launch_count']!,
          _launchCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date, packageName},
  ];
  @override
  DailyRollup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRollup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      foregroundMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}foreground_ms'],
      )!,
      launchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}launch_count'],
      )!,
    );
  }

  @override
  $DailyRollupsTable createAlias(String alias) {
    return $DailyRollupsTable(attachedDatabase, alias);
  }
}

class DailyRollup extends DataClass implements Insertable<DailyRollup> {
  final int id;
  final String date;
  final String packageName;
  final int foregroundMs;
  final int launchCount;
  const DailyRollup({
    required this.id,
    required this.date,
    required this.packageName,
    required this.foregroundMs,
    required this.launchCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['package_name'] = Variable<String>(packageName);
    map['foreground_ms'] = Variable<int>(foregroundMs);
    map['launch_count'] = Variable<int>(launchCount);
    return map;
  }

  DailyRollupsCompanion toCompanion(bool nullToAbsent) {
    return DailyRollupsCompanion(
      id: Value(id),
      date: Value(date),
      packageName: Value(packageName),
      foregroundMs: Value(foregroundMs),
      launchCount: Value(launchCount),
    );
  }

  factory DailyRollup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRollup(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      packageName: serializer.fromJson<String>(json['packageName']),
      foregroundMs: serializer.fromJson<int>(json['foregroundMs']),
      launchCount: serializer.fromJson<int>(json['launchCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'packageName': serializer.toJson<String>(packageName),
      'foregroundMs': serializer.toJson<int>(foregroundMs),
      'launchCount': serializer.toJson<int>(launchCount),
    };
  }

  DailyRollup copyWith({
    int? id,
    String? date,
    String? packageName,
    int? foregroundMs,
    int? launchCount,
  }) => DailyRollup(
    id: id ?? this.id,
    date: date ?? this.date,
    packageName: packageName ?? this.packageName,
    foregroundMs: foregroundMs ?? this.foregroundMs,
    launchCount: launchCount ?? this.launchCount,
  );
  DailyRollup copyWithCompanion(DailyRollupsCompanion data) {
    return DailyRollup(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      foregroundMs: data.foregroundMs.present
          ? data.foregroundMs.value
          : this.foregroundMs,
      launchCount: data.launchCount.present
          ? data.launchCount.value
          : this.launchCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRollup(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('packageName: $packageName, ')
          ..write('foregroundMs: $foregroundMs, ')
          ..write('launchCount: $launchCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, packageName, foregroundMs, launchCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRollup &&
          other.id == this.id &&
          other.date == this.date &&
          other.packageName == this.packageName &&
          other.foregroundMs == this.foregroundMs &&
          other.launchCount == this.launchCount);
}

class DailyRollupsCompanion extends UpdateCompanion<DailyRollup> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> packageName;
  final Value<int> foregroundMs;
  final Value<int> launchCount;
  const DailyRollupsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.packageName = const Value.absent(),
    this.foregroundMs = const Value.absent(),
    this.launchCount = const Value.absent(),
  });
  DailyRollupsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String packageName,
    this.foregroundMs = const Value.absent(),
    this.launchCount = const Value.absent(),
  }) : date = Value(date),
       packageName = Value(packageName);
  static Insertable<DailyRollup> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? packageName,
    Expression<int>? foregroundMs,
    Expression<int>? launchCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (packageName != null) 'package_name': packageName,
      if (foregroundMs != null) 'foreground_ms': foregroundMs,
      if (launchCount != null) 'launch_count': launchCount,
    });
  }

  DailyRollupsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? packageName,
    Value<int>? foregroundMs,
    Value<int>? launchCount,
  }) {
    return DailyRollupsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      packageName: packageName ?? this.packageName,
      foregroundMs: foregroundMs ?? this.foregroundMs,
      launchCount: launchCount ?? this.launchCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (foregroundMs.present) {
      map['foreground_ms'] = Variable<int>(foregroundMs.value);
    }
    if (launchCount.present) {
      map['launch_count'] = Variable<int>(launchCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRollupsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('packageName: $packageName, ')
          ..write('foregroundMs: $foregroundMs, ')
          ..write('launchCount: $launchCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$PanopticonDatabase extends GeneratedDatabase {
  _$PanopticonDatabase(QueryExecutor e) : super(e);
  $PanopticonDatabaseManager get managers => $PanopticonDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $AppSessionsTable appSessions = $AppSessionsTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final $DailyRollupsTable dailyRollups = $DailyRollupsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    events,
    appSessions,
    notifications,
    dailyRollups,
  ];
}

typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      required int timestampUtc,
      required int timezoneOffset,
      required String source,
      required String eventType,
      Value<String?> packageName,
      Value<String?> payloadJson,
      Value<int> schemaVersion,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      Value<int> timestampUtc,
      Value<int> timezoneOffset,
      Value<String> source,
      Value<String> eventType,
      Value<String?> packageName,
      Value<String?> payloadJson,
      Value<int> schemaVersion,
    });

class $$EventsTableFilterComposer
    extends Composer<_$PanopticonDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timezoneOffset => $composableBuilder(
    column: $table.timezoneOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$PanopticonDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timezoneOffset => $composableBuilder(
    column: $table.timezoneOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$PanopticonDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timezoneOffset => $composableBuilder(
    column: $table.timezoneOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$PanopticonDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, BaseReferences<_$PanopticonDatabase, $EventsTable, Event>),
          Event,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$PanopticonDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timestampUtc = const Value.absent(),
                Value<int> timezoneOffset = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> packageName = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                timestampUtc: timestampUtc,
                timezoneOffset: timezoneOffset,
                source: source,
                eventType: eventType,
                packageName: packageName,
                payloadJson: payloadJson,
                schemaVersion: schemaVersion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timestampUtc,
                required int timezoneOffset,
                required String source,
                required String eventType,
                Value<String?> packageName = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                timestampUtc: timestampUtc,
                timezoneOffset: timezoneOffset,
                source: source,
                eventType: eventType,
                packageName: packageName,
                payloadJson: payloadJson,
                schemaVersion: schemaVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$PanopticonDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, BaseReferences<_$PanopticonDatabase, $EventsTable, Event>),
      Event,
      PrefetchHooks Function()
    >;
typedef $$AppSessionsTableCreateCompanionBuilder =
    AppSessionsCompanion Function({
      Value<int> id,
      required String packageName,
      required int startUtc,
      Value<int?> endUtc,
      Value<int?> durationMs,
    });
typedef $$AppSessionsTableUpdateCompanionBuilder =
    AppSessionsCompanion Function({
      Value<int> id,
      Value<String> packageName,
      Value<int> startUtc,
      Value<int?> endUtc,
      Value<int?> durationMs,
    });

class $$AppSessionsTableFilterComposer
    extends Composer<_$PanopticonDatabase, $AppSessionsTable> {
  $$AppSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSessionsTableOrderingComposer
    extends Composer<_$PanopticonDatabase, $AppSessionsTable> {
  $$AppSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSessionsTableAnnotationComposer
    extends Composer<_$PanopticonDatabase, $AppSessionsTable> {
  $$AppSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<int> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );
}

class $$AppSessionsTableTableManager
    extends
        RootTableManager<
          _$PanopticonDatabase,
          $AppSessionsTable,
          AppSession,
          $$AppSessionsTableFilterComposer,
          $$AppSessionsTableOrderingComposer,
          $$AppSessionsTableAnnotationComposer,
          $$AppSessionsTableCreateCompanionBuilder,
          $$AppSessionsTableUpdateCompanionBuilder,
          (
            AppSession,
            BaseReferences<_$PanopticonDatabase, $AppSessionsTable, AppSession>,
          ),
          AppSession,
          PrefetchHooks Function()
        > {
  $$AppSessionsTableTableManager(
    _$PanopticonDatabase db,
    $AppSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<int> startUtc = const Value.absent(),
                Value<int?> endUtc = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
              }) => AppSessionsCompanion(
                id: id,
                packageName: packageName,
                startUtc: startUtc,
                endUtc: endUtc,
                durationMs: durationMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String packageName,
                required int startUtc,
                Value<int?> endUtc = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
              }) => AppSessionsCompanion.insert(
                id: id,
                packageName: packageName,
                startUtc: startUtc,
                endUtc: endUtc,
                durationMs: durationMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$PanopticonDatabase,
      $AppSessionsTable,
      AppSession,
      $$AppSessionsTableFilterComposer,
      $$AppSessionsTableOrderingComposer,
      $$AppSessionsTableAnnotationComposer,
      $$AppSessionsTableCreateCompanionBuilder,
      $$AppSessionsTableUpdateCompanionBuilder,
      (
        AppSession,
        BaseReferences<_$PanopticonDatabase, $AppSessionsTable, AppSession>,
      ),
      AppSession,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableCreateCompanionBuilder =
    NotificationsCompanion Function({
      Value<int> id,
      required int timestampUtc,
      required String packageName,
      required String eventType,
      Value<String?> title,
      Value<String?> body,
      Value<String?> category,
      Value<int?> priority,
      Value<String?> removedReason,
    });
typedef $$NotificationsTableUpdateCompanionBuilder =
    NotificationsCompanion Function({
      Value<int> id,
      Value<int> timestampUtc,
      Value<String> packageName,
      Value<String> eventType,
      Value<String?> title,
      Value<String?> body,
      Value<String?> category,
      Value<int?> priority,
      Value<String?> removedReason,
    });

class $$NotificationsTableFilterComposer
    extends Composer<_$PanopticonDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get removedReason => $composableBuilder(
    column: $table.removedReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$PanopticonDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get removedReason => $composableBuilder(
    column: $table.removedReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$PanopticonDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get removedReason => $composableBuilder(
    column: $table.removedReason,
    builder: (column) => column,
  );
}

class $$NotificationsTableTableManager
    extends
        RootTableManager<
          _$PanopticonDatabase,
          $NotificationsTable,
          Notification,
          $$NotificationsTableFilterComposer,
          $$NotificationsTableOrderingComposer,
          $$NotificationsTableAnnotationComposer,
          $$NotificationsTableCreateCompanionBuilder,
          $$NotificationsTableUpdateCompanionBuilder,
          (
            Notification,
            BaseReferences<
              _$PanopticonDatabase,
              $NotificationsTable,
              Notification
            >,
          ),
          Notification,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableManager(
    _$PanopticonDatabase db,
    $NotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timestampUtc = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> priority = const Value.absent(),
                Value<String?> removedReason = const Value.absent(),
              }) => NotificationsCompanion(
                id: id,
                timestampUtc: timestampUtc,
                packageName: packageName,
                eventType: eventType,
                title: title,
                body: body,
                category: category,
                priority: priority,
                removedReason: removedReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timestampUtc,
                required String packageName,
                required String eventType,
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> priority = const Value.absent(),
                Value<String?> removedReason = const Value.absent(),
              }) => NotificationsCompanion.insert(
                id: id,
                timestampUtc: timestampUtc,
                packageName: packageName,
                eventType: eventType,
                title: title,
                body: body,
                category: category,
                priority: priority,
                removedReason: removedReason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$PanopticonDatabase,
      $NotificationsTable,
      Notification,
      $$NotificationsTableFilterComposer,
      $$NotificationsTableOrderingComposer,
      $$NotificationsTableAnnotationComposer,
      $$NotificationsTableCreateCompanionBuilder,
      $$NotificationsTableUpdateCompanionBuilder,
      (
        Notification,
        BaseReferences<_$PanopticonDatabase, $NotificationsTable, Notification>,
      ),
      Notification,
      PrefetchHooks Function()
    >;
typedef $$DailyRollupsTableCreateCompanionBuilder =
    DailyRollupsCompanion Function({
      Value<int> id,
      required String date,
      required String packageName,
      Value<int> foregroundMs,
      Value<int> launchCount,
    });
typedef $$DailyRollupsTableUpdateCompanionBuilder =
    DailyRollupsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> packageName,
      Value<int> foregroundMs,
      Value<int> launchCount,
    });

class $$DailyRollupsTableFilterComposer
    extends Composer<_$PanopticonDatabase, $DailyRollupsTable> {
  $$DailyRollupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foregroundMs => $composableBuilder(
    column: $table.foregroundMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get launchCount => $composableBuilder(
    column: $table.launchCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyRollupsTableOrderingComposer
    extends Composer<_$PanopticonDatabase, $DailyRollupsTable> {
  $$DailyRollupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foregroundMs => $composableBuilder(
    column: $table.foregroundMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get launchCount => $composableBuilder(
    column: $table.launchCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyRollupsTableAnnotationComposer
    extends Composer<_$PanopticonDatabase, $DailyRollupsTable> {
  $$DailyRollupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get foregroundMs => $composableBuilder(
    column: $table.foregroundMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get launchCount => $composableBuilder(
    column: $table.launchCount,
    builder: (column) => column,
  );
}

class $$DailyRollupsTableTableManager
    extends
        RootTableManager<
          _$PanopticonDatabase,
          $DailyRollupsTable,
          DailyRollup,
          $$DailyRollupsTableFilterComposer,
          $$DailyRollupsTableOrderingComposer,
          $$DailyRollupsTableAnnotationComposer,
          $$DailyRollupsTableCreateCompanionBuilder,
          $$DailyRollupsTableUpdateCompanionBuilder,
          (
            DailyRollup,
            BaseReferences<
              _$PanopticonDatabase,
              $DailyRollupsTable,
              DailyRollup
            >,
          ),
          DailyRollup,
          PrefetchHooks Function()
        > {
  $$DailyRollupsTableTableManager(
    _$PanopticonDatabase db,
    $DailyRollupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyRollupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyRollupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyRollupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<int> foregroundMs = const Value.absent(),
                Value<int> launchCount = const Value.absent(),
              }) => DailyRollupsCompanion(
                id: id,
                date: date,
                packageName: packageName,
                foregroundMs: foregroundMs,
                launchCount: launchCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String packageName,
                Value<int> foregroundMs = const Value.absent(),
                Value<int> launchCount = const Value.absent(),
              }) => DailyRollupsCompanion.insert(
                id: id,
                date: date,
                packageName: packageName,
                foregroundMs: foregroundMs,
                launchCount: launchCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyRollupsTableProcessedTableManager =
    ProcessedTableManager<
      _$PanopticonDatabase,
      $DailyRollupsTable,
      DailyRollup,
      $$DailyRollupsTableFilterComposer,
      $$DailyRollupsTableOrderingComposer,
      $$DailyRollupsTableAnnotationComposer,
      $$DailyRollupsTableCreateCompanionBuilder,
      $$DailyRollupsTableUpdateCompanionBuilder,
      (
        DailyRollup,
        BaseReferences<_$PanopticonDatabase, $DailyRollupsTable, DailyRollup>,
      ),
      DailyRollup,
      PrefetchHooks Function()
    >;

class $PanopticonDatabaseManager {
  final _$PanopticonDatabase _db;
  $PanopticonDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$AppSessionsTableTableManager get appSessions =>
      $$AppSessionsTableTableManager(_db, _db.appSessions);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
  $$DailyRollupsTableTableManager get dailyRollups =>
      $$DailyRollupsTableTableManager(_db, _db.dailyRollups);
}
