import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@TableIndex(name: 'idx_jobs_batch_id', columns: {#batchId})
@TableIndex(name: 'idx_jobs_created_at', columns: {#createdAt})
class JobRecords extends Table {
  @override
  String get tableName => 'jobs';

  TextColumn get id => text()();
  TextColumn get batchId => text()();
  TextColumn get url => text()();
  TextColumn get sourceId => text()();
  TextColumn get sourceLabel => text()();
  TextColumn get title => text()();
  TextColumn get downloadType => text()();
  TextColumn get status => text()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().nullable()();
  IntColumn get totalBytes => integer().nullable()();
  RealColumn get bytesPerSecond => real().nullable()();
  IntColumn get etaMs => integer().nullable()();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorDetails => text().nullable()();
  BoolColumn get errorRetryable =>
      boolean().withDefault(const Constant(false))();
  TextColumn get filePath => text().nullable()();
  TextColumn get relativePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get itemIndex => integer().withDefault(const Constant(1))();
  IntColumn get itemCount => integer().withDefault(const Constant(1))();
  TextColumn get zipEntriesJson => text().withDefault(const Constant('[]'))();
  TextColumn get itemSkippedJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_batch_summaries_saved_at', columns: {#savedAtUs})
class BatchSummaryRecords extends Table {
  @override
  String get tableName => 'batch_summaries';

  TextColumn get batchId => text()();
  IntColumn get total => integer()();
  IntColumn get completed => integer()();
  IntColumn get failed => integer()();
  IntColumn get skipped => integer()();
  IntColumn get cancelled => integer()();
  IntColumn get totalBytes => integer()();
  IntColumn get elapsedMs => integer()();
  TextColumn get failuresJson => text().withDefault(const Constant('[]'))();
  TextColumn get skippedItemsJson => text().withDefault(const Constant('[]'))();
  IntColumn get savedAtUs => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {batchId};
}

@DriftDatabase(tables: [JobRecords, BatchSummaryRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'mediaflow',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
