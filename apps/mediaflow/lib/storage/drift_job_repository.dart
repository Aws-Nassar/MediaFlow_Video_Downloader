import 'package:drift/drift.dart';

import '../models/media_models.dart';
import 'app_database.dart';
import 'job_repository.dart';
import 'persistence_codec.dart';

class DriftJobRepository implements JobRepository {
  DriftJobRepository(this.database);

  final AppDatabase database;
  int _lastSummaryOrder = 0;

  @override
  Future<List<DownloadJob>> loadJobs() async {
    final query = database.select(database.jobRecords)
      ..orderBy([
        (table) => OrderingTerm.asc(table.createdAt),
        (table) => OrderingTerm.asc(table.id),
      ]);
    final rows = await query.get();
    return [for (final row in rows) _jobFromRecord(row)];
  }

  @override
  Future<List<BatchSummary>> loadSummaries() async {
    final query = database.select(database.batchSummaryRecords)
      ..orderBy([(table) => OrderingTerm.desc(table.savedAtUs)]);
    final rows = await query.get();
    for (final row in rows) {
      if (row.savedAtUs > _lastSummaryOrder) {
        _lastSummaryOrder = row.savedAtUs;
      }
    }
    return [for (final row in rows) _summaryFromRecord(row)];
  }

  @override
  Future<void> saveJob(DownloadJob job) async {
    await database
        .into(database.jobRecords)
        .insertOnConflictUpdate(_jobCompanion(job));
  }

  @override
  Future<void> saveJobProgress(DownloadJob job) async {
    final update = database.update(database.jobRecords)
      ..where((table) => table.id.equals(job.id));
    await update.write(
      JobRecordsCompanion(
        status: Value(job.status.name),
        progress: Value(job.progress),
        downloadedBytes: Value(job.downloadedBytes),
        totalBytes: Value(job.totalBytes),
        bytesPerSecond: Value(job.bytesPerSecond),
        etaMs: Value(job.eta?.inMilliseconds),
      ),
    );
  }

  @override
  Future<void> deleteJob(String id) async {
    final delete = database.delete(database.jobRecords)
      ..where((table) => table.id.equals(id));
    await delete.go();
  }

  @override
  Future<void> saveSummary(BatchSummary summary) async {
    await database
        .into(database.batchSummaryRecords)
        .insertOnConflictUpdate(
          BatchSummaryRecordsCompanion(
            batchId: Value(summary.batchId),
            total: Value(summary.total),
            completed: Value(summary.completed),
            failed: Value(summary.failed),
            skipped: Value(summary.skipped),
            cancelled: Value(summary.cancelled),
            totalBytes: Value(summary.totalBytes),
            elapsedMs: Value(summary.elapsed.inMilliseconds),
            failuresJson: Value(encodeFailures(summary.failures)),
            skippedItemsJson: Value(encodeFailures(summary.skippedItems)),
            savedAtUs: Value(_nextSummaryOrder()),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  int _nextSummaryOrder() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastSummaryOrder = now > _lastSummaryOrder ? now : _lastSummaryOrder + 1;
    return _lastSummaryOrder;
  }

  @override
  Future<void> deleteSummary(String batchId) async {
    final delete = database.delete(database.batchSummaryRecords)
      ..where((table) => table.batchId.equals(batchId));
    await delete.go();
  }

  @override
  Future<void> close() => database.close();
}

DownloadJob _jobFromRecord(JobRecord row) {
  final code = errorCodeFromName(row.errorCode);
  return DownloadJob(
    id: row.id,
    batchId: row.batchId,
    url: row.url,
    sourceId: row.sourceId,
    sourceLabel: row.sourceLabel,
    title: row.title,
    downloadType: downloadTypeFromName(row.downloadType),
    status: jobStatusFromName(row.status),
    progress: row.progress,
    downloadedBytes: row.downloadedBytes,
    totalBytes: row.totalBytes,
    bytesPerSecond: row.bytesPerSecond,
    eta: row.etaMs == null ? null : Duration(milliseconds: row.etaMs!),
    error: code == null
        ? null
        : MediaFlowError(
            code: code,
            technicalDetails: row.errorDetails,
            retryable: row.errorRetryable,
          ),
    filePath: row.filePath,
    relativePath: row.relativePath,
    createdAt: row.createdAt,
    completedAt: row.completedAt,
    itemIndex: row.itemIndex,
    itemCount: row.itemCount,
    zipEntries: decodeEntries(row.zipEntriesJson),
    itemSkipped: decodeFailures(row.itemSkippedJson),
  );
}

JobRecordsCompanion _jobCompanion(DownloadJob job) {
  return JobRecordsCompanion(
    id: Value(job.id),
    batchId: Value(job.batchId),
    url: Value(job.url),
    sourceId: Value(job.sourceId),
    sourceLabel: Value(job.sourceLabel),
    title: Value(job.title),
    downloadType: Value(job.downloadType.name),
    status: Value(job.status.name),
    progress: Value(job.progress),
    downloadedBytes: Value(job.downloadedBytes),
    totalBytes: Value(job.totalBytes),
    bytesPerSecond: Value(job.bytesPerSecond),
    etaMs: Value(job.eta?.inMilliseconds),
    errorCode: Value(job.error?.code.name),
    errorDetails: Value(job.error?.technicalDetails),
    errorRetryable: Value(job.error?.retryable ?? false),
    filePath: Value(job.filePath),
    relativePath: Value(job.relativePath),
    createdAt: Value(job.createdAt),
    completedAt: Value(job.completedAt),
    itemIndex: Value(job.itemIndex),
    itemCount: Value(job.itemCount),
    zipEntriesJson: Value(encodeEntries(job.zipEntries)),
    itemSkippedJson: Value(encodeFailures(job.itemSkipped)),
  );
}

BatchSummary _summaryFromRecord(BatchSummaryRecord row) {
  return BatchSummary(
    batchId: row.batchId,
    total: row.total,
    completed: row.completed,
    failed: row.failed,
    skipped: row.skipped,
    cancelled: row.cancelled,
    totalBytes: row.totalBytes,
    elapsed: Duration(milliseconds: row.elapsedMs),
    failures: decodeFailures(row.failuresJson),
    skippedItems: decodeFailures(row.skippedItemsJson),
  );
}
