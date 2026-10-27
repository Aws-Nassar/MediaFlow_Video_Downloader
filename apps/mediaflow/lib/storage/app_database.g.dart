// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $JobRecordsTable extends JobRecords
    with TableInfo<$JobRecordsTable, JobRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceLabelMeta = const VerificationMeta(
    'sourceLabel',
  );
  @override
  late final GeneratedColumn<String> sourceLabel = GeneratedColumn<String>(
    'source_label',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadTypeMeta = const VerificationMeta(
    'downloadType',
  );
  @override
  late final GeneratedColumn<String> downloadType = GeneratedColumn<String>(
    'download_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesPerSecondMeta = const VerificationMeta(
    'bytesPerSecond',
  );
  @override
  late final GeneratedColumn<double> bytesPerSecond = GeneratedColumn<double>(
    'bytes_per_second',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etaMsMeta = const VerificationMeta('etaMs');
  @override
  late final GeneratedColumn<int> etaMs = GeneratedColumn<int>(
    'eta_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorDetailsMeta = const VerificationMeta(
    'errorDetails',
  );
  @override
  late final GeneratedColumn<String> errorDetails = GeneratedColumn<String>(
    'error_details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorRetryableMeta = const VerificationMeta(
    'errorRetryable',
  );
  @override
  late final GeneratedColumn<bool> errorRetryable = GeneratedColumn<bool>(
    'error_retryable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("error_retryable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemIndexMeta = const VerificationMeta(
    'itemIndex',
  );
  @override
  late final GeneratedColumn<int> itemIndex = GeneratedColumn<int>(
    'item_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _zipEntriesJsonMeta = const VerificationMeta(
    'zipEntriesJson',
  );
  @override
  late final GeneratedColumn<String> zipEntriesJson = GeneratedColumn<String>(
    'zip_entries_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _itemSkippedJsonMeta = const VerificationMeta(
    'itemSkippedJson',
  );
  @override
  late final GeneratedColumn<String> itemSkippedJson = GeneratedColumn<String>(
    'item_skipped_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    batchId,
    url,
    sourceId,
    sourceLabel,
    title,
    downloadType,
    status,
    progress,
    downloadedBytes,
    totalBytes,
    bytesPerSecond,
    etaMs,
    errorCode,
    errorDetails,
    errorRetryable,
    filePath,
    relativePath,
    createdAt,
    completedAt,
    itemIndex,
    itemCount,
    zipEntriesJson,
    itemSkippedJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('source_label')) {
      context.handle(
        _sourceLabelMeta,
        sourceLabel.isAcceptableOrUnknown(
          data['source_label']!,
          _sourceLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceLabelMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('download_type')) {
      context.handle(
        _downloadTypeMeta,
        downloadType.isAcceptableOrUnknown(
          data['download_type']!,
          _downloadTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('bytes_per_second')) {
      context.handle(
        _bytesPerSecondMeta,
        bytesPerSecond.isAcceptableOrUnknown(
          data['bytes_per_second']!,
          _bytesPerSecondMeta,
        ),
      );
    }
    if (data.containsKey('eta_ms')) {
      context.handle(
        _etaMsMeta,
        etaMs.isAcceptableOrUnknown(data['eta_ms']!, _etaMsMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_details')) {
      context.handle(
        _errorDetailsMeta,
        errorDetails.isAcceptableOrUnknown(
          data['error_details']!,
          _errorDetailsMeta,
        ),
      );
    }
    if (data.containsKey('error_retryable')) {
      context.handle(
        _errorRetryableMeta,
        errorRetryable.isAcceptableOrUnknown(
          data['error_retryable']!,
          _errorRetryableMeta,
        ),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('item_index')) {
      context.handle(
        _itemIndexMeta,
        itemIndex.isAcceptableOrUnknown(data['item_index']!, _itemIndexMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    }
    if (data.containsKey('zip_entries_json')) {
      context.handle(
        _zipEntriesJsonMeta,
        zipEntriesJson.isAcceptableOrUnknown(
          data['zip_entries_json']!,
          _zipEntriesJsonMeta,
        ),
      );
    }
    if (data.containsKey('item_skipped_json')) {
      context.handle(
        _itemSkippedJsonMeta,
        itemSkippedJson.isAcceptableOrUnknown(
          data['item_skipped_json']!,
          _itemSkippedJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      sourceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_label'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      downloadType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      ),
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      ),
      bytesPerSecond: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bytes_per_second'],
      ),
      etaMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}eta_ms'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_details'],
      ),
      errorRetryable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}error_retryable'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      itemIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_index'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      zipEntriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zip_entries_json'],
      )!,
      itemSkippedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_skipped_json'],
      )!,
    );
  }

  @override
  $JobRecordsTable createAlias(String alias) {
    return $JobRecordsTable(attachedDatabase, alias);
  }
}

class JobRecord extends DataClass implements Insertable<JobRecord> {
  final String id;
  final String batchId;
  final String url;
  final String sourceId;
  final String sourceLabel;
  final String title;
  final String downloadType;
  final String status;
  final double progress;
  final int? downloadedBytes;
  final int? totalBytes;
  final double? bytesPerSecond;
  final int? etaMs;
  final String? errorCode;
  final String? errorDetails;
  final bool errorRetryable;
  final String? filePath;
  final String? relativePath;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int itemIndex;
  final int itemCount;
  final String zipEntriesJson;
  final String itemSkippedJson;
  const JobRecord({
    required this.id,
    required this.batchId,
    required this.url,
    required this.sourceId,
    required this.sourceLabel,
    required this.title,
    required this.downloadType,
    required this.status,
    required this.progress,
    this.downloadedBytes,
    this.totalBytes,
    this.bytesPerSecond,
    this.etaMs,
    this.errorCode,
    this.errorDetails,
    required this.errorRetryable,
    this.filePath,
    this.relativePath,
    required this.createdAt,
    this.completedAt,
    required this.itemIndex,
    required this.itemCount,
    required this.zipEntriesJson,
    required this.itemSkippedJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['batch_id'] = Variable<String>(batchId);
    map['url'] = Variable<String>(url);
    map['source_id'] = Variable<String>(sourceId);
    map['source_label'] = Variable<String>(sourceLabel);
    map['title'] = Variable<String>(title);
    map['download_type'] = Variable<String>(downloadType);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || downloadedBytes != null) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    }
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    if (!nullToAbsent || bytesPerSecond != null) {
      map['bytes_per_second'] = Variable<double>(bytesPerSecond);
    }
    if (!nullToAbsent || etaMs != null) {
      map['eta_ms'] = Variable<int>(etaMs);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorDetails != null) {
      map['error_details'] = Variable<String>(errorDetails);
    }
    map['error_retryable'] = Variable<bool>(errorRetryable);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || relativePath != null) {
      map['relative_path'] = Variable<String>(relativePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['item_index'] = Variable<int>(itemIndex);
    map['item_count'] = Variable<int>(itemCount);
    map['zip_entries_json'] = Variable<String>(zipEntriesJson);
    map['item_skipped_json'] = Variable<String>(itemSkippedJson);
    return map;
  }

  JobRecordsCompanion toCompanion(bool nullToAbsent) {
    return JobRecordsCompanion(
      id: Value(id),
      batchId: Value(batchId),
      url: Value(url),
      sourceId: Value(sourceId),
      sourceLabel: Value(sourceLabel),
      title: Value(title),
      downloadType: Value(downloadType),
      status: Value(status),
      progress: Value(progress),
      downloadedBytes: downloadedBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedBytes),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      bytesPerSecond: bytesPerSecond == null && nullToAbsent
          ? const Value.absent()
          : Value(bytesPerSecond),
      etaMs: etaMs == null && nullToAbsent
          ? const Value.absent()
          : Value(etaMs),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorDetails: errorDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(errorDetails),
      errorRetryable: Value(errorRetryable),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      relativePath: relativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(relativePath),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      itemIndex: Value(itemIndex),
      itemCount: Value(itemCount),
      zipEntriesJson: Value(zipEntriesJson),
      itemSkippedJson: Value(itemSkippedJson),
    );
  }

  factory JobRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobRecord(
      id: serializer.fromJson<String>(json['id']),
      batchId: serializer.fromJson<String>(json['batchId']),
      url: serializer.fromJson<String>(json['url']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sourceLabel: serializer.fromJson<String>(json['sourceLabel']),
      title: serializer.fromJson<String>(json['title']),
      downloadType: serializer.fromJson<String>(json['downloadType']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      downloadedBytes: serializer.fromJson<int?>(json['downloadedBytes']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      bytesPerSecond: serializer.fromJson<double?>(json['bytesPerSecond']),
      etaMs: serializer.fromJson<int?>(json['etaMs']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorDetails: serializer.fromJson<String?>(json['errorDetails']),
      errorRetryable: serializer.fromJson<bool>(json['errorRetryable']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      relativePath: serializer.fromJson<String?>(json['relativePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      itemIndex: serializer.fromJson<int>(json['itemIndex']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      zipEntriesJson: serializer.fromJson<String>(json['zipEntriesJson']),
      itemSkippedJson: serializer.fromJson<String>(json['itemSkippedJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'batchId': serializer.toJson<String>(batchId),
      'url': serializer.toJson<String>(url),
      'sourceId': serializer.toJson<String>(sourceId),
      'sourceLabel': serializer.toJson<String>(sourceLabel),
      'title': serializer.toJson<String>(title),
      'downloadType': serializer.toJson<String>(downloadType),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'downloadedBytes': serializer.toJson<int?>(downloadedBytes),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'bytesPerSecond': serializer.toJson<double?>(bytesPerSecond),
      'etaMs': serializer.toJson<int?>(etaMs),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorDetails': serializer.toJson<String?>(errorDetails),
      'errorRetryable': serializer.toJson<bool>(errorRetryable),
      'filePath': serializer.toJson<String?>(filePath),
      'relativePath': serializer.toJson<String?>(relativePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'itemIndex': serializer.toJson<int>(itemIndex),
      'itemCount': serializer.toJson<int>(itemCount),
      'zipEntriesJson': serializer.toJson<String>(zipEntriesJson),
      'itemSkippedJson': serializer.toJson<String>(itemSkippedJson),
    };
  }

  JobRecord copyWith({
    String? id,
    String? batchId,
    String? url,
    String? sourceId,
    String? sourceLabel,
    String? title,
    String? downloadType,
    String? status,
    double? progress,
    Value<int?> downloadedBytes = const Value.absent(),
    Value<int?> totalBytes = const Value.absent(),
    Value<double?> bytesPerSecond = const Value.absent(),
    Value<int?> etaMs = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorDetails = const Value.absent(),
    bool? errorRetryable,
    Value<String?> filePath = const Value.absent(),
    Value<String?> relativePath = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? itemIndex,
    int? itemCount,
    String? zipEntriesJson,
    String? itemSkippedJson,
  }) => JobRecord(
    id: id ?? this.id,
    batchId: batchId ?? this.batchId,
    url: url ?? this.url,
    sourceId: sourceId ?? this.sourceId,
    sourceLabel: sourceLabel ?? this.sourceLabel,
    title: title ?? this.title,
    downloadType: downloadType ?? this.downloadType,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    downloadedBytes: downloadedBytes.present
        ? downloadedBytes.value
        : this.downloadedBytes,
    totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
    bytesPerSecond: bytesPerSecond.present
        ? bytesPerSecond.value
        : this.bytesPerSecond,
    etaMs: etaMs.present ? etaMs.value : this.etaMs,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorDetails: errorDetails.present ? errorDetails.value : this.errorDetails,
    errorRetryable: errorRetryable ?? this.errorRetryable,
    filePath: filePath.present ? filePath.value : this.filePath,
    relativePath: relativePath.present ? relativePath.value : this.relativePath,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    itemIndex: itemIndex ?? this.itemIndex,
    itemCount: itemCount ?? this.itemCount,
    zipEntriesJson: zipEntriesJson ?? this.zipEntriesJson,
    itemSkippedJson: itemSkippedJson ?? this.itemSkippedJson,
  );
  JobRecord copyWithCompanion(JobRecordsCompanion data) {
    return JobRecord(
      id: data.id.present ? data.id.value : this.id,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      url: data.url.present ? data.url.value : this.url,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceLabel: data.sourceLabel.present
          ? data.sourceLabel.value
          : this.sourceLabel,
      title: data.title.present ? data.title.value : this.title,
      downloadType: data.downloadType.present
          ? data.downloadType.value
          : this.downloadType,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      bytesPerSecond: data.bytesPerSecond.present
          ? data.bytesPerSecond.value
          : this.bytesPerSecond,
      etaMs: data.etaMs.present ? data.etaMs.value : this.etaMs,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorDetails: data.errorDetails.present
          ? data.errorDetails.value
          : this.errorDetails,
      errorRetryable: data.errorRetryable.present
          ? data.errorRetryable.value
          : this.errorRetryable,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      itemIndex: data.itemIndex.present ? data.itemIndex.value : this.itemIndex,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      zipEntriesJson: data.zipEntriesJson.present
          ? data.zipEntriesJson.value
          : this.zipEntriesJson,
      itemSkippedJson: data.itemSkippedJson.present
          ? data.itemSkippedJson.value
          : this.itemSkippedJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobRecord(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('url: $url, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('title: $title, ')
          ..write('downloadType: $downloadType, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('bytesPerSecond: $bytesPerSecond, ')
          ..write('etaMs: $etaMs, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorDetails: $errorDetails, ')
          ..write('errorRetryable: $errorRetryable, ')
          ..write('filePath: $filePath, ')
          ..write('relativePath: $relativePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('itemIndex: $itemIndex, ')
          ..write('itemCount: $itemCount, ')
          ..write('zipEntriesJson: $zipEntriesJson, ')
          ..write('itemSkippedJson: $itemSkippedJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    batchId,
    url,
    sourceId,
    sourceLabel,
    title,
    downloadType,
    status,
    progress,
    downloadedBytes,
    totalBytes,
    bytesPerSecond,
    etaMs,
    errorCode,
    errorDetails,
    errorRetryable,
    filePath,
    relativePath,
    createdAt,
    completedAt,
    itemIndex,
    itemCount,
    zipEntriesJson,
    itemSkippedJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobRecord &&
          other.id == this.id &&
          other.batchId == this.batchId &&
          other.url == this.url &&
          other.sourceId == this.sourceId &&
          other.sourceLabel == this.sourceLabel &&
          other.title == this.title &&
          other.downloadType == this.downloadType &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.downloadedBytes == this.downloadedBytes &&
          other.totalBytes == this.totalBytes &&
          other.bytesPerSecond == this.bytesPerSecond &&
          other.etaMs == this.etaMs &&
          other.errorCode == this.errorCode &&
          other.errorDetails == this.errorDetails &&
          other.errorRetryable == this.errorRetryable &&
          other.filePath == this.filePath &&
          other.relativePath == this.relativePath &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.itemIndex == this.itemIndex &&
          other.itemCount == this.itemCount &&
          other.zipEntriesJson == this.zipEntriesJson &&
          other.itemSkippedJson == this.itemSkippedJson);
}

class JobRecordsCompanion extends UpdateCompanion<JobRecord> {
  final Value<String> id;
  final Value<String> batchId;
  final Value<String> url;
  final Value<String> sourceId;
  final Value<String> sourceLabel;
  final Value<String> title;
  final Value<String> downloadType;
  final Value<String> status;
  final Value<double> progress;
  final Value<int?> downloadedBytes;
  final Value<int?> totalBytes;
  final Value<double?> bytesPerSecond;
  final Value<int?> etaMs;
  final Value<String?> errorCode;
  final Value<String?> errorDetails;
  final Value<bool> errorRetryable;
  final Value<String?> filePath;
  final Value<String?> relativePath;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<int> itemIndex;
  final Value<int> itemCount;
  final Value<String> zipEntriesJson;
  final Value<String> itemSkippedJson;
  final Value<int> rowid;
  const JobRecordsCompanion({
    this.id = const Value.absent(),
    this.batchId = const Value.absent(),
    this.url = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    this.title = const Value.absent(),
    this.downloadType = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.bytesPerSecond = const Value.absent(),
    this.etaMs = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorDetails = const Value.absent(),
    this.errorRetryable = const Value.absent(),
    this.filePath = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.itemIndex = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.zipEntriesJson = const Value.absent(),
    this.itemSkippedJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobRecordsCompanion.insert({
    required String id,
    required String batchId,
    required String url,
    required String sourceId,
    required String sourceLabel,
    required String title,
    required String downloadType,
    required String status,
    this.progress = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.bytesPerSecond = const Value.absent(),
    this.etaMs = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorDetails = const Value.absent(),
    this.errorRetryable = const Value.absent(),
    this.filePath = const Value.absent(),
    this.relativePath = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.itemIndex = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.zipEntriesJson = const Value.absent(),
    this.itemSkippedJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       batchId = Value(batchId),
       url = Value(url),
       sourceId = Value(sourceId),
       sourceLabel = Value(sourceLabel),
       title = Value(title),
       downloadType = Value(downloadType),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<JobRecord> custom({
    Expression<String>? id,
    Expression<String>? batchId,
    Expression<String>? url,
    Expression<String>? sourceId,
    Expression<String>? sourceLabel,
    Expression<String>? title,
    Expression<String>? downloadType,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? downloadedBytes,
    Expression<int>? totalBytes,
    Expression<double>? bytesPerSecond,
    Expression<int>? etaMs,
    Expression<String>? errorCode,
    Expression<String>? errorDetails,
    Expression<bool>? errorRetryable,
    Expression<String>? filePath,
    Expression<String>? relativePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<int>? itemIndex,
    Expression<int>? itemCount,
    Expression<String>? zipEntriesJson,
    Expression<String>? itemSkippedJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (batchId != null) 'batch_id': batchId,
      if (url != null) 'url': url,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceLabel != null) 'source_label': sourceLabel,
      if (title != null) 'title': title,
      if (downloadType != null) 'download_type': downloadType,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (bytesPerSecond != null) 'bytes_per_second': bytesPerSecond,
      if (etaMs != null) 'eta_ms': etaMs,
      if (errorCode != null) 'error_code': errorCode,
      if (errorDetails != null) 'error_details': errorDetails,
      if (errorRetryable != null) 'error_retryable': errorRetryable,
      if (filePath != null) 'file_path': filePath,
      if (relativePath != null) 'relative_path': relativePath,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (itemIndex != null) 'item_index': itemIndex,
      if (itemCount != null) 'item_count': itemCount,
      if (zipEntriesJson != null) 'zip_entries_json': zipEntriesJson,
      if (itemSkippedJson != null) 'item_skipped_json': itemSkippedJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? batchId,
    Value<String>? url,
    Value<String>? sourceId,
    Value<String>? sourceLabel,
    Value<String>? title,
    Value<String>? downloadType,
    Value<String>? status,
    Value<double>? progress,
    Value<int?>? downloadedBytes,
    Value<int?>? totalBytes,
    Value<double?>? bytesPerSecond,
    Value<int?>? etaMs,
    Value<String?>? errorCode,
    Value<String?>? errorDetails,
    Value<bool>? errorRetryable,
    Value<String?>? filePath,
    Value<String?>? relativePath,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<int>? itemIndex,
    Value<int>? itemCount,
    Value<String>? zipEntriesJson,
    Value<String>? itemSkippedJson,
    Value<int>? rowid,
  }) {
    return JobRecordsCompanion(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      url: url ?? this.url,
      sourceId: sourceId ?? this.sourceId,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      title: title ?? this.title,
      downloadType: downloadType ?? this.downloadType,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      etaMs: etaMs ?? this.etaMs,
      errorCode: errorCode ?? this.errorCode,
      errorDetails: errorDetails ?? this.errorDetails,
      errorRetryable: errorRetryable ?? this.errorRetryable,
      filePath: filePath ?? this.filePath,
      relativePath: relativePath ?? this.relativePath,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      itemIndex: itemIndex ?? this.itemIndex,
      itemCount: itemCount ?? this.itemCount,
      zipEntriesJson: zipEntriesJson ?? this.zipEntriesJson,
      itemSkippedJson: itemSkippedJson ?? this.itemSkippedJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceLabel.present) {
      map['source_label'] = Variable<String>(sourceLabel.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (downloadType.present) {
      map['download_type'] = Variable<String>(downloadType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (bytesPerSecond.present) {
      map['bytes_per_second'] = Variable<double>(bytesPerSecond.value);
    }
    if (etaMs.present) {
      map['eta_ms'] = Variable<int>(etaMs.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorDetails.present) {
      map['error_details'] = Variable<String>(errorDetails.value);
    }
    if (errorRetryable.present) {
      map['error_retryable'] = Variable<bool>(errorRetryable.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (itemIndex.present) {
      map['item_index'] = Variable<int>(itemIndex.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (zipEntriesJson.present) {
      map['zip_entries_json'] = Variable<String>(zipEntriesJson.value);
    }
    if (itemSkippedJson.present) {
      map['item_skipped_json'] = Variable<String>(itemSkippedJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobRecordsCompanion(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('url: $url, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('title: $title, ')
          ..write('downloadType: $downloadType, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('bytesPerSecond: $bytesPerSecond, ')
          ..write('etaMs: $etaMs, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorDetails: $errorDetails, ')
          ..write('errorRetryable: $errorRetryable, ')
          ..write('filePath: $filePath, ')
          ..write('relativePath: $relativePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('itemIndex: $itemIndex, ')
          ..write('itemCount: $itemCount, ')
          ..write('zipEntriesJson: $zipEntriesJson, ')
          ..write('itemSkippedJson: $itemSkippedJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BatchSummaryRecordsTable extends BatchSummaryRecords
    with TableInfo<$BatchSummaryRecordsTable, BatchSummaryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchSummaryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<int> completed = GeneratedColumn<int>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failedMeta = const VerificationMeta('failed');
  @override
  late final GeneratedColumn<int> failed = GeneratedColumn<int>(
    'failed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<int> skipped = GeneratedColumn<int>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cancelledMeta = const VerificationMeta(
    'cancelled',
  );
  @override
  late final GeneratedColumn<int> cancelled = GeneratedColumn<int>(
    'cancelled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failuresJsonMeta = const VerificationMeta(
    'failuresJson',
  );
  @override
  late final GeneratedColumn<String> failuresJson = GeneratedColumn<String>(
    'failures_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _skippedItemsJsonMeta = const VerificationMeta(
    'skippedItemsJson',
  );
  @override
  late final GeneratedColumn<String> skippedItemsJson = GeneratedColumn<String>(
    'skipped_items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _savedAtUsMeta = const VerificationMeta(
    'savedAtUs',
  );
  @override
  late final GeneratedColumn<int> savedAtUs = GeneratedColumn<int>(
    'saved_at_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    batchId,
    total,
    completed,
    failed,
    skipped,
    cancelled,
    totalBytes,
    elapsedMs,
    failuresJson,
    skippedItemsJson,
    savedAtUs,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchSummaryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('failed')) {
      context.handle(
        _failedMeta,
        failed.isAcceptableOrUnknown(data['failed']!, _failedMeta),
      );
    } else if (isInserting) {
      context.missing(_failedMeta);
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    } else if (isInserting) {
      context.missing(_skippedMeta);
    }
    if (data.containsKey('cancelled')) {
      context.handle(
        _cancelledMeta,
        cancelled.isAcceptableOrUnknown(data['cancelled']!, _cancelledMeta),
      );
    } else if (isInserting) {
      context.missing(_cancelledMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('failures_json')) {
      context.handle(
        _failuresJsonMeta,
        failuresJson.isAcceptableOrUnknown(
          data['failures_json']!,
          _failuresJsonMeta,
        ),
      );
    }
    if (data.containsKey('skipped_items_json')) {
      context.handle(
        _skippedItemsJsonMeta,
        skippedItemsJson.isAcceptableOrUnknown(
          data['skipped_items_json']!,
          _skippedItemsJsonMeta,
        ),
      );
    }
    if (data.containsKey('saved_at_us')) {
      context.handle(
        _savedAtUsMeta,
        savedAtUs.isAcceptableOrUnknown(data['saved_at_us']!, _savedAtUsMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtUsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId};
  @override
  BatchSummaryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchSummaryRecord(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed'],
      )!,
      failed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed'],
      )!,
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped'],
      )!,
      cancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancelled'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      failuresJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failures_json'],
      )!,
      skippedItemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skipped_items_json'],
      )!,
      savedAtUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_at_us'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BatchSummaryRecordsTable createAlias(String alias) {
    return $BatchSummaryRecordsTable(attachedDatabase, alias);
  }
}

class BatchSummaryRecord extends DataClass
    implements Insertable<BatchSummaryRecord> {
  final String batchId;
  final int total;
  final int completed;
  final int failed;
  final int skipped;
  final int cancelled;
  final int totalBytes;
  final int elapsedMs;
  final String failuresJson;
  final String skippedItemsJson;
  final int savedAtUs;
  final DateTime createdAt;
  const BatchSummaryRecord({
    required this.batchId,
    required this.total,
    required this.completed,
    required this.failed,
    required this.skipped,
    required this.cancelled,
    required this.totalBytes,
    required this.elapsedMs,
    required this.failuresJson,
    required this.skippedItemsJson,
    required this.savedAtUs,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<String>(batchId);
    map['total'] = Variable<int>(total);
    map['completed'] = Variable<int>(completed);
    map['failed'] = Variable<int>(failed);
    map['skipped'] = Variable<int>(skipped);
    map['cancelled'] = Variable<int>(cancelled);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['failures_json'] = Variable<String>(failuresJson);
    map['skipped_items_json'] = Variable<String>(skippedItemsJson);
    map['saved_at_us'] = Variable<int>(savedAtUs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BatchSummaryRecordsCompanion toCompanion(bool nullToAbsent) {
    return BatchSummaryRecordsCompanion(
      batchId: Value(batchId),
      total: Value(total),
      completed: Value(completed),
      failed: Value(failed),
      skipped: Value(skipped),
      cancelled: Value(cancelled),
      totalBytes: Value(totalBytes),
      elapsedMs: Value(elapsedMs),
      failuresJson: Value(failuresJson),
      skippedItemsJson: Value(skippedItemsJson),
      savedAtUs: Value(savedAtUs),
      createdAt: Value(createdAt),
    );
  }

  factory BatchSummaryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchSummaryRecord(
      batchId: serializer.fromJson<String>(json['batchId']),
      total: serializer.fromJson<int>(json['total']),
      completed: serializer.fromJson<int>(json['completed']),
      failed: serializer.fromJson<int>(json['failed']),
      skipped: serializer.fromJson<int>(json['skipped']),
      cancelled: serializer.fromJson<int>(json['cancelled']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      failuresJson: serializer.fromJson<String>(json['failuresJson']),
      skippedItemsJson: serializer.fromJson<String>(json['skippedItemsJson']),
      savedAtUs: serializer.fromJson<int>(json['savedAtUs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batchId': serializer.toJson<String>(batchId),
      'total': serializer.toJson<int>(total),
      'completed': serializer.toJson<int>(completed),
      'failed': serializer.toJson<int>(failed),
      'skipped': serializer.toJson<int>(skipped),
      'cancelled': serializer.toJson<int>(cancelled),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'failuresJson': serializer.toJson<String>(failuresJson),
      'skippedItemsJson': serializer.toJson<String>(skippedItemsJson),
      'savedAtUs': serializer.toJson<int>(savedAtUs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BatchSummaryRecord copyWith({
    String? batchId,
    int? total,
    int? completed,
    int? failed,
    int? skipped,
    int? cancelled,
    int? totalBytes,
    int? elapsedMs,
    String? failuresJson,
    String? skippedItemsJson,
    int? savedAtUs,
    DateTime? createdAt,
  }) => BatchSummaryRecord(
    batchId: batchId ?? this.batchId,
    total: total ?? this.total,
    completed: completed ?? this.completed,
    failed: failed ?? this.failed,
    skipped: skipped ?? this.skipped,
    cancelled: cancelled ?? this.cancelled,
    totalBytes: totalBytes ?? this.totalBytes,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    failuresJson: failuresJson ?? this.failuresJson,
    skippedItemsJson: skippedItemsJson ?? this.skippedItemsJson,
    savedAtUs: savedAtUs ?? this.savedAtUs,
    createdAt: createdAt ?? this.createdAt,
  );
  BatchSummaryRecord copyWithCompanion(BatchSummaryRecordsCompanion data) {
    return BatchSummaryRecord(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      total: data.total.present ? data.total.value : this.total,
      completed: data.completed.present ? data.completed.value : this.completed,
      failed: data.failed.present ? data.failed.value : this.failed,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      cancelled: data.cancelled.present ? data.cancelled.value : this.cancelled,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      failuresJson: data.failuresJson.present
          ? data.failuresJson.value
          : this.failuresJson,
      skippedItemsJson: data.skippedItemsJson.present
          ? data.skippedItemsJson.value
          : this.skippedItemsJson,
      savedAtUs: data.savedAtUs.present ? data.savedAtUs.value : this.savedAtUs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchSummaryRecord(')
          ..write('batchId: $batchId, ')
          ..write('total: $total, ')
          ..write('completed: $completed, ')
          ..write('failed: $failed, ')
          ..write('skipped: $skipped, ')
          ..write('cancelled: $cancelled, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('failuresJson: $failuresJson, ')
          ..write('skippedItemsJson: $skippedItemsJson, ')
          ..write('savedAtUs: $savedAtUs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    batchId,
    total,
    completed,
    failed,
    skipped,
    cancelled,
    totalBytes,
    elapsedMs,
    failuresJson,
    skippedItemsJson,
    savedAtUs,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchSummaryRecord &&
          other.batchId == this.batchId &&
          other.total == this.total &&
          other.completed == this.completed &&
          other.failed == this.failed &&
          other.skipped == this.skipped &&
          other.cancelled == this.cancelled &&
          other.totalBytes == this.totalBytes &&
          other.elapsedMs == this.elapsedMs &&
          other.failuresJson == this.failuresJson &&
          other.skippedItemsJson == this.skippedItemsJson &&
          other.savedAtUs == this.savedAtUs &&
          other.createdAt == this.createdAt);
}

class BatchSummaryRecordsCompanion extends UpdateCompanion<BatchSummaryRecord> {
  final Value<String> batchId;
  final Value<int> total;
  final Value<int> completed;
  final Value<int> failed;
  final Value<int> skipped;
  final Value<int> cancelled;
  final Value<int> totalBytes;
  final Value<int> elapsedMs;
  final Value<String> failuresJson;
  final Value<String> skippedItemsJson;
  final Value<int> savedAtUs;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BatchSummaryRecordsCompanion({
    this.batchId = const Value.absent(),
    this.total = const Value.absent(),
    this.completed = const Value.absent(),
    this.failed = const Value.absent(),
    this.skipped = const Value.absent(),
    this.cancelled = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.failuresJson = const Value.absent(),
    this.skippedItemsJson = const Value.absent(),
    this.savedAtUs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchSummaryRecordsCompanion.insert({
    required String batchId,
    required int total,
    required int completed,
    required int failed,
    required int skipped,
    required int cancelled,
    required int totalBytes,
    required int elapsedMs,
    this.failuresJson = const Value.absent(),
    this.skippedItemsJson = const Value.absent(),
    required int savedAtUs,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       total = Value(total),
       completed = Value(completed),
       failed = Value(failed),
       skipped = Value(skipped),
       cancelled = Value(cancelled),
       totalBytes = Value(totalBytes),
       elapsedMs = Value(elapsedMs),
       savedAtUs = Value(savedAtUs),
       createdAt = Value(createdAt);
  static Insertable<BatchSummaryRecord> custom({
    Expression<String>? batchId,
    Expression<int>? total,
    Expression<int>? completed,
    Expression<int>? failed,
    Expression<int>? skipped,
    Expression<int>? cancelled,
    Expression<int>? totalBytes,
    Expression<int>? elapsedMs,
    Expression<String>? failuresJson,
    Expression<String>? skippedItemsJson,
    Expression<int>? savedAtUs,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (total != null) 'total': total,
      if (completed != null) 'completed': completed,
      if (failed != null) 'failed': failed,
      if (skipped != null) 'skipped': skipped,
      if (cancelled != null) 'cancelled': cancelled,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (failuresJson != null) 'failures_json': failuresJson,
      if (skippedItemsJson != null) 'skipped_items_json': skippedItemsJson,
      if (savedAtUs != null) 'saved_at_us': savedAtUs,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchSummaryRecordsCompanion copyWith({
    Value<String>? batchId,
    Value<int>? total,
    Value<int>? completed,
    Value<int>? failed,
    Value<int>? skipped,
    Value<int>? cancelled,
    Value<int>? totalBytes,
    Value<int>? elapsedMs,
    Value<String>? failuresJson,
    Value<String>? skippedItemsJson,
    Value<int>? savedAtUs,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BatchSummaryRecordsCompanion(
      batchId: batchId ?? this.batchId,
      total: total ?? this.total,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
      cancelled: cancelled ?? this.cancelled,
      totalBytes: totalBytes ?? this.totalBytes,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      failuresJson: failuresJson ?? this.failuresJson,
      skippedItemsJson: skippedItemsJson ?? this.skippedItemsJson,
      savedAtUs: savedAtUs ?? this.savedAtUs,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (completed.present) {
      map['completed'] = Variable<int>(completed.value);
    }
    if (failed.present) {
      map['failed'] = Variable<int>(failed.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<int>(skipped.value);
    }
    if (cancelled.present) {
      map['cancelled'] = Variable<int>(cancelled.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (failuresJson.present) {
      map['failures_json'] = Variable<String>(failuresJson.value);
    }
    if (skippedItemsJson.present) {
      map['skipped_items_json'] = Variable<String>(skippedItemsJson.value);
    }
    if (savedAtUs.present) {
      map['saved_at_us'] = Variable<int>(savedAtUs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchSummaryRecordsCompanion(')
          ..write('batchId: $batchId, ')
          ..write('total: $total, ')
          ..write('completed: $completed, ')
          ..write('failed: $failed, ')
          ..write('skipped: $skipped, ')
          ..write('cancelled: $cancelled, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('failuresJson: $failuresJson, ')
          ..write('skippedItemsJson: $skippedItemsJson, ')
          ..write('savedAtUs: $savedAtUs, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobRecordsTable jobRecords = $JobRecordsTable(this);
  late final $BatchSummaryRecordsTable batchSummaryRecords =
      $BatchSummaryRecordsTable(this);
  late final Index idxJobsBatchId = Index(
    'idx_jobs_batch_id',
    'CREATE INDEX idx_jobs_batch_id ON jobs (batch_id)',
  );
  late final Index idxJobsCreatedAt = Index(
    'idx_jobs_created_at',
    'CREATE INDEX idx_jobs_created_at ON jobs (created_at)',
  );
  late final Index idxBatchSummariesSavedAt = Index(
    'idx_batch_summaries_saved_at',
    'CREATE INDEX idx_batch_summaries_saved_at ON batch_summaries (saved_at_us)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    jobRecords,
    batchSummaryRecords,
    idxJobsBatchId,
    idxJobsCreatedAt,
    idxBatchSummariesSavedAt,
  ];
}

typedef $$JobRecordsTableCreateCompanionBuilder =
    JobRecordsCompanion Function({
      required String id,
      required String batchId,
      required String url,
      required String sourceId,
      required String sourceLabel,
      required String title,
      required String downloadType,
      required String status,
      Value<double> progress,
      Value<int?> downloadedBytes,
      Value<int?> totalBytes,
      Value<double?> bytesPerSecond,
      Value<int?> etaMs,
      Value<String?> errorCode,
      Value<String?> errorDetails,
      Value<bool> errorRetryable,
      Value<String?> filePath,
      Value<String?> relativePath,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<int> itemIndex,
      Value<int> itemCount,
      Value<String> zipEntriesJson,
      Value<String> itemSkippedJson,
      Value<int> rowid,
    });
typedef $$JobRecordsTableUpdateCompanionBuilder =
    JobRecordsCompanion Function({
      Value<String> id,
      Value<String> batchId,
      Value<String> url,
      Value<String> sourceId,
      Value<String> sourceLabel,
      Value<String> title,
      Value<String> downloadType,
      Value<String> status,
      Value<double> progress,
      Value<int?> downloadedBytes,
      Value<int?> totalBytes,
      Value<double?> bytesPerSecond,
      Value<int?> etaMs,
      Value<String?> errorCode,
      Value<String?> errorDetails,
      Value<bool> errorRetryable,
      Value<String?> filePath,
      Value<String?> relativePath,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<int> itemIndex,
      Value<int> itemCount,
      Value<String> zipEntriesJson,
      Value<String> itemSkippedJson,
      Value<int> rowid,
    });

class $$JobRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $JobRecordsTable> {
  $$JobRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadType => $composableBuilder(
    column: $table.downloadType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bytesPerSecond => $composableBuilder(
    column: $table.bytesPerSecond,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get etaMs => $composableBuilder(
    column: $table.etaMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get errorRetryable => $composableBuilder(
    column: $table.errorRetryable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemIndex => $composableBuilder(
    column: $table.itemIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zipEntriesJson => $composableBuilder(
    column: $table.zipEntriesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemSkippedJson => $composableBuilder(
    column: $table.itemSkippedJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $JobRecordsTable> {
  $$JobRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadType => $composableBuilder(
    column: $table.downloadType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bytesPerSecond => $composableBuilder(
    column: $table.bytesPerSecond,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get etaMs => $composableBuilder(
    column: $table.etaMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get errorRetryable => $composableBuilder(
    column: $table.errorRetryable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemIndex => $composableBuilder(
    column: $table.itemIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zipEntriesJson => $composableBuilder(
    column: $table.zipEntriesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemSkippedJson => $composableBuilder(
    column: $table.itemSkippedJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobRecordsTable> {
  $$JobRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get downloadType => $composableBuilder(
    column: $table.downloadType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bytesPerSecond => $composableBuilder(
    column: $table.bytesPerSecond,
    builder: (column) => column,
  );

  GeneratedColumn<int> get etaMs =>
      $composableBuilder(column: $table.etaMs, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get errorRetryable => $composableBuilder(
    column: $table.errorRetryable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemIndex =>
      $composableBuilder(column: $table.itemIndex, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<String> get zipEntriesJson => $composableBuilder(
    column: $table.zipEntriesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemSkippedJson => $composableBuilder(
    column: $table.itemSkippedJson,
    builder: (column) => column,
  );
}

class $$JobRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobRecordsTable,
          JobRecord,
          $$JobRecordsTableFilterComposer,
          $$JobRecordsTableOrderingComposer,
          $$JobRecordsTableAnnotationComposer,
          $$JobRecordsTableCreateCompanionBuilder,
          $$JobRecordsTableUpdateCompanionBuilder,
          (
            JobRecord,
            BaseReferences<_$AppDatabase, $JobRecordsTable, JobRecord>,
          ),
          JobRecord,
          PrefetchHooks Function()
        > {
  $$JobRecordsTableTableManager(_$AppDatabase db, $JobRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> sourceLabel = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> downloadType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int?> downloadedBytes = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<double?> bytesPerSecond = const Value.absent(),
                Value<int?> etaMs = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorDetails = const Value.absent(),
                Value<bool> errorRetryable = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> relativePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> itemIndex = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String> zipEntriesJson = const Value.absent(),
                Value<String> itemSkippedJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobRecordsCompanion(
                id: id,
                batchId: batchId,
                url: url,
                sourceId: sourceId,
                sourceLabel: sourceLabel,
                title: title,
                downloadType: downloadType,
                status: status,
                progress: progress,
                downloadedBytes: downloadedBytes,
                totalBytes: totalBytes,
                bytesPerSecond: bytesPerSecond,
                etaMs: etaMs,
                errorCode: errorCode,
                errorDetails: errorDetails,
                errorRetryable: errorRetryable,
                filePath: filePath,
                relativePath: relativePath,
                createdAt: createdAt,
                completedAt: completedAt,
                itemIndex: itemIndex,
                itemCount: itemCount,
                zipEntriesJson: zipEntriesJson,
                itemSkippedJson: itemSkippedJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String batchId,
                required String url,
                required String sourceId,
                required String sourceLabel,
                required String title,
                required String downloadType,
                required String status,
                Value<double> progress = const Value.absent(),
                Value<int?> downloadedBytes = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<double?> bytesPerSecond = const Value.absent(),
                Value<int?> etaMs = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorDetails = const Value.absent(),
                Value<bool> errorRetryable = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> relativePath = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> itemIndex = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String> zipEntriesJson = const Value.absent(),
                Value<String> itemSkippedJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobRecordsCompanion.insert(
                id: id,
                batchId: batchId,
                url: url,
                sourceId: sourceId,
                sourceLabel: sourceLabel,
                title: title,
                downloadType: downloadType,
                status: status,
                progress: progress,
                downloadedBytes: downloadedBytes,
                totalBytes: totalBytes,
                bytesPerSecond: bytesPerSecond,
                etaMs: etaMs,
                errorCode: errorCode,
                errorDetails: errorDetails,
                errorRetryable: errorRetryable,
                filePath: filePath,
                relativePath: relativePath,
                createdAt: createdAt,
                completedAt: completedAt,
                itemIndex: itemIndex,
                itemCount: itemCount,
                zipEntriesJson: zipEntriesJson,
                itemSkippedJson: itemSkippedJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobRecordsTable, JobRecord>(table),
                  BaseReferences<_$AppDatabase, $JobRecordsTable, JobRecord>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobRecordsTable,
      JobRecord,
      $$JobRecordsTableFilterComposer,
      $$JobRecordsTableOrderingComposer,
      $$JobRecordsTableAnnotationComposer,
      $$JobRecordsTableCreateCompanionBuilder,
      $$JobRecordsTableUpdateCompanionBuilder,
      (JobRecord, BaseReferences<_$AppDatabase, $JobRecordsTable, JobRecord>),
      JobRecord,
      PrefetchHooks Function()
    >;
typedef $$BatchSummaryRecordsTableCreateCompanionBuilder =
    BatchSummaryRecordsCompanion Function({
      required String batchId,
      required int total,
      required int completed,
      required int failed,
      required int skipped,
      required int cancelled,
      required int totalBytes,
      required int elapsedMs,
      Value<String> failuresJson,
      Value<String> skippedItemsJson,
      required int savedAtUs,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BatchSummaryRecordsTableUpdateCompanionBuilder =
    BatchSummaryRecordsCompanion Function({
      Value<String> batchId,
      Value<int> total,
      Value<int> completed,
      Value<int> failed,
      Value<int> skipped,
      Value<int> cancelled,
      Value<int> totalBytes,
      Value<int> elapsedMs,
      Value<String> failuresJson,
      Value<String> skippedItemsJson,
      Value<int> savedAtUs,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$BatchSummaryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BatchSummaryRecordsTable> {
  $$BatchSummaryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failuresJson => $composableBuilder(
    column: $table.failuresJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skippedItemsJson => $composableBuilder(
    column: $table.skippedItemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedAtUs => $composableBuilder(
    column: $table.savedAtUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatchSummaryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchSummaryRecordsTable> {
  $$BatchSummaryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failuresJson => $composableBuilder(
    column: $table.failuresJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skippedItemsJson => $composableBuilder(
    column: $table.skippedItemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedAtUs => $composableBuilder(
    column: $table.savedAtUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchSummaryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchSummaryRecordsTable> {
  $$BatchSummaryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get failed =>
      $composableBuilder(column: $table.failed, builder: (column) => column);

  GeneratedColumn<int> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<int> get cancelled =>
      $composableBuilder(column: $table.cancelled, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<String> get failuresJson => $composableBuilder(
    column: $table.failuresJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skippedItemsJson => $composableBuilder(
    column: $table.skippedItemsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedAtUs =>
      $composableBuilder(column: $table.savedAtUs, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BatchSummaryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchSummaryRecordsTable,
          BatchSummaryRecord,
          $$BatchSummaryRecordsTableFilterComposer,
          $$BatchSummaryRecordsTableOrderingComposer,
          $$BatchSummaryRecordsTableAnnotationComposer,
          $$BatchSummaryRecordsTableCreateCompanionBuilder,
          $$BatchSummaryRecordsTableUpdateCompanionBuilder,
          (
            BatchSummaryRecord,
            BaseReferences<
              _$AppDatabase,
              $BatchSummaryRecordsTable,
              BatchSummaryRecord
            >,
          ),
          BatchSummaryRecord,
          PrefetchHooks Function()
        > {
  $$BatchSummaryRecordsTableTableManager(
    _$AppDatabase db,
    $BatchSummaryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchSummaryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchSummaryRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BatchSummaryRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> batchId = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> completed = const Value.absent(),
                Value<int> failed = const Value.absent(),
                Value<int> skipped = const Value.absent(),
                Value<int> cancelled = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<String> failuresJson = const Value.absent(),
                Value<String> skippedItemsJson = const Value.absent(),
                Value<int> savedAtUs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchSummaryRecordsCompanion(
                batchId: batchId,
                total: total,
                completed: completed,
                failed: failed,
                skipped: skipped,
                cancelled: cancelled,
                totalBytes: totalBytes,
                elapsedMs: elapsedMs,
                failuresJson: failuresJson,
                skippedItemsJson: skippedItemsJson,
                savedAtUs: savedAtUs,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String batchId,
                required int total,
                required int completed,
                required int failed,
                required int skipped,
                required int cancelled,
                required int totalBytes,
                required int elapsedMs,
                Value<String> failuresJson = const Value.absent(),
                Value<String> skippedItemsJson = const Value.absent(),
                required int savedAtUs,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BatchSummaryRecordsCompanion.insert(
                batchId: batchId,
                total: total,
                completed: completed,
                failed: failed,
                skipped: skipped,
                cancelled: cancelled,
                totalBytes: totalBytes,
                elapsedMs: elapsedMs,
                failuresJson: failuresJson,
                skippedItemsJson: skippedItemsJson,
                savedAtUs: savedAtUs,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BatchSummaryRecordsTable, BatchSummaryRecord>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $BatchSummaryRecordsTable,
                    BatchSummaryRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchSummaryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchSummaryRecordsTable,
      BatchSummaryRecord,
      $$BatchSummaryRecordsTableFilterComposer,
      $$BatchSummaryRecordsTableOrderingComposer,
      $$BatchSummaryRecordsTableAnnotationComposer,
      $$BatchSummaryRecordsTableCreateCompanionBuilder,
      $$BatchSummaryRecordsTableUpdateCompanionBuilder,
      (
        BatchSummaryRecord,
        BaseReferences<
          _$AppDatabase,
          $BatchSummaryRecordsTable,
          BatchSummaryRecord
        >,
      ),
      BatchSummaryRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobRecordsTableTableManager get jobRecords =>
      $$JobRecordsTableTableManager(_db, _db.jobRecords);
  $$BatchSummaryRecordsTableTableManager get batchSummaryRecords =>
      $$BatchSummaryRecordsTableTableManager(_db, _db.batchSummaryRecords);
}
